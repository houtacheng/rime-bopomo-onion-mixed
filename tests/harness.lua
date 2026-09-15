-- 以假的 librime-lua API 載入 rime.lua，讓測試可以直接呼叫方案裡的濾鏡與處理器。
-- 真正的 API 由 librime-lua 注入，這裡只補上測試會走到的那幾個。
local M = {}

M.root = (arg[0]:match("^(.*)/[^/]*$") or ".") .. "/.."

-- 假的候選與 yield：濾鏡吐出來的東西收進 M.collected
-- data_dir 決定 rime.lua 去哪裡找 english_gloss.txt 與 tools/.debug-keys。
-- 預設指向 tests/，這樣排錯記錄不會被測試寫髒；要查釋義表的測試才傳 repo 根目錄。
function M.install(data_dir)
  local dir = data_dir or (M.root .. "/tests")
  rime_api = { get_user_data_dir = function() return dir end }
  Opencc = function() return { convert = function(_, text) return text end } end
  ReverseDb = function() error("測試未提供反查表") end
  Candidate = function(kind, s, e, text, comment)
    return { type = kind, start = s, _end = e, text = text, comment = comment }
  end
  ShadowCandidate = function(_, kind, text, comment)
    return { type = kind, text = text, comment = comment }
  end
  yield = function(cand) M.collected[#M.collected + 1] = cand end
  M.collected = {}
  dofile(M.root .. "/rime.lua")
end

-- 單一候選的假輸入串流，供濾鏡走訪
function M.one(text, kind)
  return { iter = function()
    local done = false
    return function()
      if done then return nil end
      done = true
      return { type = kind or "", start = 0, _end = #text, text = text, comment = "" }
    end
  end }
end

-- 假的 context。committed 依序記下上屏的內容，組字狀態會隨 commit/clear 改變，
-- 這樣連續按鍵的測試才貼近真實。
function M.context(opts)
  opts = opts or {}
  local options = {}
  local ctx
  ctx = {
    input = opts.input or "",
    composing = opts.composing ~= false,
    menu = opts.menu ~= false,
    committed = {},
    get_option = function(_, key) return options[key] == true end,
    set_option = function(_, key, value) options[key] = value end,
    is_composing = function() return ctx.composing end,
    has_menu = function() return ctx.menu and ctx.composing end,
    get_selected_candidate = function() return opts.candidate end,
    highlight = function() end,
    commit = function() ctx.committed[#ctx.committed + 1] = "〔組字〕"; ctx.composing = false end,
    clear = function() ctx.composing = false end,
  }
  return ctx
end

-- 配一個假的 engine：上屏的文字同樣記進 ctx.committed
function M.env(ctx)
  return { engine = {
    context = ctx,
    commit_text = function(_, text) ctx.committed[#ctx.committed + 1] = text end,
  } }
end

-- 計分板
local fails, checks = 0, 0

function M.check(label, got, want)
  checks = checks + 1
  if got == want then
    print(string.format("  ✓ %s", label))
  else
    fails = fails + 1
    print(string.format("  ✗ %s\n      得到 %s\n      預期 %s", label, tostring(got), tostring(want)))
  end
end

function M.report(title)
  print(string.format("\n%s：%d 項，%d 項失敗", title, checks, fails))
  os.exit(fails == 0 and 0 or 1)
end

return M
