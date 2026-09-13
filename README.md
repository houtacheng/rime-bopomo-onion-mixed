# 鼠鬚管洋蔥注音：中英混打與繁簡選字

這是一套 macOS 鼠鬚管（Squirrel）設定，以洋蔥純注音為基礎，加入本機英文候選與繁簡選字功能。

## 功能

- 洋蔥純注音，大千鍵盤配置。
- 中文輸入狀態中顯示本機英文候選。
- `Tab` 接受首選英文／候選。
- 預設輸出繁體中文。
- 候選右側顯示對應簡體提示。
- 選字時按 `Shift + →`，直接輸出目前候選的簡體版本。
- 所有轉換與個人詞頻學習都在本機完成。

## 安裝

1. 安裝支援 librime-lua 的鼠鬚管。
2. 將本儲存庫中的檔案複製到 `~/Library/Rime/`。
3. 從鼠鬚管選單執行「重新部署」。
4. 選擇「洋蔥純注音」方案。

請先備份自己原有的 Rime 設定。部署產生的 `build/`、使用者詞頻、同步資料和裝置識別資料不包含在本儲存庫中。

## 詞庫來源與授權

- `terra_pinyin_onion.dict.yaml` 以 Terra Pinyin、CC-CEDICT 等資料為基礎，檔案標示為 [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)。
- 洋蔥純注音方案及相關補充資料保留原檔作者與來源註記。
- `english_mixed.dict.yaml` 由 macOS `/usr/share/dict/web2` 本機產生。其系統 README 說明該詞表源自 Webster's Second International，原始著作權已失效。
- `rime.lua` 及本儲存庫新增的整合設定以 CC BY-SA 3.0 方式分享。

本專案不是晶晶輸入法，亦不包含其專有 AI 模型；中英混打由 Rime 本機詞庫實現。
