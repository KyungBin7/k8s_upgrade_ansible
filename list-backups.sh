#!/bin/bash

# Kubernetes 백업 목록 조회 스크립트

BACKUP_DIR="/opt/k8s-backup"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Kubernetes 클러스터 백업 목록 ===${NC}"
echo

# 백업 디렉토리 존재 확인
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}오류: 백업 디렉토리가 존재하지 않습니다: $BACKUP_DIR${NC}"
    exit 1
fi

# 백업 목록 확인
backups=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name '[0-9]*' | sort -r)

if [ -z "$backups" ]; then
    echo -e "${YELLOW}백업이 없습니다.${NC}"
    exit 0
fi

echo -e "${GREEN}사용 가능한 백업 목록:${NC}"
echo "----------------------------------------"
printf "%-15s %-20s %-15s %s\n" "타임스탬프" "생성 시간" "크기" "상태"
echo "----------------------------------------"

for backup_path in $backups; do
    timestamp=$(basename "$backup_path")
    
    # Unix timestamp를 사람이 읽을 수 있는 형식으로 변환
    if command -v date >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            human_time=$(date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Invalid")
        else
            # Linux
            human_time=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Invalid")
        fi
    else
        human_time="N/A"
    fi
    
    # 백업 크기 계산
    if [ -d "$backup_path" ]; then
        size=$(du -sh "$backup_path" 2>/dev/null | cut -f1 || echo "N/A")
        
        # 백업 상태 확인 (etcd 스냅샷 존재 여부)
        if [ -f "$backup_path/etcd-snapshot.db" ]; then
            status="${GREEN}완전${NC}"
        elif [ -d "$backup_path/binaries" ]; then
            status="${YELLOW}부분${NC}"
        else
            status="${RED}불완전${NC}"
        fi
        
        printf "%-15s %-20s %-15s %b\n" "$timestamp" "$human_time" "$size" "$status"
        
        # 백업 정보 파일이 있으면 추가 정보 표시
        if [ -f "$backup_path/backup-info.txt" ]; then
            k8s_version=$(grep "현재 K8s 버전:" "$backup_path/backup-info.txt" 2>/dev/null | cut -d: -f2 | xargs)
            node_role=$(grep "노드 역할:" "$backup_path/backup-info.txt" 2>/dev/null | cut -d: -f2 | xargs)
            if [ -n "$k8s_version" ] && [ -n "$node_role" ]; then
                echo "    └── K8s: $k8s_version, 역할: $node_role"
            fi
        fi
    fi
done

echo "----------------------------------------"
echo

# 최신 백업 추천
latest_backup=$(echo "$backups" | head -1 | xargs basename)
if [ -n "$latest_backup" ]; then
    echo -e "${BLUE}💡 롤백 사용 예시 (최신 백업):${NC}"
    echo "ansible-playbook -i inventory/hosts rollback-playbook.yml \\"
    echo "  -e \"k8s_backup_timestamp=$latest_backup\""
    echo
fi

# 상세 정보 확인 옵션
if [ "$1" = "--detail" ] || [ "$1" = "-d" ]; then
    echo -e "${BLUE}=== 백업 상세 정보 ===${NC}"
    for backup_path in $backups; do
        timestamp=$(basename "$backup_path")
        echo
        echo -e "${YELLOW}백업 타임스탬프: $timestamp${NC}"
        
        if [ -f "$backup_path/backup-info.txt" ]; then
            echo "백업 정보:"
            cat "$backup_path/backup-info.txt" | sed 's/^/  /'
        fi
        
        echo "백업 파일 목록:"
        ls -la "$backup_path" | sed 's/^/  /'
    done
fi

echo -e "${BLUE}사용법:${NC}"
echo "  ./list-backups.sh          # 백업 목록만 표시"
echo "  ./list-backups.sh --detail # 상세 정보 포함" 