# 鼠鬚管外觀編輯器

本機 GUI，用來調整 `squirrel.custom.yaml` 的外觀設定。

```bash
python3 ~/Library/Rime/tools/rime-appearance/server.py
```

會自動開啟瀏覽器。按 `Control + C` 結束。

## 功能

- **讀取目前外觀** —— 啟動時直接從 `squirrel.custom.yaml` 讀取現值
- **字型** —— 列出本機 1500+ 個字型，顯示**可讀名稱**（標楷體、蘋方-繁 細體），
  清單中每個項目都用它自己的字型渲染；中文名、英文名、PostScript 名稱都能搜
- **配色** —— 列出 `squirrel.custom.yaml` 與鼠鬚管內建的所有配色。可以載入任一個配色修改，
  再選擇**覆蓋原配色**或**另存新檔**；每個顏色都能單獨調透明度，編輯時預覽即時反映草稿
- **即時預覽** —— 右側模擬候選窗，顏色、字型、圓角、間距、透明度都會跟著變
- **套用並部署** —— 寫回設定檔後自動部署，並**確認真的生效**
- **快照還原** —— 每次套用前自動建立快照，隨時可以退回

## 實作備註

**色值是 BGR 不是 RGB。** Rime 的 `0xBBGGRR` 與 `0xAABBGGRR` 都是反過來的，
新增配色時要換算，別直接把 CSS 的 `#RRGGBB` 填進去。

**透明度用八位色值。** 鼠鬚管的 `SquirrelConfig.swift` 有兩條解析規則：八位是
`0xAABBGGRR`、六位是 `0xBBGGRR`（alpha 視為 255）。本工具在不透明時寫六位、
有透明度時才寫八位，保持檔案好讀。這與 `style/alpha` 不同——後者是整個候選窗的
不透明度，前者可以讓個別顏色（例如只有背景）半透明。

**字型有兩個名稱，別搞混。** `system_profiler` 回傳的 `_name` 是 PostScript 名稱
（`DFKaiShu-SB-Estd-BF`），`fullname`／`family` 才是可讀名稱（`標楷體`）。
介面顯示可讀名稱，但寫進 `font_face` 的必須是 PostScript 名稱。

**內建配色不能真的覆蓋。** 它們在 `Squirrel.app` 內部，唯讀。按「覆蓋原配色」時，
本工具改為在 `squirrel.custom.yaml` 建立同名區塊——Rime 的合併順序會讓它蓋過內建版，
效果相同，而且刪掉就能還原。既有的自訂配色則是就地改寫色值，其他設定與註解保留。

**`color_scheme:` 要填區塊名稱，不是顯示名稱。** 例如 `preset_color_schemes/mac_lamb`
區塊裡寫著 `name: "lamb"`，但設定要填的是 `mac_lamb`。

**部署結果要驗證。** 鼠鬚管的 `--reload` 只是送一個 DistributedNotification，
送完就結束、不回報成敗，執行中的程序有時會忽略它。所以套用後會去比對
`build/squirrel.yaml` 的 mtime 有沒有變，沒變就明白告訴你要從選單手動部署。

**寫回是逐行就地改值**，不是整份 YAML 重新輸出——`squirrel.custom.yaml`
有四百多行註解與二十幾個配色區塊，用 YAML 函式庫往返會把它們全部弄丟。

## 執行期資料

`snapshots/` 與 `.fonts.json` 是本機資料，已排除在版本控制之外。
字型清單掃描一次約 15 秒，之後讀快取；裝了新字型就按「重新掃描系統字型」。
