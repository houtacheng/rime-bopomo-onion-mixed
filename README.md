# 鼠鬚管洋蔥注音：中英混打與繁簡選字

macOS 鼠鬚管（Squirrel）設定，以**洋蔥純注音**為基礎，加上本機英文候選、繁簡選字，以及讀音輸出等功能。所有轉換與詞頻學習都在本機完成，不連外。

完整操作說明請見 **[docs/USAGE.md](docs/USAGE.md)**。

---

## 這是什麼

一套可以直接放進 `~/Library/Rime/` 的設定檔集合：注音方案、英文詞庫、Lua 擴充與外觀設定。核心特色是**中英混打不需切換模式**——打下的字母同時被當作英文與注音兩種可能處理，由你的下一個按鍵決定要哪一種。

## 這不是什麼

不是晶晶輸入法（ZingIME），也不包含任何專有 AI 模型。中英混打由 Rime 的本機詞庫與排序規則實現，英文候選的排序依據是離線詞頻表，不是模型推論。

---

## 功能

**注音輸入**
- 洋蔥純注音，大千鍵盤配置
- 支援簡拼（每個音節可只打第一個字母）與聲韻母亂序輸入
- 預設輸出繁體中文，候選右側顯示對應簡體提示

**中英混打**
- 中文輸入狀態下同時顯示本機英文候選，不必切換模式
- 一般情況注音候選排第一位，`Tab` 接受第一個英文候選
- 輸入本身就是常用英文單字時（四個字母以上、詞頻前 2000 名，如 `home`、`time`），英文自動排第一位
- 英文候選依真實詞頻排序，完全相符的詞必定排在它自己的補全之前
- 內建常見科技公司、軟體、平台與開發工具的正確英文名稱

**讀音與字形輸出**
- **按住 `Shift`**，候選右側的提示即時變成該候選的注音；放開恢復簡體提示。按 `Shift + →` 輸出
- **按住 `Control`**，提示變成漢語拼音。按 `Control + →` 輸出
- `Option + →` 輸出**簡體**
- `Option + ↑` 把**所打的鍵碼**原樣轉成注音符號（單獨打出 `ㄅ` 用這個）

**其他**
- 輸入「今天、明天、現在、時區」等詞顯示動態日期時間，含 `YYYY.MM.DD`、`YYYYMMDD` 等格式
- 輸入公里、公分、星座等名稱可選對應單位或符號
- `Ctrl + \` 進入數字輸入，可取阿拉伯數字、中文數字、金融大寫、蘇州碼、羅馬數字、圈點數字

---

## 安裝

1. 安裝 macOS 鼠鬚管（Squirrel）。**建議 1.1.2 或更新版本**——舊版 0.18 不支援本設定使用的部分外觀選項。

   ```bash
   brew install --cask squirrel
   ```

2. 備份你原有的 Rime 設定。

   ```bash
   tar -czf ~/Rime-backup.tar.gz -C ~/Library/Rime .
   ```

3. 把本儲存庫的檔案複製到 `~/Library/Rime/`。

4. 從鼠鬚管選單執行「重新部署」，然後選擇「洋蔥純注音」方案。

部署產生的 `build/`、個人詞頻（`*.userdb/`）、同步資料與裝置識別資料都不在本儲存庫中，複製檔案不會覆蓋你的學習紀錄。

---

## 常用鍵位速查

| 按鍵 | 作用 |
|---|---|
| `Shift` + `Q A Z W S X` | 選第 1–6 候選（左手） |
| `Shift` + `Y H N U J M` | 選第 1–6 候選（右手） |
| 空白鍵 | 上屏第一候選 |
| `Tab` | 接受第一個英文候選 |
| `↑` | 左移一個注音；已用 `↓` 移動過候選時改為上一個候選 |
| `↓` | 下一個候選 |
| `←` / `→` | 上一頁 / 下一頁 |
| `Shift + ←` | 左移一個注音 |
| 按住 `Shift` | 提示顯示注音，`Shift + →` 輸出 |
| 按住 `Control` | 提示顯示漢語拼音，`Control + →` 輸出 |
| `Option + →` | 輸出簡體 |
| `Option + ↑` | 輸出所打鍵碼的注音符號 |
| `Shift + 空白` | 中／英切換 |
| `Control` + 數字 | 直接輸出該數字（未在打字時） |
| `Ctrl + \` | 數字輸入（可轉中文數字等） |

完整鍵位總表與各功能的詳細說明請見 **[docs/USAGE.md](docs/USAGE.md)**。

---

## 外觀編輯器

附一個本機 GUI，可以調字型與配色、即時預覽、套用後自動部署，並保留快照隨時退回：

```bash
python3 ~/Library/Rime/tools/rime-appearance/server.py
```

字型清單會列出本機所有字型，**每個項目都用它自己的字型渲染**，選之前就看得到長相。
詳見 [tools/rime-appearance/README.md](tools/rime-appearance/README.md)。

## 檔案結構

| 檔案 | 用途 |
|---|---|
| `bopomo_onion.schema.yaml` | 主方案：拼寫規則、鍵位綁定、元件組態 |
| `bopomo_onion.extended.dict.yaml` | 主詞庫（匯入下列三個來源） |
| `terra_pinyin_onion.dict.yaml`<br>`terra_pinyin_onion_add.dict.yaml` | 中文字詞，以拼音標註 |
| `mixin_bpmf.dict.yaml` | 內嵌注音文碼表 |
| `bopomo_onion_symbols.yaml` | 符號、單位與 emoji |
| `english_mixed.schema.yaml`<br>`english_mixed.dict.yaml`<br>`english_tech.dict.yaml` | 英文候選方案與詞庫 |
| `rime.lua` | 所有 Lua 擴充：候選排序、讀音輸出、日期數字轉換 |
| `lua/english_common.lua` | 常用英文詞的詞頻排名表 |
| `default.custom.yaml` | 全域鍵位與方案清單 |
| `squirrel.custom.yaml` | 外觀設定與配色 |
| `essay-zh-hant-mc.txt` | 詞頻語料 |
| `tools/rime-appearance/` | 外觀編輯器（本機 GUI） |

---

## 自訂

常用的可調參數集中在 [`rime.lua`](rime.lua) 檔案開頭附近：

| 參數 | 預設 | 作用 |
|---|---|---|
| `ENGLISH_LEAD_MIN_LENGTH` | `4` | 輸入至少這麼長才可能讓英文排第一 |
| `ENGLISH_LEAD_RANK_LIMIT` | `2000` | 詞頻排名門檻；設 `0` 即關閉，注音永遠第一 |
| `BOPOMOFO_SEPARATOR` | `""` | 注音輸出的音節分隔符，可設為 `" "` |
| `PINYIN_SEPARATOR` | `" "` | 拼音輸出的音節分隔符 |
| `LATIN_BUFFER_LIMIT` | `60` | 候選排序時最多緩衝幾個英文候選 |

外觀在 [`squirrel.custom.yaml`](squirrel.custom.yaml)，已按配色／版面／字型／幾何／視覺效果分組。

---

## 詞庫來源與授權

- `terra_pinyin_onion.dict.yaml` 以 Terra Pinyin、CC-CEDICT 等資料為基礎，檔案標示為 [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)。
- 洋蔥純注音方案及相關補充資料保留原檔作者與來源註記。
- `english_mixed.dict.yaml` 的詞表由 macOS `/usr/share/dict/web2` 本機產生。其系統 README 說明該詞表源自 Webster's Second International，原始著作權已失效。
- `english_mixed.dict.yaml` 的權重與 `lua/english_common.lua` 的詞頻排名取自 [hermitdave/FrequencyWords](https://github.com/hermitdave/FrequencyWords)（OpenSubtitles 2018 英文詞頻，MIT 授權）。前 5 萬名常用詞依詞頻對數映射到 1000–99000，其餘冷僻詞以 `64 - 詞長` 給 36–63。
- `rime.lua` 及本儲存庫新增的整合設定以 CC BY-SA 3.0 方式分享。

詳細授權條文見 [LICENSE.md](LICENSE.md)。
