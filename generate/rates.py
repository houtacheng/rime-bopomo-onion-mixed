#!/usr/bin/env python3
"""產生 lua/rates.lua：給 rime.lua 做貨幣換算用的匯率表。

  generate/rates.py

輸入法本身**不連外**——它只讀產生出來的檔案。要更新匯率就手動跑這支腳本，
候選旁邊會標出檔案裡的日期，所以不會悄悄給出過期的數字。

資料來源是 open.er-api.com（免費、不需金鑰、含新台幣）。想換來源就改 SOURCE，
只要最後寫出同樣格式的 lua 檔即可。
"""

import argparse
import json
import sys
import urllib.request

SOURCE = "https://open.er-api.com/v6/latest/USD"
KEEP = ["TWD", "USD", "CAD", "JPY", "EUR", "CNY", "GBP", "HKD", "KRW", "AUD",
        "SGD", "THB", "MYR", "PHP", "VND", "INR", "CHF", "NZD", "RUB", "BRL"]


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", default=SOURCE, help="匯率 API")
    parser.add_argument("--out", default="lua/rates.lua", help="輸出檔案")
    args = parser.parse_args()

    with urllib.request.urlopen(args.source, timeout=30) as response:
        payload = json.load(response)

    rates = payload.get("rates") or payload.get("conversion_rates")
    if not rates:
        sys.exit("回應裡沒有匯率：" + args.source)
    base = payload.get("base_code") or payload.get("base") or "USD"
    date = (payload.get("time_last_update_utc") or "")[5:16].strip() or payload.get("date", "")

    kept = [(code, rates[code]) for code in KEEP if code in rates]
    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write("-- 匯率表，由 generate/rates.py 從 %s 產生。\n" % args.source)
        handle.write("-- 輸入法只讀這個檔案，不會自己連外；要更新就重跑那支腳本。\n")
        handle.write("return {\n  date = %s,\n  base = %s,\n  rates = {\n"
                     % (json.dumps(date), json.dumps(base)))
        for code, value in kept:
            handle.write("    %s = %s,\n" % (code, repr(float(value))))
        handle.write("  },\n}\n")
    print("%s：%d 種貨幣，日期 %s" % (args.out, len(kept), date))


if __name__ == "__main__":
    main()
