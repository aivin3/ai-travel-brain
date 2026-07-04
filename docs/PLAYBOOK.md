# PLAYBOOK — 人手判斷 → if-then 規則

> 點解有呢個檔：呢啲判斷冇得寫成 script，但可以寫成「條件 → 動作」等機械跟。
> 跟得足 = 唔使有判斷力都做啱。每條規則帶一句點解，令你唔會誤刪。

---

## P1 · 反幻覺內容政策（寫入 tripData 嘅每個事實）

| If | Then |
|---|---|
| 寫任何 價錢/開放時間/班次/活動日期 | 必須有來源，並標可靠度：`實查`（官網即時睇到）/ `參考~`（搜尋結果非即時）/ `≈估算`（推算） |
| 來源係新聞/活動公告 | 抄 ≤120 字**逐字引用** + 來源名，先准寫入結論（無 raw-quote = 無呢個事實） |
| 唔肯定 / 搵唔到來源 | 寫 `（待確認）`，唔好寫個「似啱」嘅數 —— 錯得有語氣係最危險嘅幻覺 |
| 行程含 博物館/景點 有固定休館日 | 對齊星期幾核一次（例：好多館逢一休）；行程編排要避開。**前科：花火大會日期估錯季節，險啲編入行程** |
| 出發前 ≤2 週 | 重新核對：①各活動日期/售票 ②休館日 ③颱風季睇 JMA/CWA 預報（8 月日本/台灣 = 颱風季） |
| 用戶報實價（機票已買/酒店已訂） | 以用戶為準，標 `實查`，寫入 `confirmation` 欄 |

## P2 · 圖片來源政策（決策樹）

```
需要一張景點/餐廳圖？
├─ Wikimedia 有？→ 用 REST API 搵 originalimage.source（upload.wikimedia.org）
│   └─ 用之前：curl 驗 200 + image/*（check.sh 會再驗）
├─ 得 Google 縮圖（gstatic/encrypted-tbn）？→ 唔准 hotlink。download 落 deploy*/img/
│   自 host，引用 https://<repo>.github.io/img/x.jpg
├─ 網站有 Cloudflare（如 khh.travel）？→ 伺服器抓唔到，叫用戶自己 save 圖俾你 host
├─ 餐廳？→ 唔好亂搵圖，用「📷 Google 相片」連結（tripData 的 link 欄）
└─ 乜都冇？→ imageUrl 留空 + 填 icon emoji（模板出 act-ph 示意卡，明標非實拍）
```
點解：圖片 URL 係幻覺+死鏈高發區；上面每條分支都係踩過坑之後嘅結論（G5）。

## P3 · 家庭行程決策規則（本用戶：3大1小，小朋友 8 歲）

| If | Then |
|---|---|
| 郊區活動散場後返市區車程 >60 分鐘 且 帶小朋友 | 唔好排公共交通夜歸：改 ①提早走 ②就近住一晚 ③預約包車，三選一寫入行程 |
| 活動完結時間 貼近尾班車 <45 分鐘 buffer | 當冇尾班車處理（散場人潮會食晒 buffer）；同上三選一 |
| 一日入面 步行/戶外 連續 >3 小時（8 月暑天） | 中間插室內冷氣點（商場/博物館/食肆）；帶童中暑風險係硬約束 |
| 連續兩日都係「重腳程」日 | 第二日改輕鬆日（節奏交替）；小朋友第三日一定冧 |
| 午後易雷雨地區（8 月九州/台灣） | 每日 backup[] 至少一個室內選項 |
| 颱風預警（出發前 72h 內有路徑圖掃過目的地） | 出「Plan B 日」：全室內版行程 + 交通改簽連結寫入 tips |
| 樂園/體驗（KidZania 類）要預約 | 開賣日寫入 events/tips + 提用戶較鬧鐘；賣飛失敗 = 成日行程重排 |

## P4 · 幾時先加 feature（防 scope creep）

| If | Then |
|---|---|
| 用戶明確要求新工具/欄位 | 做，但跟 P5 SOP 改模板 |
| 你「覺得」加個 feature 會好啲 | 唔好做。呢個 project 已上線俾家人用緊；提議可以，動手要用戶點頭 |
| 加新 tripData 欄位 | 同步三件套：schema/tripData.schema.json 註釋 + 兩個模板 render + validate()（如需檢查） |
| 想 refactor「令 code 靚啲」 | 唔好。working code 唔郁；只准修 bug 同「抬高地板」（加閘/加驗證） |

## P5 · 改共用模板 SOP（改 render/工具 JS 必跟）

1. 先改 `templates/roadbook.html`。
2. **即刻**用同一段文字改 `templates/roadbook_jp.html`（兩檔 JS 要逐字節一致，連縮排；用 grep 搵同一錨點字串照抄）。
3. 如果改動需要新 CSS class → 兩檔**各自**加（CSS 准唔同，用各自嘅色變數；pastel 冇 `--aka/--gold`，和風冇 `--coral/--amber`）。
4. 重生**所有** trip：`for t in trips/*/tripData.json; do python3 scripts/generate.py "$t"; done`
5. 跑 `bash scripts/check.sh`（drift 閘會逼你做齊 2 同 4）。
6. 改咗模板 = live 版都舊咗 → 跑 `bash scripts/deploy.sh`（P6）。
- 新視覺模板 = copy `roadbook.html` 只改 CSS，主 JS 一隻字唔准郁（G2；drift 閘自動涵蓋新檔）。

## P6 · Deploy SOP（已腳本化，唔好人手逐步做）

```bash
bash scripts/deploy.sh                    # 重出全部（重生→push→等 Pages→驗 live 一致）
bash scripts/deploy.sh fukuoka-2026-08    # 只重出一個 trip 嘅離線+共用兩條
```
- 要喺**工作夾**跑（deploy*/ 資料夾要存在）；淨 clone 會即刻報錯。
- **新 deploy** → 起好 deploy 資料夾（獨立 git repo 掛 GitHub Pages）後，加一行入 `scripts/deploy_map.tsv`（`url \t dir \t slug \t offline|sync`）—— 唔加 = deploy.sh 同 check.sh 都唔知佢存在。
- 改咗模板 = 全部 trip 嘅 live 版都舊咗，跑無參數版重出晒。
- 最後跑 `bash scripts/check.sh`（§4 會驗 live 200 + live==本地 + 本地==重生）。

## P7 · 新 trip 開工清單

1. 讀 `CLAUDE.md` → 跟 `skill.md` 七步 workflow。
2. 黃金範本：**抄 `trips/fukuoka-2026-08/tripData.json` 嘅結構**（唔好由零作），對照 `docs/GOLDEN_RUBRIC.md` 自評。
3. 模板揀 `roadbook.html`（夢幻）或 `roadbook_jp.html`（和風）。
4. `title` 要同現有 trip 唔同（G9）。
5. 收工前：`python3 scripts/generate.py <tripData> --strict` 清零警告 + `bash scripts/check.sh` 全綠。
