#!/bin/bash
# ============================================
# XAMPP 워치독 - 자동 재시작 모니터
# ============================================

# 설정
WORKDIR="$HOME/.xampp-healthcheck"
XAMPP_DIR="$HOME/xampp"                # XAMPP 위치에 맞게 수정
XAMPP_BIN="$XAMPP_DIR/lampp/lampp"     # Linux: lampp, Windows: xampp_start
LOG_FILE="$WORKDIR/logs/watchdog.log"
PID_FILE="$WORKDIR/.watchdog.pid"
TRIGGER_FILE="$WORKDIR/.trigger"
INTERVAL=15                             # 15초마다 확인

# 로그 폴더 생성
mkdir -p "$WORKDIR/logs"

# ============================================
# 로그 기록 함수
# ============================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ============================================
# XAMPP (Apache/MySQL) 실행 여부 확인
# ============================================
is_xampp_running() {
    # Apache 및 MySQL 프로세스 확인
    if pgrep -f "httpd|apache2" > /dev/null && pgrep -f "mysqld" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# ============================================
# XAMPP 시작
# ============================================
start_xampp() {
    log "[+] XAMPP가 꺼져 있습니다. 재시작 시도 중..."
    
    if [ -x "$XAMPP_BIN" ]; then
        sudo "$XAMPP_BIN" start >> "$LOG_FILE" 2>&1
        sleep 3
        
        if is_xampp_running; then
            log "[✓] XAMPP 재시작 성공"
            return 0
        else
            log "[✗] XAMPP 시작 실패. 나중에 다시 시도합니다"
            return 1
        fi
    else
        log "[✗] XAMPP 바이너리를 찾을 수 없습니다: $XAMPP_BIN"
        return 1
    fi
}

# ============================================
# XAMPP 중지
# ============================================
stop_xampp() {
    log "[!] XAMPP 중지 중..."
    sudo "$XAMPP_BIN" stop >> "$LOG_FILE" 2>&1
    sleep 2
    log "[✓] XAMPP 중지 완료"
}

# ============================================
# 트리거 파일 확인 (강제 재시작용)
# ============================================
check_trigger() {
    if [ -f "$TRIGGER_FILE" ]; then
        log "[!] 트리거 감지! XAMPP 강제 재시작..."
        rm -f "$TRIGGER_FILE"
        
        stop_xampp
        sleep 2
        start_xampp
        return 0
    fi
    return 1
}

# ============================================
# 메인 루프
# ============================================
main() {
    # 중복 실행 방지
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "[-] 워치독이 이미 실행 중입니다 (PID: $(cat "$PID_FILE"))"
        exit 1
    fi
    
    echo $$ > "$PID_FILE"
    log "========================================"
    log "[+] 워치독 시작됨 (PID: $$)"
    log "[+] 확인 주기: ${INTERVAL}초"
    log "========================================"
    
    # 종료 시그널 처리
    trap 'log "[!] 워치독 종료됨"; rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT
    
    while true; do
        # 1. 수동 트리거 확인
        if check_trigger; then
            sleep "$INTERVAL"
            continue
        fi
        
        # 2. XAMPP 상태 확인
        if ! is_xampp_running; then
            log "[-] XAMPP가 중지된 것으로 감지됨"
            
            # 최대 3회 재시도
            for i in 1 2 3; do
                log "[+] 시작 시도 $i회차"
                if start_xampp; then
                    break
                fi
                sleep 5
            done
        fi
        
        sleep "$INTERVAL"
    done
}

main "$@"