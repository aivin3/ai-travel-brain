# 🧳 AI Travel Brain

香港出發、國際旅行用的 AI 旅遊大腦。Claude 幫你做 **research → 規劃 → 出手機路書**：
出發前規劃、旅行途中手機查、同家人分享，一份自包含 HTML 搞掂。

> **新 AI 接手請先讀 [`BLUEPRINT.md`](BLUEPRINT.md)**（完整上下文備份）。

---

## 點用

- **由零計劃**：同 Claude 講「幫我計劃 8 月福岡 7 日親子遊」→ 跑 `skill.md` workflow → 出路書。
- **已有行程**：貼低行程表 → 解析後出路書。
- **自己手砌**：改 `trips/<slug>/tripData.json` → `python3 scripts/generate.py trips/<slug>/tripData.json` → 開 `roadbook.html`。

## 路書功能（手機優先・自包含・離線可用）

- 🗺️ **每日速覽表** + 黏住每日 tab + 回頂掣（goTop）
- 📸 每景點打卡圖（真實圖／無圖用漸層示意卡）+ ✅必做 + ✨發光徽章（必去/限定）
- 📍 **開地圖** + 🧭 **一鍵路線導航**（到下一站）+ 🗺️ **今日路線地圖**（串當日所有點）
- 🍴 **餐廳指南**（分類・介紹・Menu・📷Google 相片）
- 🎉 **期間限定活動**（獨立 tab）
- 🧮 **計錢分攤**：成員 + 💰公數錢包 + 日期時間 + 分類 + 最少轉帳 + ¥/HK\$ 切換 + 預算 + **Firebase 多人實時共用**（共用版）
- 🎫 **訂單收納**（機票/酒店/門票確認號 + 今日要用）
- 📱 **分享 QR** + 🖨 **一鍵 PDF**
- 🏨 住宿（Airbnb 揀區）· 💰 預算三檔 · 🧭 實用速查

## 兩套視覺模板（由 tripData `template` 揀）

- `templates/roadbook.html` — 夢幻馬卡龍 pastel（流動彩虹背景 + 玻璃卡）
- `templates/roadbook_jp.html` — 和風高對比（米紙紋 + 藍染封面 + 日の丸 + 紅 torii logo + pop 硬陰影）

## 檔案結構

```
AI Travel Brain/
├── BLUEPRINT.md            # ★ 完整上下文備份（新 AI 必讀）
├── CLAUDE.md               # 最高指令 + workflow
├── skill.md                # /travel 7 步 workflow
├── README.md               # 本檔
├── firebase.config.json    # Firebase RTDB config（公開值）
├── .env.example
├── scripts/generate.py     # tripData.json → roadbook.html（零依賴）
├── templates/{roadbook.html, roadbook_jp.html}
├── schema/tripData.schema.json
├── trips/{kaohsiung-2026-08, fukuoka-2026-08}/{tripData.json, roadbook.html}
└── deploy*/                # 4 個 GitHub Pages repo 的部署輸出 + img/
```

## Live links

| Trip | 離線版 | 共用版（Firebase 實時分帳） |
|---|---|---|
| 🇹🇼 高雄 7 日 | https://aivin3.github.io/kaohsiung-trip-2026/ | https://aivin3.github.io/kaohsiung-trip-sync/ |
| 🗾 福岡（和風） | https://aivin3.github.io/fukuoka-trip-2026/ | https://aivin3.github.io/fukuoka-trip-sync/ |

## 要求

- Python 3（只用標準庫，**唔使 pip install**）
- 一個瀏覽器
- （可選）node 用嚟 `node --check` 驗 JS

## 小貼士

- 改行程：改 `tripData.json` 重跑 generate.py，**唔好手改 HTML**。
- 改 render 邏輯/工具：**兩個模板一齊改**（grep 同字串 replace）。
- 圖片：只用驗證過嘅真 URL（Wikimedia REST + curl 驗 200）或 self-host `deploy*/img/`。
- iOS：**唔好用 `background-attachment:fixed`**（會橫向溢位）。
