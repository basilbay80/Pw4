#!/bin/bash
# ============================================
# XAMPP 가드 - 3차 워치독
# 역할: monitor.sh & watchdog.sh 실행 보장
# ============================================

GUARD_DIR="/var/tmp/.xampp-guard"
MONITOR_SCRIPT="/tmp/.xampp-helper/monitor.sh"
WATCHDOG_SCRIPT="$HOME/.xampp-healthcheck/watchdog.sh"
PID_FILE="$GUARD_DIR/.guard.pid"
LOG_FILE="$GUARD_DIR/guard.log"
INTERVAL=45

# 폴더 생성 (/var/tmp에 있으면 sudo 필요)
mkdir -p "$GUARD_DIR" 2>/dev/null || sudo mkdir -p "$GUARD_DIR"
sudo chmod 777 "$GUARD_DIR" 2>/dev/null

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [가드] $1" >> "$LOG_FILE"
}

ensure_running() {
    local name="$1"
    local script="$2"
    local pattern="$3"
    
    if ! pgrep -f "$pattern" > /dev/null; then
        log "[!] $name 죽음. 재시작 중..."
        if [ -f "$script" ]; then
            chmod +x "$script"
            nohup bash "$script" > /dev/null 2>&1 &
            log "[✓] $name 재시작됨"
        fi
    fi
}

main() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "[-] 가드가 이미 실행 중입니다"
        exit 1
    fi
    
    echo $$ > "$PID_FILE"
    log "========================================"
    log "[+] 가드 시작됨 (PID: $$)"
    log "========================================"
    
    trap 'log "[!] 가드 종료됨"; rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT
    
    while true; do
        ensure_running "모니터"  "$MONITOR_SCRIPT"  "monitor.sh"
        ensure_running "워치독" "$WATCHDOG_SCRIPT" "watchdog.sh"
        sleep "$INTERVAL"
    done
}

main "$@"