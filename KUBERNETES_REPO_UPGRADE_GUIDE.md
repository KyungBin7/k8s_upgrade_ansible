# Kubernetes 1.24+ CDN Repository 업그레이드 가이드

## 📋 개요

Kubernetes 1.24부터 안정적인 CDN 기반 레포지토리 `prod-cdn.packages.k8s.io`를 사용하여 1.33까지 완전 지원하는 업그레이드 시스템입니다.

## 🔍 문제 발생 원인 (해결됨)

### 1. 기존 문제점들
- **구 URL 불안정성**: `pkgs.k8s.io` 접속 불안정
- **복잡한 버전별 분기**: 1.29까지/1.30부터 등 복잡한 로직
- **APT GPG 키 설정 오류**: APT 설정에서 YUM GPG 키 참조

### 2. 새로운 해결책
- **안정적인 CDN URL**: `prod-cdn.packages.k8s.io` 사용
- **통합된 버전 지원**: 1.24부터 1.33까지 단일 시스템
- **올바른 GPG 키 설정**: APT/YUM 각각 올바른 경로 사용

## 🛠️ 수정 내용

### 1. 새로운 CDN 기반 Repository URL

#### ✅ **새로운 URL 패턴**
```yaml
# YUM 계열 (CentOS/RHEL/Rocky Linux)
baseurl: "https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.30/rpm/"
gpg_key: "https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.30/rpm/repodata/repomd.xml.key"

# APT 계열 (Ubuntu/Debian)
repo_url: "https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.30/deb/"
gpg_key: "https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.30/deb/Release.key"
```

#### ❌ **기존 URL 패턴 (사용 중단)**
```yaml
# 기존 불안정한 URL
baseurl: "https://pkgs.k8s.io/core:/stable:/v1.30/rpm/"
```

### 2. 단순화된 버전별 로직

#### ✅ **새로운 단순 로직**
```yaml
# 1.24+ : CDN repo 사용
# 1.23- : 레거시 repo 사용 (바이너리 설치 권장)

k8s_legacy_repo_max_version: "1.23"
k8s_official_repo_min_version: "1.24"
```

#### ❌ **기존 복잡한 로직 (제거됨)**
```yaml
# 1.29까지/1.30부터 등 복잡한 분기 제거
```

### 3. 통합된 Repository 설정

#### ✅ **단일 통합 설정**
```yaml
# k8s_official_repo_config 하나로 통합 (1.24-1.33)
k8s_official_repo_config:
  yum: { CDN 기반 설정 }
  apt: { CDN 기반 설정 }
```

#### ❌ **기존 분산 설정 (제거됨)**
```yaml
# k8s_community_repo_config 제거
# k8s_official_repo_config vs k8s_community_repo_config 분리 제거
```

---

## 🎯 1.30 업그레이드 실패 문제 해결 핵심 수정사항

### ❌ 문제 원인
1. **APT GPG 키 설정 오류**: APT 설정에서 YUM GPG 키를 참조
2. **불안정한 URL**: `pkgs.k8s.io` 접속 불안정
3. **복잡한 분기 로직**: 1.29까지/1.30부터 버전별 처리 복잡성

### ✅ 해결 방법

#### 1. 안정적인 CDN URL 사용
```yaml
# 모든 버전 (1.24-1.33)에서 안정적인 CDN URL 사용
repo_baseurl: "https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v{{ version }}/rpm/"
```

#### 2. APT GPG 키 설정 수정
```yaml
# 기존 (잘못된 설정)
url: "{{ k8s_selected_repo_config.yum.gpg_key if k8s_use_official_repo ... }}"

# 수정 (올바른 설정) 
url: "{{ k8s_selected_repo_config.apt.gpg_key | default('legacy') }}"
```

#### 3. 단순화된 로직
```yaml
# 단순한 버전 체크
k8s_use_legacy_logic: "{{ k8s_target_minor_for_repo is version('1.23', '<=') }}"
```

---

## 🚨 긴급 대응: 패키지 설치 실패 해결

### Package Repository 문제로 인한 설치 실패

만약 다음과 같은 에러가 발생한다면:
```
No package kubeadm=1.30.14-* available.
```

이는 새로운 Kubernetes package repository 인프라 변경으로 인한 문제입니다.

**즉시 해결 방법:**

1. **Binary 설치 강제 사용** (권장):
   ```yaml
   # playbook.yml에 추가
   k8s_force_binary_install: true
   k8s_target_version: "v1.30.8"  # 확실히 존재하는 버전 사용
   ```

2. **임시 버전 다운그레이드**:
   ```yaml
   k8s_target_version: "v1.30.8"  # 1.30.14 대신 사용
   ```

**원인:**
- 2024년 3월 4일 Google 호스팅 repository가 완전 제거됨
- 새로운 community repository (`pkgs.k8s.io`)는 1.24 이상만 지원
- CDN URL 접근 문제 또는 패키지 메타데이터 동기화 지연
- 일부 최신 패치 버전이 아직 CDN에 동기화되지 않음

**영구 해결책:**
- Binary 설치를 기본으로 사용하거나
- Repository 설정을 최신 CDN으로 업데이트
- 검증된 버전만 사용

---