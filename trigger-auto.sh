#!/bin/bash
# ============================================
# 자동 트리거 - 다음 조건에서 자동 재시작:
#   - HTTP 응답 없음
#   - MySQL 응답 없음
# ============================================

WORKDIR="$HOME/.xampp-healthcheck"
TRIGGER_FILE="$WORKDIR/.trigger"
LOG="$WORKDIR/logs/trigger.log"

mkdir -p "$WORKDIR/logs"

log() { echo "[$(date '+%F %T')] $1" >> "$LOG"; }

# HTTP 확인
check_http() {
    curl -fsS --max-time 5 "http://localhost" > /dev/null 2>&1
}

# MySQL 포트 확인
check_mysql() {
    (echo > /dev/tcp/127.0.0.1/3306) > /dev/null 2>&1
}

# 루프
while true; do
    if ! check_http; then
        log "[-] HTTP 응답 없음!"
        touch "$TRIGGER_FILE"
    fi
    
    if ! check_mysql; then
        log "[-] MySQL 응답 없음!"
        touch "$TRIGGER_FILE"
    fi
    
    sleep 20
done