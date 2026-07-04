# GUARDRAILS — 失敗模式目錄（症狀 → 規則 → 邊個機械檢查捉到）

> 點解有呢個檔：`scripts/check.sh` 同 `generate.py validate()` 每個閘背後都有一單真實事故或可預見事故。
> 呢度係「點解唔准刪嗰個閘」嘅證據。想刪/改閘 → 先讀對應條目，證明失敗模式已經唔存在。
> 格式固定：**症狀 → 規則 → 機械檢查**。新踩坑 → 加一條 + 加對應檢查，唔好淨係寫散文。

---

## G1 · 兩模板共用 JS drift（頭號隱形 bug 源）
- **症狀**：改咗 `roadbook.html` 嘅 render/工具 JS，唔記得同步 `roadbook_jp.html`（或倒轉）。表面冇事，直到有 trip 用另一個模板，先發現功能缺咗/舊咗。**真實案例：2026-07 前 pastel 版缺咗 overview 速覽表、glow 徽章、events 縮圖成個月，冇人發現。**
- **規則**：`roadbook.html` 同 `roadbook_jp.html` 嘅主 `<script>` 區塊必須**逐字節一致**（連縮排）；兩檔只准 CSS 唔同。改 JS = 兩檔同步改（SOP 見 PLAYBOOK P5）。
- **機械檢查**：check.sh §1d —— 抽兩檔最後一個 `<script>`，normalize 尾隨空白後 diff，唔一致即 FAIL。

## G2 · 分家模板 fork（歷史：roadbook-washi.html，2026-07-04 已刪）
- **症狀**：有人 copy 模板出去做新視覺，JS 順手改咗/冇跟上，變成第二套碼 —— 唔受 drift 閘保護，工具功能靜默缺失。真實案例：washi fork JS 完全分家、缺訂單收納/Firebase 同步/QR、仲有 iOS 坑，喺 repo 躺咗好耐冇人發現。
- **規則**：**新視覺模板 = copy `templates/roadbook.html`，只准改 CSS，主 `<script>` 一隻字都唔准郁**。做完佢自動受 G1 drift 閘保護（閘係「全部 templates/*.html 對基準」）。
- **機械檢查**：check.sh §1d —— 任何模板主 JS 同基準唔一致即 FAIL；想「試驗性分家」= 唔准，先統一先入 repo。

## G3 · 手改 HTML / 改完唔重生（stale 成品）
- **症狀**：直接手改 `trips/*/roadbook.html`（或改咗 tripData/模板但冇重跑 generate.py）。下次任何人重生成，手改嘢即刻蒸發；或者 repo 入面成品同數據講緊兩個唔同故事。
- **規則**：成品永遠由 `tripData.json + 模板` 重生出嚟；**永遠唔好手改 HTML**。
- **機械檢查**：check.sh §2d —— 重生一份同 repo 成品 diff（略過 generationDate 行），唔一致即 FAIL。

## G4 · `background-attachment:fixed`（iOS 坑）
- **症狀**：iPhone 開路書出現橫向溢位、position:fixed 元素 jank。2026-06 已踩過並移除。
- **規則**：模板禁用 `background-attachment`；用 `html{overflow-x:hidden;-webkit-text-size-adjust:100%}` 方案。
- **機械檢查**：check.sh §1b —— grep 所有模板，有即 FAIL。

## G5 · 圖片幻覺 / 死鏈 / 唔穩圖源
- **症狀**：路書現場開，圖片格仔爛咗。成因三種：①URL 係作出嚟（幻覺）②gstatic `encrypted-tbn` 縮圖過期 ③圖真係死咗。
- **規則**：`imageUrl` 只准真實 https 公開圖（Wikimedia / 自 host `deploy*/img/`）；gstatic 一律 download 自 host；唔肯定就留空（模板會出 act-ph 示意卡）。
- **機械檢查**：generate.py validate —— 非 https / gstatic / encrypted-tbn 即 ERROR ship 唔到；check.sh §3 —— 每條 URL ranged-GET 驗 200/206 + `image/*`。
- **注意（狼來了防護）**：Wikimedia 對 burst 請求出 **429 = rate-limit ≠ 死鏈**。check.sh 已有 UA + 間隔 + 退避 + 7 日 cache（`scripts/.img_cache.tsv`，唔 commit）。見到 429 FAIL → 等 10 分鐘再跑，唔好剷閘、唔好換圖。

## G6 · placeholder 殘留 / Firebase 錯注入
- **症狀**：成品入面見到 `__TRIP_DATA__` 字樣（生成鏈斷咗）；或者離線版夾咗 Firebase SDK（會走網）；或者共用版冇咗 SDK（分帳唔同步，靜默）。
- **規則**：三個 placeholder（`__TITLE__ __TRIP_DATA__ __FIREBASE__`）模板必須齊；離線 tripData 冇 `firebase` key，共用版先有。
- **機械檢查**：check.sh §1a（模板齊 placeholder）+ §2c（成品無殘留；firebase 有無同 SDK 有無必須一致）。

## G7 · `</script>` 提早閉合 / 注入砸爛 JS
- **症狀**：tripData 字串內容（例如 note 寫咗 "</script>" 或怪引號組合）令成品 JS 爆語法，成頁白屏。
- **規則**：generate.py 注入前 `.replace("</","<\\/")`（已內建，唔准刪）；內容避免喺字串塞 HTML tag。
- **機械檢查**：check.sh §2b —— 對**每個生成成品**（唔止模板）抽 JS 過 `node --check`。

## G8 · Python `re.sub` 替換字串轉義坑
- **症狀**：用 `re.sub(pat, REPL, s)` 而 REPL 內有 `\s` `\1` 等 → 被當轉義序列，靜默出錯字。2026-06 已踩過。
- **規則**：凡 REPL 係變數/含反斜杠 → 一律 `re.sub(pat, lambda m: REPL, s)`；或者直接用 `str.replace`（generate.py 而家全用 `.replace`）。
- **機械檢查**：無（code review 規則）。改 generate.py / 寫新 script 時人手守。

## G9 · trip title 重複 → localStorage 相撞
- **症狀**：兩個 trip 用同一個 `title` → 分帳 (`exp_<title>`) 同訂單 (`book_<title>`) 喺同一部手機互相覆寫，用戶數據靜默壞。
- **規則**：每個 trip 嘅 `title` 必須全 repo 唯一。
- **機械檢查**：check.sh §2f —— titles 有重複即 FAIL。

## G10 · Deploy 靜默死鏈 / 靜默 stale
- **症狀**：`deploy*/` 資料夾係獨立 git repo（唔喺本 repo 入面）。三種靜默死法：①push 失敗/repo 改名 → 開唔到 ②commit 咗冇 push / Pages 未刷新 → live 係舊版 ③改咗模板/數據漏重出 → 本地 deploy 檔都係舊。
- **規則**：deploy 一律跑 `bash scripts/deploy.sh`（重生→push→等 Pages→驗 live 一致）；新 deploy 必須加入 `scripts/deploy_map.tsv`（url/dir/slug/mode 四欄，係 deploy 清單嘅單一真相）。
- **機械檢查**：check.sh §4 三層 —— live 200；live == 本地 deploy 檔；本地 deploy 檔 == 由當前數據+模板重生。（淨 clone 冇 deploy 資料夾會跳後兩層並警告。）
- **已知現象（2026-07-04 實測）**：Pages「deploy」步驟會 transient fail（幾個 repo 同時 push 尤其易中；build 成功但 deploy 失敗）。deploy.sh 會自動報 run 結論；修法 = 空 commit 重觸發（`git commit --allow-empty && git push`），唔使改任何內容。

## G11 · 揀錯模板靜默 fallback
- **症狀**：tripData 寫 `"template": "roadbook_pj.html"`（打錯字）→ 舊版 generate.py 靜默用預設模板，出咗個完全唔同設計都冇人發現。
- **規則**：模板名必須真實存在，唔存在係 ERROR 唔係 fallback。
- **機械檢查**：generate.py validate —— 搵唔到模板檔即 ERROR。

## G12 · 內容幻覺（價/時間/休館日/活動日期）
- **症狀**：路書寫住嘅開放時間/票價/花火日期係啱嘅語氣、錯嘅事實。**真實案例：「原鶴溫泉川開き花火」以為 8 月，查證係 5–6 月，險啲編入行程。**
- **規則**：見 PLAYBOOK P1（反幻覺內容政策：來源標籤 / raw-quote / 出發前核對清單）。
- **機械檢查**：部分——validate 會捉 events 冇 link/date（冇得驗證=高危）；事實正確性本身機器驗唔到，靠 P1 流程 + 出發前人手核對。**已知缺口**。

## G13 · Wikimedia/外站 429 ≠ 死鏈（狼來了）
- **症狀**：check.sh 連跑幾次後圖片閘大量 FAIL 429，誤以為圖死咗，亂換圖/剷閘。
- **規則**：429 = 你請求太密，唔係圖有問題。等 10 分鐘再跑；cache 會令已驗過嘅唔使重驗。
- **機械檢查**：check.sh §3 對 429 出專用錯誤訊息（教你等，唔係教你換圖）。

## G14 · Firebase 規則靜默過期/改壞
- **症狀**：共用分帳突然唔同步 —— 前端唔會彈 error，家人以為係網絡問題。成因：RTDB 測試模式規則 30 日過期，或有人喺 console 改壞規則。
- **規則**：正確狀態（用戶 2026-07 前已 publish）= 房間內 (`rooms/$code`) 可讀寫、`/rooms` 列舉拒絕、`/rooms` 以外拒絕。規則 JSON 喺 BLUEPRINT §5。
- **機械檢查**：check.sh §5 —— 房間級讀 probe（要通）+ `/rooms` 外寫 probe（要拒）。
