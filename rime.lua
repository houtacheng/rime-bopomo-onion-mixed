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
        for _, value in ipairs(values) do
          yield(Candidate("date_symbol", candidate.start, candidate._end, value, "〔日期〕"))
        end
        yield(candidate)
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

function simplified_hint(input, env)
  for candidate in input:iter() do
    local simplified = tw_to_s:convert(candidate.text)
    local comment = candidate.comment
    if simplified ~= candidate.text then
      comment = "〔" .. simplified .. "〕"
    end
    yield(ShadowCandidate(candidate, candidate.type, candidate.text, comment))
  end
end

function simplified_commit(key, env)
  local representation = key:repr()
  if representation ~= "Shift+Right" and representation ~= "Control+Shift+Right" then
    return 2
  end

  local context = env.engine.context
  if not context:has_menu() then
    return 2
  end

  if representation == "Shift+Right" then
    local bopomofo = raw_to_bopomofo(context.input)
    if not bopomofo then return 2 end
    env.engine:commit_text(bopomofo)
  else
    local candidate = context:get_selected_candidate()
    if not candidate then return 2 end
    env.engine:commit_text(tw_to_s:convert(candidate.text))
  end
  context:clear()
  return 1
end
