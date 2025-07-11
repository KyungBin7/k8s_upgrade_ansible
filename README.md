# Kubernetes 클러스터 업그레이드 Ansible 플레이북

이 저장소는 Kubernetes 클러스터를 안전하게 업그레이드하기 위한 Ansible 플레이북입니다.

## 새로운 기능: 1.30 이후 버전 Fallback 메커니즘

### 개요
Kubernetes 1.30 이후 버전들에 대해 패키지 저장소에서 특정 패치 버전을 사용할 수 없을 때 자동으로 사용 가능한 버전으로 fallback하는 메커니즘이 추가되었습니다.

### 주요 기능
- **자동 Fallback**: 요청된 패치 버전이 사용 불가능할 때 사용 가능한 최신 패치 버전으로 자동 변경
- **1.30 이후 지원**: 1.30, 1.31, 1.32, 1.33 버전까지 지원
- **유연한 전략**: `latest_patch` 또는 `previous_patch` 전략 선택 가능
- **안전한 업그레이드**: 기존 1.29 이하 버전들은 기존 로직 그대로 유지

### 설정 방법
```yaml
# defaults/main.yml
k8s_version_fallback_enabled: true          # fallback 활성화
k8s_version_fallback_strategy: "latest_patch"  # 전략 설정
k8s_version_fallback_min_version: "1.30"    # 1.30 이후부터 적용
```

### 사용 방법
1. **자동 모드**: 설정 변경 없이 기존과 동일하게 실행
2. **강제 모드**: 특정 버전 필요 시 `k8s_force_version: true` 설정

### 버전 확인 스크립트
```bash
# 스크립트 실행 권한 부여
chmod +x check_available_versions.sh

# 사용 가능한 버전 확인
./check_available_versions.sh
```

## 지원 버전
- Kubernetes 1.23 ~ 1.33
- 1.30 이후 버전은 자동 fallback 지원

## 사용법
기존 사용법과 동일하게 플레이북을 실행하면 됩니다.

```bash
ansible-playbook -i inventory/hosts playbook.yml
```

## 문제 해결
- 특정 패치 버전이 필요한 경우: `k8s_force_version: true` 설정
- Fallback 비활성화: `k8s_version_fallback_enabled: false` 설정
- 버전 확인: `./check_available_versions.sh` 실행
