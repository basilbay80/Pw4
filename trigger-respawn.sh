#!/bin/bash
# ============================================
# XAMPP 재시작 트리거
# 사용법: ./trigger-respawn.sh
# ============================================

WORKDIR="$HOME/.xampp-healthcheck"
TRIGGER_FILE="$WORKDIR/.trigger"

mkdir -p "$WORKDIR"
touch "$TRIGGER_FILE"

echo "[✓] 트리거 생성됨: $TRIGGER_FILE"
echo "[✓] 워치독이 15초 내에 XAMPP를 재시작합니다..."