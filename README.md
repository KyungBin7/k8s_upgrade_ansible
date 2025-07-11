# Kubernetes 클러스터 업그레이드 Ansible 플레이북

## 🎯 주요 특징 (2025년 1월 업데이트)

- **✅ 안정적인 Binary 설치 기본 사용**: Repository 문제 완전 해결
- **🔄 자동 버전 감지**: 현재 버전과 업그레이드 가능한 버전 자동 감지
- **🛡️ 안전한 롤링 업그레이드**: 마스터 → 워커 순차 업그레이드
- **📦 유연한 설치 방법**: Binary(기본) / Package 설치 선택 가능
- **🔙 백업 및 복구**: etcd, 설정 파일 자동 백업

## 🚀 빠른 시작

### 1. Ansible 설치
```bash
dnf install -y epel-release
dnf install -y ansible

git clone <repository-url>
cd k8s_upgrade_ansible
```
### 2. 인벤토리 설정
```bash
# inventory/hosts 파일에서 IP 주소 수정
vi inventory/hosts
```

### 3. SSH 키 배포
```bash
# SSH_SETUP.md 파일 참고 (1, 2단계만 진행)
ssh-copy-id user@target-node
```

### 4. 연결 테스트
```bash
ansible all -m ping
```

### 5. 클러스터 업그레이드 실행
```bash
ansible-playbook -i inventory/hosts playbook.yml -v
```

## ⚙️ 고급 설정

### Binary 설치 (기본값)
```yaml
# 별도 설정 불필요 - 자동으로 Binary 설치 사용
k8s_package_manager: "auto"
```

### 패키지 설치 사용 (선택사항)
```yaml
# 패키지 설치를 원하는 경우
k8s_prefer_package_install: true
```

### 특정 버전 업그레이드
```yaml
k8s_target_version: "v1.30.8"
k8s_force_version: true
```

## 📋 업그레이드 순서

1. **Control Plane 노드** (순차적)
2. **Worker 노드** (순차적)
3. **자동 검증 및 확인**

## 🛠️ 트러블슈팅

- **Repository 문제**: 자동으로 Binary 설치로 전환됨
- **자세한 가이드**: `KUBERNETES_REPO_UPGRADE_GUIDE.md` 참고

---

**Note**: k8s_cluster_rollback playbook은 현재 개발 중입니다.
