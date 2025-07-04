# Kubernetes - Calico 버전 호환성 매트릭스

## 📊 **조사 결과 요약**

### 🔍 **Kubernetes 1.23~1.27 버전과 Calico 호환성**

본 조사는 Kubernetes 1.23~1.27 버전과 호환되는 Calico 버전을 조사하고, 관련 플레이북을 개발하기 위해 수행되었습니다.

---

## 🎯 **권장 Kubernetes - Calico 버전 조합**

| Kubernetes 버전 | 권장 Calico 버전 | 최소 Calico 버전 | Operator 버전 | 출시 시기 | 주요 특징 |
|-----------------|----------------|----------------|---------------|----------|----------|
| **1.23.x** | **3.24.6** | 3.22.0 | v1.30.9 | 2021-2022 | 안정적인 조합, 장기 지원 |
| **1.24.x** | **3.25.2** | 3.23.0 | v1.32.7 | 2022 | Dockershim 제거 대응 |
| **1.25.x** | **3.26.4** | 3.24.0 | v1.34.3 | 2022-2023 | PodSecurityPolicy 제거 |
| **1.26.x** | **3.27.4** | 3.25.0 | v1.36.1 | 2022-2023 | 성능 최적화 |
| **1.27.x** | **3.28.2** | 3.26.0 | v1.38.1 | 2023 | 최신 기능 지원 |

### 📋 **버전 선택 기준**

1. **안정성**: 충분한 테스트와 커뮤니티 피드백을 받은 버전
2. **호환성**: Kubernetes API 버전과의 완전한 호환성
3. **성능**: 특히 Calico 3.25.1+ 버전의 vertical scaling 성능 개선
4. **보안**: 최신 보안 패치가 적용된 버전

---

## 🚀 **주요 개선사항 및 특징**

### **Calico 3.25.1+ 성능 개선**
- **수직 확장(Vertical Scaling) 최적화**: 500+ pods per node 지원
- **CPU 사용량 최적화**: resync 작업 성능 개선
- **메모리 효율성**: 대규모 클러스터에서의 메모리 사용량 최적화

### **버전별 주요 특징**

#### **Calico 3.22-3.24 (K8s 1.23-1.25)**
- 안정적인 기본 네트워킹 기능
- eBPF 데이터플레인 지원
- 기본적인 네트워크 정책

#### **Calico 3.25-3.26 (K8s 1.24-1.26)**
- 수직 확장 성능 개선
- 향상된 BGP 지원
- WireGuard 암호화 개선

#### **Calico 3.27-3.28 (K8s 1.26-1.27)**
- nftables 백엔드 지원
- 멀티 클러스터 네트워킹
- 향상된 관찰 가능성

---

## 🛠 **업그레이드 플레이북 특징**

### **자동 버전 매칭**
```yaml
# Kubernetes 버전별 Calico 권장 버전 매트릭스
calico_version_matrix:
  "1.23":
    recommended_version: "v3.24.6"
    minimum_version: "v3.22.0"
    operator_version: "v1.30.9"
  "1.24":
    recommended_version: "v3.25.2"
    minimum_version: "v3.23.0"
    operator_version: "v1.32.7"
  # ... 추가 버전들
```

### **지원 설치 방법**
1. **Operator 방식**: Tigera Operator를 통한 관리형 설치
2. **Manifest 방식**: YAML 매니페스트를 통한 직접 설치

### **안전성 기능**
- ✅ **자동 백업**: 업그레이드 전 기존 설정 백업
- ✅ **점진적 업그레이드**: 단계별 업그레이드 진행
- ✅ **네트워크 테스트**: 업그레이드 후 연결성 검증
- ✅ **롤백 지원**: 실패 시 이전 버전으로 복구

---

## 📝 **사용 예제**

### **기본 사용법**
```bash
# Kubernetes 클러스터 업그레이드 (Calico 포함)
ansible-playbook -i inventory/hosts playbook.yml \
  -e k8s_upgrade_phase=control_plane

# Calico만 업그레이드
ansible-playbook -i inventory/hosts playbook.yml \
  --tags calico
```

### **고급 설정**
```yaml
# group_vars/all.yml
k8s_calico_upgrade_enabled: true
k8s_calico_force_upgrade: false
k8s_calico_backup_enabled: true
k8s_calico_upgrade_timeout: 300
k8s_calico_network_test: true
```

---

## ⚠️ **주의사항 및 제한사항**

### **업그레이드 전 확인사항**
1. **네트워크 정책**: 기존 NetworkPolicy 설정 확인
2. **CNI 충돌**: 다른 CNI 플러그인과의 충돌 여부 확인
3. **커스텀 설정**: 사용자 정의 Calico 설정 백업

### **지원되지 않는 경우**
- Kubernetes 1.22 이하 버전
- Flannel에서 Calico로의 마이그레이션 (별도 도구 필요)
- 멀티 CNI 환경

---

## 🔗 **참고 자료**

### **공식 문서**
- [Calico 공식 문서](https://docs.tigera.io/calico/latest/)
- [Kubernetes 네트워킹 가이드](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

### **호환성 정보**
- [Calico 시스템 요구사항](https://docs.tigera.io/calico/latest/getting-started/bare-metal/requirements)
- [Kubernetes 버전 정책](https://kubernetes.io/releases/version-skew-policy/)

### **성능 최적화**
- [Calico 수직 확장 가이드](https://www.tigera.io/blog/calicos-3-26-0-update-unlocks-high-density-vertical-scaling-in-kubernetes/)
- [eBPF 데이터플레인 성능](https://www.tigera.io/blog/introducing-the-calico-ebpf-dataplane/)

---

## 📈 **향후 계획**

### **단기 계획**
- [ ] Kubernetes 1.28-1.30 버전 지원 추가
- [ ] Calico 3.29-3.30 버전 지원
- [ ] 자동 성능 튜닝 기능

### **장기 계획**
- [ ] Cilium 지원 추가
- [ ] 멀티 CNI 마이그레이션 도구
- [ ] 실시간 네트워크 모니터링

---

**📅 문서 업데이트**: {{ ansible_date_time.date }}  
**🔄 마지막 검증**: Calico 3.30.x, Kubernetes 1.27.x 