#!/bin/bash

# Kubernetes 1.30 이후 버전에 대한 사용 가능한 패치 버전 확인 스크립트

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# 버전 확인 함수
check_k8s_version() {
    local version=$1
    local minor_version=$(echo $version | cut -d'.' -f1-2)
    
    print_header "Kubernetes $version 버전 확인"
    
    # GitHub API로 릴리스 버전 확인
    echo "GitHub 릴리스 버전 확인 중..."
    if command -v curl &> /dev/null; then
        local github_releases=$(curl -s "https://api.github.com/repos/kubernetes/kubernetes/releases" | grep -o "v$minor_version\.[0-9]*" | sort -V -r | head -10)
        if [[ -n "$github_releases" ]]; then
            print_success "사용 가능한 GitHub 릴리스 버전:"
            echo "$github_releases" | sed 's/^/  /'
        else
            print_warning "GitHub 릴리스 버전을 가져올 수 없습니다."
        fi
    else
        print_warning "curl이 설치되지 않아 GitHub 릴리스를 확인할 수 없습니다."
    fi
    
    # 공식 저장소 확인
    echo -e "\n공식 저장소 확인 중..."
    local repo_url="https://pkgs.k8s.io/core:/stable:/v$minor_version/rpm/repodata/repomd.xml"
    if curl -s -f "$repo_url" > /dev/null 2>&1; then
        print_success "공식 저장소 ($minor_version) 사용 가능"
    else
        print_warning "공식 저장소 ($minor_version) 사용 불가능"
    fi
    
    # 레거시 저장소 확인
    echo "레거시 저장소 확인 중..."
    if curl -s -f "https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64/repodata/repomd.xml" > /dev/null 2>&1; then
        print_success "레거시 저장소 사용 가능"
    else
        print_warning "레거시 저장소 사용 불가능"
    fi
    
    echo ""
}

# 현재 시스템의 패키지 매니저 확인
check_package_manager() {
    print_header "패키지 매니저 확인"
    
    if command -v yum &> /dev/null; then
        print_success "YUM 패키지 매니저 감지"
        
        # 현재 설정된 Kubernetes 저장소 확인
        if yum repolist | grep -i kubernetes &> /dev/null; then
            print_success "Kubernetes 저장소 설정됨"
            yum repolist | grep -i kubernetes | sed 's/^/  /'
        else
            print_warning "Kubernetes 저장소가 설정되지 않음"
        fi
        
        # 사용 가능한 kubeadm 버전 확인 (1.30 이후)
        echo -e "\n사용 가능한 kubeadm 1.30+ 버전:"
        yum --showduplicates list kubeadm 2>/dev/null | grep -E "1\.(3[0-9]|[4-9][0-9])" | tail -10 | sed 's/^/  /' || print_warning "kubeadm 1.30+ 패키지를 찾을 수 없습니다."
        
    elif command -v apt &> /dev/null; then
        print_success "APT 패키지 매니저 감지"
        
        # 현재 설정된 Kubernetes 저장소 확인
        if apt list --installed 2>/dev/null | grep -i kubernetes &> /dev/null; then
            print_success "Kubernetes 패키지 설치됨"
        else
            print_warning "Kubernetes 패키지가 설치되지 않음"
        fi
        
        # 사용 가능한 kubeadm 버전 확인 (1.30 이후)
        echo -e "\n사용 가능한 kubeadm 1.30+ 버전:"
        apt-cache madison kubeadm 2>/dev/null | grep -E "1\.(3[0-9]|[4-9][0-9])" | head -10 | sed 's/^/  /' || print_warning "kubeadm 1.30+ 패키지를 찾을 수 없습니다."
        
    else
        print_warning "알려진 패키지 매니저를 찾을 수 없습니다."
    fi
    
    echo ""
}

# Fallback 설정 확인
check_fallback_config() {
    print_header "Fallback 설정 확인"
    
    local defaults_file="k8s_cluster_upgrade/defaults/main.yml"
    if [[ -f "$defaults_file" ]]; then
        print_success "기본 설정 파일 존재: $defaults_file"
        
        # Fallback 설정 확인
        if grep -q "k8s_version_fallback_enabled" "$defaults_file"; then
            local fallback_enabled=$(grep "k8s_version_fallback_enabled" "$defaults_file" | awk '{print $2}')
            local fallback_strategy=$(grep "k8s_version_fallback_strategy" "$defaults_file" | awk '{print $2}' | tr -d '"')
            local fallback_min_version=$(grep "k8s_version_fallback_min_version" "$defaults_file" | awk '{print $2}' | tr -d '"')
            
            print_success "Fallback 설정:"
            echo "  - 활성화: $fallback_enabled"
            echo "  - 전략: $fallback_strategy"
            echo "  - 최소 버전: $fallback_min_version"
            
            # 사용 가능한 패치 버전 확인
            echo -e "\n사용 가능한 패치 버전:"
            for version in "1.30" "1.31" "1.32" "1.33"; do
                if grep -A 5 "\"$version\":" "$defaults_file" | grep -q "available_patch_versions"; then
                    print_success "$version 버전 패치 목록 설정됨"
                    grep -A 5 "\"$version\":" "$defaults_file" | grep "available_patch_versions" | sed 's/^/  /'
                else
                    print_warning "$version 버전 패치 목록 미설정"
                fi
            done
        else
            print_warning "Fallback 설정이 구성되지 않았습니다."
        fi
    else
        print_error "기본 설정 파일을 찾을 수 없습니다: $defaults_file"
    fi
    
    echo ""
}

# 메인 실행
main() {
    print_header "Kubernetes 1.30+ 버전 가용성 확인"
    echo "이 스크립트는 Kubernetes 1.30 이후 버전들의 사용 가능성을 확인합니다."
    echo ""
    
    # 네트워크 연결 확인
    if ! ping -c 1 google.com &> /dev/null; then
        print_warning "인터넷 연결이 불안정합니다. 일부 확인이 제한될 수 있습니다."
        echo ""
    fi
    
    # 각 버전 확인
    for version in "1.30.8" "1.31.4" "1.32.3" "1.33.3"; do
        check_k8s_version "$version"
    done
    
    # 시스템 패키지 매니저 확인
    check_package_manager
    
    # Fallback 설정 확인
    check_fallback_config
    
    print_header "권장 사항"
    echo "1. 1.30 이후 버전 업그레이드 시 fallback 메커니즘이 자동으로 작동합니다."
    echo "2. 특정 패치 버전이 필요한 경우 k8s_force_version: true 설정을 사용하세요."
    echo "3. 업그레이드 전에 반드시 백업을 수행하세요."
    echo "4. 네트워크 연결이 안정적인 환경에서 업그레이드를 진행하세요."
    echo ""
    
    print_success "버전 확인이 완료되었습니다!"
}

# 스크립트 실행
main "$@" 