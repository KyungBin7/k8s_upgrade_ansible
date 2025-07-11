# Kubernetes 1.30+ 레포지토리 업그레이드 가이드

## 📋 개요

Kubernetes 1.29에서 1.30으로 업그레이드 시 패키지 설치 문제가 발생하는 이유와 해결 방법을 설명합니다.

## 🔍 문제 발생 원인

### 1. Kubernetes 레포지토리 구조 변경
- **2023년 9월 13일**부터 Kubernetes는 레거시 Google 호스팅 레포지토리에서 새로운 커뮤니티 소유 레포지토리로 완전 전환
- **레거시 레포지토리**: `apt.kubernetes.io`, `yum.kubernetes.io` (더 이상 사용 불가)
- **새 커뮤니티 레포지토리**: `pkgs.k8s.io` (1.24 이상 지원)

### 2. 버전별 전용 레포지토리
- 새 구조에서는 각 마이너 버전마다 전용 레포지토리 제공
- 예: `https://pkgs.k8s.io/core:/stable:/v1.30/rpm/`

### 3. 기존 코드 한계
- 1.28 이상에서만 공식 repo 사용하는 단순 로직
- 1.30 이후 변경사항 미반영

## 🛠️ 수정 내용

### 1. 버전별 레포지토리 설정 분리 (`vars/main.yml`)

```yaml
# 1.29까지: 기존 로직 유지 (레거시 + 공식 repo 병행)
# 1.30 이후: 커뮤니티 repo 무조건 사용

k8s_legacy_repo_max_version: "1.29"
k8s_community_repo_min_version: "1.24"
```

### 2. 버전별 로직 분기 (`06_check_official_repo.yml`)

#### 1.29까지 (기존 로직 유지)
- 1.28 이상: pkgs.k8s.io 사용 시도
- 1.27 이하: 레거시 repo 사용
- 실패 시 바이너리 설치로 폴백

#### 1.30 이후 (새로운 로직)
- **무조건 커뮤니티 repo** (`pkgs.k8s.io`) 사용
- 버전별 전용 레포지토리 자동 선택
- 레거시 repo 사용 안함

### 3. 지원 버전 확장
- **1.31, 1.32, 1.33** 버전 매트릭스 추가
- 각 버전별 etcd, CRI-O 호환성 정보 포함

## 📈 업그레이드 경로

### 현재 → 1.29
```
기존 로직 사용 (변경 없음)
├── 1.28+ : pkgs.k8s.io (공식)
└── 1.27- : packages.cloud.google.com (레거시)
```

### 1.29 → 1.30+
```
새로운 커뮤니티 로직
└── 1.30+ : pkgs.k8s.io (커뮤니티, 버전별 전용 repo)
```

## 🔧 주요 변경 파일

### 1. `k8s_cluster_upgrade/vars/main.yml`
- **추가**: `k8s_community_repo_config` 설정
- **추가**: `k8s_legacy_repo_config` 설정  
- **추가**: 버전 경계 변수들
- **추가**: 1.31~1.33 버전 매트릭스

### 2. `k8s_cluster_upgrade/tasks/06_check_official_repo.yml`
- **수정**: 버전별 분기 로직
- **수정**: 1.30+ 무조건 커뮤니티 repo 사용
- **개선**: 더 상세한 로깅 및 디버깅 정보

### 3. `k8s_cluster_upgrade/tasks/20_install_packages.yml`
- **영향 없음**: 기존 변수 구조 유지하여 호환성 보장

## ✅ 테스트 시나리오

### 1. 기존 환경 (1.29까지)
- **1.27 → 1.28**: 레거시 → 공식 repo 전환 ✅
- **1.28 → 1.29**: 공식 repo 유지 ✅

### 2. 새로운 환경 (1.30+)
- **1.29 → 1.30**: 공식 → 커뮤니티 repo 전환 ✅
- **1.30 → 1.31**: 커뮤니티 repo 내 버전별 전환 ✅
- **1.31 → 1.32 → 1.33**: 순차 업그레이드 ✅

## 🚨 주의사항

### 1. 네트워크 정책
- `pkgs.k8s.io` 도메인 허용 필요
- IP 기반 제한이 있는 환경에서는 로컬 미러 권장

### 2. 인증서 및 GPG 키
- 새로운 GPG 키 경로: `/etc/apt/keyrings/kubernetes-apt-keyring.gpg`
- 버전별 GPG 키 URL 자동 변경

### 3. 하위 호환성
- **1.29까지 코드 변경 없음** (요청사항 준수)
- 기존 환경에 영향 없이 새 버전 지원 추가

## 🔍 디버깅

### 로그 확인 포인트
```yaml
# 버전별 로직 확인
- "레거시 로직 사용: {{ k8s_use_legacy_logic }}"
- "사용 repo: 공식/커뮤니티/레거시"

# 레포지토리 URL 확인  
- "YUM Repository: https://pkgs.k8s.io/core:/stable:/v1.XX/rpm/"
- "APT Repository: https://pkgs.k8s.io/core:/stable:/v1.XX/deb/"
```

### 문제 해결
1. **404 에러**: 버전별 repo URL 확인
2. **GPG 에러**: 키 경로 및 권한 확인
3. **패키지 없음**: 커뮤니티 repo 지원 버전 확인

## 📚 참고 자료

- [Kubernetes 커뮤니티 레포지토리 공지](https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/)
- [레거시 레포지토리 중단 공지](https://kubernetes.io/blog/2023/08/31/legacy-package-repository-deprecation/)
- [레포지토리 변경 가이드](https://kubernetes-io-vnext-staging.netlify.app/docs/tasks/administer-cluster/kubeadm/change-package-repository/)

---
📅 **작성일**: 2025년 1월 8일  
🔄 **적용 버전**: Kubernetes 1.24 ~ 1.33  
✅ **테스트 완료**: 1.29→1.30→1.31→1.32→1.33 순차 업그레이드 