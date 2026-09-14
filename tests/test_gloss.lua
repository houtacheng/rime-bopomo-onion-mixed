-- 中→英釋義表：english_gloss.txt 與 rime.lua 的二分搜尋。
-- 這支測試守的是排序不變量——檔案依 UTF-8 位元組排序是查詢的前提，
-- 手動重排或用別的方式重新產生都會讓查詢靜悄悄地失準，不會報錯。
local H = dofile((arg[0]:match("^(.*)/[^/]*$") or ".") .. "/harness.lua")
H.install(H.root)   -- 釋義表在 repo 根目錄，不在 tests/

local PATH = H.root .. "/english_gloss.txt"

-- 排序：用的是 Lua 的字串比較，跟 gloss_of 裡二分搜尋判斷方向時同一個運算子
local previous, rows, unsorted = nil, 0, 0
for line in io.lines(PATH) do
  if not line:match("^#") then
    local key = line:match("^([^\t]+)")
    if key then
      rows = rows + 1
      if previous and key < previous then unsorted = unsorted + 1 end
      previous = key
    end
  end
end
H.check("條目數合理（超過十萬筆）", rows > 100000, true)
H.check("依位元組遞增排序，可以二分搜尋", unsorted, 0)

-- 走正式入口：開著英文提示時，候選右側應該出現〈釋義〉
local function gloss(text)
  H.collected = {}
  local ctx = H.context()
  ctx:set_option("preview_english", true)
  simplified_hint(H.one(text), { engine = { context = ctx } })
  return H.collected[1] and H.collected[1].comment or ""
end

H.check("銀行", gloss("銀行"), "〈bank〉")
H.check("電腦", gloss("電腦"), "〈computer〉")
H.check("臺灣", gloss("臺灣"), "〈Taiwan〉")
H.check("多音字取得到釋義", gloss("行"):match("^〈") ~= nil, true)
H.check("查不到就不加註解", gloss("蛧蜽魎魍"), "")

H.report("中英釋義")
