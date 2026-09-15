-- Control + 數字直接上屏：digit_commit 處理器。
-- 難處在於組字中的 Control+N 有兩種來源——使用者實體按著 Control 想打數字，
-- 以及 key_binder 為了選字轉送出來的（Tab 與 Shift+字母 那組全都轉送成 Control+N）。
-- 攔錯會把選字功能整組吃掉，所以兩種都要測。
local H = dofile((arg[0]:match("^(.*)/[^/]*$") or ".") .. "/harness.lua")
H.install()

local function key(repr, released)
  return {
    repr = function() return repr end,
    release = function() return released == true end,
    shift = function() return repr:find("Shift", 1, true) ~= nil end,
    ctrl = function() return repr:find("Control", 1, true) ~= nil end,
    alt = function() return repr:find("Alt", 1, true) ~= nil end,
    super = function() return false end,
  }
end

-- 照方案裡的處理器順序送：reading_preview 在前（它維護「Control 是否按著」），
-- digit_commit 在後。回傳最後一個按鍵的處理結果。
local function feed(ctx, ...)
  local result
  for _, k in ipairs({ ... }) do
    local env = H.env(ctx)
    reading_preview(k, env)
    result = digit_commit(k, env)
  end
  return result
end

local function output(ctx) return table.concat(ctx.committed, "|") end

local CTRL = key("Control+Control_L")
local SHIFT = key("Shift+Shift_L")

print("未組字：一鍵一個數字")
local ctx = H.context({ composing = false, menu = false })
H.check("按著 Control 連打 2 0 2 6", (function()
  feed(ctx, CTRL, key("Control+2"), key("Control+0"), key("Control+2"), key("Control+6"))
  return output(ctx)
end)(), "2|0|2|6")

ctx = H.context({ composing = false, menu = false })
H.check("攔下按鍵不讓應用程式收到", feed(ctx, CTRL, key("Control+7")), 1)
H.check("Control+0 也可以", (function()
  local c = H.context({ composing = false, menu = false })
  feed(c, CTRL, key("Control+0"))
  return output(c)
end)(), "0")

print("\n組字中：先上屏目前候選，再輸出數字")
ctx = H.context({ candidate = { text = "不" } })
H.check("實體按 Control 打數字", (function()
  feed(ctx, CTRL, key("Control+5"))
  return output(ctx)
end)(), "〔組字〕|5")
H.check("組字狀態已結束", ctx.composing, false)

ctx = H.context({ candidate = { text = "不" } })
H.check("接著再打一個數字", (function()
  feed(ctx, CTRL, key("Control+5"), key("Control+3"))
  return output(ctx)
end)(), "〔組字〕|5|3")

print("\n組字中：key_binder 轉送來選字的不能攔")
ctx = H.context({ candidate = { text = "不" } })
H.check("Shift+Q → Control+1 照樣選字", feed(ctx, SHIFT, key("Shift+Q"), key("Control+1")), 2)
H.check("沒有誤上屏任何東西", output(ctx), "")

ctx = H.context({ candidate = { text = "不" } })
H.check("Tab → Control+1 照樣選字", feed(ctx, key("Tab"), key("Control+1")), 2)
H.check("沒有誤上屏任何東西", output(ctx), "")

ctx = H.context({ candidate = { text = "不" } })
H.check("放開 Control 後再轉送就不算實體按鍵", (function()
  return feed(ctx, CTRL, key("Shift+A"), key("Control+2"))
end)(), 2)

print("\n舊版 librime-lua 沒有 context:commit 時的退路")
ctx = H.context({ candidate = { text = "不" } })
ctx.commit = nil                                        -- 模擬沒有綁這個方法
ctx.get_commit_text = function() return "不錯" end      -- 整串待上屏的文字
H.check("改用 get_commit_text 拿整串", (function()
  feed(ctx, CTRL, key("Control+5"))
  return output(ctx)
end)(), "不錯|5")

ctx = H.context({ candidate = { text = "不" } })
ctx.commit = nil
H.check("連 get_commit_text 都沒有就退到候選文字", (function()
  feed(ctx, CTRL, key("Control+5"))
  return output(ctx)
end)(), "不|5")

print("\n其他")
H.check("放開事件不處理", digit_commit(key("Control+1", true), H.env(H.context())), 2)
H.check("沒有 Control 的數字鍵不處理", digit_commit(key("1"), H.env(H.context())), 2)

H.report("數字輸入")
