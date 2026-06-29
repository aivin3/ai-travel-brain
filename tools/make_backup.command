#!/bin/bash
# AI Travel Brain — 一鍵離線備份（第三層：git repo + deploy repos 之外的本機/iCloud tar bundle）
# 用法：雙擊本檔，或 bash tools/make_backup.command
set -e
cd "$(dirname "$0")/.." || exit 1
ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$ROOT/backups"
mkdir -p "$OUT"
BUNDLE="$OUT/ai-travel-brain_${STAMP}.tgz"

# 只打包源碼（排除 deploy*/ 獨立 repo、backups 自身、.git、img 大檔可選保留）
tar --exclude='./deploy' --exclude='./deploy-*' --exclude='./backups' \
    --exclude='./.git' --exclude='*/.git' --exclude='.DS_Store' \
    -czf "$BUNDLE" \
    BLUEPRINT.md CLAUDE.md README.md skill.md .env.example .gitignore \
    firebase.config.json scripts templates schema trips tools 2>/dev/null || true

echo "✅ 已備份：$BUNDLE"
echo "   大小：$(du -h "$BUNDLE" | cut -f1)"
echo ""
echo "三重備份現況："
echo "  1) Master git repo（private）：github.com/aivin3/ai-travel-brain"
echo "  2) 4 個 deploy GitHub Pages repo（含 img）：kaohsiung/fukuoka-trip-2026(±sync)"
echo "  3) 本機/iCloud tar bundle：$BUNDLE（呢個 folder 喺 iCloud Drive → 自動雲端同步）"
echo ""
echo "接手 AI：解壓後先讀 BLUEPRINT.md。"
