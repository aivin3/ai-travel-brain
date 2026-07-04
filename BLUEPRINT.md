# 🧳 AI Travel Brain — 專案完整備份與上下文轉移清單（Project Blueprint & Context Backup）

> 本檔目的：俾**一個完全冇本對話歷史嘅 AI** 讀完即可 100% 繼承理解，無縫接手繼續開發。
> 最後更新：2026-06（請以 git log 為準）。語言：繁體中文（程式碼/變數保留原文）。
> ⚠️ 2026-07 制度化（Fable 5 一次性審查）後：規則以 `CLAUDE.md`（憲法）+ `docs/`（PLAYBOOK/GUARDRAILS/GOLDEN_RUBRIC）+ `scripts/check.sh`（收工閘）為準；本檔內嵌源碼/個別描述（例如 generate.py 全文、「glow 只和風顯示」）係歷史快照，同 repo 現檔有出入時**以現檔為準**。制度化總結見 `INSTITUTIONALIZED.md`。

---

## 1. 專案核心概述 (Project Overview)

- **專案名稱**：AI Travel Brain（旅遊大腦）。
- **核心目的**：由 Claude 主導做旅遊 **research → 規劃 → 生成「自包含手機 HTML 路書」**；出發前規劃、旅行途中手機查、同家人分享。
- **使用者**：香港出發、國際旅行（家庭，3 大 1 小 8 歲女）。輸出語言繁體中文。
- **靈感來源**：github.com/huanyuzhilv/skills-travel-planner（抄其骨架：tripData 數據層 + HTML 生成器 + research workflow），但換走中國平台數據源（小紅書/飛豬/TikHub/12306/攜程），改用通用 Web 來源。
- **核心特徵**：
  - 每個 trip = 一個 `trips/<slug>/tripData.json`（結構化數據）→ `generate.py` 注入模板 → 一個**自包含單檔 `roadbook.html`**（CSS/JS 全內嵌，離線可用，圖片除外）。
  - 兩套視覺模板：`roadbook.html`（夢幻馬卡龍 pastel）／`roadbook_jp.html`（和風高對比）；由 tripData 嘅 `"template"` 欄揀。
  - 內建旅行工具：🧮 計錢分攤（含公數錢包 + Firebase 實時共用）、🎫 訂單收納、📱 分享 QR、🖨 一鍵 PDF、🗺️ 一鍵路線導航。
  - 部署：GitHub Pages（每 trip 一條 link；另有 Firebase 共用版）。
- **目前階段**：**核心功能已完成並上線（2 個 trip：高雄、福岡）**，進入「功能擴充 + 內容微調」階段。

---

## 2. 終期技術架構與依賴 (Final Tech Stack & Dependencies)

### 語言/框架/庫
- **Python 3**（只用標準庫；**零 pip 依賴**）— 只得 `scripts/generate.py`。
- **前端**：純 **vanilla HTML / CSS / JS**（**無框架、無 build step**）。所有邏輯喺模板 `<script>` 內，由內嵌 JSON 渲染。
- **資料格式**：JSON（每 trip 一個 `tripData.json`）。
- **Firebase**（可選，只為「多人實時共用分帳」）：**Realtime Database**（**唔係 Firestore**），用 **compat SDK 10.12.2**（`firebase-app-compat.js` + `firebase-database-compat.js`，由 CDN 載入）。
- **外部服務**（前端 deep-link / 圖片，全部唔使 key）：
  - Google Maps：`maps/search/?api=1&query=` 搜尋、`maps/dir/?api=1&origin=&destination=&waypoints=&travelmode=` 路線。
  - 圖片：Wikimedia `upload.wikimedia.org`（真實圖）或 **self-host 喺 `deploy*/img/`**（用戶提供圖）。
  - QR：`api.qrserver.com/v1/create-qr-code`（分享 QR，按需載入）。
- **托管**：GitHub Pages（帳戶 `aivin3`）。

### 系統架構（資料流向）
```
tripData.json  ──┐
                 ├─►  generate.py  ──►  roadbook.html（自包含，內嵌 JSON + 模板 JS）──►  deploy*/index.html ──► GitHub Pages
templates/*.html ┘     │ 替換 placeholder：__TITLE__ / __TRIP_DATA__ / __FIREBASE__
                       │ data.get("template") 揀模板；data.get("firebase") 先注入 Firebase SDK+config
```
- **模板 placeholder**：`__TITLE__`、`__TRIP_DATA__`（注入整個 tripData JSON，已 `.replace("</","<\\/")` 防提早閉合 script）、`__FIREBASE__`（有 `firebase` config 先注入 SDK + `window.FIREBASE_CONFIG`）。
- **渲染**：模板 JS 讀 `<script id="trip-data" type="application/json">` → `render()` 砌 DOM。**唔係 React，係手寫 template literal 砌 innerHTML**。
- **模式切換**：頂部 `setMode('trip'|'money'|'book')` 切 `#view-trip` / `#view-tools`（分帳）/ `#view-book`（訂單）。

### 部署資產（live）
| 用途 | GitHub repo | URL | 模板 | Firebase |
|---|---|---|---|---|
| 高雄・離線 | `aivin3/kaohsiung-trip-2026` | https://aivin3.github.io/kaohsiung-trip-2026/ | roadbook.html（夢幻） | 無 |
| 高雄・共用 | `aivin3/kaohsiung-trip-sync` | https://aivin3.github.io/kaohsiung-trip-sync/ | roadbook.html | 有 |
| 福岡・離線 | `aivin3/fukuoka-trip-2026` | https://aivin3.github.io/fukuoka-trip-2026/ | roadbook_jp.html（和風） | 無 |
| 福岡・共用 | `aivin3/fukuoka-trip-sync` | https://aivin3.github.io/fukuoka-trip-sync/ | roadbook_jp.html | 有 |

- **Firebase 專案**：`travel-split-7e1a5`（Realtime Database，地區 asia-southeast1）。config 喺 `firebase.config.json`（client-side 公開值，commit OK）。⚠️ **安全規則用戶需自行 Publish**（見第 5 節）。
- **排程任務**：`kaohsiung-events-rescan`（一次性，2026-08-01 09:00 +08，重掃高雄 8 月活動並更新路書）。

---

## 3. 已確認的關鍵技術共識 (Confirmed Technical Decisions & Pitfalls)

> 以下全部係本對話**驗證並確認成功**嘅決定／踩過嘅坑，新 AI 務必跟住，**避免重蹈覆轍**。

### 設計模式
- **資料／視覺分離**：tripData.json（純數據）＋ template（純視覺/邏輯）＋ generate.py（注入）。改行程只改 JSON 重生成，**唔好手改 roadbook.html**。
- **兩模板共用同一份 render JS**：`roadbook_jp.html` 由 `roadbook.html` copy 出嚟再各自改 CSS。**改 render 邏輯/工具時要用 script 同步改兩個檔**（grep 同一字串 replace）。CSS 變數兩邊都有：`--ink/--ink2/--muted/--line/--good/--indigo`（共用安全），但 `--coral`(夢幻) vs `--aka`(和風) 唔同；新增共用 CSS 只用兩邊都有嘅變數。

### 反幻覺・圖片鐵律（重要）
- **只用真實、可 hotlink 嘅圖 URL**：Wikimedia REST `https://<lang>.wikipedia.org/api/rest_v1/page/summary/<title>` 取 `originalimage.source`（`upload.wikimedia.org/...`），**逐條 `curl -I` 驗 200 image/* 先用**。
- **gstatic 縮圖（encrypted-tbn）唔穩定** → 一定要 **download 落 `deploy*/img/` self-host**，引用絕對 URL `https://<repo>.github.io/img/x.jpg`。
- **khh.travel 有 Cloudflare**：伺服器 curl 攞唔到（403/「Just a moment」），用戶要自己 save 圖再俾我 host。
- **餐廳唔放亂搵圖**：改 `📷 Google 相片` 掣（Google Maps 連結睇該店真相）。冇真圖嘅景點 → 用 `act-ph` 漸層示意卡（明標非實拍）。

### iOS 響應式（踩過坑）
- **`background-attachment:fixed` 喺 iOS 會搞橫向溢位 + position:fixed jank** → 已移除；改用 `html{overflow-x:hidden;-webkit-text-size-adjust:100%}`。
- **回頂掣**：`scrollTo({behavior:'smooth'})` 喺部分 iOS WebView 失效 → 用 `goTop()`（try smooth，fallback `scrollingElement.scrollTop=0 + window.scrollTo(0,0)`）。

### generate.py / Python 坑
- `re.sub(pat, REPL, s)`：**REPL 含 `\s` 等會被當轉義** → 一律用 **lambda 替換** `re.sub(pat, lambda m: REPL, s)`。
- JSON payload 注入前 `.replace("</","<\\/")` 防 `</script>` 提早閉合。

### 分帳演算法（已驗證）
- **每人淨額** `net = 個人實付 + 公數夾錢 − 應分攤份額`（公錢付嘅開支 payer='POOL' 唔加任何人實付，但加各分攤人份額；夾錢算「提供」）。
- **最少轉帳**：貪心（max creditor ↔ max debtor 逐筆對沖）。已用例子驗證（3 人夾 900 / 公錢付 600 → 餘 300，淨額總和=錢包餘額）。
- **顯示貨幣切換** `disp`（¥/NT$ ↔ HK$）係**每人本機偏好，唔同步**（Firebase 共用模式都係 local）。

### Firebase 共用（已上線驗證）
- 用 **Realtime Database**；房 `rooms/{行程碼}`，子節點 `members/{id}`、`expenses/{id}`、`pool/{id}`、`meta{rate,budget,cur}`、`pw`（明文，輕量保護）。
- **per-child 寫入**（add/del 只動自己節點）避免整объ覆寫衝突；`on('value')` listener 重建 EX 並 re-render。
- **gated**：模板永遠包含 sync code，但只喺 `window.FIREBASE_CONFIG` 存在（generate 注入）先啟用；離線版冇注入 = 純 localStorage，**唔載 Firebase SDK**。
- 棄方案：Firestore（建立時冇遇問題但 code 已寫 RTDB）、whole-object set（會 clobber，改 per-child）。

### 被捨棄方案
- **MCP server / 後端框架**：唔用，堅持純前端自包含 HTML（最易分享、離線）。
- **PDF 生成庫**：用瀏覽器 `window.print()` + print CSS（淺色版），唔用後端 PDF。
- **Google Places API 內嵌餐廳相**：因要 key + billing，用戶揀咗唔開 → 改 📷 連結。

---

## 4. 完整代碼樹與核心源碼 (Codebase)

### 目錄樹
```
AI Travel Brain/
├── BLUEPRINT.md                  # 本檔（上下文備份）
├── CLAUDE.md                     # 最高指令 + workflow（每次開工必讀）
├── skill.md                      # /travel 完整 7 步 workflow
├── README.md                     # 快速上手
├── firebase.config.json          # Firebase Realtime DB config（公開值）
├── .env.example                  # 環境變數範例（本專案幾乎零 env）
├── scripts/
│   └── generate.py               # tripData.json → roadbook.html（注入模板，零依賴）
├── templates/
│   ├── roadbook.html             # 夢幻 pastel 模板（含 render JS + 分帳/訂單/QR 工具）
│   └── roadbook_jp.html          # 和風高對比模板（render JS 同上，CSS 不同）
├── schema/
│   └── tripData.schema.json      # tripData 權威結構定義
├── trips/
│   ├── kaohsiung-2026-08/
│   │   ├── tripData.json          # 高雄 7 日數據（template: 預設 roadbook.html）
│   │   └── roadbook.html          # 生成成品
│   └── fukuoka-2026-08/
│       ├── tripData.json          # 福岡 8 日數據（template: roadbook_jp.html）
│       └── roadbook.html
├── deploy/            (=kaohsiung-trip-2026 repo)   index.html + img/
├── deploy-fukuoka/    (=fukuoka-trip-2026 repo)     index.html + img/（自 host 景點圖）
├── deploy-fukuoka-sync/  (=fukuoka-trip-sync repo)  index.html（含 firebase）
└── deploy-kaohsiung-sync/(=kaohsiung-trip-sync repo) index.html（含 firebase）
```
> ⚠️ `deploy*/` 各自係獨立 git repo（push 去對應 GitHub Pages repo）。`img/` 存 self-host 圖。

### 核心源碼

**完整、即插即用嘅最新源碼以 git repo 為單一真相**（見第 5 節 master 備份 repo）。以下逐字嵌入細檔（`generate.py`），大檔（templates ~50KB、tripData ~800 行）請喺 repo / `templates/`、`trips/` 直接讀取（避免本文過長、保證一致）。

#### `scripts/generate.py`
```python
#!/usr/bin/env python3
"""
AI Travel Brain — Roadbook Generator
讀 tripData.json → 注入手機優先 HTML 模板 → 出自包含單檔 roadbook.html。
- 模板由 data["template"] 揀（預設 roadbook.html）。
- data["firebase"] 存在先注入 Firebase SDK + window.FIREBASE_CONFIG（共用版）。
零外部 dependency（只用標準庫）。
用法：python3 scripts/generate.py trips/<slug>/tripData.json [-o out.html]
"""
import argparse, json, sys, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "templates" / "roadbook.html"
REQUIRED = ["title"]

def warn(msg): print(f"⚠️  {msg}", file=sys.stderr)

def validate(d):
    missing = [k for k in REQUIRED if not d.get(k)]
    if missing:
        sys.exit(f"❌ tripData 缺少必要欄位: {', '.join(missing)}")
    if not d.get("days"):
        warn("無 days[]，路書只會有封面/預算等區塊。")
    for i, day in enumerate(d.get("days", []), 1):
        for a in day.get("activities", []):
            if a.get("meal"):
                continue
            if not (a.get("mapQuery") or a.get("address") or a.get("name")):
                warn(f"D{i} 有活動冇 name/address/mapQuery，唔會有開地圖掣。")

def build(trip_path: Path, out_path: Path):
    data = json.loads(trip_path.read_text(encoding="utf-8"))
    validate(data)
    data.setdefault("generationDate", datetime.date.today().isoformat())

    tpl_name = data.get("template", "roadbook.html")
    tpl_path = ROOT / "templates" / tpl_name
    if not tpl_path.exists():
        warn(f"搵唔到模板 {tpl_name}，改用預設 roadbook.html")
        tpl_path = TEMPLATE
    tpl = tpl_path.read_text(encoding="utf-8")
    payload = json.dumps(data, ensure_ascii=False, indent=2)
    payload = payload.replace("</", "<\\/")  # 防 </script> 提早閉合
    html = tpl.replace("__TITLE__", data.get("title", "旅程路書")) \
              .replace("__TRIP_DATA__", payload)

    # Firebase 實時同步（可選）：有 "firebase" config 先注入 SDK + config
    fb = data.get("firebase")
    if fb:
        fbjson = json.dumps(fb, ensure_ascii=False).replace("</", "<\\/")
        fb_block = ('<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js"></script>'
                    '<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-database-compat.js"></script>'
                    '<script>window.FIREBASE_CONFIG=' + fbjson + ';</script>')
    else:
        fb_block = ''
    html = html.replace("__FIREBASE__", fb_block)

    out_path.write_text(html, encoding="utf-8")
    return data

def main():
    ap = argparse.ArgumentParser(description="tripData.json → roadbook.html")
    ap.add_argument("tripData", help="tripData.json 路徑")
    ap.add_argument("-o", "--output", help="輸出 HTML 路徑（預設同目錄 roadbook.html）")
    args = ap.parse_args()
    trip_path = Path(args.tripData).resolve()
    if not trip_path.exists():
        sys.exit(f"❌ 搵唔到 {trip_path}")
    out_path = Path(args.output).resolve() if args.output else trip_path.parent / "roadbook.html"
    data = build(trip_path, out_path)
    days = len(data.get("days", []))
    print(f"✅ 已生成路書：{out_path}")
    print(f"   {data.get('title')} · {days} 天" + (f" · {data['dateRange']}" if data.get('dateRange') else ""))

if __name__ == "__main__":
    main()
```

#### tripData 結構（摘要；完整見 `schema/tripData.schema.json`）
頂層欄位：`template`(選), `firebase`(選), `kicker, title, subtitle, dateRange, travelers, heroImage`,
`expense{cur,rate,budget}`(分帳預設幣別/匯率/預算), `overview[]{d,t}`(每日速覽表),
`weather{summary,avgHigh,avgLow,rainfall,clothing,tips}`,
`days[]{date,weekday,theme,weather{icon,high,low}, activities[], backup[]}`,
`events[]{name,date,where,tag,note,link,mapQuery,imageUrl}`(期間限定活動,獨立 tab),
`dining[]{category,items[]{name,area,price,hours,intro,signature,mapQuery,link,menuLink,imageUrl}}`,
`alternatives[]{category,items[]{name,area,duration,hours,cost,tag,note,mapQuery,imageUrl}}`,
`hotels[]{name,area,pricePerNight,rating,highlights,confirmation,mapQuery,imageUrl}`,
`budget{tiers[]{label,total,note,pick}, transport/accommodation/food/tickets/other{subtotal}, total, perPerson, note}`,
`essentials{currency,plug,transit,emergency,sim,timezone,language,tipping}`, `tips[]`。
- `activities[]` 元素：`{time, name, icon(無圖時 placeholder emoji), note, mustDo, glow("必去"/"限定"發光徽章,只和風模板顯示), duration, cost(0=免費), transport, address, mapQuery, imageUrl, transfer("去下一站"文字), meal{name,cuisine,perPerson,recommended,location,mapQuery,menuLink}}`。

#### 模板 render JS 主要區塊（`templates/roadbook.html` / `roadbook_jp.html` 內，邏輯相同）
- `render()`：cover（hero+kicker+title+meta+deco emoji）→ nav（總覽/各日/活動/美食/備選/住宿/預算/實用）→ overview 速覽表 → weather → days（每日卡：day-head 印章日期 + theme + `🗺️ 今日路線地圖` daymap 掣 + activities）→ events → dining → alternatives → hotels → budget(tiers) → essentials → tips。
  - activity 渲染：`.time` 膠囊、`.nm`(+glow)、note、`✅必做`(mustDo)、tags(時長/費用/交通)、圖或 `.act-ph` 漸層卡、`📍開地圖`(mapBtn)、`➡️去下一站`(transfer)+`🧭路線`(dirUrl 起→終+travelMode)。
- 工具 JS（共用）：
  - **分帳 v3**：`EX{members,expenses,pool,rate,budget,cur,disp}`；`expRender/expAdd*/expSettle/poolBalance`；Firebase `SYNC{on,ref}` + `syncJoin/syncLeave/attachListener/reJoin/fbInit/seedRoom`（gated on `FBC=window.FIREBASE_CONFIG`）；localStorage key `exp_<title>`。
  - **訂單收納**：`BK[]`、`bkRender/bkAdd/bkDel`、「今日要用」過濾、localStorage `book_<title>`。
  - **分享 QR**：`shareQR()` 彈 overlay（qrserver QR of location.href）。
  - **路線**：`dirUrl(o,d,mode)`、`travelMode(t)`、`qOf(a)`、`dayRouteUrl(d)`（串當日 mapQuery 做 Google Maps waypoints 路線）。
  - `setMode(m)` 切 view；`goTop()` 回頂。
- CSS：兩模板各自一套（夢幻：流動彩虹漸層背景+夢幻光暈+玻璃卡；和風：米紙鮫小紋點+藍染封面+日の丸+波浪+pop 硬陰影卡+紅 torii logo）；共用 print CSS（淺色慳墨、隱藏掣/背景）。

---

## 5. 環境配置與執行指南 (Environment & Run Guide)

### 環境需求
- **Python 3**（macOS 內建即可，零 pip 安裝）。
- 一個瀏覽器睇 roadbook.html。
- （可選）`node` 只用嚟 `node --check` 驗 JS 語法。
- GitHub CLI 唔需要；用 `git` + keychain cached token push（帳戶 aivin3）。

### `.env.example`（本專案幾乎零 env）
```
# 本專案唔用傳統 .env；唯一「config」係 firebase.config.json（client-side 公開值，可 commit）。
# Firebase（Realtime Database）config 範例（值見 firebase.config.json）：
# {
#   "apiKey": "...", "authDomain": "<proj>.firebaseapp.com",
#   "databaseURL": "https://<proj>-default-rtdb.<region>.firebasedatabase.app",
#   "projectId": "...", "storageBucket": "...", "messagingSenderId": "...", "appId": "..."
# }
# GitHub push 用本機 keychain 已存嘅 token（classic, repo scope）。一次性用完建議 revoke。
```

### Firebase 安全規則（用戶需喺 Realtime Database → Rules → Publish）
```json
{ "rules": { "rooms": { "$code": { ".read": true, ".write": true } } } }
```
（測試模式 30 日後過期；上面規則永久。輕量保護：行程碼 + 可選密碼，非銀行級。）

### 常用指令
```bash
# 1) 生成某 trip 路書（離線版）
python3 scripts/generate.py trips/<slug>/tripData.json
open trips/<slug>/roadbook.html

# 2) 生成共用版（注入 firebase）→ 部署
python3 -c "import json;d=json.load(open('trips/<slug>/tripData.json'));d['firebase']=json.load(open('firebase.config.json'));open('/tmp/s.json','w').write(json.dumps(d,ensure_ascii=False))"
python3 scripts/generate.py /tmp/s.json -o deploy-<x>-sync/index.html

# 3) 驗 JS 語法（可選）
python3 -c "import re;h=open('trips/<slug>/roadbook.html').read();print(re.findall(r'<script>(.*?)</script>',h,re.S)[-1])" > /tmp/c.js
node --check /tmp/c.js

# 4) 部署（每個 deploy*/ 係獨立 repo）
cp trips/<slug>/roadbook.html deploy/index.html
( cd deploy && git add index.html && git commit -m "update" && git push origin main )

# 5) 改完模板要同步兩個 + 重生所有 trip + 重部署 4 條 link
```

### 測試方法
- `node --check` 驗 inline JS 語法。
- 用瀏覽器開 roadbook.html 手動驗（分帳結算、訂單、QR、路線掣、PDF）。
- 部署後 `curl -s <pages-url> | grep <marker>` 確認 build 上線。

---

## 6. 接下來的開發計畫與待辦事項 (Next Steps & Roadmap)

### 未竟之功 / 待辦
1. **福岡日期對齊**：機票係 **8/21 去 / 8/28 返（國泰 CX588/CX513）**，但路書 `fukuoka-2026-08` 仲係 **8/22–8/28（7 日）**。需確認用戶最終日子，必要時把路書改 8/21–8/28（多 8/21 一日）。
2. **甘木川花火大會**：已查證 **2026/8/22（六）約 4,000 發，小石原川甘木橋下流**；由博多去（JR+甘木鐵道 via 基山 / 高速巴士 / 包車）。可加入福岡 `events` + Day 晚行程（注意尾班車/帶 8 歲女夜歸）。⚠️ 之前「原鶴溫泉川開き花火」係 5–6 月，已剔除。
3. **圖片缺口**：個別景點仲用 `act-ph` 示意卡（如野森已補真圖）；可繼續補真圖（用戶提供檔 → self-host `deploy*/img/`）。
4. **Firebase 安全規則**：用戶需 Publish 上面 rules（測試模式會過期）。
5. **未做嘅候選功能**（用戶曾傾過，未起）：🧳 行李清單工具、🌦️ 出發前即時天氣/颱風連結、🗣️ 日語旅遊用語速查卡、里數/積分機票（travel-hacking）、全程互動地圖（Leaflet/My Maps）。
6. **安全**：建議 revoke 一次性用過嘅 GitHub token。
7. **排程**：`kaohsiung-events-rescan`（2026-08-01）會自動重掃高雄活動；可為福岡加類似排程（約出發前 2 週）。

### 下一步建議優先序
1. 敲定福岡日期 → 改路書 + 加甘木花火行程。
2. 補福岡缺圖。
3. 揀做行李清單 / 天氣連結 / 用語卡（純前端，與訂單工具同模式）。

---

## 附：如何「無縫遷移到另一個 AI」
1. **最完整 = master git repo**（見 README/最新 commit）：clone 即得全部最新源碼（templates、tripData、generate.py、deploy 輸出）。把 repo URL + 本 BLUEPRINT.md 一齊俾新 AI = 100% 繼承。
2. 新 AI 開工**必讀順序**：`BLUEPRINT.md` → `CLAUDE.md` → `schema/tripData.schema.json` → `templates/roadbook.html`（render + 工具）→ 某 `trips/*/tripData.json`（實例）。
3. 改嘢鐵律：改數據改 JSON 重生成；改邏輯同步改兩個模板；圖只用驗證過嘅真 URL 或 self-host；iOS 唔好用 `background-attachment:fixed`。
