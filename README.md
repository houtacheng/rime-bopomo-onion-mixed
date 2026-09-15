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
- **按 `Shift`／`Control`／`Option`** 切換候選右側的提示：注音／漢語拼音／英文釋義。
  再按同一個鍵關閉，上屏或結束組字時自動清除
- 提示開著時按 **`→`** 就輸出目前預覽的內容
- 也可以直接：`Shift + →` 注音文、`Control + ←` 漢語拼音、`Control + →` 簡體
- `Control + ↑` 把**所打的鍵碼**原樣轉成注音符號（單獨打出 `ㄅ` 用這個）

**其他**
- 輸入「今天、明天、現在、時區」等詞顯示動態日期時間，含 `YYYY.MM.DD`、`YYYYMMDD` 等格式
  - 也有原詞與結果併排的形式：`明天（2026.09.15）`、`明天 2026.09.15(二)`、`明天 20260915`、
    `五分鐘後 04:30`
- **相對時間**：輸入「一小時後」「十分鐘前」「三個月後」「後天」「十天後」等詞直接算出結果。
  數量可用中文數字或阿拉伯數字（`二十五分鐘後`、`10分鐘後`），也接受「半小時後」「半個月後」
- 輸入公里、公分、度、公升、赫茲、美金、星座等名稱可選對應單位或符號（`度` → `°` `℃` `℉`，`美金` → `$` `US$` `USD`）
- 按著 `Control` 打上排數字鍵就輸出數字，組字中也可以（macOS 於放開 `Control` 時整串上屏）；
  `.` `,` `-` `/` `;` 可以一起打，`1.`、`2026/09/15`、`1,000`、`13:30` 一氣呵成（`;` 給的是 `:`）
- `Ctrl + \` 進入數字輸入，可取阿拉伯數字、中文數字、金融大寫、蘇州碼、羅馬數字、圈點數字
- 同一個入口也接受**算式**（`12+5*3`）與**單位換算**（`100cm` → `39.3701 in`、`98f` → `36.6667 ℃`、
  `10ping`、`5kg`），以及**匯率**（`100usd` → `3,177.54 TWD`）——匯率讀本機檔案並標示日期，輸入法不連外
- 算式與換算可以一起打。原單位的結果排最前面，之後每個目標單位都給帶算式與不帶算式兩種寫法：
  `100+20usd` → `100+20=120USD`、`120USD`、`100+20=120USD=166.79 CAD`、`166.79 CAD`

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

## Windows（小狼毫）

方案、詞庫、鍵位、Lua 功能在 Windows 上完全相同，只有外觀設定檔不同——
本 repo 同時放了 `squirrel.custom.yaml`（macOS）與 `weasel.custom.yaml`（Windows），
兩個前端各讀各的。安裝與對應關係見 **[docs/WINDOWS.md](docs/WINDOWS.md)**。

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
| `Shift` / `Control` / `Option` | 切換提示為注音／拼音／英文（再按一次關閉） |
| 提示開著時按 `→` | 輸出目前預覽的內容 |
| `Shift + →` | 輸出注音文 |
| `Control + ←` | 輸出漢語拼音 |
| `Control + →` | 輸出簡體 |
| `Control + ↑` | 輸出所打鍵碼的注音符號 |
| `Shift + 空白` | 中／英切換 |
| `Control` + 數字 | 輸出數字，組字中也可以（macOS 放開 `Control` 時整串上屏） |
| `Ctrl + \` | 數字輸入（可轉中文數字等） |

完整鍵位總表與各功能的詳細說明請見 **[docs/USAGE.md](docs/USAGE.md)**。

---

## 外觀編輯器

外觀（字型、配色、版面）可以用 **[鼠鬚管外觀編輯器](https://github.com/houtacheng/rime-appearance-editor)** 調整——
即時預覽、字型逐項用自己的字型渲染、套用後自動部署、快照隨時還原。

[下載 DMG](https://github.com/houtacheng/rime-appearance-editor/releases/latest)（universal，macOS 13+），或自己建置：

```bash
git clone https://github.com/houtacheng/rime-appearance-editor.git && cd rime-appearance-editor && ./app/build.sh --install
```

它是獨立專案，不限於本方案，任何鼠鬚管設定都能用。

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
| `squirrel.custom.yaml` | 外觀設定與配色（macOS） |
| `weasel.custom.yaml` | 外觀設定與配色（Windows） |
| `essay-zh-hant-mc.txt` | 詞頻語料 |
| `tests/` | 回歸測試，以假的 librime API 載入 `rime.lua`（`tests/run.sh`） |
| `generate/` | 生成檔的產生器（詞表、詞頻排名、中英釋義、匯率表） |
| `english_gloss.txt` | 中→英釋義表（CC-CEDICT 衍生） |

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
- `english_gloss.txt` 的中英釋義由 [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict) 產生，
  依 **[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)** 授權——與本儲存庫其餘內容的 3.0 不同，
  因為 CC BY-SA 4.0 的內容不可降版為 3.0。只取前三個義項並截短至 70 字元，依 UTF-8 位元組排序以供二分搜尋。
- `rime.lua` 及本儲存庫新增的整合設定以 CC BY-SA 3.0 方式分享。

詳細授權條文見 [LICENSE.md](LICENSE.md)。
