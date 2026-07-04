#!/usr/bin/env bash
# ============================================================================
# scripts/check.sh — 收工 QA 閘（一鍵，全 pass 先准講「done」）
#
# 點解有呢個檔：判斷力唔會以散文傳承俾之後嘅 session；只有「會 fail 嘅檢查」
# 先擋得住錯誤。呢度每一個閘都對應一個真實踩過（或預見）嘅坑，
# 對照表喺 docs/GUARDRAILS.md。唔好刪任何閘；要改先讀 GUARDRAILS 對應條目。
#
# 用法：
#   bash scripts/check.sh              # 全套（含網絡：圖片 200 + deploy link）
#   bash scripts/check.sh --offline    # 跳過網絡檢查（冇網先用；收工前要補跑全套）
#
# 退出碼：0 = 全部通過；1 = 有閘 fail（唔准收工/唔准話 done）
# ============================================================================
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OFFLINE=0
[ "${1:-}" = "--offline" ] && OFFLINE=1

FAILS=0
PASS(){ printf '✅ %s\n' "$1"; }
FAIL(){ printf '❌ FAIL: %s\n' "$1"; FAILS=$((FAILS+1)); }
WARN(){ printf '⚠️  %s\n' "$1"; }
SECTION(){ printf '\n━━━ %s ━━━\n' "$1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 共用 JS 模板對（roadbook-washi.html 係分家實驗 fork，JS 唔共用，唔入呢個閘；見 GUARDRAILS G2）
SHARED_JS_PAIR=("templates/roadbook.html" "templates/roadbook_jp.html")

# ---------------------------------------------------------------------------
# 0) 工具存在（點解：node --check 係唯一 JS 語法閘，冇佢 = 閘穿窿，寧願 fail）
# ---------------------------------------------------------------------------
SECTION "0. 環境"
command -v python3 >/dev/null || { FAIL "冇 python3"; echo "＝＝ 環境都唔齊，停 ＝＝"; exit 1; }
if command -v node >/dev/null; then PASS "python3 + node 齊"; else FAIL "冇 node（brew install node；JS 語法閘必需）"; fi

# 抽 HTML 最後一個 <script> 區塊（= 模板主 JS）
extract_js(){ # $1=html檔 $2=輸出js檔
  python3 - "$1" "$2" <<'PYEOF'
import re, sys
h = open(sys.argv[1], encoding="utf-8").read()
blocks = re.findall(r'<script>(.*?)</script>', h, re.S)
if not blocks:
    sys.exit(f"搵唔到 <script> 區塊: {sys.argv[1]}")
open(sys.argv[2], "w", encoding="utf-8").write(blocks[-1])
PYEOF
}

# ---------------------------------------------------------------------------
# 1) 模板靜態閘
# ---------------------------------------------------------------------------
SECTION "1. 模板（templates/*.html）"
for t in templates/*.html; do
  # 1a. placeholder 齊（點解：缺 __FIREBASE__ = 共用版靜默冇 sync；缺其他 = 生成即爛）
  for ph in __TITLE__ __TRIP_DATA__ __FIREBASE__; do
    grep -q "$ph" "$t" || FAIL "$t 缺 $ph placeholder"
  done
  # 1b. iOS 坑（點解：background-attachment:fixed 喺 iOS 造成橫向溢位+jank，2026-06 已踩過）
  if grep -q 'background-attachment' "$t"; then FAIL "$t 含 background-attachment（iOS 坑，用 html{overflow-x:hidden} 方案）"; fi
  # 1c. 模板 JS 語法
  if command -v node >/dev/null; then
    extract_js "$t" "$TMP/tpl.js" && node --check "$TMP/tpl.js" >/dev/null 2>&1 \
      && PASS "$t JS 語法 OK" || FAIL "$t 主 JS 過唔到 node --check"
  fi
done

# 1d. 共用 JS drift 閘（點解：兩模板共用同一份 render+工具 JS，歷史上已經走樣過一次
#     —— pastel 版曾缺 overview/glow/events 縮圖。呢個閘要求兩檔主 JS 逐字節一致，
#     只有 CSS 准唔同。改邏輯必須兩檔同步改，改完呢度先會綠。）
extract_js "${SHARED_JS_PAIR[0]}" "$TMP/js_a.js"
extract_js "${SHARED_JS_PAIR[1]}" "$TMP/js_b.js"
# 正規化：去尾隨空白（唔正規化其他嘢——縮排都要一致，先易 grep-replace 同步）
sed 's/[[:space:]]*$//' "$TMP/js_a.js" > "$TMP/js_a_n.js"
sed 's/[[:space:]]*$//' "$TMP/js_b.js" > "$TMP/js_b_n.js"
if diff -q "$TMP/js_a_n.js" "$TMP/js_b_n.js" >/dev/null; then
  PASS "共用 JS 無 drift（${SHARED_JS_PAIR[0]} ↔ ${SHARED_JS_PAIR[1]}）"
else
  FAIL "共用 JS drift！兩模板主 <script> 唔一致（頭號隱形 bug 源）。diff 摘要："
  diff "$TMP/js_a_n.js" "$TMP/js_b_n.js" | head -20
fi

# ---------------------------------------------------------------------------
# 2) 每個 trip：JSON → 生成 → 語法 → 殘留 → 新鮮度
# ---------------------------------------------------------------------------
SECTION "2. trips/*/tripData.json → 生成驗證"
TITLES="$TMP/titles.txt"; : > "$TITLES"
ALL_IMG="$TMP/imgs.txt";  : > "$ALL_IMG"

for td in trips/*/tripData.json; do
  slug="$(basename "$(dirname "$td")")"
  out="$TMP/$slug.html"

  # 2a. JSON 有效 + generate.py validate 過（點解：爛數據唔准 ship；validate 規則喺 generate.py）
  if ! python3 -c "import json;json.load(open('$td'))" 2>"$TMP/err"; then
    FAIL "$td JSON 無效: $(cat "$TMP/err" | head -2)"; continue
  fi
  if python3 scripts/generate.py "$td" -o "$out" >"$TMP/gen.log" 2>&1; then
    PASS "$slug 生成 OK"
    grep '⚠️' "$TMP/gen.log" | while IFS= read -r l; do WARN "$slug: $l"; done
  else
    FAIL "$slug generate.py 出錯:"; tail -5 "$TMP/gen.log"; continue
  fi

  # 2b. 生成品 JS 語法（點解：真數據注入後先會爆嘅 template-literal 錯，模板檢查捉唔到）
  if command -v node >/dev/null; then
    extract_js "$out" "$TMP/out.js" && node --check "$TMP/out.js" >/dev/null 2>&1 \
      || FAIL "$slug 生成品 JS 過唔到 node --check（多數係 tripData 字串攪亂 template literal）"
  fi

  # 2c. placeholder 殘留 + firebase 洩漏（點解：殘留 = 生成鏈斷；離線版夾 SDK = 錯模式出街）
  grep -q '__TRIP_DATA__\|__TITLE__\|__FIREBASE__' "$out" && FAIL "$slug 生成品有 placeholder 殘留"
  if python3 -c "import json,sys;sys.exit(0 if 'firebase' in json.load(open('$td')) else 1)"; then
    grep -q 'firebasejs' "$out" || FAIL "$slug tripData 有 firebase config 但生成品冇 SDK"
  else
    grep -q 'firebasejs' "$out" && FAIL "$slug 係離線版但生成品夾咗 Firebase SDK"
  fi

  # 2d. 新鮮度：repo 內成品必須 = 由當前 tripData+模板重生（點解：手改 HTML / 改完 JSON
  #     或模板唔重生，係「睇落無事、下次一改就炸」嘅暗雷。generationDate 行除外。）
  committed="$(dirname "$td")/roadbook.html"
  if [ ! -f "$committed" ]; then
    FAIL "$slug 未有成品 roadbook.html（跑 python3 scripts/generate.py $td）"
  else
    grep -v '"generationDate"' "$committed" > "$TMP/c.html"
    grep -v '"generationDate"' "$out"       > "$TMP/n.html"
    diff -q "$TMP/c.html" "$TMP/n.html" >/dev/null \
      && PASS "$slug 成品新鮮（同重生一致）" \
      || FAIL "$slug 成品 stale／被手改（重跑 generate.py 再 commit；永遠唔好手改 HTML）"
  fi

  # 收集 title（2f 查重）同圖片 URL（3 網絡閘）
  python3 -c "import json;print(json.load(open('$td')).get('title',''))" >> "$TITLES"
  python3 - "$td" >> "$ALL_IMG" <<'PYEOF'
import json, sys
def walk(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if k in ("imageUrl", "heroImage") and isinstance(v, str) and v.strip():
                print(v.strip())
            else:
                walk(v)
    elif isinstance(o, list):
        for x in o: walk(x)
walk(json.load(open(sys.argv[1])))
PYEOF
done

# 2e. 禁用圖源（點解：gstatic/encrypted-tbn 縮圖會失效，2026-06 已踩過 → 必須自 host）
if grep -q 'gstatic\|encrypted-tbn' "$ALL_IMG"; then
  FAIL "tripData 有 gstatic/encrypted-tbn 縮圖 URL（唔穩定）→ download 落 deploy*/img/ 自 host"
fi

# 2f. trip title 唔准重複（點解：分帳/訂單 localStorage key = exp_<title>/book_<title>，
#     同名 title 會令兩個 trip 喺同一部機互相覆寫數據）
if [ "$(sort "$TITLES" | uniq -d | wc -l)" -gt 0 ]; then
  FAIL "有 trip title 重複（localStorage key 相撞）: $(sort "$TITLES" | uniq -d | tr '\n' ' ')"
else
  PASS "trip titles 冇重複"
fi

# ---------------------------------------------------------------------------
# 3) 網絡閘（--offline 跳過；收工前必須跑全套）
# ---------------------------------------------------------------------------
if [ "$OFFLINE" = "1" ]; then
  SECTION "3. 網絡閘 — 已跳過（--offline）"
  WARN "圖片 200 檢查 + deploy link 健康檢查未跑；收工前要跑一次全套 check.sh"
else
  SECTION "3. 圖片 URL 逐條驗（200 + image/*）"
  # 點解：路書係手機旅行途中用，一張爛圖 = 現場開頁爛卡；圖 URL 又係幻覺高發區。
  # 注意：Wikimedia 對連環請求會出 429（rate-limit，唔係死鏈）→ 必須有 UA + 間隔 + 退避重試，
  # 否則呢個閘會狼來了，然後俾人剷走。
  UA="ai-travel-brain-check/1.0 (personal roadbook QA; contact: repo owner)"
  # 已驗證 cache（7 日）：圖好少死，但 Wikimedia 對 burst 限流好狠 —— 冇 cache 嘅話
  # 呢個閘會慢 + 狼來了（429 假陽性），最後俾人剷走。cache 檔唔 commit（.gitignore）。
  CACHE="scripts/.img_cache.tsv"; touch "$CACHE"
  NOW=$(date +%s); TTL=$((7*24*3600))
  IMG_FAILS=0; IMG_CACHED=0
  sort -u "$ALL_IMG" > "$TMP/imgs_u.txt"
  while IFS= read -r u; do
    ts="$(grep -F "	$u" "$CACHE" | tail -1 | cut -f1)"
    if [ -n "$ts" ] && [ $((NOW-ts)) -lt "$TTL" ]; then IMG_CACHED=$((IMG_CACHED+1)); continue; fi
    # ranged GET（攞 1 byte）好過 HEAD（Wikimedia 對 HEAD burst 限流更狠）；成功 = 206 或 200
    res=""
    for attempt in 1 2 3; do
      res="$(curl -sL -A "$UA" -r 0-0 -o /dev/null -w '%{http_code} %{content_type}' --max-time 15 "$u" 2>/dev/null)"
      case "$res" in 429*) sleep $((attempt*20));; *) break;; esac
    done
    code="${res%% *}"; ctype="${res#* }"
    if { [ "$code" != "200" ] && [ "$code" != "206" ]; } || ! printf '%s' "$ctype" | grep -qi 'image/'; then
      if [ "$code" = "429" ]; then
        FAIL "圖片驗唔到（rate-limit 429，唔一定死鏈）: $u —— 等 10 分鐘再跑 check.sh（cache 會令已過嘅唔使重驗）"
      else
        FAIL "圖片死鏈/非圖: [$code $ctype] $u"
      fi
      IMG_FAILS=$((IMG_FAILS+1))
    else
      printf '%s\t%s\n' "$NOW" "$u" >> "$CACHE"
    fi
    sleep 1   # 禮貌間隔，防 rate-limit
  done < "$TMP/imgs_u.txt"
  [ "$IMG_FAILS" = "0" ] && PASS "$(wc -l < "$TMP/imgs_u.txt" | tr -d ' ') 條圖片 URL 全部 200 image/*"

  SECTION "4. Deploy link 健康檢查"
  # 點解：deploy*/ 資料夾唔喺本 repo，push 咗冇上線 / repo 改名都係靜默死；呢度係唯一補閘。
  if [ -f scripts/deploy_urls.txt ]; then
    while IFS= read -r u; do
      case "$u" in \#*|"") continue;; esac
      code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$u")"
      [ "$code" = "200" ] && PASS "上線中: $u" || FAIL "deploy link 死咗 [$code]: $u"
    done < scripts/deploy_urls.txt
  else
    WARN "冇 scripts/deploy_urls.txt，跳過 deploy 檢查"
  fi
fi

# ---------------------------------------------------------------------------
# 總結
# ---------------------------------------------------------------------------
printf '\n════════════════════════════════════\n'
if [ "$FAILS" -gt 0 ]; then
  printf '🔴 check.sh FAIL：%s 項未過。修完再跑，全綠先准講「done」。\n' "$FAILS"
  printf '   （每個閘點解存在 → docs/GUARDRAILS.md）\n'
  exit 1
else
  printf '🟢 check.sh 全部通過，可以收工。\n'
  exit 0
fi
