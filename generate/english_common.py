#!/usr/bin/env python3
"""產生 lua/english_common.lua：常用英文詞的詞頻排名表。

  generate/english_common.py --frequency en_50k.txt

rime.lua 的 chinese_first 用它判斷「這串輸入像不像一個常用英文單字」，
像的話就讓英文排到注音前面。只需要排名、不需要次數，所以這裡只取前 LIMIT 名。

同一份 en_50k.txt 也是 english_mixed.py 的權重來源：
  curl -sSLO https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/en/en_50k.txt
"""

import argparse

LIMIT = 5000   # 門檻 ENGLISH_LEAD_RANK_LIMIT 預設 2000，留一倍餘裕方便調寬

HEADER = """-- 由 hermitdave/FrequencyWords（OpenSubtitles 2018, MIT）產生：常用英文詞的詞頻排名。
-- chinese_first 用它判斷輸入是否像一個常用英文單字。格式：{ 詞 = 排名 }
return {
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--frequency", default="en_50k.txt", help="FrequencyWords 的 en_50k.txt")
    parser.add_argument("--out", default="lua/english_common.lua", help="輸出檔案")
    parser.add_argument("--limit", type=int, default=LIMIT, help="收到第幾名為止")
    args = parser.parse_args()

    entries = []
    with open(args.frequency, encoding="utf-8") as handle:
        for line in handle:
            word = line.partition(" ")[0].strip()
            # 詞頻表收了 's、't 這類撇號碎片，排除它們排名才連續。
            # 判斷用 isalpha 而不是 a-z：yöu 這種帶變音符號的詞因此留在表內，
            # 反正編碼只認 a-z，它永遠比不到，只是佔一個名額。
            if word.isalpha():
                entries.append(word)
            if len(entries) >= args.limit:
                break

    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write(HEADER)
        for rank, word in enumerate(entries, 1):
            handle.write('["%s"]=%d,\n' % (word, rank))
        handle.write("}\n")
    print("%s：%d 筆" % (args.out, len(entries)))


if __name__ == "__main__":
    main()
