# Kubernetes 클러스터 롤백 Ansible Role

이 Ansible role은 `k8s_cluster_upgrade` role에서 생성된 백업을 사용하여 Kubernetes 클러스터를 이전 상태로 롤백하는 기능을 제공합니다.

## 기능

- **완전한 롤백**: etcd, 설정 파일, 바이너리 파일을 모두 복원
- **선택적 롤백**: 필요한 구성 요소만 선택적으로 복원
- **자동 환경 감지**: 노드 역할, 패키지 관리자, 컨테이너 런타임 자동 감지
- **안전한 롤백**: 단계별 검증 및 복구 메커니즘
- **드라이런 모드**: 실제 작업 없이 계획만 확인
- **다양한 롤백 모드**: full, binary-only, config-only, etcd-only

## 지원 환경

- **OS**: Rocky Linux 8/9, CentOS 8/9, Ubuntu 18.04/20.04/22.04/24.04
- **Kubernetes**: k8s_cluster_upgrade role로 백업된 모든 버전
- **설치 방식**: 바이너리 설치, yum/apt 패키지 설치
- **컨테이너 런타임**: containerd, CRI-O, Docker

## 요구사항

- Ansible 2.12+
- root 권한 또는 sudo 권한
- k8s_cluster_upgrade role로 생성된 백업 존재
- 백업 디렉토리 접근 권한

## 설치

```bash
# Ansible Galaxy를 통한 설치 (향후 지원 예정)
ansible-galaxy install metanet.k8s_cluster_rollback

# 또는 직접 클론
git clone <repository_url>
```

## 사용법

### 기본 사용법

```bash
# 전체 롤백
ansible-playbook -i inventory/hosts rollback-playbook.yml \
  -e "k8s_backup_timestamp=1703123456"
```

### 롤백 모드별 사용법

```bash
# 바이너리만 롤백
ansible-playbook -i inventory/hosts rollback-playbook.yml \
  -e "k8s_backup_timestamp=1703123456" \
  -e "k8s_rollback_mode=binary-only"

# 설정 파일만 롤백
ansible-playbook -i inventory/hosts rollback-playbook.yml \
  -e "k8s_backup_timestamp=1703123456" \
  -e "k8s_rollback_mode=config-only"

# etcd만 롤백 (마스터 노드만)
ansible-playbook -i inventory/hosts rollback-playbook.yml \
  -e "k8s_backup_timestamp=1703123456" \
  -e "k8s_rollback_mode=etcd-only" \
  --limit k8s_masters
```

### 고급 사용법

```bash
# 드라이런 모드 (계획만 확인)
ansible-playbook -i inventory/hosts rollback-playbook.yml \
  -e "k8s_backup_timestamp=1703123456" \
  -e "k8s_dry_run=true"

# 확인 없이 강제 롤백 (CI/CD 환경)
ansible-playbook -i inventory/hosts rollback-playbook.yml \
  -e "k8s_backup_timestamp=1703123456" \
  -e "k8s_require_confirmation=false"

# 특정 태그만 실행
ansible-playbook -i inventory/hosts rollback-playbook.yml \
  -e "k8s_backup_timestamp=1703123456" \
  --tags "verify,restore"
```

## 변수

### 필수 변수

| 변수 | 설명 | 예시 |
|------|------|------|
| `k8s_backup_timestamp` | 복원할 백업의 타임스탬프 | `"1703123456"` |

### 주요 선택적 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `k8s_rollback_mode` | `"full"` | 롤백 모드 (full, binary-only, config-only, etcd-only) |
| `k8s_rollback_strategy` | `"safe"` | 롤백 전략 (safe, force, verify-only) |
| `k8s_require_confirmation` | `true` | 대화형 확인 프롬프트 활성화 |
| `k8s_dry_run` | `false` | 드라이런 모드 (계획만 표시) |
| `k8s_backup_before_rollback` | `false` | 롤백 전 현재 상태 백업 |
| `k8s_verify_rollback` | `true` | 롤백 후 검증 수행 |

### 경로 설정

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `k8s_backup_dir` | `"/opt/k8s-backup"` | 백업 루트 디렉토리 |
| `k8s_bin_dir` | `"/usr/local/bin"` | Kubernetes 바이너리 디렉토리 |
| `k8s_config_dir` | `"/etc/kubernetes"` | Kubernetes 설정 디렉토리 |

## 디렉토리 구조

```
k8s_cluster_rollback/
├── defaults/
│   └── main.yml          # 기본 변수
├── tasks/
│   ├── main.yml          # 메인 오케스트레이션
│   ├── 01_verify_backup.yml      # 백업 검증
│   ├── 02_detect_environment.yml # 환경 감지
│   ├── 04_prepare_rollback.yml   # 롤백 준비
│   ├── 05_restore_etcd.yml       # etcd 복원
│   └── 07_restore_binaries.yml   # 바이너리 복원
├── vars/
│   └── main.yml          # 내부 변수
├── meta/
│   └── main.yml          # Galaxy 메타데이터
└── README.md
```

## 롤백 과정

1. **백업 검증**: 백업 파일 존재 및 무결성 확인
2. **환경 감지**: 노드 역할, 패키지 관리자 등 자동 감지
3. **현재 상태 백업**: 롤백 전 현재 상태 백업 (선택적)
4. **클러스터 준비**: 서비스 중지, 네트워크 정리
5. **etcd 복원**: etcd 스냅샷 복원 (마스터 노드)
6. **설정 파일 복원**: Kubernetes 설정 파일 복원
7. **바이너리 복원**: Kubernetes 바이너리 복원
8. **서비스 재시작**: 클러스터 서비스 재시작
9. **검증**: 롤백 결과 검증
10. **정리**: 임시 파일 정리 및 완료

## 태그

| 태그 | 설명 |
|------|------|
| `rollback` | 모든 롤백 작업 |
| `verify` | 검증 관련 작업 |
| `preparation` | 준비 작업 |
| `restore` | 복원 작업 |
| `etcd` | etcd 관련 작업 |
| `binaries` | 바이너리 관련 작업 |
| `configs` | 설정 파일 관련 작업 |

## 백업 디렉토리 구조

롤백 role은 다음과 같은 백업 구조를 기대합니다:

```
/opt/k8s-backup/
└── {timestamp}/
    ├── backup-info.txt           # 백업 메타데이터
    ├── etcd-snapshot.db          # etcd 스냅샷
    ├── kubernetes.tar.gz         # Kubernetes 설정
    ├── etcd.tar.gz              # etcd 설정
    ├── kubelet.tar.gz           # kubelet 설정
    ├── binaries/                # 바이너리 파일
    │   ├── kubectl
    │   ├── kubelet
    │   └── kubeadm
    ├── systemd/                 # systemd 서비스 파일
    │   ├── kubelet.service
    │   └── 10-kubeadm.conf
    └── cluster-state/           # 클러스터 상태 정보
        ├── nodes.yaml
        ├── pods.yaml
        └── version.txt
```

## 문제 해결

### 일반적인 오류

1. **백업 파일 없음**
   ```
   TASK [k8s_cluster_rollback : 백업 디렉토리 존재 확인] ***
   fatal: [master1]: FAILED! => {"msg": "Backup directory not found"}
   ```
   - 해결: `k8s_backup_timestamp` 값 확인 및 백업 디렉토리 존재 여부 확인

2. **권한 오류**
   ```
   TASK [k8s_cluster_rollback : etcd 데이터 디렉토리 생성] ***
   fatal: [master1]: FAILED! => {"msg": "Permission denied"}
   ```
   - 해결: root 권한으로 실행하거나 적절한 sudo 권한 설정

3. **서비스 시작 실패**
   ```
   TASK [k8s_cluster_rollback : etcd 서비스 시작] ***
   fatal: [master1]: FAILED! => {"msg": "Service failed to start"}
   ```
   - 해결: 로그 확인 (`journalctl -u etcd`) 및 설정 파일 검증

### 복구 방법

1. **부분 실패 시**: `--start-at-task` 옵션으로 특정 태스크부터 재시작
2. **완전 실패 시**: `k8s_enable_recovery_mode=true`로 자동 복구 시도
3. **수동 복구**: 백업된 현재 상태에서 수동 복원

## 제한사항

- 현재 단일 마스터 클러스터만 지원 (멀티 마스터 지원 예정)
- 롤백 중 클러스터 서비스 중단 시간 발생
- 패키지 다운그레이드는 기본적으로 비활성화 (위험성)
- 네트워크 정책 및 PV/PVC는 별도 복원 필요할 수 있음

## 보안 고려사항

- 백업 파일에 민감한 정보 포함 (인증서, 토큰 등)
- 백업 디렉토리 접근 권한 적절히 설정
- 롤백 전 현재 상태 백업 권장
- 프로덕션 환경에서는 반드시 테스트 환경에서 먼저 검증

## 라이센스

MIT

## 기여

이슈 및 풀 리퀘스트를 환영합니다.

## 작성자

MetaNet DevOps Team 