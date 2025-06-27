# Kubernetes 클러스터 업그레이드 Ansible Role

바이너리 또는 패키지로 설치된 Kubernetes 클러스터를 안전하게 업그레이드하는 재사용 가능한 Ansible Role입니다.

## 특징

- **자동 버전 감지**: 현재 Kubernetes 버전을 자동으로 감지
- **스마트 업그레이드**: 다음 마이너 버전으로 자동 업그레이드 또는 수동 버전 지정
- **다중 설치 방식 지원**: 패키지 관리자(yum/apt) 및 바이너리 설치 모두 지원
- **인텔리전트 Repository 선택**: K8s 공식 repo 지원 여부에 따라 자동으로 최적의 repo 선택
- **롤링 업그레이드**: 무중단 서비스를 위한 순차적 노드 업그레이드
- **자동 백업**: etcd 스냅샷 및 설정 파일 백업
- **포괄적인 검증**: 업그레이드 전후 상태 검증
- **CRI-O 런타임 지원**: CRI-O 컨테이너 런타임 환경 최적화
- **OS 호환성**: Rocky Linux, CentOS, Ubuntu 지원

## 지원 버전

- **Kubernetes**: 1.23 - 1.28
- **OS**: Rocky 8/9, CentOS 8/9, Ubuntu 18.04/20.04/22.04
- **Ansible**: 2.9+

## 요구사항

### 컨트롤 노드
- Ansible 2.9 이상
- Python 3.6 이상

### 타겟 노드
- sudo 권한을 가진 사용자
- kubectl, kubeadm, kubelet 설치됨
- CRI-O 컨테이너 런타임 설치됨
- 인터넷 연결 (바이너리 다운로드용)

## 설치

### Ansible Galaxy를 통한 설치
```bash
ansible-galaxy install metanet.k8s_cluster_upgrade
```

### Git을 통한 설치
```bash
git clone https://github.com/metanet/k8s-cluster-upgrade-ansible.git
cd k8s-cluster-upgrade-ansible
```

## 사용법

### 기본 사용법 (자동 버전 업그레이드)

```yaml
# playbook.yml
---
- hosts: k8s_cluster
  become: yes
  roles:
    - metanet.k8s_cluster_upgrade
```

### 고급 설정

```yaml
# playbook.yml
---
- hosts: k8s_cluster
  become: yes
  vars:
    # 특정 버전으로 업그레이드
    k8s_target_version: "1.25.0"
    k8s_force_version: true
    
    # 백업 설정
    k8s_backup_enabled: true
    k8s_backup_dir: "/opt/k8s-backup"
    
    # 업그레이드 전략
    k8s_upgrade_strategy: "rolling"
    k8s_upgrade_timeout: 900
    
    # 드레인 설정
    k8s_upgrade_skip_drain: false
    k8s_upgrade_drain_timeout: 600
  roles:
    - metanet.k8s_cluster_upgrade
```

### 인벤토리 예제

```ini
# inventory/hosts
[k8s_masters]
master1 ansible_host=192.168.1.10
master2 ansible_host=192.168.1.11
master3 ansible_host=192.168.1.12

[k8s_workers]
worker1 ansible_host=192.168.1.20
worker2 ansible_host=192.168.1.21
worker3 ansible_host=192.168.1.22

[k8s_cluster:children]
k8s_masters
k8s_workers

[k8s_cluster:vars]
ansible_user=rocky
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

## 주요 변수

### 버전 관리
| 변수 | 기본값 | 설명 |
|------|--------|------|
| `k8s_current_version` | `""` | 현재 버전 (자동 감지) |
| `k8s_target_version` | `""` | 목표 버전 (미지정시 다음 버전) |
| `k8s_force_version` | `false` | 강제 버전 지정 |

### 업그레이드 설정
| 변수 | 기본값 | 설명 |
|------|--------|------|
| `k8s_upgrade_strategy` | `"rolling"` | 업그레이드 전략 |
| `k8s_upgrade_timeout` | `600` | 업그레이드 타임아웃 (초) |
| `k8s_upgrade_skip_drain` | `false` | 드레인 건너뛰기 |
| `k8s_upgrade_drain_timeout` | `300` | 드레인 타임아웃 (초) |

### 백업 설정
| 변수 | 기본값 | 설명 |
|------|--------|------|
| `k8s_backup_enabled` | `true` | 백업 활성화 |
| `k8s_backup_dir` | `"/opt/k8s-backup"` | 백업 디렉터리 |
| `k8s_backup_retention_days` | `7` | 백업 보존 기간 |

### 경로 설정
| 변수 | 기본값 | 설명 |
|------|--------|------|
| `k8s_bin_dir` | `"/usr/local/bin"` | 바이너리 설치 경로 |
| `k8s_config_dir` | `"/etc/kubernetes"` | 설정 파일 경로 |

## 태그 사용법

특정 단계만 실행하려면 태그를 사용하세요:

```bash
# 사전 검사만 실행
ansible-playbook -i inventory/hosts playbook.yml --tags preflight

# 공식 repo 체크만 실행
ansible-playbook -i inventory/hosts playbook.yml --tags repo-check

# 백업만 실행
ansible-playbook -i inventory/hosts playbook.yml --tags backup

# 검증만 실행
ansible-playbook -i inventory/hosts playbook.yml --tags verify

# 컨트롤 플레인만 업그레이드
ansible-playbook -i inventory/hosts playbook.yml --tags control-plane

# 워커 노드만 업그레이드
ansible-playbook -i inventory/hosts playbook.yml --tags worker
```

## 업그레이드 프로세스

1. **사전 검사**: 시스템 요구사항 및 네트워크 연결 확인
2. **버전 감지**: 현재 Kubernetes 버전 자동 감지
3. **목표 버전 결정**: 업그레이드할 버전 결정
4. **공식 Repository 체크**: K8s 공식 repo 지원 여부 확인 및 최적 repo 선택
5. **백업**: etcd 스냅샷 및 중요 설정 파일 백업
6. **역할 감지**: 노드가 마스터인지 워커인지 자동 감지
7. **첫 번째 마스터 업그레이드**: 첫 번째 컨트롤 플레인 노드 업그레이드
8. **추가 마스터 업그레이드**: 나머지 컨트롤 플레인 노드들 순차 업그레이드
9. **워커 노드 업그레이드**: 모든 워커 노드들 순차 업그레이드
10. **검증**: 클러스터 상태 및 기능 검증
11. **정리**: 임시 파일 정리 및 최종 상태 확인

## 트러블슈팅

### 일반적인 문제들

#### 1. kubectl 연결 실패
```yaml
# kubeconfig 경로 확인
k8s_kubeconfig_path: "/etc/kubernetes/admin.conf"
```

#### 2. 드레인 실패
```yaml
# 드레인 건너뛰기
k8s_upgrade_skip_drain: true
```

#### 3. 타임아웃 발생
```yaml
# 타임아웃 늘리기
k8s_upgrade_timeout: 1200
k8s_upgrade_drain_timeout: 600
```

#### 4. 백업 공간 부족
```yaml
# 백업 비활성화 (권장하지 않음)
k8s_backup_enabled: false
```

### 로그 확인

```bash
# 업그레이드 로그 확인
tail -f /var/log/k8s-upgrade.log

# 서비스 상태 확인
systemctl status kubelet
journalctl -u kubelet -f
```

### 수동 복구

업그레이드가 실패한 경우:

1. **백업에서 복구**
```bash
# etcd 복구
sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd/*
sudo etcdctl snapshot restore /opt/k8s-backup/etcd-snapshot.db --data-dir=/var/lib/etcd
sudo systemctl start etcd
```

2. **설정 파일 복구**
```bash
sudo cp -r /opt/k8s-backup/kubernetes/* /etc/kubernetes/
```

## 개발자 정보

- **작성자**: MetaNet DevOps Team
- **라이센스**: MIT
- **저장소**: https://github.com/metanet/k8s-cluster-upgrade-ansible

## 기여

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요. 