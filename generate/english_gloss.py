#!/usr/bin/env python3
"""產生 english_gloss.txt：給 rime.lua 查中文候選英文釋義用的表。

  generate/english_gloss.py --cedict cedict_ts.u8

rime.lua 按 Option 時查這個檔。11 萬筆做成 Lua table 會吃掉十幾 MB 記憶體，
所以改成對檔案做二分搜尋——**依 UTF-8 位元組排序是查詢的前提，不要手動重排**。

每個詞最多取三個義項，以「; 」相接；超過 LIMIT 字元就從後面往回丟義項，
但至少保留第一個，所以偶爾會有很長的單一義項（十三經那種列舉整串典籍的）。

同一個繁體詞在 CC-CEDICT 裡可能有多個讀音各自一條（行 有 hang2/heng2/xing2 三條），
一個詞只留一行：取釋義最長的那條，長度相同就取先出現的。挑最長是因為多音字裡
資訊量最大的那個讀音通常就是最想看到的，而「第一條」往往是姓氏或冷僻讀音。

這些規則是從現有的 english_gloss.txt 反推出來的（原始腳本沒有留下），比對過幾種
可能的取捨方式後選了最貼合的一組。以今天的 CC-CEDICT 重跑，與版控中的檔案有
573 個詞不同，約佔 0.49%——多音字選了另一個讀音的釋義。要讓兩者完全一致，
就用這支腳本重新產生一次 english_gloss.txt。

詞典檔（約 4 MB 壓縮，CC BY-SA 4.0）：
  curl -sSLO https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz
  gunzip cedict_1_0_ts_utf-8_mdbg.txt.gz
"""

import argparse
import gzip
import re

LIMIT = 70          # 釋義字元數上限，超過就往回丟義項
MAX_SENSES = 3
SEPARATOR = "; "

HEADER = """# CC-CEDICT 衍生的中→英釋義表，供 rime.lua 二分搜尋使用。
# 來源：https://www.mdbg.net/chinese/dictionary?page=cc-cedict （CC BY-SA 4.0）
# 格式：繁體詞<TAB>釋義（最多三個義項，以分號分隔）。依 UTF-8 位元組排序，勿手動重排。
"""

ENTRY = re.compile(r"^(\S+) (\S+) \[[^\]]*\] /(.*)/\s*$")

# CC-CEDICT 的交叉參照與量詞標記：對「這個詞的英文是什麼」沒有幫助，
# 而且參照目標寫成「逼格[bi1 ge2]」這種帶拼音的形式，跟著上屏很難看。
# 整條都只有這種義項的詞（B格、K金）就整筆不收。
CROSS_REFERENCE = re.compile(r"^(CL:|see |see also |variant of |old variant of |erhua variant)")


def gloss_of(senses):
    chosen = [s for s in senses if not CROSS_REFERENCE.match(s)][:MAX_SENSES]
    while len(chosen) > 1 and len(SEPARATOR.join(chosen)) > LIMIT:
        chosen.pop()
    return SEPARATOR.join(chosen)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--cedict", default="cedict_ts.u8", help="CC-CEDICT 檔案（可直接吃 .gz）")
    parser.add_argument("--out", default="english_gloss.txt", help="輸出檔案")
    args = parser.parse_args()

    opener = gzip.open if args.cedict.endswith(".gz") else open
    entries = {}
    with opener(args.cedict, "rt", encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#"):
                continue
            matched = ENTRY.match(line)
            if not matched:
                continue
            traditional, senses = matched.group(1), matched.group(3).split("/")
            # 純 ASCII 的條目（110、3C）打不出中文候選，查不到也用不上
            if traditional.isascii():
                continue
            text = gloss_of(senses)
            current = entries.get(traditional)
            if text and (current is None or len(text) > len(current)):
                entries[traditional] = text

    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write(HEADER)
        for word in sorted(entries, key=lambda w: w.encode("utf-8")):
            handle.write("%s\t%s\n" % (word, entries[word]))
    print("%s：%d 筆" % (args.out, len(entries)))


if __name__ == "__main__":
    main()
