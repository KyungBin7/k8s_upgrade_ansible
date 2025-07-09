# Kubernetes 클러스터 업그레이드 사용 가이드

## 🚀 빠른 시작

### 1. 환경 설정

```bash
# inventory 파일 수정 (필수)
vi inventory/hosts

# 실제 IP 주소와 사용자명으로 변경
[k8s_masters]
master1 ansible_host=YOUR_MASTER1_IP ansible_user=YOUR_USER
master2 ansible_host=YOUR_MASTER2_IP ansible_user=YOUR_USER

[k8s_workers]
worker1 ansible_host=YOUR_WORKER1_IP ansible_user=YOUR_USER
worker2 ansible_host=YOUR_WORKER2_IP ansible_user=YOUR_USER
```

### 2. 연결 테스트

```bash
# 모든 노드 연결 확인
ansible all -m ping

# 특정 그룹만 확인
ansible k8s_masters -m ping
ansible k8s_workers -m ping
```

### 3. 현재 상태 확인

```bash
# 현재 Kubernetes 버전 확인
ansible k8s_cluster -m shell -a "kubectl version --short"

# 노드 상태 확인
ansible k8s_masters -m shell -a "kubectl get nodes"

# CRI-O 상태 확인
ansible k8s_cluster -m shell -a "systemctl status crio"
```

## 📋 업그레이드 시나리오

### 시나리오 1: 자동 버전 업그레이드 (권장)

```bash
# Dry-run 먼저 실행
ansible-playbook playbook.yml --check

# 실제 업그레이드 실행
ansible-playbook playbook.yml
```

### 시나리오 2: 특정 버전으로 업그레이드

```bash
# inventory/hosts 파일에서 설정
# k8s_target_version=v1.24.0
# k8s_force_version=true

# 또는 명령행에서 변수 전달
ansible-playbook playbook.yml -e "k8s_target_version=v1.24.0" -e "k8s_force_version=true"
```

### 시나리오 3: 인터랙티브 모드 (확인 프롬프트)

```bash
# 각 단계마다 확인 프롬프트 표시
ansible-playbook playbook.yml -e "k8s_interactive_mode=true"
```

### 시나리오 4: 단계별 실행

```bash
# 1. 사전 검사만 실행
ansible-playbook playbook.yml --tags preflight

# 2. 공식 repo 체크만 실행  
ansible-playbook playbook.yml --tags repo-check

# 3. 백업만 실행
ansible-playbook playbook.yml --tags backup

# 4. 마스터 노드만 업그레이드
ansible-playbook playbook.yml --tags control-plane

# 5. 워커 노드만 업그레이드
ansible-playbook playbook.yml --tags worker

# 6. 검증만 실행
ansible-playbook playbook.yml --tags verify
```

### 시나리오 5: 특정 노드만 업그레이드

```bash
# 특정 호스트만 업그레이드
ansible-playbook playbook.yml --limit master1

# 특정 그룹만 업그레이드
ansible-playbook playbook.yml --limit k8s_masters
ansible-playbook playbook.yml --limit k8s_workers
```

### 시나리오 6: 버그 버전 자동 회피

```bash
# 기본적으로 버그가 있는 버전은 자동으로 회피됩니다
# 예: 1.29.15 → 1.29.16+ 자동 교체

# 버그 버전 회피 비활성화 (권장하지 않음)
ansible-playbook playbook.yml -e "k8s_enable_buggy_version_override=false"

# 강제로 버그가 있는 버전 사용 (매우 위험)
ansible-playbook playbook.yml -e "k8s_target_version=v1.29.15" -e "k8s_force_version=true"

# 버그 버전 정보 확인
ansible-playbook playbook.yml --tags target -v
```

> **⚠️ 중요**: Kubernetes 1.29.15는 치명적인 버그가 있어 자동으로 1.29.16+ 버전으로 교체됩니다.
> 강제 모드(`k8s_force_version=true`)를 사용해도 치명적인 버그가 있는 버전은 차단됩니다.

## ⚙️ 고급 설정

### 업그레이드 전략 변경

```yaml
# inventory/hosts에서 설정
k8s_upgrade_strategy=all-at-once  # 모든 노드 동시 업그레이드
# 또는
k8s_upgrade_strategy=rolling      # 순차 업그레이드 (기본값)
```

### 백업 설정

```yaml
# 백업 비활성화 (권장하지 않음)
k8s_backup_enabled=false

# 백업 위치 변경
k8s_backup_dir=/custom/backup/path

# 백업 보존 기간 변경
k8s_backup_retention_days=14
```

### 타임아웃 설정

```yaml
# 전체 업그레이드 타임아웃 (초)
k8s_upgrade_timeout=1800  # 30분

# 드레인 타임아웃 (초)
k8s_upgrade_drain_timeout=900  # 15분
```

## 🔍 모니터링 및 로그

### 실시간 로그 확인

```bash
# Ansible 로그
tail -f ansible.log

# 각 노드에서 업그레이드 로그 확인
ansible k8s_cluster -m shell -a "tail -f /var/log/k8s-upgrade.log"

# kubelet 로그 확인
ansible k8s_cluster -m shell -a "journalctl -u kubelet -f"
```

### 클러스터 상태 모니터링

```bash
# 노드 상태 지속적으로 확인
watch kubectl get nodes

# 파드 상태 확인
watch kubectl get pods --all-namespaces

# 이벤트 모니터링
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🚨 문제 해결

### 일반적인 문제들

#### 1. SSH 연결 실패
```bash
# SSH 키 확인
ssh -i ~/.ssh/id_rsa rocky@192.168.1.10

# SSH 에이전트 확인
ssh-add -l
```

#### 2. sudo 권한 문제
```bash
# 사용자 sudo 권한 확인
ansible k8s_cluster -m shell -a "sudo whoami"
```

#### 3. 드레인 실패
```bash
# 드레인 건너뛰기
ansible-playbook playbook.yml -e "k8s_upgrade_skip_drain=true"
```

#### 4. 업그레이드 중단 시 복구
```bash
# 백업에서 복구
ansible k8s_cluster -m shell -a "ls -la /opt/k8s-backup/"

# 서비스 재시작
ansible k8s_cluster -m systemd -a "name=kubelet state=restarted"
ansible k8s_cluster -m systemd -a "name=crio state=restarted"
```

### 롤백 절차

1. **서비스 중지**
```bash
ansible k8s_cluster -m systemd -a "name=kubelet state=stopped"
```

2. **바이너리 복구**
```bash
# 백업 위치 확인 후 복구
ansible k8s_cluster -m copy -a "src=/opt/k8s-backup/TIMESTAMP/binaries/ dest=/usr/local/bin/ remote_src=yes mode=755"
```

3. **설정 파일 복구**
```bash
ansible k8s_cluster -m copy -a "src=/opt/k8s-backup/TIMESTAMP/etc/kubernetes/ dest=/etc/kubernetes/ remote_src=yes"
```

4. **서비스 재시작**
```bash
ansible k8s_cluster -m systemd -a "name=kubelet state=started"
```

## 📊 업그레이드 후 검증

```bash
# 클러스터 전체 상태 확인
kubectl cluster-info

# 모든 노드 Ready 상태 확인
kubectl get nodes

# 시스템 파드 상태 확인
kubectl get pods -n kube-system

# 애플리케이션 파드 상태 확인
kubectl get pods --all-namespaces

# 네트워킹 테스트
kubectl run test-pod --image=busybox --restart=Never --rm -it -- nslookup kubernetes.default
```

## 📞 지원

문제가 발생한 경우:

1. **로그 수집**: `ansible.log` 및 `/var/log/k8s-upgrade.log` 확인
2. **클러스터 상태**: `kubectl get events` 및 `kubectl describe nodes` 결과 수집  
3. **백업 확인**: `/opt/k8s-backup/` 디렉터리 내용 확인
4. **Issue 생성**: 상세한 환경 정보와 함께 GitHub Issue 생성 