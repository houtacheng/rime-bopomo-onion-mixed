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

-- 上屏方式依平台而異（見 rime.lua 的說明），兩條路都要測：
-- 這支測試跑兩次，第二次由 run.sh 設 APPDATA 模擬 Windows。
local WINDOWS = os.getenv("APPDATA") ~= nil
print(WINDOWS and "（Windows 路徑：一按一個字）" or "（macOS 路徑：累積成組字，放開 Control 才上屏）")

local RELEASE_CTRL = key("Release+Control_L", true)

print("\n未組字：按著 Control 打 2 0 2 6")
local ctx = H.context({ composing = false, menu = false })
feed(ctx, CTRL, key("Control+2"), key("Control+0"), key("Control+2"), key("Control+6"), RELEASE_CTRL)
H.check("放開 Control 後拿到整串數字", output(ctx), WINDOWS and "2|0|2|6" or "2026")

ctx = H.context({ composing = false, menu = false })
H.check("攔下按鍵不讓應用程式收到", feed(ctx, CTRL, key("Control+7")), 1)

ctx = H.context({ composing = false, menu = false })
feed(ctx, CTRL, key("Control+0"), RELEASE_CTRL)
H.check("Control+0 也可以", output(ctx), "0")

print("\n數字串裡的標點")
ctx = H.context({ composing = false, menu = false })
feed(ctx, CTRL, key("Control+1"), key("Control+period"), RELEASE_CTRL)
H.check("Control+. 在數字串中是句點", output(ctx), WINDOWS and "1|." or "1.")

ctx = H.context({ composing = false, menu = false })
feed(ctx, CTRL, key("Control+2"), key("Control+0"), key("Control+2"), key("Control+6"),
     key("Control+slash"), key("Control+0"), key("Control+9"), RELEASE_CTRL)
H.check("日期形式 2026/09", output(ctx), WINDOWS and "2|0|2|6|/|0|9" or "2026/09")

ctx = H.context({ composing = false, menu = false })
H.check("沒在打數字時不攔截，讓模式切換照舊",
  feed(ctx, RELEASE_CTRL, CTRL, key("Control+period")), 2)

ctx = H.context({ composing = false, menu = false })
feed(ctx, CTRL, key("Control+1"), RELEASE_CTRL)
H.check("打完數字放開 Control，下一次 Control+. 就還給全形切換",
  feed(ctx, CTRL, key("Control+period")), 2)

if not WINDOWS then
  print("\n累積中的編輯")
  ctx = H.context({ composing = false, menu = false })
  feed(ctx, CTRL, key("Control+1"), key("Control+2"), key("Escape"))
  H.check("Esc 整串丟掉，不上屏", output(ctx), "")
  H.check("Esc 之後不再累積", ctx.composing, false)

  ctx = H.context({ composing = false, menu = false })
  H.check("BackSpace 交給編輯器處理", (function()
    feed(ctx, CTRL, key("Control+1"))
    return feed(ctx, key("BackSpace"))
  end)(), 2)

  ctx = H.context({ composing = false, menu = false })
  feed(ctx, CTRL, key("Control+1"), key("a"))
  H.check("改按別的鍵會先把數字送出去", output(ctx), "1")
end

print("\n組字中：先上屏目前候選，再輸出數字")
ctx = H.context({ candidate = { text = "不" } })
H.check("實體按 Control 打數字", (function()
  feed(ctx, CTRL, key("Control+5"), RELEASE_CTRL)
  return output(ctx)
end)(), "〔組字〕|5")

print("\n組字中：key_binder 轉送來選字的不能攔")
ctx = H.context({ candidate = { text = "不" } })
H.check("Shift+Q → Control+1 照樣選字", feed(ctx, SHIFT, key("Shift+Q"), key("Control+1")), 2)
H.check("沒有誤上屏任何東西", output(ctx), "")

ctx = H.context({ candidate = { text = "不" } })
H.check("Tab → Control+1 照樣選字", feed(ctx, key("Tab"), key("Control+1")), 2)
H.check("沒有誤上屏任何東西", output(ctx), "")

ctx = H.context({ candidate = { text = "不" } })
H.check("放開 Control 後再轉送就不算實體按鍵",
  feed(ctx, CTRL, key("Shift+A"), key("Control+2")), 2)

print("\n舊版 librime-lua 沒有 context:commit 時的退路")
ctx = H.context({ candidate = { text = "不" } })
ctx.commit = nil
ctx.get_commit_text = function() return "不錯" end
H.check("改用 get_commit_text 拿整串", (function()
  feed(ctx, CTRL, key("Control+5"))
  return output(ctx)
end)(), "不錯|5")

print("\n其他")
H.check("放開事件不觸發數字", digit_commit(key("Control+1", true), H.env(H.context({ composing = false, menu = false }))), 2)
H.check("沒有 Control 的數字鍵不處理", digit_commit(key("1"), H.env(H.context())), 2)

H.report("數字輸入")
