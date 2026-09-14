# 產生器

`english_mixed.dict.yaml`、`english_gloss.txt`、`lua/english_common.lua` 是從外部資料
產生出來的，三個檔案加起來超過 11 MB。它們照舊進版控——這個 repo 的前提是「複製檔案
就能用」，而且來源資料（`/usr/share/dict/web2`）只有 macOS 有，不能要求使用者自己產生。

但產生的方法不該只留在作者腦子裡，所以放在這裡。

| 腳本 | 產出 | 筆數 |
|---|---|---|
| `english_mixed.py` | `english_mixed.dict.yaml` | 235,974 |
| `english_common.py` | `lua/english_common.lua` | 5,000 |
| `english_gloss.py` | `english_gloss.txt` | 115,618 |

各自的規則寫在腳本開頭的說明裡，`--help` 也看得到。

## 取得來源資料

```bash
curl -sSLO https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/en/en_50k.txt
curl -sSL https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz -o cedict.txt.gz
```

`en_50k.txt` 約 600 KB（MIT），CC-CEDICT 約 4 MB 壓縮（CC BY-SA 4.0）。兩個都不進版控。

## 重新產生

在 repo 根目錄執行：

```bash
generate/english_mixed.py  --frequency en_50k.txt
generate/english_common.py --frequency en_50k.txt
generate/english_gloss.py  --cedict cedict.txt.gz
```

產生完記得重新部署，並且跑一次 `tests/run.sh`。

## 重現程度

以同一份 `en_50k.txt` 重跑，`english_mixed.dict.yaml` 與 `lua/english_common.lua`
與版控中的檔案 **byte 完全相同**。

`english_gloss.py` 是從現有檔案反推出來的（原始腳本沒留下），以今天的 CC-CEDICT 重跑
有 573 個詞不同，約 0.49%，都是多音字選了另一個讀音的釋義。要讓腳本與產物完全對齊，
用它重新產生一次即可。
