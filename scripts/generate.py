#!/usr/bin/env python3
"""
AI Travel Brain — Roadbook Generator
讀 tripData.json → 注入手機優先 HTML 模板 → 出自包含單檔 roadbook.html（可離線、可分享）。

用法:
  python3 scripts/generate.py trips/tokyo-example/tripData.json
  python3 scripts/generate.py trips/tokyo-example/tripData.json -o trips/tokyo-example/roadbook.html

零外部 dependency（只用標準庫）。
"""
import argparse, json, sys, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "templates" / "roadbook.html"

REQUIRED = ["title"]
# 已知會失效/唔准 hotlink 嘅圖源（踩過坑：encrypted-tbn 縮圖會死 → 必須自 host）
BANNED_IMG = ("gstatic.com", "encrypted-tbn")

def warn(msg): print(f"⚠️  {msg}", file=sys.stderr)

def _walk_images(o, path="$"):
    """遍歷成個 tripData，搵晒所有 imageUrl/heroImage → [(json路徑, url)]"""
    out = []
    if isinstance(o, dict):
        for k, v in o.items():
            if k in ("imageUrl", "heroImage") and isinstance(v, str) and v.strip():
                out.append((f"{path}.{k}", v.strip()))
            else:
                out.extend(_walk_images(v, f"{path}.{k}"))
    elif isinstance(o, list):
        for i, x in enumerate(o):
            out.extend(_walk_images(x, f"{path}[{i}]"))
    return out

def validate(d, strict=False):
    """爛數據唔准 ship：errors 一定 exit 1；warnings 提醒（--strict 時都當 error）。
    點解喺生成器度做：呢度係所有路書必經之路，係唯一冇得繞過嘅位。"""
    errors, warns = [], []

    missing = [k for k in REQUIRED if not d.get(k)]
    if missing:
        errors.append(f"tripData 缺少必要欄位: {', '.join(missing)}")

    # 模板名必須真實存在 —— 靜默 fallback 會令揀錯模板出錯設計都出到街
    tpl_name = d.get("template", "roadbook.html")
    if not (ROOT / "templates" / tpl_name).exists():
        errors.append(f"template '{tpl_name}' 喺 templates/ 搵唔到（打錯字？）")

    # 圖片 URL 鐵律（反幻覺）：必須 https；禁 gstatic/encrypted-tbn（會死鏈）
    for path, url in _walk_images(d):
        if not url.startswith("https://"):
            errors.append(f"{path} 唔係 https URL: {url[:80]}（唔肯定就留空，唔好作）")
        if any(b in url for b in BANNED_IMG):
            errors.append(f"{path} 用咗 gstatic/encrypted-tbn 縮圖（會失效）→ download 落 deploy*/img/ 自 host: {url[:80]}")

    if not d.get("days"):
        warns.append("無 days[]，路書只會有封面/預算等區塊。")
    if d.get("highlights") and not d.get("overview"):
        warns.append("用緊舊欄 highlights；新 trip 建議改用 overview（每日速覽表）。")

    for i, day in enumerate(d.get("days", []), 1):
        for a in day.get("activities", []):
            if a.get("meal"):
                continue
            nm = a.get("name", "(無名)")
            if not (a.get("mapQuery") or a.get("address")):
                warns.append(f"D{i}「{nm}」冇 mapQuery/address → 現場冇「📍開地圖」掣。")
            if not (a.get("imageUrl") or a.get("icon")):
                warns.append(f"D{i}「{nm}」冇 imageUrl 又冇 icon → 卡面會空白。")

    for i, ev in enumerate(d.get("events", []), 1):
        if not (ev.get("link") or ev.get("mapQuery")):
            warns.append(f"events[{i}]「{ev.get('name','?')}」冇 link 又冇 mapQuery → 臨近冇得驗證/導航。")
        if not ev.get("date"):
            warns.append(f"events[{i}]「{ev.get('name','?')}」冇 date → 唔知邊日去。")

    for g in d.get("dining", []):
        for it in g.get("items", []):
            if not it.get("mapQuery"):
                warns.append(f"dining「{it.get('name','?')}」冇 mapQuery → 現場搵唔到店。")

    # 預算慣例（由高雄/福岡兩個上線 trip 歸納）：每個銀碼欄必須有 HK$ 等值
    # —— 用戶心算單位係 HK$；本地價可以並列（例 "≈ ¥520,000（約 HK$25,370）"）
    bud = d.get("budget")
    if bud:
        money_fields = [("tiers[].total", t.get("total", "")) for t in bud.get("tiers", [])]
        for k in ("transport", "accommodation", "food", "tickets", "other"):
            if isinstance(bud.get(k), dict):
                money_fields.append((f"{k}.subtotal", bud[k].get("subtotal", "")))
        money_fields += [("total", bud.get("total", "")), ("perPerson", bud.get("perPerson", ""))]
        for k, v in money_fields:
            if v and "HK$" not in str(v):
                warns.append(f"budget.{k}「{str(v)[:40]}」冇 HK$ 等值 —— 慣例係本地價+（約 HK$X）並列。")

    for w in warns:
        warn(w)
    if errors or (strict and warns):
        for e in errors:
            print(f"❌ {e}", file=sys.stderr)
        if strict and warns:
            print(f"❌ --strict 模式：上面 {len(warns)} 個警告當 error", file=sys.stderr)
        sys.exit("❌ validate 唔過，未生成。（規則點解存在 → docs/GUARDRAILS.md）")

def build(trip_path: Path, out_path: Path, strict=False):
    data = json.loads(trip_path.read_text(encoding="utf-8"))
    validate(data, strict=strict)
    data.setdefault("generationDate", datetime.date.today().isoformat())

    # 模板存在性已喺 validate() 把關（唔准靜默 fallback）
    tpl_path = ROOT / "templates" / data.get("template", "roadbook.html")
    tpl = tpl_path.read_text(encoding="utf-8")
    payload = json.dumps(data, ensure_ascii=False, indent=2)
    # 防止 </script> 在 JSON 字串內提早關閉 script 標籤
    payload = payload.replace("</", "<\\/")
    html = tpl.replace("__TITLE__", data.get("title", "旅程路書")) \
              .replace("__TRIP_DATA__", payload)

    # Firebase 實時同步（可選）：tripData 有 "firebase" config 先注入 SDK + config，否則純離線
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
    ap.add_argument("--strict", action="store_true", help="警告都當 error（新 trip 收工前用）")
    args = ap.parse_args()

    trip_path = Path(args.tripData).resolve()
    if not trip_path.exists():
        sys.exit(f"❌ 搵唔到 {trip_path}")
    out_path = Path(args.output).resolve() if args.output else trip_path.parent / "roadbook.html"

    data = build(trip_path, out_path, strict=args.strict)
    days = len(data.get("days", []))
    print(f"✅ 已生成路書：{out_path}")
    print(f"   {data.get('title')} · {days} 天" + (f" · {data['dateRange']}" if data.get('dateRange') else ""))
    print(f"   手機/電腦用瀏覽器開即睇，可離線、可分享。")

if __name__ == "__main__":
    main()
