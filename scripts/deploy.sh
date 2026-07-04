#!/usr/bin/env bash
# ============================================================================
# scripts/deploy.sh — 一鍵重出 deploy（PLAYBOOK P6 腳本化）
#
# 點解有呢個檔：改咗模板/數據之後要重出 4 條 link（2 trip × 離線/共用），
# 人手跟 P6 好易漏一條，而漏咗係靜默死（家人開到舊版都唔知）。
# 呢度照 scripts/deploy_map.tsv 逐條：重生 → cp → commit+push → 等 Pages 刷新 → 驗 live 一致。
#
# 用法：
#   bash scripts/deploy.sh              # 全部 4 條
#   bash scripts/deploy.sh fukuoka-2026-08   # 只出呢個 slug 嘅（離線+共用）
#
# 前提：喺「工作夾」跑（deploy*/ 資料夾要存在）；淨 clone 冇 deploy 資料夾會即刻報錯。
# ============================================================================
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ONLY="${1:-}"

FAILS=0
PASS(){ printf '✅ %s\n' "$1"; }
FAIL(){ printf '❌ %s\n' "$1"; FAILS=$((FAILS+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f scripts/deploy_map.tsv ] || { echo "❌ 冇 scripts/deploy_map.tsv"; exit 1; }

while IFS="$(printf '\t')" read -r url dir slug mode; do
  case "$url" in \#*|"") continue;; esac
  [ -n "$ONLY" ] && [ "$slug" != "$ONLY" ] && continue
  printf '\n━━━ %s（%s）→ %s ━━━\n' "$slug" "$mode" "$dir"

  if [ ! -d "$dir/.git" ]; then FAIL "$dir 唔係 git repo（要喺工作夾跑）"; continue; fi

  # 1) 重生（sync 版注入 firebase config）
  if [ "$mode" = "sync" ]; then
    python3 -c "import json;d=json.load(open('trips/$slug/tripData.json'));d['firebase']=json.load(open('firebase.config.json'));open('$TMP/s.json','w').write(json.dumps(d,ensure_ascii=False))" || { FAIL "$slug 注入 firebase 失敗"; continue; }
    python3 scripts/generate.py "$TMP/s.json" -o "$dir/index.html" || { FAIL "$slug 生成失敗"; continue; }
  else
    python3 scripts/generate.py "trips/$slug/tripData.json" -o "$dir/index.html" || { FAIL "$slug 生成失敗"; continue; }
  fi

  # 2) commit + push（冇變動就唔 commit）
  if git -C "$dir" diff --quiet -- index.html; then
    PASS "$dir 內容無變，唔使 push"
  else
    ( cd "$dir" && git add index.html img/ 2>/dev/null; git add index.html && git commit -q -m "update roadbook ($(date +%Y-%m-%d))" && git push -q origin main ) \
      && PASS "$dir 已 push" || { FAIL "$dir push 失敗"; continue; }
  fi

  # 3) 等 GitHub Pages 刷新 → 驗 live == 本地（點解：push 成功 ≠ 上線成功；CDN 有延遲）
  ok=0
  for i in 1 2 3 4 5 6; do
    curl -sL --max-time 20 "$url" -o "$TMP/live.html"
    if diff -q "$TMP/live.html" "$dir/index.html" >/dev/null 2>&1; then ok=1; break; fi
    sleep 20
  done
  [ "$ok" = "1" ] && PASS "live 已一致: $url" \
    || FAIL "live 仲未同本地一致（Pages 可能仲喺度 build，2 分鐘後跑 check.sh 覆核）: $url"
done < scripts/deploy_map.tsv

printf '\n════════════════════════════════════\n'
if [ "$FAILS" -gt 0 ]; then printf '🔴 deploy 有 %s 項未完成\n' "$FAILS"; exit 1
else printf '🟢 deploy 全部完成。最後跑 bash scripts/check.sh 收工。\n'; fi
