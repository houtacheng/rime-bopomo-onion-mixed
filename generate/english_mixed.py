#!/usr/bin/env python3
"""產生 english_mixed.dict.yaml：本機英文詞表，權重取自 OpenSubtitles 詞頻。

  generate/english_mixed.py --frequency en_50k.txt

詞表來自 macOS 的 /usr/share/dict/web2，只留純 ASCII 字母的條目（web2 裡只有
Jean-Christophe、Jean-Pierre 兩筆含連字號會被濾掉），順序照 web2 原樣，不重排——
rime 建表時會依 sort: by_weight 自行處理。

權重的用意是「常用詞恆在冷僻詞之前，且任何詞都勝過它自己的補全」：
補全必定比原詞長，而冷僻詞的權重隨詞長遞減，所以後者自然成立。

  前 5 萬名（en_50k.txt 收的就是這 5 萬）：詞頻取自然對數後線性映射到 1000–99000，
                                          上限低於 english_tech 的 100000
  其餘冷僻詞：                            64 - 詞長，下限 36（web2 最長的詞是 28 字母，
                                          剛好落在 36）
  大寫變體：                              再減 1，讓小寫排在前面

詞頻檔案（622 KB，MIT 授權）：
  curl -sSLO https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/en/en_50k.txt
"""

import argparse
import math
import sys
import time

HEADER = """# Rime dictionary
# encoding: utf-8
# Generated from the local macOS word list ({words}).
# 權重來源：hermitdave/FrequencyWords（OpenSubtitles 2018 英文詞頻，MIT 授權）。
# 前 5 萬名常用詞依詞頻取對數後映射到 1000–99000（低於 english_tech 的 100000）；
# 其餘冷僻詞以 64 - 詞長 給 36–63，確保常用詞恆在冷僻詞之前，
# 且任何詞都勝過它自己的補全（補全必定更長）。大寫變體減 1 以讓小寫優先。
---
name: english_mixed
version: "{version}"
sort: by_weight
use_preset_vocabulary: false
import_tables:
  - english_tech
columns:
  - text
  - code
  - weight
...
"""

COMMON_LOW, COMMON_HIGH = 1000, 99000
RARE_BASE, RARE_FLOOR = 64, 36


def read_frequency(path):
    """en_50k.txt 的格式是「詞 出現次數」，依次數遞減排序。"""
    counts = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            word, _, count = line.partition(" ")
            count = count.strip()
            if count:
                counts[word] = int(count)
    if not counts:
        sys.exit("詞頻檔案是空的：" + path)
    return counts


def read_words(path):
    with open(path, encoding="utf-8") as handle:
        return [line.rstrip("\n") for line in handle]


def weight_of(word, code, counts, low_log, span):
    count = counts.get(code)
    if count is not None:
        weight = round(COMMON_LOW + (COMMON_HIGH - COMMON_LOW) * (math.log(count) - low_log) / span)
        if word != code:
            weight -= 1
        return weight
    weight = RARE_BASE - len(word)
    if word != code:
        weight -= 1
    return max(weight, RARE_FLOOR)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--words", default="/usr/share/dict/web2", help="詞表（預設 macOS 的 web2）")
    parser.add_argument("--frequency", default="en_50k.txt", help="FrequencyWords 的 en_50k.txt")
    parser.add_argument("--out", default="english_mixed.dict.yaml", help="輸出檔案")
    parser.add_argument("--version", default=time.strftime("%Y%m%d"), help="寫進檔頭的版本字串")
    args = parser.parse_args()

    counts = read_frequency(args.frequency)
    low_log = math.log(min(counts.values()))
    span = math.log(max(counts.values())) - low_log

    lines = []
    for word in read_words(args.words):
        # 編碼只認 a-z，所以含連字號、撇號或重音字母的條目打不出來，直接跳過
        if not (word.isascii() and word.isalpha()):
            continue
        code = word.lower()
        lines.append("%s\t%s\t%d\n" % (word, code, weight_of(word, code, counts, low_log, span)))

    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write(HEADER.format(words=args.words, version=args.version))
        handle.writelines(lines)
    print("%s：%d 筆" % (args.out, len(lines)))


if __name__ == "__main__":
    main()
