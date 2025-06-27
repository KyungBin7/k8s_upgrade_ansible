# SSH 키 생성 및 배포 가이드

Kubernetes 클러스터 업그레이드를 수행하기 전에 SSH 키 기반 인증을 설정해야 합니다.

## 🔑 SSH 키 생성 및 배포

### 방법 1: 자동 SSH 키 설정 (권장)

#### 1. SSH 키 자동 생성 및 배포
```bash
# 패스워드 입력이 필요합니다 (-k 옵션)
ansible-playbook ssh-setup.yml -k
```

실행 시 각 서버의 root 패스워드를 입력해야 합니다:
```
SSH password: [각 서버의 root 패스워드 입력]
```

#### 2. 배포 완료 확인
```bash
# 패스워드 없이 연결되는지 확인
ansible all -m ping

# 결과 예시:
# master1 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

### 방법 2: 수동 SSH 키 설정

#### 1. SSH 키 생성 (로컬)
```bash
# RSA 3072bit 키 생성
ssh-keygen -t rsa -b 3072 -f ~/.ssh/id_rsa_k8s -C "k8s-cluster"

# 또는 기본 키 사용
ssh-keygen -t rsa -b 3072
```

#### 2. SSH 키 수동 배포
```bash
# 각 서버에 공개키 복사
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.40.151.121
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.40.151.122
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.40.151.123
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.40.151.131
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.40.151.132
```

#### 3. 연결 테스트
```bash
# 각 서버에 패스워드 없이 연결되는지 확인
ssh root@10.40.151.121 "whoami"
ssh root@10.40.151.122 "whoami"
ssh root@10.40.151.123 "whoami"
ssh root@10.40.151.131 "whoami"
ssh root@10.40.151.132 "whoami"
```

## 🚀 전체 워크플로우

### 1. SSH 키 설정
```bash
# 자동 SSH 키 설정
ansible-playbook ssh-setup.yml -k
```

### 2. 연결 확인
```bash
# 모든 노드 연결 확인
ansible all -m ping

# 그룹별 연결 확인
ansible k8s_masters -m ping
ansible k8s_workers -m ping
```

### 3. 현재 상태 확인
```bash
# Kubernetes 버전 확인
ansible k8s_cluster -m shell -a "kubectl version --short"

# 노드 상태 확인
ansible k8s_masters -m shell -a "kubectl get nodes"

# CRI-O 상태 확인
ansible k8s_cluster -m shell -a "systemctl status crio"
```

### 4. Kubernetes 업그레이드
```bash
# Dry-run 실행
ansible-playbook playbook.yml --check

# 실제 업그레이드 실행
ansible-playbook playbook.yml
```

## 🔧 사용자 환경별 설정

### Root 사용자 환경 (현재 설정)
```ini
# inventory/hosts
[k8s_masters]
master1 ansible_host=10.40.151.121 ansible_user=root
master2 ansible_host=10.40.151.122 ansible_user=root
master3 ansible_host=10.40.151.123 ansible_user=root

[k8s_workers]
worker1 ansible_host=10.40.151.131 ansible_user=root
worker2 ansible_host=10.40.151.132 ansible_user=root
```

### 일반 사용자 환경 (sudo 권한 필요)
```ini
# inventory/hosts
[k8s_masters]
master1 ansible_host=10.40.151.121 ansible_user=rocky
master2 ansible_host=10.40.151.122 ansible_user=rocky
master3 ansible_host=10.40.151.123 ansible_user=rocky

[k8s_workers]
worker1 ansible_host=10.40.151.131 ansible_user=rocky
worker2 ansible_host=10.40.151.132 ansible_user=rocky

[k8s_cluster:vars]
ansible_become=true
ansible_become_method=sudo
```

## 🚨 문제 해결

### SSH 키 충돌 문제
```bash
# 기존 키 백업
cp ~/.ssh/id_rsa ~/.ssh/id_rsa.backup
cp ~/.ssh/id_rsa.pub ~/.ssh/id_rsa.pub.backup

# 새 키 생성
ssh-keygen -t rsa -b 3072 -f ~/.ssh/id_rsa -N "" -q
```

### 패스워드 인증 실패
```bash
# SSH 접근 가능 여부 확인
ssh root@10.40.151.121

# 방화벽 확인
ansible all -m shell -a "systemctl status sshd" -k
```

### 권한 문제
```bash
# authorized_keys 권한 확인
ansible all -m file -a "path=/root/.ssh/authorized_keys mode=0600 owner=root group=root" -k
```

### 네트워크 연결 문제
```bash
# 네트워크 연결 테스트
ping 10.40.151.121
ping 10.40.151.122
ping 10.40.151.123
ping 10.40.151.131
ping 10.40.151.132

# Ansible 연결 테스트
ansible all -m setup -a "filter=ansible_default_ipv4" -k
```

## 📋 체크리스트

배포 전 확인 사항:

- [ ] SSH 서비스가 모든 노드에서 실행 중
- [ ] 방화벽에서 SSH 포트(22) 허용
- [ ] inventory/hosts 파일에 올바른 IP 주소 설정
- [ ] 각 노드의 root 패스워드 준비
- [ ] 로컬 머신에서 모든 노드로 네트워크 연결 가능

배포 후 확인 사항:

- [ ] `ansible all -m ping` 성공
- [ ] `ssh root@SERVER_IP` 패스워드 없이 연결
- [ ] `ansible k8s_cluster -m shell -a "whoami"` 실행 성공

## 🎯 다음 단계

SSH 키 설정이 완료되면:

1. **클러스터 상태 확인**: `ansible-playbook playbook.yml --tags preflight`
2. **백업 실행**: `ansible-playbook playbook.yml --tags backup`
3. **업그레이드 실행**: `ansible-playbook playbook.yml`

모든 설정이 완료되면 패스워드 없이 안전하게 Kubernetes 클러스터를 업그레이드할 수 있습니다! 