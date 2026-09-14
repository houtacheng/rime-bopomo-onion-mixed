# Windows（小狼毫）安裝與移植

方案、詞庫、鍵位、Lua 功能在 Windows 上與 macOS **完全相同**，只有外觀設定檔不同。
本 repo 同時放了 `squirrel.custom.yaml`（macOS）與 `weasel.custom.yaml`（Windows），
兩個前端各讀各的，不會互相干擾。

---

## 安裝

1. 安裝 **[小狼毫 Weasel](https://github.com/rime/weasel/releases)**（0.14 以上）。
   官方安裝檔已內建 `librime-lua` 與 `librime-octagram`，本方案的 Lua 功能不需額外安裝。

2. 把本 repo 的檔案複製到 `%APPDATA%\Rime\`：

   ```powershell
   git clone https://github.com/houtacheng/rime-bopomo-onion-mixed.git
   Copy-Item -Recurse -Force .\rime-bopomo-onion-mixed\* "$env:APPDATA\Rime\"
   ```

   複製前先備份原有設定。`build/`、使用者詞頻、同步資料都不在 repo 中，不會被覆蓋。

3. 右鍵點工作列的小狼毫圖示 → **重新部署**，然後在方案選單選「洋蔥純注音」。

---

## 兩邊完全一致的部分

| 項目 | 說明 |
|---|---|
| 方案與詞庫 | `bopomo_onion.schema.yaml`、所有 `*.dict.yaml`、符號表 |
| 全部鍵位 | `default.custom.yaml` 與方案內的 `key_binder` 原封不動 |
| Lua 功能 | 中英混打、讀音輸出、日期數字、英文釋義 |
| 按住修飾鍵預覽 | 見下方說明，Windows 同樣可用 |

`rime.lua` 會用 `rime_api.get_user_data_dir()` 自動取得使用者資料目錄，
所以 `english_gloss.txt` 在 `%APPDATA%\Rime\` 下能正確找到，不需要改路徑。

---

## 按住修飾鍵預覽為什麼能一致

小狼毫的 `WeaselTSF/KeyEvent.cpp` 把修飾鍵翻譯成 rime 鍵碼：

```cpp
case VK_SHIFT:   return kinfo.scanCode == 0x36 ? ibus::Shift_R : ibus::Shift_L;
case VK_CONTROL: return kinfo.isExtended ? ibus::Control_R : ibus::Control_L;
case VK_MENU:    return ibus::Alt_L;
```

並在 `kinfo.isKeyUp` 時加上 `RELEASE_MASK`——**按下與放開都有事件**，與 macOS 的
Squirrel 在 `flagsChanged` 中的作法等價。而且兩邊都會把當下的修飾位一起帶上
（repr 是 `Shift+Shift_L` 而非 `Shift_L`），`rime.lua` 只比對裸鍵名，兩個平台通用。

注意 `VK_MENU` 一律回傳 `Alt_L`，不區分左右 Alt。`rime.lua` 的對照表兩者都列了，不受影響。

---

## 外觀設定的對應關係

Squirrel 與 Weasel 的 style 鍵名不同，`weasel.custom.yaml` 已經做好對應：

| Squirrel | Weasel |
|---|---|
| `candidate_list_layout: stacked` | `horizontal: false` |
| `text_orientation: horizontal` | `vertical_text: false` |
| `inline_preedit` | 同名同義 |
| `inline_candidate: true` | `preedit_type: preview` |
| `candidate_format: '[label]. …'` | `label_format: "%s."` |
| `corner_radius` | `layout/corner_radius` |
| `hilited_corner_radius` | `layout/round_corner` |
| `line_spacing` | `layout/candidate_spacing` |
| `spacing` | `layout/spacing` |
| `border_height` / `border_width` | `layout/border_width`（無負值概念） |

**配色可以 1:1 搬過去。** 兩個前端的色值格式相同（`0xBBGGRR` 與 `0xAABBGGRR`，
BGR 順序），`sunda` 用到的 8 個色鍵小狼毫全部支援。

**字型必須換。** 蘋方、蘋果儷中黑是 macOS 字型，Windows 沒有。預設改成微軟正黑體；
想更接近的話可自行安裝思源黑體，把 `font_face` 改成 `"Noto Sans TC"`。

---

## 實機驗證後確認的兩件事

這兩點是在 Windows 虛擬機上用按鍵記錄實測出來的，設計因此調整過：

**修飾鍵的放開事件會立刻抵達。** 小狼毫不管你按多久，按下與放開都在同一秒送達
（macOS 的鼠鬚管則是真的等到放手）。所以預覽改成「按一下切換」，不依賴放開事件。

**`Alt + 方向鍵` 到不了輸入法。** 記錄中 `Alt+Left`／`Alt+Right` 出現 0 次，
而同一份記錄裡 `Shift+Right`、`Control+Right` 都正常。Alt 的按住狀態在方向鍵抵達
前就被放開，Win 鍵更糟——`Win + →` 是系統的視窗貼齊快捷鍵，方向鍵的按下事件會被
作業系統整個吃掉。所以輸出一律走「按修飾鍵選模式、再按 `→`」。

如果你用 Parallels，還要留意它的鍵盤快速鍵設定檔會把 `⌥ + 方向鍵` 翻譯成
`Ctrl + 方向鍵`（macOS 的「跳一個單字」對應到 Windows 的等價操作）。
在 **偏好設定 → 快速鍵** 裡把那兩條取消勾選，⌥ 才會原樣傳進去。

## 排錯：看輸入法實際收到什麼按鍵

在 `%APPDATA%\Rime\tools\` 建立一個空檔案 `.debug-keys`，重新部署後
所有組合鍵的 `repr` 與各修飾位狀態都會記錄進去。刪掉檔案即停止。

這是查清上述兩個問題的關鍵工具——沒有它只能靠猜。

---

## 外觀編輯器

[鼠鬚管外觀編輯器](https://github.com/houtacheng/rime-appearance-editor) 目前是 macOS 專屬
（Swift + AppKit）。其後端 `server.py` 只用 Python 標準函式庫，理論上可移植，
但需要改寫設定檔路徑與部署指令（`WeaselDeployer.exe /deploy`）。Windows 上請直接編輯
`weasel.custom.yaml`。
