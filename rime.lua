-- 顯示繁體候選的簡體提示，並提供純注音／簡體快捷上屏。
local tw_to_s = Opencc("tw2s.json")

local bopomofo_keys = {
  ["1"]="ㄅ", q="ㄆ", a="ㄇ", z="ㄈ", ["2"]="ㄉ", w="ㄊ", s="ㄋ", x="ㄌ",
  e="ㄍ", d="ㄎ", c="ㄏ", r="ㄐ", f="ㄑ", v="ㄒ", ["5"]="ㄓ", t="ㄔ",
  g="ㄕ", b="ㄖ", y="ㄗ", h="ㄘ", n="ㄙ", u="ㄧ", j="ㄨ", m="ㄩ",
  ["8"]="ㄚ", i="ㄛ", k="ㄜ", [","]="ㄝ", ["9"]="ㄞ", o="ㄟ", l="ㄠ",
  ["."]="ㄡ", ["0"]="ㄢ", p="ㄣ", [";"]="ㄤ", ["/"]="ㄥ", ["-"]="ㄦ",
  [" "]="ˉ", ["6"]="ˊ", ["3"]="ˇ", ["4"]="ˋ", ["7"]="˙"
}

local function raw_to_bopomofo(raw)
  local result = ""
  for i = 1, #raw do
    local key = raw:sub(i, i)
    if key ~= "\\" then
      local symbol = bopomofo_keys[key]
      if not symbol then return nil end
      result = result .. symbol
    end
  end
  return result ~= "" and result or nil
end

local weekday = { "日", "一", "二", "三", "四", "五", "六" }
local stems = { "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸" }
local branches = { "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥" }
local date_triggers = { ["今天"]=true, ["昨天"]=true, ["明天"]=true }

local symbols = {
  ["公里"] = { "㎞", "km" }, ["公尺"] = { "m" },
  ["公分"] = { "㎝", "cm" }, ["毫米"] = { "㎜", "mm" },
  ["平方公尺"] = { "㎡" }, ["立方公尺"] = { "㎥" },
  ["公斤"] = { "㎏", "kg" }, ["公克"] = { "g" },
  ["攝氏"] = { "℃" }, ["華氏"] = { "℉" },
  ["水瓶"] = { "♒" }, ["雙魚"] = { "♓" }, ["牡羊"] = { "♈" },
  ["金牛"] = { "♉" }, ["雙子"] = { "♊" }, ["巨蟹"] = { "♋" },
  ["獅子"] = { "♌" }, ["處女"] = { "♍" }, ["天秤"] = { "♎" },
  ["天蠍"] = { "♏" }, ["射手"] = { "♐" }, ["摩羯"] = { "♑" },
  ["株"] = { "㈱" }, ["滿"] = { "🈵" }
}

local function ganzhi(year)
  return stems[((year - 4) % 10) + 1] .. branches[((year - 4) % 12) + 1] .. "年"
end

local function year_formats(year)
  local result = {
    tostring(year) .. " 年",
    "民國 " .. tostring(year - 1911) .. " 年",
    ganzhi(year)
  }
  if year >= 2019 then
    table.insert(result, "令和 " .. tostring(year - 2018) .. " 年")
  end
  return result
end

local function date_formats(timestamp)
  local d = os.date("*t", timestamp)
  local result = {
    string.format("%04d.%02d.%02d", d.year, d.month, d.day),
    string.format("%04d.%02d.%02d(%s)", d.year, d.month, d.day, weekday[d.wday]),
    string.format("%04d%02d%02d", d.year, d.month, d.day),
    string.format("%d 年 %d 月 %d 日", d.year, d.month, d.day),
    string.format("%04d-%02d-%02d", d.year, d.month, d.day),
    string.format("民國 %d 年 %d 月 %d 日", d.year - 1911, d.month, d.day),
    "週" .. weekday[d.wday],
    "禮拜" .. weekday[d.wday]
  }
  if d.year >= 2019 then
    table.insert(result, string.format("令和 %d 年 %d 月 %d 日", d.year - 2018, d.month, d.day))
  end
  return result
end

local function extras_for(text)
  local now = os.time()
  local d = os.date("*t", now)
  if text == "今年" then return year_formats(d.year) end
  if text == "去年" then return year_formats(d.year - 1) end
  if text == "明年" then return year_formats(d.year + 1) end
  if text == "今天" then return date_formats(now) end
  if text == "昨天" then return date_formats(now - 86400) end
  if text == "明天" then return date_formats(now + 86400) end
  if text == "現在" then
    return { os.date("%H:%M", now), os.date("%H:%M:%S", now), os.date("%Y-%m-%d %H:%M:%S", now) }
  end
  if text == "時區" then
    return { os.date("%Z", now), "UTC" .. os.date("%z", now) }
  end
  return symbols[text]
end

function date_symbol_extras(input, env)
  local expanded = {}
  for candidate in input:iter() do
    local values = extras_for(candidate.text)
    if values and not expanded[candidate.text] then
      expanded[candidate.text] = true
      if date_triggers[candidate.text] then
        yield(candidate)
        for _, value in ipairs(values) do
          yield(Candidate("date_symbol", candidate.start, candidate._end, value, "〔日期〕"))
        end
      else
        yield(candidate)
        for _, value in ipairs(values) do
          yield(Candidate("date_symbol", candidate.start, candidate._end, value, "〔日期／符號〕"))
        end
      end
    else
      yield(candidate)
    end
  end
end

-- 中文候選優先：英文候選維持彼此的相對順序，整體排到中文之後。
-- 只降級「純 ASCII 且以字母開頭」的候選，因此日期（2026.09.13、20260913）、
-- 數字格式（羅馬數字等，type 為 number）與標點都不受影響。
local PROTECTED_TYPES = { date_symbol = true, number = true, punct = true }

-- chinese_first 在產生候選時記下「目前第一個英文候選」，english_commit（Tab）直接取用。
-- 兩者同在本檔共用這個 upvalue，就不必依賴 librime-lua 的候選列走訪 API。
-- 必須在迴圈中即時寫入：濾鏡是 coroutine，消費端取滿一頁就會把它掛起，迴圈結束後的賦值不保證執行得到。
local first_english_text = nil

-- 常用英文詞的詞頻排名，來自 lua/english_common.lua。載不到就退化成「中文永遠第一」，不會壞掉。
local COMMON_RANK = (function()
  for _, mod in ipairs({ "english_common", "lua.english_common" }) do
    local ok, data = pcall(require, mod)
    if ok and type(data) == "table" then return data end
  end
  return {}
end)()

-- 何時讓英文排到第一位。
-- 這是 ZingIME「無法組成注音時只剩英文」的替代方案：本方案有簡拼，任何字母序列都是合法注音，
-- 不存在「不可能」的輸入，所以改用詞頻判斷這串輸入像不像一個常用英文單字。
-- 門檻調寬會讓更多輸入被判為英文；設 ENGLISH_LEAD_RANK_LIMIT = 0 即完全關閉、回到中文永遠第一。
local ENGLISH_LEAD_MIN_LENGTH = 4   -- 三個字母以內多半是注音簡拼，一律讓中文優先
local ENGLISH_LEAD_RANK_LIMIT = 2000
local HELD_ZH_LIMIT = 20            -- 等待英文完全相符時最多扣住幾個中文候選

local function should_english_lead(raw)
  if #raw < ENGLISH_LEAD_MIN_LENGTH then return false end
  local rank = COMMON_RANK[raw]
  return rank ~= nil and rank <= ENGLISH_LEAD_RANK_LIMIT
end

-- 緩衝上限：避免英文候選極多時（例如只輸入一個字母）拖慢逐頁取詞。
-- 超過上限後改為原序輸出，屬於降級而非錯誤。
local LATIN_BUFFER_LIMIT = 60

local function is_english_candidate(cand)
  if PROTECTED_TYPES[cand.type] then return false end
  local text = cand.text
  if text:find("[\128-\255]") then return false end  -- 含非 ASCII 位元組＝中文候選
  return text:find("^%a") ~= nil                       -- 必須以 ASCII 字母開頭
end

function chinese_first(input, env)
  local raw = (env.engine.context.input or ""):lower()
  local latin, held_zh = {}, {}
  local exact_taken = false
  local lead_done = not should_english_lead(raw)
  first_english_text = nil

  local function release_held()
    for _, c in ipairs(held_zh) do yield(c) end
    held_zh = {}
    lead_done = true
  end

  for cand in input:iter() do
    if is_english_candidate(cand) then
      if not lead_done and not exact_taken and cand.text:lower() == raw then
        -- 英文領先：完全相符者排第一，再放行被扣住的中文候選
        first_english_text = cand.text
        exact_taken = true
        yield(cand)
        release_held()
      elseif #latin < LATIN_BUFFER_LIMIT then
        latin[#latin + 1] = cand
        if #latin == 1 then first_english_text = cand.text end
        if not exact_taken and cand.text:lower() == raw then
          -- 完全相符者提到英文候選之首（例如打 home 就要先看到 home）
          exact_taken = true
          first_english_text = cand.text
          table.insert(latin, 1, table.remove(latin, #latin))
        end
      else
        yield(cand)
      end
    elseif lead_done then
      yield(cand)
    else
      held_zh[#held_zh + 1] = cand
      if #held_zh >= HELD_ZH_LIMIT then release_held() end
    end
  end

  if not lead_done then release_held() end
  for _, cand in ipairs(latin) do
    yield(cand)
  end
end

local digit_normal = { [0] = "零", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
local digit_financial = { [0] = "零", "壹", "貳", "參", "肆", "伍", "陸", "柒", "捌", "玖" }
local suzhou = { [0] = "〇", "〡", "〢", "〣", "〤", "〥", "〦", "〧", "〨", "〩" }
local small_units = { "", "十", "百", "千" }
local financial_units = { "", "拾", "佰", "仟" }
local large_units = { "", "萬", "億", "兆" }

local function four_digits(value, digits, units)
  local out, pending_zero = "", false
  for pos = 3, 0, -1 do
    local base = 10 ^ pos
    local n = math.floor(value / base) % 10
    if n == 0 then
      if out ~= "" and value % base ~= 0 then pending_zero = true end
    else
      if pending_zero then out = out .. digits[0]; pending_zero = false end
      out = out .. digits[n] .. units[pos + 1]
    end
  end
  return out
end

local function chinese_integer(raw, financial)
  local value = tonumber(raw)
  if not value or value < 0 or value >= 10000000000000000 then return nil end
  if value == 0 then return "零" end
  local digits = financial and digit_financial or digit_normal
  local units = financial and financial_units or small_units
  local groups, result, group_index = {}, "", 1
  while value > 0 do
    groups[group_index] = value % 10000
    value = math.floor(value / 10000)
    group_index = group_index + 1
  end
  local need_zero = false
  for i = #groups, 1, -1 do
    local group = groups[i]
    if group == 0 then
      if result ~= "" then need_zero = true end
    else
      if result ~= "" and (need_zero or group < 1000) then result = result .. digits[0] end
      result = result .. four_digits(group, digits, units) .. large_units[i]
      need_zero = false
    end
  end
  if not financial then result = result:gsub("^一十", "十") end
  return result
end

local function roman(value)
  if value < 1 or value > 3999 then return nil end
  local map = {
    {1000,"M"},{900,"CM"},{500,"D"},{400,"CD"},{100,"C"},{90,"XC"},
    {50,"L"},{40,"XL"},{10,"X"},{9,"IX"},{5,"V"},{4,"IV"},{1,"I"}
  }
  local out = ""
  for _, item in ipairs(map) do
    while value >= item[1] do out = out .. item[2]; value = value - item[1] end
  end
  return out
end

local function suzhou_number(raw)
  return (raw:gsub("%d", function(ch) return suzhou[tonumber(ch)] end))
end

function number_formats(input, segment, env)
  if input == "#" then
    yield(Candidate("number", segment.start, segment._end, "數字輸入", "繼續輸入阿拉伯數字"))
    return
  end
  local raw = input:match("^#(%d+)$")
  if not raw then return end
  -- 原始阿拉伯數字放第一位：大千配置把 0-9 全用作注音鍵，這是中文模式下打數字的出口。
  -- 想讓中文數字排回第一位，把這行移到 normal 那兩行之後即可。
  yield(Candidate("number", segment.start, segment._end, raw, "阿拉伯數字"))
  local normal = chinese_integer(raw, false)
  local financial = chinese_integer(raw, true)
  if normal then yield(Candidate("number", segment.start, segment._end, normal, "中文數字")) end
  if financial then yield(Candidate("number", segment.start, segment._end, financial, "大寫數字")) end
  yield(Candidate("number", segment.start, segment._end, suzhou_number(raw), "蘇州碼"))
  local r = roman(tonumber(raw))
  if r then yield(Candidate("number", segment.start, segment._end, r, "羅馬數字")) end
  if #raw == 1 then
    local n = tonumber(raw)
    local circled = ({ [0]="⓪", "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨" })[n]
    local black = ({ [0]="⓿", "❶", "❷", "❸", "❹", "❺", "❻", "❼", "❽", "❾" })[n]
    yield(Candidate("number", segment.start, segment._end, circled, "圈圈數字"))
    yield(Candidate("number", segment.start, segment._end, black, "黑圈數字"))
  end
end

---------------------------------------------------------------------------
-- 選中候選的完整讀音（注音文／漢語拼音）
--
-- 反查表 build/bopomo_onion.extended.reverse.bin 由部署時自動產生，存的是字典原始編碼：
-- terra_pinyin 式拼音，ü 寫作 v、聲調用數字，多音節詞以空白分隔（銀行 → "yin2 hang2"）。
---------------------------------------------------------------------------
local REVERSE_DB_FILE = "build/bopomo_onion.extended.reverse.bin"
local BOPOMOFO_SEPARATOR = ""    -- 想讓音節之間留空白就改成 " "
local PINYIN_SEPARATOR = " "

local CHAR_PATTERN = (utf8 and utf8.charpattern) or "[\0-\127\194-\244][\128-\191]*"

local reverse_db_cache = nil
local function reverse_db()
  if reverse_db_cache == nil then
    local ok, db = pcall(ReverseDb, REVERSE_DB_FILE)
    reverse_db_cache = (ok and db) or false
  end
  return reverse_db_cache or nil
end

local function utf8_chars(text)
  local chars = {}
  for ch in text:gmatch(CHAR_PATTERN) do chars[#chars + 1] = ch end
  return chars
end

-- 先查整詞，以保留多音字的詞彙讀音（銀行 → yin2 hang2，而不是 yin2 xing2）。
-- 整詞回傳的分段數與字數不符時，代表拿到的是同一個字的多種讀音，改為逐字取第一個。
-- 反查表裡不是每個編碼都是拼音。內嵌注音文（mixin_bpmf）的條目長得像「＊b」，
-- 直接拿去轉換會產生亂碼，所以先驗格式：純小寫字母 + 可選的聲調數字。
local function is_pinyin_code(code)
  return code:match("^%l+[1-5]?$") ~= nil
end

local function syllables_of(text)
  local db = reverse_db()
  if not db then return nil end
  local chars = utf8_chars(text)
  if #chars == 0 then return nil end

  local whole = db:lookup(text)
  if whole and whole ~= "" then
    local parts = {}
    for part in whole:gmatch("%S+") do parts[#parts + 1] = part end
    if #parts == #chars then
      for _, part in ipairs(parts) do
        if not is_pinyin_code(part) then parts = nil break end
      end
      if parts then return parts end
    end
  end

  local out = {}
  for i, ch in ipairs(chars) do
    local found = db:lookup(ch)
    local first = found and found:match("%S+")
    if not first or not is_pinyin_code(first) then return nil end
    out[i] = first
  end
  return out
end

local BOPOMOFO_SYMBOLS = {
  b="ㄅ", p="ㄆ", m="ㄇ", f="ㄈ", d="ㄉ", t="ㄊ", n="ㄋ", l="ㄌ",
  g="ㄍ", k="ㄎ", h="ㄏ", j="ㄐ", q="ㄑ", x="ㄒ",
  Z="ㄓ", C="ㄔ", S="ㄕ", r="ㄖ", z="ㄗ", c="ㄘ", s="ㄙ",
  i="ㄧ", u="ㄨ", v="ㄩ",
  a="ㄚ", o="ㄛ", e="ㄜ", E="ㄝ", A="ㄞ", I="ㄟ", O="ㄠ", U="ㄡ",
  M="ㄢ", N="ㄣ", K="ㄤ", G="ㄥ", R="ㄦ",
  ["1"]="", ["2"]="ˊ", ["3"]="ˇ", ["4"]="ˋ", ["5"]="˙",   -- 一聲照慣例不標
}

-- 這串轉寫與 bopomo_onion.schema.yaml 的 speller/algebra 是同一套規則，順序必須一致：
-- ang/eng 要在 an/en 之前，iu→iU 要在 iu→v 之前，否則會轉錯。
local function pinyin_to_bopomofo(syllable)
  local s = syllable
  s = s:gsub("[%(%)]", "")
  s = s:gsub("iu", "iU")
  s = s:gsub("ui", "uI")
  s = s:gsub("ong", "ung")
  s = s:gsub("yi?", "i")
  s = s:gsub("wu?", "u")
  s = s:gsub("iu", "v")
  s = s:gsub("([jqx])u", "%1v")
  s = s:gsub("([iuv])n", "%1en")
  s = s:gsub("zhi?", "Z")
  s = s:gsub("chi?", "C")
  s = s:gsub("shi?", "S")
  s = s:gsub("([zcsr])i", "%1")
  s = s:gsub("ai", "A"); s = s:gsub("ei", "I")
  s = s:gsub("ao", "O"); s = s:gsub("ou", "U")
  s = s:gsub("ang", "K"); s = s:gsub("eng", "G")
  s = s:gsub("an", "M"); s = s:gsub("en", "N")
  s = s:gsub("er", "R"); s = s:gsub("eh", "E")
  s = s:gsub("([iv])e", "%1E")

  local out = {}
  for ch in s:gmatch(".") do
    local symbol = BOPOMOFO_SYMBOLS[ch]
    if symbol == nil then return nil end
    out[#out + 1] = symbol
  end
  return table.concat(out)
end

local PINYIN_TONE_MARKS = {
  a = { "ā", "á", "ǎ", "à" },  o = { "ō", "ó", "ǒ", "ò" },
  e = { "ē", "é", "ě", "è" },  i = { "ī", "í", "ǐ", "ì" },
  u = { "ū", "ú", "ǔ", "ù" },  ["ü"] = { "ǖ", "ǘ", "ǚ", "ǜ" },
}

-- 標調位置依漢語拼音正詞法：有 a 標 a，否則有 o 或 e 標之；
-- iu 標在 u、ui 標在 i；其餘標剩下的母音。輕聲不標。
local function pinyin_with_tone(syllable)
  local base, tone = syllable:match("^(%a+)([1-5])$")
  if not base then
    base = syllable:match("^(%a+)$")
    if not base then return nil end
    tone = "5"
  end
  base = base:gsub("v", "ü")
  local n = tonumber(tone)
  if n == 5 then return base end

  local target
  if     base:find("a", 1, true)  then target = "a"
  elseif base:find("o", 1, true)  then target = "o"
  elseif base:find("e", 1, true)  then target = "e"
  elseif base:find("iu", 1, true) then target = "u"
  elseif base:find("ui", 1, true) then target = "i"
  elseif base:find("ü", 1, true)  then target = "ü"
  elseif base:find("u", 1, true)  then target = "u"
  elseif base:find("i", 1, true)  then target = "i"
  end
  if not target then return base end
  return (base:gsub(target, PINYIN_TONE_MARKS[target][n], 1))
end

-- 把候選文字轉成讀音字串。mode 為 "bopomofo" 或 "pinyin"；反查不到回傳 nil。
local function reading_of(text, mode)
  local syllables = syllables_of(text)
  if not syllables then return nil end
  local parts = {}
  for i, syllable in ipairs(syllables) do
    if mode == "pinyin" then
      parts[i] = pinyin_with_tone(syllable) or syllable
    else
      parts[i] = pinyin_to_bopomofo(syllable) or syllable
    end
  end
  return table.concat(parts, mode == "pinyin" and PINYIN_SEPARATOR or BOPOMOFO_SEPARATOR)
end

-- 按住修飾鍵時，候選右側的提示改顯示讀音。用不同括號與簡體提示區分。
local PREVIEW_OPTIONS = {
  { option = "preview_bopomofo", mode = "bopomofo", open = "﹝", close = "﹞" },
  { option = "preview_pinyin",   mode = "pinyin",   open = "〔", close = "〕" },
}

function simplified_hint(input, env)
  local context = env.engine.context
  local preview
  for _, entry in ipairs(PREVIEW_OPTIONS) do
    if context:get_option(entry.option) then preview = entry break end
  end

  for candidate in input:iter() do
    local comment = candidate.comment
    if preview then
      local reading = reading_of(candidate.text, preview.mode)
      if reading then
        comment = preview.open .. reading .. preview.close
      end
    else
      local simplified = tw_to_s:convert(candidate.text)
      if simplified ~= candidate.text then
        comment = "〔" .. simplified .. "〕"
      end
    end
    yield(ShadowCandidate(candidate, candidate.type, candidate.text, comment))
  end
end

-- 按住 Shift 看注音、按住 Control 看漢語拼音。放開就恢復簡體提示。
-- 排錯用：建立這個檔案後，按下的修飾鍵 repr 會被記錄下來；刪掉檔案即停止。
local DEBUG_KEYS = (function()
  local path = os.getenv("HOME") .. "/Library/Rime/tools/.debug-keys"
  local fh = io.open(path, "r")
  if fh then fh:close() return path end
  return nil
end)()

local PREVIEW_MODIFIERS = {
  Shift_L = "preview_bopomofo", Shift_R = "preview_bopomofo",
  Control_L = "preview_pinyin", Control_R = "preview_pinyin",
}

-- repr() 會把所有修飾鍵前綴串在鍵名前（key_event.cc 的 KeyEvent::repr），
-- 按下 Shift 時事件同時帶著 Shift_L 鍵碼與 shift 修飾位，repr 是「Shift+Shift_L」而非「Shift_L」。
-- 所以只取最後一段鍵名，按下／放開一律用 key:release() 判斷。
local function bare_key_name(key)
  local repr = key:repr()
  return repr:match("([^+]+)$") or repr
end

function reading_preview(key, env)
  local name = bare_key_name(key)
  if DEBUG_KEYS then
    local fh = io.open(DEBUG_KEYS, "a")
    if fh then
      fh:write(string.format("%s\trelease=%s\tbare=%s\n",
                             key:repr(), tostring(key:release()), name))
      fh:close()
    end
  end
  local option = PREVIEW_MODIFIERS[name]
  if not option then return 2 end
  local context = env.engine.context
  local want = not key:release()
  if context:get_option(option) == want then return 2 end

  -- set_option 會讓 librime 重跑 RefreshNonConfirmedComposition（engine.cc 的 OnOptionUpdate），
  -- 而那會把高亮歸零。先記下再還原，否則選到第 3 個候選時一按 Shift 就跳回第 1 個。
  local index = 0
  pcall(function()
    local composition = context.composition
    if composition and not composition:empty() then
      index = composition:back().selected_index or 0
    end
  end)
  context:set_option(option, want)
  if index > 0 and context:has_menu() then
    pcall(function() context:highlight(index) end)
  end
  return 2   -- 不吃掉按鍵，修飾鍵的其他用途照常
end

-- Control + 數字：直接上屏阿拉伯數字。
-- 只在「沒有組字」時攔截：組字中 Control+1~6 是選第 N 個候選，而且 Tab 與 Shift+Q 等鍵
-- 都是轉送成 Control+N 來選字的，攔下來會把選字功能整組吃掉。
local CONTROL_DIGITS = {}
for digit = 0, 9 do CONTROL_DIGITS["Control+" .. digit] = tostring(digit) end

function digit_commit(key, env)
  if key:release() then return 2 end
  local digit = CONTROL_DIGITS[key:repr()]
  if not digit then return 2 end
  local context = env.engine.context
  if context:is_composing() then return 2 end
  env.engine:commit_text(digit)
  return 1
end

-- 注意：Squirrel 0.18 的 SquirrelInputController.m 在 NSEventTypeKeyDown 一開始就有
-- `if (modifiers & NSEventModifierFlagCommand) break;`（註解為 ignore Command+X hotkeys），
-- 所有「Command＋其他鍵」都不會送進 librime，因此 Super+Right 永遠觸發不到。
-- 簡體上屏改用 Option+→（Alt+Right）；Control+→ 不可用，會被 macOS 的切換桌面空間攔走。
local SIMPLIFIED_KEYS = { ["Alt+Right"] = true, ["Super+Right"] = true }

-- Tab：接受目前第一個英文候選（ZingIME 式的「按 Tab 表態為英文」）。
-- 沒有英文候選時回傳 2，讓 key_binder 的 Tab → Control+1 照舊接手。
function english_commit(key, env)
  if key:repr() ~= "Tab" then
    return 2
  end
  local context = env.engine.context
  if not context:has_menu() or not first_english_text then
    return 2
  end
  env.engine:commit_text(first_english_text)
  first_english_text = nil
  context:clear()
  return 1
end

-- 與「按住修飾鍵看讀音」對稱：按住 Shift 看注音 → Shift+→ 輸出；按住 Control 看拼音 → Control+→ 輸出。
-- Control+→ 需要先在系統設定停用「調度中心 → 移到右邊一個空間」，否則會被 macOS 攔走；
-- Option+← 不受影響，保留當後備。
local READING_KEYS = {
  ["Shift+Right"]   = "bopomofo",  -- 選中候選的完整注音
  ["Control+Right"] = "pinyin",    -- 選中候選的漢語拼音
  ["Alt+Left"]      = "pinyin",    -- 同上，不需改系統設定的後備鍵
  ["Alt+Up"]        = "raw",       -- 所打鍵碼原樣轉注音符號（要單獨打出「ㄅ」就用這個）
}

function special_commit(key, env)
  local repr = key:repr()
  local mode = READING_KEYS[repr]
  local to_simplified = SIMPLIFIED_KEYS[repr]
  if not mode and not to_simplified then
    return 2
  end

  local context = env.engine.context
  if not context:has_menu() then
    return 2
  end
  local candidate = context:get_selected_candidate()
  if not candidate then
    return 2
  end

  if to_simplified then
    env.engine:commit_text(tw_to_s:convert(candidate.text))
    context:clear()
    return 1
  end

  if mode == "raw" then
    local typed = raw_to_bopomofo(context.input)
    if not typed then return 2 end
    env.engine:commit_text(typed)
    context:clear()
    return 1
  end

  local reading = reading_of(candidate.text, mode)
  if reading then
    env.engine:commit_text(reading)
    context:clear()
    return 1
  end

  -- 反查不到讀音（英文候選、符號、內嵌注音文等）。
  -- 注音沿用原本的行為：把打下去的鍵碼直接轉成注音符號；拼音則不處理，交回給後面的元件。
  if mode == "bopomofo" then
    local typed = raw_to_bopomofo(context.input)
    if typed then
      env.engine:commit_text(typed)
      context:clear()
      return 1
    end
  end
  return 2
end
