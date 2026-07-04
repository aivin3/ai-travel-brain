# AI Travel Brain — 憲法（每次開工必讀，全文 <100 行係刻意嘅）

> 用戶：香港家庭（3大1小，小朋友 8 歲）。輸出繁體中文；景點/店名保留當地原名。
> 產品：`tripData.json` → `scripts/generate.py` → 自包含單檔 `roadbook.html`（手機優先、離線可用）。
> 已上線俾家人用緊（4 條 GitHub Pages link）——你嘅改動會直接影響真旅程。

---

## 0 · 你而家要做咩？（決策樹）

| 任務 | 行呢條路 |
|---|---|
| 計劃新旅程 / 整路書 | `skill.md` 七步 workflow；結構**抄黃金範本** `trips/fukuoka-2026-08/tripData.json`；自評 `docs/GOLDEN_RUBRIC.md` |
| 改行程內容 | 只改 `trips/<slug>/tripData.json` → 重跑 generate.py。**永遠唔准手改 roadbook.html** |
| 改模板 render/工具 JS | 先讀 `docs/PLAYBOOK.md` P5（兩檔同步 SOP）。呢度係全 project 最容易整爛嘢嘅位 |
| 加 feature | 用戶冇明確叫 = 唔做（PLAYBOOK P4） |
| 部署 | `bash scripts/deploy.sh`（P6；工作夾先跑到） |
| 任何檢查 fail / 想刪個閘 | 先讀 `docs/GUARDRAILS.md` 對應條目（每個閘背後係一單事故） |
| 接手唔識背景 | `BLUEPRINT.md`（完整上下文）→ 本檔 → schema → 模板 → 黃金範本 |

## 1 · 鐵律（違反 = 錯，冇例外）

1. **事實要有來源**：價/時間/班次/活動日期必標 `實查`/`參考~`/`≈估算`；新聞類要 ≤120 字逐字引用；唔肯定寫 `（待確認）`。錯得有語氣係最危險嘅幻覺（PLAYBOOK P1）。
2. **圖片唔准作**：`imageUrl` 只准真實 https（Wikimedia / 自 host）；gstatic 縮圖必 download 自 host；冇真圖就留空+icon。決策樹喺 PLAYBOOK P2。
3. **成品由數據重生**：改嘢 = 改 JSON/模板 → 重跑 `generate.py`。手改 HTML 會被 check.sh 當 stale 打回頭。
4. **所有模板共用 JS 逐字節一致**：`templates/*.html` 只准 CSS 唔同；改 JS 必全部同步（P5）；新視覺模板 = copy `roadbook.html` 只改 CSS（G2）。
5. **`title` 全 repo 唯一**（兩 trip 同名 = localStorage 分帳/訂單互相覆寫，G9）。
6. **手機現場優先**：每個景點/餐廳/酒店盡量有 `mapQuery`；`essentials` 八欄填齊 —— 路書係喺旅途中查嘅，唔係擺喺屋企睇。
7. **帶童硬約束**：夜歸>60分鐘車程/貼尾班車/暑天連續戶外>3小時 → 照 PLAYBOOK P3 改行程，唔准「應該冇事」。
8. **working code 唔郁**：唔准為優雅 refactor；只准修 bug 同加閘。

## 2 · 講「done」之前必過嘅閘（冇得傾）

```bash
bash scripts/check.sh          # 全套（模板drift/生成/JS語法/圖片200/deploy 200）
```
- **exit 0 先准話完成。** 冇網先用 `--offline`，但交付前要補跑全套。
- 新砌/大改嘅 trip 加跑：`python3 scripts/generate.py <tripData> --strict`（警告清零）。
- 圖片閘見 429 = rate-limit 唔係死鏈：等 10 分鐘再跑（G13），唔准剷閘或亂換圖。
- 改咗模板 → 重生**所有** trips + `bash scripts/deploy.sh` 重出全部 live（P5/P6）。

## 3 · 數據源（國際通用；中國平台一律唔用）

官方景點網/旅遊局 → 官方鐵路航空 → Booking/Agoda/Google Hotels → Google Maps/Tabelog（餐廳）→ 目的地氣象局（天氣）。來源失效標 `⚠️ 已 fallback`。

## 4 · 出路書前俾用戶過目（標準確認格式）

```
━━━━━━━━━━━━━━━━━━━━━━
🧳 行程確認 | <目的地> <日數>天 | <日期>
人數：… ｜ 預算：… ｜ 偏好：…
每日主題：D1 … / D2 … / D3 …
住宿：… ｜ 估計總花費：…（可靠度：…）
未核實項：①… ②…
━━━━━━━━━━━━━━━━━━━━━━
確認 OK → 生成 roadbook.html
```

## 5 · 檔案指針

| 檔 | 係咩 | 幾時讀 |
|---|---|---|
| `docs/PLAYBOOK.md` | 人手判斷 if-then 化（P1–P7） | 做對應任務前 |
| `docs/GUARDRAILS.md` | 失敗模式目錄（症狀→規則→邊個閘捉） | 檢查 fail / 想改閘 |
| `docs/GOLDEN_RUBRIC.md` | 黃金範本 + yes/no 自評表 | 每次出路書前 |
| `scripts/check.sh` | 收工 QA 閘 | 收工前必跑 |
| `skill.md` | /travel 七步 workflow | 計劃新旅程 |
| `schema/tripData.schema.json` | 數據結構權威定義 | 砌/改 tripData |
| `BLUEPRINT.md` | 完整上下文備份（架構/坑/deploy 對照表） | 接手/搵背景 |
