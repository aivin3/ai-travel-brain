# 🧠 FABLE 5 一次性審查任務書（Institution-Building, NOT Execution）

> 你係 Fable 5，呢個 project 一世只用你一次。session 之後會由較弱模型長期運作。
> **你唯一任務：把你嘅判斷力轉成「可長期沿用嘅制度與檔案」，令之後每一個較弱 session 都因此變強。**
> 立制度，**唔好**攞嚟做日常任務。

---

## 0. 心法（讀之前先入腦）
判斷力**唔會**以散文形式 transfer 俾弱模型；只會以三種形式 transfer：
1. **閘（可執行檢查）** — 會令 build / 收工失敗嘅 script。
2. **規則（if-then 決策）** — 機械可跟、無需判斷。
3. **範例（golden example）** — 照抄就啱。

所以：**可執行 > 散文；擋死錯誤 > 提醒小心；零額外判斷可用 > 需要理解。**

## 1. 先讀（用最少 token 建立理解，唔好重新發現）
Clone `github.com/aivin3/ai-travel-brain`，順序讀：
`BLUEPRINT.md` → `CLAUDE.md` → `skill.md` → `schema/tripData.schema.json` → `templates/roadbook.html`（render() + 工具 JS）→ 一個 `trips/*/tripData.json`。
（`roadbook_jp.html` 嘅 render/工具 JS 同 roadbook.html **應該一致**，只有 CSS 唔同 —— 呢個「兩模板共用 JS」係最大脆弱點。）

## 2. 禁止事項（違反 = 浪費你唯一一次）
- ❌ 唔好改任何行程內容 / 起新 feature / 執行日常任務。
- ❌ 唔好為「優雅」refactor working code —— 只准「抬高地板」嘅改動。
- ❌ 唔好泛泛講 best practice、唔好淨係讚。
- ❌ 唔好一次過重寫全部；揀**最高槓桿**嗰幾個檔深做。

## 3. 交付物（制度檔案，一個 PR / commit）
按槓桿排序，做得幾多得幾多，但**質 > 量**：

1. **`CLAUDE.md` → 憲法版**：剪走廢話，淨低「不可違反鐵律」+ 決策樹 + **「講 done 之前必過嘅閘清單」**。每一行都要**改變行為**，否則刪。

2. **`scripts/check.sh`（最重要）**：一鍵 QA 閘，弱模型收工前必跑，**失敗要 exit 非 0 並嘈**。至少檢查：
   - 每個 `trips/*/tripData.json` JSON 有效 + 過 `generate.py` validate。
   - 生成後 inline JS 過 `node --check`（抽最後一個 `<script>`）。
   - **兩個模板嘅「共用 JS 段」有冇 drift**（例如 diff `render(` 到工具區塊的正規化文本；唔一致就 fail —— 呢個係頭號隱形 bug 源）。
   - 冇 `background-attachment:fixed`（iOS 坑）。
   - 所有 `imageUrl` / heroImage `curl -sI` 係 200 + `content-type: image/*`（唔係就列出 + fail）。
   - 模板含 `__TITLE__ __TRIP_DATA__ __FIREBASE__` placeholder；離線生成後唔應殘留 placeholder 或誤載 firebase。
   - （可加）deploy link `curl` 200 健康檢查。

3. **`docs/GUARDRAILS.md`**：失敗模式目錄。每條格式固定：**症狀 → 規則 → 邊個機械檢查捉到佢**。至少涵蓋 BLUEPRINT 第 3 節嗰啲坑，並補你預見到嘅新坑。

4. **`docs/PLAYBOOK.md`**：把「人手判斷」寫成 if-then 規則。至少：
   - **反幻覺內容政策**：價/時間/開放時間一律標來源，未證標「待確認」；新聞/事實需 ≤120 字 raw-quote；日期/休館日出發前必核。
   - **圖片來源政策**：只用 Wikimedia REST 驗 200 或 self-host `deploy*/img/`；gstatic 縮圖必 download；khh.travel(Cloudflare) 抓唔到要用戶提供。
   - **家庭/細路 · 休館日 · 颱風/尾班車** 決策規則（例：郊區夜歸>X 分 + 帶童 → 建議包車；行程對齊星期避休館）。
   - **「幾時先加 feature、點安全改兩個共用模板」** SOP（改邏輯必同步兩檔 + 跑 check.sh）。

5. **golden 參考 + 自評 rubric**：指定一個「範本級」`trips/*/tripData.json` 做黃金標準；寫一張弱模型可以自我打分嘅 rubric（每項可 yes/no）。

6. **升級 `generate.py` 的 `validate()`**：把「盡量多」嘅判斷搬入生成器（爛數據根本 ship 唔到）：缺圖警告、activity 缺 mapQuery、events/dining 缺 link、budget 幣別一致性等。

## 4. 你自己工作嘅鐵律
- 每個產出旁邊留**一句「點解」**，令未來模型唔會誤刪你嘅規則。
- 用**最少改動**達到最大「抬高地板」效果。
- 最尾交**一頁總結**：`INSTITUTIONALIZED.md` —— 你institutionalize咗咩、每個檔點用、**仲餘低嘅最高風險缺口係邊個**（俾人類跟進）。

## 5. 成功準則（你走之後）
一個較弱 session **淨係照 CLAUDE.md 做事 + 收工前跑 `scripts/check.sh`**，就足以避開所有已知坑、產出達 golden 標準嘅路書 —— **唔再需要人類逐次把關**。
