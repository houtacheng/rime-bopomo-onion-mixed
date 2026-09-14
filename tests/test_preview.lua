-- 讀音提示的切換：reading_preview 處理器。
-- 修飾鍵同時是選字鍵的前半段（Shift+Q、Shift+←…），按組合鍵時作業系統一定會先送一個
-- 單獨的修飾鍵事件，所以切換完必須能在下一個按鍵認出「剛才那下是組合鍵」並還原。
local H = dofile((arg[0]:match("^(.*)/[^/]*$") or ".") .. "/harness.lua")
H.install()

-- 假的按鍵事件。repr 直接決定修飾位，與 librime 的 KeyEvent::repr 一致：
-- 按下 Shift 時事件同時帶著 Shift_L 鍵碼與 shift 修飾位，repr 是「Shift+Shift_L」。
local function key(repr, released)
  return {
    repr = function() return repr end,
    release = function() return released == true end,
    shift = function() return repr:find("Shift", 1, true) ~= nil end,
    ctrl = function() return repr:find("Control", 1, true) ~= nil end,
    alt = function() return repr:find("Alt", 1, true) ~= nil end,
    super = function() return repr:find("Super", 1, true) ~= nil end,
  }
end

local SHIFT_DOWN = key("Shift+Shift_L")
local SHIFT_UP = key("Release+Shift_L", true)
local CTRL_DOWN = key("Control+Control_L")
local ALT_DOWN = key("Alt+Alt_L")
local SHIFT_Q = key("Shift+Q")           -- 選第 1 候選
local SHIFT_LEFT = key("Shift+Left")     -- 左移一個注音
local SHIFT_K = key("Shift+K")           -- 下一頁
local CTRL_LEFT = key("Control+Left")    -- 輸出漢語拼音
local RIGHT = key("Right")
local SPACE = key("space")

local function press(ctx, ...)
  for _, k in ipairs({ ... }) do reading_preview(k, { engine = { context = ctx } }) end
  local on = {}
  for _, name in ipairs({ "preview_bopomofo", "preview_pinyin", "preview_english" }) do
    if ctx:get_option(name) then on[#on + 1] = name:gsub("preview_", "") end
  end
  return #on == 0 and "off" or table.concat(on, "+")
end

print("單獨按修飾鍵：照常切換")
H.check("Shift → 注音", press(H.context(), SHIFT_DOWN), "bopomofo")
H.check("Control → 拼音", press(H.context(), CTRL_DOWN), "pinyin")
H.check("Option → 英文", press(H.context(), ALT_DOWN), "english")
H.check("開啟後按 →（無修飾位）仍開著，才能輸出",
  press(H.context(), SHIFT_DOWN, RIGHT), "bopomofo")
H.check("再按一次同一個修飾鍵就關閉",
  press(H.context(), SHIFT_DOWN, SPACE, SHIFT_DOWN), "off")
H.check("改按別的修飾鍵就換模式",
  press(H.context(), SHIFT_DOWN, SPACE, CTRL_DOWN), "pinyin")

print("\n組合鍵：下一個按鍵仍帶著同一個修飾位 → 還原")
H.check("Shift+Q 選字（macOS：修飾鍵事件在前）",
  press(H.context(), SHIFT_DOWN, SHIFT_Q), "off")
H.check("Shift+Q 選字（小狼毫：放開事件先到）",
  press(H.context(), SHIFT_DOWN, SHIFT_UP, SHIFT_Q), "off")
H.check("Shift+← 左移一個注音", press(H.context(), SHIFT_DOWN, SHIFT_LEFT), "off")
H.check("Shift+K 翻頁", press(H.context(), SHIFT_DOWN, SHIFT_K), "off")
H.check("Control+← 輸出拼音，不留下拼音提示",
  press(H.context(), CTRL_DOWN, CTRL_LEFT), "off")

local ctx = H.context()
press(ctx, SHIFT_DOWN, RIGHT)
H.check("提示已開著時用 Shift+Q 選字 → 維持開著", press(ctx, SHIFT_DOWN, SHIFT_Q), "bopomofo")

print("\n其他")
H.check("沒在組字就清乾淨", press(H.context({ composing = false, menu = false }), SHIFT_DOWN, SPACE), "off")
H.check("有候選列時吃掉修飾鍵",
  reading_preview(SHIFT_DOWN, { engine = { context = H.context() } }), 1)
H.check("沒有候選列時放行",
  reading_preview(SHIFT_DOWN, { engine = { context = H.context({ menu = false }) } }), 2)
H.check("一般按鍵不攔截",
  reading_preview(SPACE, { engine = { context = H.context() } }), 2)

H.report("讀音提示")
