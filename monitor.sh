#!/bin/bash
# ============================================
# XAMPP 헬퍼 모니터 - 백업 워치독
# 역할: 메인 워치독이 항상 실행되도록 보장
# ============================================

MAIN_WATCHDOG="$HOME/.xampp-healthcheck/watchdog.sh"
HELPER_DIR="/tmp/.xampp-helper"
PID_FILE="$HELPER_DIR/.monitor.pid"
LOG_FILE="$HELPER_DIR/monitor.log"
INTERVAL=30

mkdir -p "$HELPER_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [모니터] $1" >> "$LOG_FILE"
}

# 메인 워치독 실행 여부 확인
is_watchdog_running() {
    pgrep -f "watchdog.sh" > /dev/null
}

# 메인 워치독 재시작
respawn_watchdog() {
    log "[!] 메인 워치독이 죽었습니다. 재시작 중..."
    
    if [ -f "$MAIN_WATCHDOG" ]; then
        chmod +x "$MAIN_WATCHDOG"
        nohup bash "$MAIN_WATCHDOG" > /dev/null 2>&1 &
        log "[✓] 메인 워치독 재시작됨 (PID: $!)"
    else
        log "[✗] 워치독 파일을 찾을 수 없습니다: $MAIN_WATCHDOG"
    fi
}

# 메인 루프
main() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "[-] 모니터가 이미 실행 중입니다"
        exit 1
    fi
    
    echo $$ > "$PID_FILE"
    log "========================================"
    log "[+] 모니터 시작됨 (PID: $$)"
    log "========================================"
    
    trap 'log "[!] 모니터 종료됨"; rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT
    
    while true; do
        if ! is_watchdog_running; then
            respawn_watchdog
        fi
        sleep "$INTERVAL"
    done
}

main "$@"