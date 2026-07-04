# INSTITUTIONALIZED — Fable 5 一次性制度化總結（2026-07-04）

> 呢次 session 嘅任務係「立制度，唔係做任務」：把判斷力轉成 ①會 fail 嘅閘 ②機械 if-then 規則 ③照抄就啱嘅範例。
> 之後嘅 session（唔理幾弱）只要：**照 CLAUDE.md 做事 + 收工前跑 `bash scripts/check.sh` 攞 exit 0**。

---

## 1 · 起咗咩制度（檔案 → 點用）

| 檔 | 係咩 | 弱 session 點用 |
|---|---|---|
| `scripts/check.sh` | **收工 QA 閘**（13 類檢查：模板 placeholder/iOS 坑/JS 語法/共用 JS drift/生成驗證/成品新鮮度/title 唯一/圖片 200/deploy 200） | 收工前跑；exit 0 先准話 done。冇網 `--offline`，交付前補全套 |
| `scripts/generate.py`（升級 validate） | 爛數據 ship 唔到：非 https 圖/gstatic/模板名打錯 = ERROR；缺導航/缺圖icon/events 冇 link/budget 冇 HK$ 等值 = 警告；`--strict` 警告變 error | 生成時自動行；新 trip 收工加 `--strict` |
| `CLAUDE.md`（憲法版） | 決策樹 + 8 條鐵律 + 收工閘清單，<100 行 | 每次開工必讀，跟決策樹入對應檔 |
| `docs/GUARDRAILS.md` | 13 個失敗模式：症狀→規則→邊個閘捉 | 檢查 fail / 想改閘先讀；防止後人誤刪閘 |
| `docs/PLAYBOOK.md` | 判斷 if-then 化：P1 反幻覺 / P2 圖源決策樹 / P3 帶童硬約束（夜歸/尾班車/颱風）/ P4 幾時先加 feature / P5 改共用模板 SOP / P6 deploy SOP / P7 新 trip 清單 | 做對應任務前照跟 |
| `docs/GOLDEN_RUBRIC.md` | 黃金範本 = `trips/fukuoka-2026-08/tripData.json` + 五組 yes/no 自評 | 新 trip 抄結構；出路書前逐項自評 |
| `scripts/deploy.sh` + `scripts/deploy_map.tsv` | 一鍵重出 deploy（重生→push→等 Pages→驗 live 一致）；map = deploy 清單單一真相 | 改完模板/數據跑 deploy.sh；新 deploy 加一行入 map |

## 2 · 呢次順手修咗嘅真 bug（全部係閘落地時暴露）

1. **共用 JS 已 drift 一個月**：pastel 模板缺 overview 速覽表/glow 徽章/events 縮圖（和風版先有）。已統一兩檔 JS 逐字節一致（overview 優先、highlights fallback、glow/縮圖兩邊都有，pastel 補咗對應 CSS）。以後 drift 閘（check.sh §1d）逼住同步。
2. **roadbook-washi.html** 有 iOS 坑 `background-attachment:fixed` + 缺 `__FIREBASE__` placeholder。已修，但佢 JS 仍係分家（見缺口 #1）。
3. **tokyo-example 成品 stale**（同 tripData 唔對齊）。已重生；以後新鮮度閘（§2d）會捉。
4. **generate.py 靜默 fallback**：模板名打錯會靜默用預設模板。而家係 ERROR。
5. 全部 trips 已用統一模板重生 + 過晒閘。

## 3 · 校準紀錄（點解啲閘係咁設）

- 圖片閘用 **ranged GET（1 byte）+ UA + 間隔 + 退避 + 7 日 cache**（`scripts/.img_cache.tsv`，已 .gitignore）：Wikimedia 對 burst HEAD 限流狠（429 ≠ 死鏈）。冇呢套，閘會狼來了然後俾人剷。
- budget 規則係「每個銀碼欄要有 **HK$ 等值**」而唔係「唔准混幣」：實測兩個上線 trip 慣例係 `≈ ¥520,000（約 HK$25,370）` 雙標，混幣係 feature 唔係 bug。
- 黃金範本揀福岡：實測 19/19 活動有導航、19/19 有圖或icon、7/7 日有 backup、essentials 八欄齊 —— rubric 每項佢自己都過到。

## 4 · 缺口狀態（2026-07-04 第二輪，用戶拍板「跟建議做」後）

**已解決（同輪落閘）：**
- ~~washi 分家 fork~~ → **已刪檔**（git 歷史可救返）；drift 閘升級做「全部 templates/*.html 對基準逐字節一致」，將來新模板自動受保護（G2 重寫）。
- ~~deploy 新鮮度驗唔到~~ → 新增 `scripts/deploy.sh`（重生→push→等 Pages→驗 live 一致）+ `scripts/deploy_map.tsv`（deploy 清單單一真相，取代 deploy_urls.txt）+ check.sh §4 三層閘（live 200 / live==本地 / 本地==重生）。
- ~~Firebase 規則~~ → 實測**用戶已 publish 正確 per-room rules**（房間讀寫通、/rooms 列舉拒、外圍寫拒）；check.sh §5 加咗兩支 probe 長期監察（G14）。

**仲餘低（按風險排）：**
1. **內容正確性冇機械閘**：events 日期/休館日/價錢啱唔啱，機器驗唔到（前科：花火大會季節估錯）。靠 P1 流程 + rubric C 組 + validate 捉「冇 link/冇 date」。跟進方向：照高雄先例，為每個 trip 開「出發前 2 週 rescan」排程。
2. **iCloud 工作夾 ↔ GitHub repo 雙份真相**：`Desktop/AI Travel Brain`（工作夾，非 git）同 master repo 靠人手同步，會 drift。跟進方向：工作夾直接 git init 掛 remote，廢除人手同步。
3. GitHub token（keychain 嗰個 classic token）用完建議 revoke（BLUEPRINT 遺留事項）。

## 5 · 收工準則（一句）

**改完任何嘢：`bash scripts/check.sh` 全綠 + 過一次 GOLDEN_RUBRIC → 先准講 done。**
