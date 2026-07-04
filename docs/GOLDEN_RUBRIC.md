# GOLDEN — 黃金範本 + 出路書自評 Rubric

> **黃金範本 = `trips/fukuoka-2026-08/tripData.json`**（和風模板、100% 導航覆蓋、7/7 backup、雙幣預算、10 個 events 連來源）。
> 點解係佢：係實際上線俾家人用緊、經最多輪人手打磨嘅一份；結構上每個欄位都有齊示範。
> 新 trip 唔好由零作結構 —— **抄佢，改內容**。
>
> 下面每項都係 yes/no，弱 session 都判到。**任何一項 No = 未達標，唔好交付。**
> （機械項 check.sh/validate 會捉；呢度係俾你出路書前自己過一次嘅完整清單。）

## A. 結構完整（對照黃金範本頂層欄位）
- [ ] `title` 全 repo 唯一；有 `kicker/subtitle/dateRange/travelers/heroImage`
- [ ] 有 `overview[]`（每日速覽；唔好用舊欄 highlights）
- [ ] 有 `weather`（總述）+ 每個 day 有 `weather{icon,high,low}`
- [ ] 有 `expense{cur,rate,budget}`（分帳工具開箱即用）
- [ ] 有 `dining`（分類）+ `alternatives`（備選庫）+ `hotels` + `budget` + `essentials` + `tips`

## B. 每日行程（days[]）
- [ ] 每日有 `theme`；每個活動有 `time`
- [ ] **每個**非餐飲活動有 `mapQuery` 或 `address`（黃金範本 19/19；現場冇地圖掣 = 廢卡）
- [ ] **每個**非餐飲活動有 `imageUrl`（已驗真）或 `icon` emoji（卡面唔空白）
- [ ] 活動之間有 `transfer`（去下一站交通文字）—— 至少主要換場位有
- [ ] **每日**有 `backup[]` 至少一個（室內優先；8 月 = 午後雷雨季）
- [ ] 落地日/回程日輕量；冇連續兩日重腳程（P3 節奏規則）

## C. 內容誠實（P1 反幻覺）
- [ ] 所有價錢有可靠度標籤（實查/參考~/≈估算）；`budget.note` 有動態定價 disclaimer
- [ ] 所有 budget 銀碼欄有 HK$ 等值（本地價可並列，例 `≈ ¥520,000（約 HK$25,370）`）
- [ ] events 每個有 `date` + `link`（或 mapQuery）；日期經來源核實，唔係印象
- [ ] 唔肯定嘅嘢寫咗 `（待確認）`，冇「似啱嘅數」
- [ ] 圖片全部 Wikimedia / 自 host `deploy*/img/`；冇 gstatic；餐廳用 📷 連結唔擺圖

## D. 手機現場可用性（路書係喺旅途中用嘅）
- [ ] `essentials` 八欄齊：currency/plug/transit/emergency/sim/timezone/language/tipping
- [ ] 餐飲卡有 `mapQuery`（+有 menuLink 更好）
- [ ] 開一次生成品喺瀏覽器：封面圖出、每日路線地圖掣開到 Google Maps、分帳可加數

## E. 收工機械閘
- [ ] `python3 scripts/generate.py trips/<slug>/tripData.json --strict` 零警告零錯誤
- [ ] `bash scripts/check.sh` 全綠（exit 0）

> 自評方法：逐項答 yes/no，唔准「大致有」。有 No → 修完再過一次成張表。
