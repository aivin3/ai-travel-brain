# AI Travel Brain — 旅遊研究・規劃・路書主規範

> 🆕 **新 AI 接手 / 跨環境遷移**：先讀 [`BLUEPRINT.md`](BLUEPRINT.md)（完整上下文備份：架構/決定/坑/源碼/待辦）。
> Master 源碼備份 repo（private）：`github.com/aivin3/ai-travel-brain`。
> 開工必讀順序：BLUEPRINT.md → 本檔 → schema/tripData.schema.json → templates/roadbook.html → 某 trips/*/tripData.json。

> 本檔是 Claude 在此工作區的最高指令。所有旅遊 research / planning / 出路書必須遵守。
> 用戶：香港出發，國際旅行（家庭為主）。語言：**繁體中文輸出**，景點/酒店/餐廳保留當地原名方便當地用。
> 定位：**自己旅行用**（出發前規劃 + 旅行途中手機查 + 同家人分享），唔係商業客戶路書。
> 靈感來源：github.com/huanyuzhilv/skills-travel-planner（抄其骨架：tripData 數據層 + HTML 生成器 + research workflow），但**換走中國平台數據源**（小紅書/飛豬/TikHub/12306/攜程），改用通用 Web 來源。

---

## 鐵律

1. **數據要核實**：景點門票/營業時間/交通班次/酒店價，凡寫入 tripData 必附來源；唔肯定標 `（未核實）`。
2. **可靠度分級**：價錢標 `實查`（官網即時）/ `參考~`（搜尋結果，非即時）/ `≈估算`（推算）。每份預算附 disclaimer：動態定價，落單前自行於官方平台確認。
3. **手機優先**：路書係旅行途中喺手機用 → 每個景點/酒店/餐廳盡量帶 `mapQuery` 或 `address`，等「📍開地圖」掣有得㩒。
4. **唔好作圖**：`imageUrl` 一定要真實 HTTPS 公開連結（官方/維基/旅遊局），唔肯定就留空，唔好塞假 URL。
5. **離線可用**：路書係自包含單檔 HTML（CSS/JS 全內嵌），冇網都開到；只有 imageUrl 圖片要網。
6. **彈性節奏**：落地日輕鬆、預留 buffer、午後落雨地區留室內 backup、景點地理分群減少折返。
7. **反幻覺**：任何「最新」事實（價/時間/活動）要 ≤120 字逐字引用 + 來源；無引用 = 唔寫入結論。

---

## Step 0（每次開工必跑）

1. 讀 `CLAUDE.md`（本檔）+ `skill.md`（完整 workflow）+ `schema/tripData.schema.json`（數據結構）。
2. 若用戶指明已有行程 → 跳 research，直接 intake 入 tripData。
3. 確認最小必要欄位：出發地、日期/日數、人數（含小朋友年齡）、目的地（或要唔要推薦）、預算、偏好。缺就問，唔好亂估。

---

## Workflow 摘要（完整見 skill.md）

| 步 | 做咩 | 工具 |
|----|------|------|
| 1 資訊收集 | 確認上述最小欄位 | 對話 |
| 2 目的地推薦（如需） | 候選 → 交通可行性（單程≤4-5h佳）→ 天氣 → 多維比較表俾用戶揀 | WebSearch |
| 3 多維 research | 並行查：天氣、交通（含轉乘驗證）、景點（票價/時間）、餐飲、住宿、真實體驗 | WebSearch / WebFetch |
| 4 行程編排 | 景點地理分群、節奏交替、餐廳就近、留 buffer、落地日輕量 | — |
| 5 預算彙整 | 分類（交通/住宿/餐飲/門票/雜項）+ 可靠度標籤 | — |
| 6 出路書 | 砌 `tripData.json` → `python3 scripts/generate.py trips/<目的地>/tripData.json` | generate.py |
| 7 交付 | 出 `roadbook.html`，叫用戶瀏覽器開；可改 JSON 重生成 | — |

---

## 目錄結構

```
AI Travel Brain/
├── CLAUDE.md                       # 本規範
├── skill.md                        # /travel 完整 workflow
├── README.md                       # 快速上手
├── scripts/generate.py             # tripData.json → roadbook.html（零 dependency）
├── templates/roadbook.html         # 手機優先 HTML 模板（JSON 內嵌 + JS 渲染）
├── schema/tripData.schema.json     # 數據 schema（權威定義）
└── trips/<目的地>-<年月>/
    ├── tripData.json               # 可重用數據層
    ├── roadbook.html               # 最終成品（生成）
    └── sources/                    # 可選：research 原始資料存檔
```

每個新旅程 → 開一個 `trips/<目的地>-<年月>/` 資料夾。

---

## 數據源（國際通用，取代中國平台）

| 用途 | 首選 | fallback |
|------|------|----------|
| 景點/票價/開放時間 | 官方景點網 / 當地旅遊局 | WebSearch + Google Maps |
| 交通班次/價 | 官方航空/鐵路（JR/SNCF/Trainline）、Rome2Rio | WebSearch（標 參考~） |
| 酒店 | Booking / Agoda / Google Hotels（睇價同位置） | WebSearch |
| 餐廳 | Google Maps 評分 / Tabelog（日）/ 當地食評 | WebSearch |
| 天氣 | 目的地氣象局 / AccuWeather / weather.com | WebSearch |
| 圖片 | 官方網 / Wikimedia Commons / 旅遊局圖庫（須 HTTPS 公開） | 留空 |

> 富途/小紅書/飛豬等**唔用**。任何來源失效 → 標 `⚠️ [來源] 不可用，已 fallback`。

---

## 出圖規範（make HTML）

砌好 `tripData.json` 後一律：
```bash
python3 scripts/generate.py trips/<目的地>-<年月>/tripData.json
```
- generate.py 會校驗必要欄位、補 generationDate、注入模板、出單檔 HTML。
- 想自訂輸出路徑：`-o <path.html>`。
- 改完行程 → 改 `tripData.json` → 重跑即更新，**唔好直接手改 HTML**。

---

## 標準確認輸出（出路書前俾用戶過目）

```
━━━━━━━━━━━━━━━━━━━━━━
🧳 行程確認 | <目的地> <日數>天 | <日期>
━━━━━━━━━━━━━━━━━━━━━━
人數：… ｜ 預算：… ｜ 偏好：…
每日主題：D1 … / D2 … / D3 …
住宿：… ｜ 估計總花費：…（可靠度：…）
未核實項：①… ②…
━━━━━━━━━━━━━━━━━━━━━━
確認 OK → 我即生成 roadbook.html
```
