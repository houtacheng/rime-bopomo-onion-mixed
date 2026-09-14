-- 拼寫規則沒有走樣：rime.lua 的 pinyin_to_bopomofo 與 schema 的 speller/algebra
-- 是同一套轉寫的兩份手寫實作，順序改錯就會讀錯音。這支測試拿詞庫裡真正用到的
-- 音節逐一對照兩條路徑：
--   schema 路徑：音節 → algebra 的 xform → xlit → 鍵碼 → Control+↑（raw_to_bopomofo）
--   lua   路徑：音節 → 反查表 → 讀音提示的 ﹝注音﹞
-- 兩邊都只用 repo 自己的資料，沒有另外寫死對照表。
local H = dofile((arg[0]:match("^(.*)/[^/]*$") or ".") .. "/harness.lua")
H.install()

-- 假的反查表，回傳目前要測的那個音節（reverse_db() 只會取用一次並快取）
local lookup_result
ReverseDb = function() return { lookup = function() return lookup_result end } end

---------------------------------------------------------------------------
-- 從 schema 讀規則
---------------------------------------------------------------------------
local xforms, xlit_from, xlit_to = {}, nil, nil
do
  local in_algebra, done_xforms = false, false
  for line in io.lines(H.root .. "/bopomo_onion.schema.yaml") do
    local code = line:gsub("%s+#.*$", "")                      -- 去掉行尾註解
    if line:match("^%s*algebra:") then
      in_algebra = true
    elseif in_algebra and not line:match("^%s*#") then
      if line:match("^[^%s#]") then break end                  -- 離開 speller 區塊
      -- 只取「字母簡化」之前的 xform：abbrev/derive 是簡拼與亂序，不影響讀音
      if code:match("^%s*%-%s*abbrev") then done_xforms = true end
      local from, to = code:match("^%s*%-%s*xform/(.-)/(.-)/%s*$")
      if from and not done_xforms then
        xforms[#xforms + 1] = { from, (to:gsub("%$(%d)", "%%%1")) }
      end
      local f, t = code:match("xlit|(.-)|(.-)|")
      if f then xlit_from, xlit_to = f, t end
    end
  end
end
assert(#xforms > 0 and xlit_from, "讀不到 schema 的 algebra 規則")
assert(utf8.len(xlit_from) == utf8.len(xlit_to), "xlit 兩邊長度不一致")

local xlit = {}
do
  local to = {}
  for _, c in utf8.codes(xlit_to) do to[#to + 1] = utf8.char(c) end
  local i = 0
  for _, c in utf8.codes(xlit_from) do i = i + 1; xlit[utf8.char(c)] = to[i] end
end

---------------------------------------------------------------------------
-- 兩條路徑
---------------------------------------------------------------------------
local function schema_reading(syllable)
  local s = syllable
  for _, rule in ipairs(xforms) do s = s:gsub(rule[1], rule[2]) end
  local keys = {}
  for ch in s:gmatch(".") do
    local key = xlit[ch]
    if not key then return nil, "xlit 沒有 " .. ch end
    keys[#keys + 1] = key
  end
  local committed
  local ctx = H.context({ input = table.concat(keys), candidate = { text = "字" } })
  special_commit({ repr = function() return "Control+Up" end, release = function() return false end },
                 { engine = { commit_text = function(_, text) committed = text end, context = ctx } })
  -- 一聲在讀音輸出裡照慣例不標，鍵碼路徑則會帶出 ˉ
  return committed and (committed:gsub("ˉ$", ""))
end

local function lua_reading(syllable)
  lookup_result = syllable
  H.collected = {}
  local ctx = H.context()
  ctx:set_option("preview_bopomofo", true)
  simplified_hint(H.one("字"), { engine = { context = ctx } })
  local comment = H.collected[1] and H.collected[1].comment or ""
  return (comment:match("^﹝(.*)﹞$"))
end

---------------------------------------------------------------------------
-- 拿詞庫裡真正用到的音節來比
---------------------------------------------------------------------------
local syllables, seen = {}, {}
for _, dict in ipairs({ "terra_pinyin_onion.dict.yaml", "terra_pinyin_onion_add.dict.yaml" }) do
  for line in io.lines(H.root .. "/" .. dict) do
    local code = line:match("^[^#\t]+\t([^\t]+)")
    if code then
      for token in code:gmatch("%S+") do
        -- 反查表用得上的編碼就是純小寫字母加可選聲調，其餘（含括號的異讀）本來就取不到讀音
        if not seen[token] and token:match("^%l+[1-5]?$") then
          seen[token] = true
          syllables[#syllables + 1] = token
        end
      end
    end
  end
end
table.sort(syllables)
assert(#syllables > 1000, "音節取太少，詞庫格式可能變了")

local mismatches = {}
for _, syllable in ipairs(syllables) do
  local want = schema_reading(syllable)
  local got = lua_reading(syllable)
  if want ~= got then
    mismatches[#mismatches + 1] = string.format("%s：schema 給 %s，lua 給 %s",
      syllable, tostring(want), tostring(got))
  end
end

print(string.format("對照詞庫裡的 %d 個音節", #syllables))
for i = 1, math.min(#mismatches, 20) do print("    " .. mismatches[i]) end
if #mismatches > 20 then print(string.format("    …另有 %d 筆", #mismatches - 20)) end
H.check("pinyin_to_bopomofo 與 speller/algebra 一致", #mismatches, 0)

-- 幾個一眼看得出對錯的例子，兼作規則順序的哨兵
H.check("ㄧㄡ：iu 要先變 iU，不能先被吃成 v", lua_reading("liu2"), "ㄌㄧㄡˊ")
H.check("ㄐㄩ：ju → jv", lua_reading("ju1"), "ㄐㄩ")
H.check("ㄤ：ang 要排在 an 之前", lua_reading("chang2"), "ㄔㄤˊ")
H.check("ㄣ：in → ien", lua_reading("xin1"), "ㄒㄧㄣ")
H.check("ㄓ：zhi → Z", lua_reading("zhi4"), "ㄓˋ")
H.check("輕聲", lua_reading("de5"), "ㄉㄜ˙")

H.report("拼寫規則")
