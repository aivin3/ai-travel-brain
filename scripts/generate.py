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

def warn(msg): print(f"⚠️  {msg}", file=sys.stderr)

def validate(d):
    missing = [k for k in REQUIRED if not d.get(k)]
    if missing:
        sys.exit(f"❌ tripData 缺少必要欄位: {', '.join(missing)}")
    if not d.get("days"):
        warn("無 days[]，路書只會有封面/預算等區塊。")
    # 輕量提醒：每日活動建議帶 mapQuery/address，旅行途中先有導航掣
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
    args = ap.parse_args()

    trip_path = Path(args.tripData).resolve()
    if not trip_path.exists():
        sys.exit(f"❌ 搵唔到 {trip_path}")
    out_path = Path(args.output).resolve() if args.output else trip_path.parent / "roadbook.html"

    data = build(trip_path, out_path)
    days = len(data.get("days", []))
    print(f"✅ 已生成路書：{out_path}")
    print(f"   {data.get('title')} · {days} 天" + (f" · {data['dateRange']}" if data.get('dateRange') else ""))
    print(f"   手機/電腦用瀏覽器開即睇，可離線、可分享。")

if __name__ == "__main__":
    main()
