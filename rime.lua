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
  ["株"] = { "㈱" }, ["滿"] = { "🈵" },

  -- 溫度與角度
  ["度"] = { "°", "℃", "℉" }, ["角度"] = { "°" }, ["溫度"] = { "℃", "℉" },
  -- 長度
  ["微米"] = { "㎛" }, ["奈米"] = { "㎚" },
  ["英吋"] = { "″", "in" }, ["英尺"] = { "′", "ft" }, ["英里"] = { "mi" },
  ["平方公里"] = { "㎢" }, ["平方公分"] = { "㎠" }, ["立方公分"] = { "㎤", "cc" },
  -- 容量與重量
  ["公升"] = { "ℓ", "L" }, ["毫升"] = { "㎖", "ml" }, ["公噸"] = { "t" },
  ["毫克"] = { "㎎" }, ["磅"] = { "lb" }, ["盎司"] = { "oz" },
  -- 電與功率
  ["瓦"] = { "W" }, ["千瓦"] = { "㎾" }, ["歐姆"] = { "Ω" },
  ["伏特"] = { "V" }, ["安培"] = { "A" }, ["分貝"] = { "㏈" },
  -- 頻率與時間
  ["赫茲"] = { "㎐" }, ["千赫"] = { "㎑" }, ["兆赫"] = { "㎒" }, ["吉赫"] = { "㎓" },
  ["毫秒"] = { "㎳" }, ["微秒"] = { "㎲" }, ["奈秒"] = { "㎱" },
  -- 比例與其他
  ["百分比"] = { "%", "％" }, ["千分比"] = { "‰" }, ["萬分比"] = { "‱" },
  ["帕"] = { "㎩" }, ["卡路里"] = { "㎈", "cal" },

  -- 貨幣。符號在前、代碼在後，因為打字時多半是要符號。
  -- 不收「元」「圓」這種單字，太常見會在不相干的詞上跳出來。
  ["台幣"] = { "NT$", "TWD" }, ["新台幣"] = { "NT$", "TWD" },
  ["美金"] = { "$", "US$", "USD" }, ["美元"] = { "$", "US$", "USD" },
  ["加幣"] = { "C$", "CAD" }, ["加元"] = { "C$", "CAD" },
  ["日圓"] = { "¥", "JPY", "円" }, ["日元"] = { "¥", "JPY", "円" },
  ["歐元"] = { "€", "EUR" }, ["英鎊"] = { "£", "GBP" },
  ["人民幣"] = { "¥", "CNY", "RMB" }, ["港幣"] = { "HK$", "HKD" },
  ["韓元"] = { "₩", "KRW" }, ["韓圜"] = { "₩", "KRW" },
  ["澳幣"] = { "A$", "AUD" }, ["澳元"] = { "A$", "AUD" },
  ["紐幣"] = { "NZ$", "NZD" }, ["星幣"] = { "S$", "SGD" },
  ["新加坡幣"] = { "S$", "SGD" }, ["馬幣"] = { "RM", "MYR" },
  ["泰銖"] = { "฿", "THB" }, ["越南盾"] = { "₫", "VND" },
  ["披索"] = { "₱", "PHP" }, ["盧比"] = { "₹", "INR" },
  ["盧布"] = { "₽", "RUB" }, ["里拉"] = { "₺", "TRY" },
  ["法郎"] = { "₣", "CHF" }, ["瑞士法郎"] = { "CHF", "₣" },
  ["比特幣"] = { "₿", "BTC" }, ["以太幣"] = { "Ξ", "ETH" },
  ["美分"] = { "¢" }, ["貨幣"] = { "¤" },
}

-- 個人詞條：從 lua/personal_phrases.lua 併入 symbols。
-- 那個檔案不進版控，所以電話、住址這類東西留在本機，設定本身仍可公開分享。
-- 檔案不存在就跳過，不影響其他功能。
do
  for _, mod in ipairs({ "personal_phrases", "lua.personal_phrases" }) do
    local ok, personal = pcall(require, mod)
    if ok and type(personal) == "table" then
      for word, values in pairs(personal) do symbols[word] = values end
      break
    end
  end
end

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

---------------------------------------------------------------------------
-- 相對時間：一小時後、十分鐘前、後天、三個月後…
---------------------------------------------------------------------------
local UTF8_CHAR = (utf8 and utf8.charpattern) or "[\0-\127\194-\244][\128-\191]*"

local CN_DIGIT = { ["零"]=0, ["〇"]=0, ["一"]=1, ["二"]=2, ["兩"]=2, ["三"]=3,
                   ["四"]=4, ["五"]=5, ["六"]=6, ["七"]=7, ["八"]=8, ["九"]=9 }
local CN_UNIT = { ["十"]=10, ["百"]=100 }

-- 支援阿拉伯數字與中文數字（十、十五、二十五、一百二十）。
-- 空字串視為 1，所以「小時後」等同「一小時後」。
local function chinese_to_number(text)
  if text == "" then return 1 end
  if text == "半" then return 0.5 end
  local n = tonumber(text)
  if n then return n end
  local total, section, seen = 0, 0, false
  for ch in text:gmatch(UTF8_CHAR) do
    local digit, unit = CN_DIGIT[ch], CN_UNIT[ch]
    if digit then
      section = digit; seen = true
    elseif unit then
      if section == 0 then section = 1 end   -- 「十五」開頭的十
      total = total + section * unit; section = 0; seen = true
    else
      return nil                              -- 出現非數字字元就不是相對時間
    end
  end
  if not seen then return nil end
  return total + section
end

local REL_DIRECTIONS = { {"之後", 1}, {"以後", 1}, {"後", 1},
                         {"之前", -1}, {"以前", -1}, {"前", -1} }

-- kind：sec 用秒數加減，其餘交給 os.time 做日曆進位（跨月跨年才會正確）
local REL_UNITS = {
  {"個小時","sec",3600}, {"小時","sec",3600}, {"鐘頭","sec",3600}, {"時","sec",3600},
  {"分鐘","sec",60}, {"分","sec",60},
  {"秒鐘","sec",1}, {"秒","sec",1},
  {"個星期","day",7}, {"個禮拜","day",7}, {"星期","day",7}, {"禮拜","day",7}, {"週","day",7},
  {"天","day",1}, {"日","day",1},
  {"個月","month",1}, {"月","month",1},
  {"年","year",1},
}

-- 一律以位元組長度由長到短比對，否則「分鐘」會先被「分」吃掉、「個月」被「月」吃掉
table.sort(REL_DIRECTIONS, function(a, b) return #a[1] > #b[1] end)
table.sort(REL_UNITS, function(a, b) return #a[1] > #b[1] end)

local function time_formats(timestamp)
  local d = os.date("*t", timestamp)
  local today = os.date("*t")
  local same_day = d.year == today.year and d.month == today.month and d.day == today.day
  local out = { os.date("%H:%M", timestamp), os.date("%H:%M:%S", timestamp) }
  if same_day then
    table.insert(out, string.format("%d 點 %d 分", d.hour, d.min))
  else
    -- 跨日了，只給時分會看不出是哪天
    table.insert(out, os.date("%Y-%m-%d %H:%M", timestamp))
    table.insert(out, string.format("%d 月 %d 日 %d 點 %d 分", d.month, d.day, d.hour, d.min))
  end
  table.insert(out, os.date("%Y-%m-%d %H:%M:%S", timestamp))
  return out
end

-- 某月有幾天：下個月的第 0 日就是這個月的最後一日，os.time 會自行正規化
local function days_in_month(year, month)
  return os.date("*t", os.time({ year = year, month = month + 1, day = 0, hour = 12 })).day
end

local FIXED_DAYS = { ["後天"] = 2, ["大後天"] = 3, ["前天"] = -2, ["大前天"] = -3 }

-- 在時間格式中插入「原詞＋時刻」的併排形式，與下面的日期版同一套做法。
local function time_formats_with_word(word, timestamp)
  local values = time_formats(timestamp)
  local clock = os.date("%H:%M", timestamp)
  table.insert(values, 3, word .. "（" .. clock .. "）")
  table.insert(values, 4, word .. " " .. clock)
  return values
end

-- 在日期格式中插入「原詞＋日期」的併排形式。
-- 放在最常用的兩個純日期格式之後（第 3～5 位），加上原詞本身剛好佔滿第一頁六格。
-- 代價是純 YYYYMMDD 被擠到第二頁；想換回來就調整這裡的插入位置。
local function date_formats_with_word(word, timestamp)
  local values = date_formats(timestamp)
  local d = os.date("*t", timestamp)
  local plain = string.format("%04d.%02d.%02d", d.year, d.month, d.day)
  local dated = string.format("%04d.%02d.%02d(%s)", d.year, d.month, d.day, weekday[d.wday])
  local compact = string.format("%04d%02d%02d", d.year, d.month, d.day)
  table.insert(values, 3, word .. "（" .. plain .. "）")
  table.insert(values, 4, word .. " " .. dated)
  table.insert(values, 5, word .. " " .. compact)
  return values
end

local function relative_time(text)
  local days = FIXED_DAYS[text]
  if days then return date_formats_with_word(text, os.time() + days * 86400), "〔日期〕" end

  local sign, rest
  for _, entry in ipairs(REL_DIRECTIONS) do
    local suffix = entry[1]
    if #text > #suffix and text:sub(-#suffix) == suffix then
      sign, rest = entry[2], text:sub(1, #text - #suffix)
      break
    end
  end
  if not sign then return nil end

  for _, entry in ipairs(REL_UNITS) do
    local unit, kind, scale = entry[1], entry[2], entry[3]
    if #rest >= #unit and rest:sub(-#unit) == unit then
      local quantity = rest:sub(1, #rest - #unit)
      -- 單字單位不接受省略數量：「日後」「年前」「月前」都是常用詞，不是在算日子。
      -- 兩個字以上的單位沒有這個問題（沒有「小時後」這種詞），所以「小時後」仍等同
      -- 「一小時後」。#unit 以位元組算，一個漢字是 3 個。
      if quantity == "" and #unit <= 3 then return nil end
      local count = chinese_to_number(quantity)
      if not count then return nil end
      local amount = sign * count * scale
      -- 數量可以是小數（半天、半個月、1.5 年）。os.time 與 os.date 的欄位必須是整數，
      -- 給小數會直接報錯（field 'day' is not an integer），連帶讓整個濾鏡中斷、候選消失。
      -- 所以先往更細的單位換算，換到整數為止：年→月→天→秒。
      -- 因此半年是六個月、半個月是十五天、半天是十二小時（結果變成時刻而不是日期）。
      if kind == "year" and amount % 1 ~= 0 then
        amount, kind = amount * 12, "month"
      end
      if kind == "month" and amount % 1 ~= 0 then
        amount, kind = amount * 30, "day"
      end
      if kind == "day" and amount % 1 ~= 0 then
        amount, kind = amount * 86400, "sec"
      end
      amount = math.floor(amount)
      local now = os.time()
      if kind == "sec" then
        return time_formats_with_word(text, now + amount), "〔時間〕"
      end
      local d = os.date("*t", now)
      if kind == "day" then
        d.day = d.day + amount                -- 天數交給 os.time 正規化即可
      else
        if kind == "month" then
          local total = d.year * 12 + (d.month - 1) + amount
          d.year = math.floor(total / 12)
          d.month = total % 12 + 1
        else
          d.year = d.year + amount
        end
        -- 月底要截斷，不能讓它溢出。1/31 加一個月，os.time 會算成 3/3，
        -- 但一般人期望的是 2/28。
        d.day = math.min(d.day, days_in_month(d.year, d.month))
      end
      return date_formats_with_word(text, os.time(d)), "〔日期〕"
    end
  end
  return nil
end

local function extras_for(text)
  local now = os.time()
  local d = os.date("*t", now)
  if text == "今年" then return year_formats(d.year) end
  if text == "去年" then return year_formats(d.year - 1) end
  if text == "明年" then return year_formats(d.year + 1) end
  if text == "今天" then return date_formats_with_word(text, now), "〔日期〕" end
  if text == "昨天" then return date_formats_with_word(text, now - 86400), "〔日期〕" end
  if text == "明天" then return date_formats_with_word(text, now + 86400), "〔日期〕" end
  if text == "現在" then
    return time_formats_with_word(text, now), "〔時間〕"
  end
  if text == "時區" then
    return { os.date("%Z", now), "UTC" .. os.date("%z", now) }, "〔時間〕"
  end
  local relative, label = relative_time(text)
  if relative then return relative, label end
  return symbols[text]
end

function date_symbol_extras(input, env)
  local expanded = {}
  for candidate in input:iter() do
    local values, label = extras_for(candidate.text)
    if values and not expanded[candidate.text] then
      expanded[candidate.text] = true
      label = label or (date_triggers[candidate.text] and "〔日期〕" or "〔日期／符號〕")
      yield(candidate)
      for _, value in ipairs(values) do
        yield(Candidate("date_symbol", candidate.start, candidate._end, value, label))
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

---------------------------------------------------------------------------
-- 計算與單位換算：Ctrl + \ 之後打算式（12+5*3）或「數字＋單位」（100cm、98f、5kg）
---------------------------------------------------------------------------

-- 只認四則運算的小剖析器。不用 load()——那等於把打下去的字當程式碼執行。
local function evaluate(expression)
  local text = expression:gsub(",", "")      -- 千分位逗號忽略
  local pos = 1
  local parse_expression

  local function parse_atom()
    local ch = text:sub(pos, pos)
    if ch == "(" then
      pos = pos + 1
      local value = parse_expression()
      if not value or text:sub(pos, pos) ~= ")" then return nil end
      pos = pos + 1
      return value
    end
    if ch == "-" then pos = pos + 1; local value = parse_atom(); return value and -value end
    if ch == "+" then pos = pos + 1; return parse_atom() end
    local number = text:match("^%d+%.?%d*", pos) or text:match("^%.%d+", pos)
    if not number then return nil end
    pos = pos + #number
    return tonumber(number)
  end

  local function parse_power()                -- 次方右結合：2^3^2 是 2^(3^2)
    local base = parse_atom()
    if not base then return nil end
    if text:sub(pos, pos) == "^" then
      pos = pos + 1
      local exponent = parse_power()
      if not exponent then return nil end
      return base ^ exponent
    end
    return base
  end

  local function parse_term()
    local value = parse_power()
    if not value then return nil end
    while true do
      local op = text:sub(pos, pos)
      if op ~= "*" and op ~= "/" and op ~= "%" then return value end
      pos = pos + 1
      local rhs = parse_power()
      if not rhs then return nil end
      if op == "*" then
        value = value * rhs
      else
        if rhs == 0 then return nil end       -- 除以零不給候選，勝過吐出 inf
        value = (op == "/") and (value / rhs) or (value % rhs)
      end
    end
  end

  parse_expression = function()
    local value = parse_term()
    if not value then return nil end
    while true do
      local op = text:sub(pos, pos)
      if op ~= "+" and op ~= "-" then return value end
      pos = pos + 1
      local rhs = parse_term()
      if not rhs then return nil end
      value = (op == "+") and (value + rhs) or (value - rhs)
    end
  end

  local result = parse_expression()
  if not result or pos <= #text then return nil end   -- 有剩字＝不是合法算式
  return result
end

local function format_number(value)
  if type(value) ~= "number" or value ~= value then return nil end
  if value == math.huge or value == -math.huge then return nil end
  local rounded = math.floor(value + 0.5)
  if math.abs(value - rounded) < 1e-9 and math.abs(value) < 1e15 then
    return string.format("%d", rounded)
  end
  if math.abs(value) < 1e-4 or math.abs(value) >= 1e12 then
    return (string.format("%.4g", value))
  end
  local out = string.format("%.4f", value):gsub("0+$", ""):gsub("%.$", "")
  return out
end

-- 單位：factor 是換算到基準單位的倍率，order 是候選的排列順序。
-- 順序刻意把跨制的單位放前面——會想換算多半就是因為兩制不同。
local UNIT_FAMILIES = {
  {
    order = { "in", "ft", "m", "cm", "mm", "km", "yd", "mi" },
    factors = { mm = 0.001, cm = 0.01, m = 1, km = 1000,
                ["in"] = 0.0254, ft = 0.3048, yd = 0.9144, mi = 1609.344 },
  },
  {
    order = { "lb", "oz", "kg", "g", "t", "mg" },
    factors = { mg = 1e-6, g = 0.001, kg = 1, t = 1000, oz = 0.0283495231, lb = 0.45359237 },
  },
  {
    order = { "l", "ml", "gal", "floz", "cc" },
    factors = { ml = 0.001, cc = 0.001, l = 1, gal = 3.785411784, floz = 0.0295735296 },
  },
  {
    order = { "ping", "m2", "ft2", "km2", "acre", "ha" },
    factors = { m2 = 1, km2 = 1e6, ha = 10000, acre = 4046.8564224,
                ft2 = 0.09290304, ping = 3.305785 },   -- 坪＝六尺見方
  },
  {
    order = { "kmh", "mph", "ms", "knot" },
    factors = { ms = 1, kmh = 1 / 3.6, mph = 0.44704, knot = 0.514444444 },
  },
}

local UNIT_ALIASES = {
  inch = "in", inches = "in", foot = "ft", feet = "ft", yard = "yd", mile = "mi",
  meter = "m", metre = "m", pound = "lb", lbs = "lb", ounce = "oz", gram = "g",
  litre = "l", liter = "l", gallon = "gal", ["m^2"] = "m2", sqm = "m2", sqft = "ft2",
  celsius = "c", fahrenheit = "f", kelvin = "k", kph = "kmh", knots = "knot",
}

-- 溫度不是倍率關係，得各自換算
local function temperature_conversions(value, unit)
  local celsius
  if unit == "c" then celsius = value
  elseif unit == "f" then celsius = (value - 32) * 5 / 9
  elseif unit == "k" then celsius = value - 273.15
  else return nil end
  local out = {}
  local targets = { c = celsius, f = celsius * 9 / 5 + 32, k = celsius + 273.15 }
  local labels = { c = "℃", f = "℉", k = "K" }
  for _, target in ipairs({ "c", "f", "k" }) do
    if target ~= unit then
      local text = format_number(targets[target])
      if text then out[#out + 1] = text .. " " .. labels[target] end
    end
  end
  return out
end

-- 匯率。輸入法本身不連外：只讀 lua/rates.lua，那個檔案由 generate/rates.py 產生。
-- 格式是 { date = "2026-09-15", base = "USD", rates = { TWD = 31.5, ... } }。
-- 檔案不在就沒有貨幣候選，其他換算完全不受影響。
local RATES = (function()
  for _, mod in ipairs({ "rates", "lua.rates" }) do
    local ok, data = pcall(require, mod)
    if ok and type(data) == "table" and type(data.rates) == "table" then return data end
  end
  return nil
end)()

local CURRENCY_ORDER = { "TWD", "USD", "CAD", "JPY", "EUR", "CNY", "GBP", "HKD", "KRW", "AUD" }
local NO_DECIMALS = { JPY = true, KRW = true, VND = true }   -- 這幾種本來就不用小數

local function group_digits(text)
  local sign, integer, rest = text:match("^(%-?)(%d+)(.*)$")
  if not integer then return text end
  local grouped = integer:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  return sign .. grouped .. rest
end

-- 錢跟量不一樣：兩位小數就夠，而且要有千分位才讀得出位數
local function format_money(value, code)
  if value ~= value or value == math.huge or value == -math.huge then return nil end
  local text = string.format(NO_DECIMALS[code] and "%.0f" or "%.2f", value)
  return group_digits(text)
end

local function currency_conversions(value, code)
  if not RATES then return nil end
  code = code:upper()
  local rate = RATES.rates[code]
  if not rate or rate == 0 then return nil end
  local base = value / rate                   -- 先換回基準幣別再換出去
  local out = {}
  for _, target in ipairs(CURRENCY_ORDER) do
    local target_rate = RATES.rates[target]
    if target_rate and target ~= code then
      local text = format_money(base * target_rate, target)
      if text then out[#out + 1] = text .. " " .. target end
    end
  end
  if #out == 0 then return nil end
  -- 匯率會過期，所以把日期標在候選旁邊，不讓它悄悄給出舊數字
  return out, "〔匯率 " .. tostring(RATES.date or "?") .. "〕"
end

-- 單位或貨幣都試一次，回傳候選、註解、以及要顯示的單位寫法
-- （貨幣代碼慣例大寫，度量單位維持小寫）
local conversions_for

local function unit_conversions(value, unit)
  unit = UNIT_ALIASES[unit] or unit
  local temperature = temperature_conversions(value, unit)
  if temperature then return temperature end
  for _, family in ipairs(UNIT_FAMILIES) do
    local factor = family.factors[unit]
    if factor then
      local base = value * factor
      local out = {}
      for _, target in ipairs(family.order) do
        if target ~= unit then
          local text = format_number(base / family.factors[target])
          if text then out[#out + 1] = text .. " " .. target end
        end
      end
      return out
    end
  end
  return nil
end

conversions_for = function(value, unit)
  local metric = unit_conversions(value, unit:lower())
  if metric and #metric > 0 then return metric, "〔換算〕", unit:lower() end
  local money, label = currency_conversions(value, unit)
  if money then return money, label, unit:upper() end
  return nil
end

function number_formats(input, segment, env)
  if input == "#" then
    yield(Candidate("number", segment.start, segment._end, "數字輸入", "繼續輸入阿拉伯數字"))
    return
  end
  local body = input:match("^#(.+)$")
  if not body then return end

  -- 數字＋單位 → 換算（100cm、5kg、98f）
  local amount, unit = body:match("^([%d%.,]+)(%a[%a%d^]*)$")
  if amount then
    local conversions, label = conversions_for(tonumber((amount:gsub(",", ""))), unit)
    if conversions then
      for _, text in ipairs(conversions) do
        yield(Candidate("number", segment.start, segment._end, text, label))
      end
      return
    end
  end

  -- 算式＋單位 → 把整條鏈顯示出來：100+20=120USD=166.79 CAD
  -- 算過的式子留在候選裡，才看得出這個數字是怎麼來的。
  local expression, expression_unit = body:match("^([%d%.,%+%-%*/%%%^%(%)]+)(%a[%a%d^]*)$")
  if expression and expression:find("[%+%-%*/%%%^%(%)]") then
    local value = evaluate(expression)
    local shown = value and format_number(value)
    if shown then
      local conversions, label, display = conversions_for(value, expression_unit)
      if conversions then
        local head = expression .. "=" .. shown .. display .. "="
        for _, text in ipairs(conversions) do
          yield(Candidate("number", segment.start, segment._end, head .. text, label))
        end
        return
      end
    end
  end

  -- 數字夾標點（1.、2026/09/15、3-5）：原樣優先，因為多半是日期或區間；
  -- 但它同時也可能是算式，所以把計算結果附在後面。
  local mixed = body:match("^[%d][%d%.,/%-]*$")
  if mixed and body:find("[^%d]") then
    yield(Candidate("number", segment.start, segment._end, body, "數字"))
    local value = format_number(evaluate(body))
    if value and value ~= body then
      yield(Candidate("number", segment.start, segment._end, value, "〔計算〕"))
    end
    return
  end

  -- 明確的算式（有 + * ^ ( ) %）：計算結果優先
  if body:find("[%+%*%^%(%)%%]") then
    local value = format_number(evaluate(body))
    if value then
      yield(Candidate("number", segment.start, segment._end, value, "〔計算〕"))
    end
    return
  end

  local raw = body:match("^(%d+)$")
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

---------------------------------------------------------------------------
-- 中文 → 英文釋義
--
-- english_gloss.txt 由 CC-CEDICT 產生，依 UTF-8 位元組排序。
-- 11 萬筆做成 Lua table 會佔十幾 MB，所以改成對檔案做二分搜尋：
-- 每次查詢約 17 次 seek，只在按住 Option 時才會用到。
---------------------------------------------------------------------------
-- 使用者資料目錄：macOS 是 ~/Library/Rime，Windows 是 %APPDATA%\Rime。
-- librime-lua 有暴露 rime_api.get_user_data_dir()，用它就不必判斷平台。
-- 斜線在 Windows 的檔案 API 也通，不需要換成反斜線。
local function user_data_path(name)
  local dir
  if rime_api and rime_api.get_user_data_dir then
    dir = rime_api.get_user_data_dir()
  end
  if not dir or dir == "" then   -- 舊版 librime-lua 沒有這個函式時的退路
    dir = (os.getenv("APPDATA") and os.getenv("APPDATA") .. "/Rime")
       or (os.getenv("HOME") .. "/Library/Rime")
  end
  return dir .. "/" .. name
end

-- 排錯用：建立這個檔案後，按下的修飾鍵 repr 會被記錄下來；刪掉檔案即停止。
local DEBUG_KEYS = (function()
  local path = user_data_path("tools/.debug-keys")
  local fh = io.open(path, "r")
  if fh then fh:close() return path end
  return nil
end)()

local GLOSS_PATH = user_data_path("english_gloss.txt")
local gloss_handle, gloss_size

local function gloss_file()
  if gloss_handle == nil then
    local fh = io.open(GLOSS_PATH, "rb")
    if fh then
      gloss_size = fh:seek("end")
      gloss_handle = fh
    else
      gloss_handle, gloss_size = false, 0
    end
  end
  return gloss_handle or nil
end

local function gloss_of(word)
  local fh = gloss_file()
  if not fh or not word or word == "" then return nil end
  local lo, hi = 0, gloss_size
  while lo < hi do
    local mid = (lo + hi) // 2
    fh:seek("set", mid)
    if mid > 0 then fh:read("l") end      -- 丟掉被切半的那行
    local line = fh:read("l")
    if not line then hi = mid
    else
      local key = line:match("^([^\t]*)")
      if key and key < word then lo = fh:seek() else hi = mid end
    end
  end
  -- lo 一定落在行首。往後掃幾行確認（同一個詞不會佔超過幾行）
  fh:seek("set", lo)
  for _ = 1, 4 do
    local line = fh:read("l")
    if not line then return nil end
    local key, text = line:match("^([^\t]+)\t(.+)$")
    if key == word then return text end
    if key and key > word then return nil end
  end
  return nil
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
  { option = "preview_english",  mode = "english",  open = "〈", close = "〉" },
}

function simplified_hint(input, env)
  local context = env.engine.context
  local preview
  for _, entry in ipairs(PREVIEW_OPTIONS) do
    if context:get_option(entry.option) then preview = entry break end
  end
  if DEBUG_KEYS then
    local fh = io.open(DEBUG_KEYS, "a")
    if fh then
      fh:write(string.format("%s   [filter] preview=%s  bopomofo=%s pinyin=%s english=%s\n",
        os.date("%H:%M:%S"), preview and preview.mode or "nil",
        tostring(context:get_option("preview_bopomofo")),
        tostring(context:get_option("preview_pinyin")),
        tostring(context:get_option("preview_english"))))
      fh:close()
    end
  end

  local logged = false
  for candidate in input:iter() do
    local comment = candidate.comment
    if preview then
      local reading = (preview.mode == "english")
        and gloss_of(candidate.text)
        or reading_of(candidate.text, preview.mode)
      if DEBUG_KEYS and not logged then
        logged = true
        local fh = io.open(DEBUG_KEYS, "a")
        if fh then
          fh:write(string.format("  [cand] mode=%s text=%q reading=%q 原註解=%q\n",
            preview.mode, tostring(candidate.text), tostring(reading),
            tostring(candidate.comment)))
          fh:close()
        end
      end
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

-- 按一下 Shift 看注音、Control 看漢語拼音、Option 看英文釋義；再按一次關閉。

local PREVIEW_MODIFIERS = {
  Shift_L = "preview_bopomofo", Shift_R = "preview_bopomofo",
  Control_L = "preview_pinyin", Control_R = "preview_pinyin",
  Alt_L = "preview_english",    Alt_R = "preview_english",
}

-- 某個按鍵事件身上是否還帶著開啟預覽的那個修飾位。用來認出「這是組合鍵」。
local PREVIEW_MODIFIER_HELD = {
  preview_bopomofo = function(key) return key:shift() end,
  preview_pinyin   = function(key) return key:ctrl() end,
  preview_english  = function(key) return key:alt() end,
}

-- repr() 會把所有修飾鍵前綴串在鍵名前（key_event.cc 的 KeyEvent::repr），
-- 按下 Shift 時事件同時帶著 Shift_L 鍵碼與 shift 修飾位，repr 是「Shift+Shift_L」而非「Shift_L」。
-- 所以只取最後一段鍵名，按下／放開一律用 key:release() 判斷。
local function bare_key_name(key)
  local repr = key:repr()
  return repr:match("([^+]+)$") or repr
end

-- set_option 會讓 librime 重跑 RefreshNonConfirmedComposition（engine.cc 的
-- OnOptionUpdate），而那會把高亮歸零。先記下再還原。
local function keep_highlight(context, apply)
  local index = 0
  pcall(function()
    local composition = context.composition
    if composition and not composition:empty() then
      index = composition:back().selected_index or 0
    end
  end)
  apply()
  if index > 0 and context:has_menu() then
    pcall(function() context:highlight(index) end)
  end
end

-- 修飾鍵同時是選字鍵的前半段：本方案的選字、翻頁、移位全綁在 Shift+字母／Shift+方向鍵上
-- （Shift+Q、Shift+K、Shift+←…），而按組合鍵時作業系統一定會先送一個單獨的修飾鍵事件，
-- 於是每次選字都順手把預覽切換了一次——提示會忽然從簡體變成注音，而且若停在「開」，
-- 接下來按 → 就不是翻頁，而是把注音文上屏。
--
-- 作法：切換時先記下原本的狀態，下一個按鍵若是非修飾鍵、身上卻還帶著同一個修飾位，
-- 就代表剛才那下是組合鍵的前半段，把狀態原樣還原。
-- 兩個平台都成立——不依賴放開事件何時抵達（小狼毫是按下與放開同時送達）。
local pending_preview = nil   -- { option = 剛切換的選項, state = 切換前的三個選項狀態 }

-- 使用者是不是真的按著 Control。判斷方式同上：實體按下時作業系統會先送一個單獨的
-- Control_L／Control_R 事件，key_binder 轉送出來的 Control+N（Shift+Q、Tab 選字）
-- 前面沒有那個事件，前一個按鍵身上也不帶 ctrl。digit_commit 靠這個分辨「要打數字」
-- 與「要選候選」。不看放開事件，所以小狼毫的按下與放開同時送達也不影響。
local control_held = false

local function preview_state(context)
  local state = {}
  for _, entry in ipairs(PREVIEW_OPTIONS) do
    state[entry.option] = context:get_option(entry.option)
  end
  return state
end

local function toggle_preview(context, option, on)
  pending_preview = { option = option, state = preview_state(context) }
  keep_highlight(context, function()
    -- 切換模式時先關掉別的，免得兩個同時開著
    for _, entry in ipairs(PREVIEW_OPTIONS) do
      if entry.option ~= option and context:get_option(entry.option) then
        context:set_option(entry.option, false)
      end
    end
    context:set_option(option, on)
  end)
end

local function undo_preview(context)
  local state = pending_preview.state
  pending_preview = nil
  keep_highlight(context, function()
    for option, value in pairs(state) do
      if context:get_option(option) ~= value then
        context:set_option(option, value)
      end
    end
  end)
end

function reading_preview(key, env)
  local name = bare_key_name(key)
  -- 排錯用：建立 tools/.debug-keys 後，所有按鍵的 repr 會被記錄下來。
  -- 只記非單一字元的鍵（修飾鍵與組合鍵），免得每打一個注音就寫一行。
  if DEBUG_KEYS then
    local repr = key:repr()
    if #repr > 1 then
      local fh = io.open(DEBUG_KEYS, "a")
      if fh then
        fh:write(string.format("%s %-28s release=%-5s bare=%-12s shift=%s ctrl=%s alt=%s super=%s\n",
                               os.date("%H:%M:%S"), repr, tostring(key:release()), name,
                               tostring(key:shift()), tostring(key:ctrl()),
                               tostring(key:alt()), tostring(key:super())))
        fh:close()
      end
    end
  end

  local context = env.engine.context
  local option = PREVIEW_MODIFIERS[name]

  if not key:release() then
    if name == "Control_L" or name == "Control_R" then
      control_held = true
    elseif not option then
      control_held = control_held and key:ctrl()
    end
  end

  -- 剛才那下修飾鍵其實是組合鍵的前半段？把它還原（見上方說明）。
  -- 修飾鍵自己的事件（含放開）不算，否則小狼毫立刻送達的放開就會把待判狀態吃掉。
  if pending_preview and not option then
    local undone = PREVIEW_MODIFIER_HELD[pending_preview.option](key)
    if undone then undo_preview(context) else pending_preview = nil end
    if DEBUG_KEYS then
      local fh = io.open(DEBUG_KEYS, "a")
      if fh then
        fh:write(string.format("%s   [proc] %s（%s）\n", os.date("%H:%M:%S"),
          undone and "還原：剛才是組合鍵" or "確認：剛才是單獨按修飾鍵", name))
        fh:close()
      end
    end
  end

  -- 修飾鍵：按下時切換預覽。
  --
  -- 不能用「放開就關掉」。Windows 的小狼毫不管按多久，按下與放開都在同一瞬間送達
  -- （實測時間戳完全相同），那樣預覽會開了又立刻關掉，只看得到一閃。
  -- 改成按一下切換、再按一次關閉，兩個平台行為一致。
  -- 沒在組字時清掉殘留的預覽狀態，否則上次留下的模式會跟到下一次輸入
  if not context:is_composing() then
    for _, entry in ipairs(PREVIEW_OPTIONS) do
      if context:get_option(entry.option) then
        context:set_option(entry.option, false)
      end
    end
  end

  if option then
    if key:release() then return 2 end
    -- 再按一次同一個修飾鍵就關掉，不必等別的鍵
    local on = not context:get_option(option)
    toggle_preview(context, option, on)
    if DEBUG_KEYS then
      local fh = io.open(DEBUG_KEYS, "a")
      if fh then
        fh:write(string.format("%s   [proc] %s %s  讀回=%s  has_menu=%s\n",
          os.date("%H:%M:%S"), on and "開啟" or "關閉", option,
          tostring(context:get_option(option)), tostring(context:has_menu())))
        fh:close()
      end
    end
    -- 有候選列時吃掉這個按鍵，組字中應用程式本來就收不到。
    -- Shift+字母 那組選字鍵是另一個事件，會走上面的還原路徑。
    return context:has_menu() and 1 or 2
  end

  return 2
end


-- Control + 數字：直接輸出阿拉伯數字。
--
-- 組字中的 Control+N 有兩種來源：使用者實體按著 Control 想打數字，以及 key_binder
-- 為了選字轉送出來的（Tab 與 Shift+Q 那組選字鍵全都轉送成 Control+N）。攔錯會把
-- 選字功能整組吃掉，所以看 control_held——只有前面真的出現過實體 Control 鍵事件才算。
--
-- 上屏方式兩個平台不同，原因是實測出來的前端差異：鼠鬚管只送得出「按鍵抵達時 session
-- 已經在組字」的上屏，從沒組字的狀態憑空生一個又立刻結束，它當作沒發生（候選列會正常
-- 跳出來，所以不是 librime 的問題）。小狼毫沒這個限制。
-- 因此 macOS 把數字累積成一次組字、放開 Control 時才上屏：那一刻 session 還在組字，
-- 送得出去，而且打的過程中候選列會顯示目前累積到哪。
local COMMIT_NEEDS_COMPOSITION = os.getenv("APPDATA") == nil

local CONTROL_DIGITS = {}
for digit = 0, 9 do CONTROL_DIGITS["Control+" .. digit] = tostring(digit) end

-- 數字串裡會用到的標點。這幾顆鍵在 default.custom.yaml 裡是模式切換
-- （Control+, 切中英、Control+. 切全形、Control+/ 切標點），所以**只在數字串進行中**
-- 才攔截：沒在打數字時原本的快捷鍵照常有效。
local CONTROL_PUNCT = {
  ["Control+period"] = ".", ["Control+comma"] = ",",
  ["Control+minus"] = "-", ["Control+slash"] = "/",
}

local MODIFIER_KEYS = {
  Shift_L = true, Shift_R = true, Control_L = true, Control_R = true,
  Alt_L = true, Alt_R = true, Super_L = true, Super_R = true, Caps_Lock = true,
}

-- 借道既有的數字輸入：「#N」的第一個候選就是那個數字本身（number_formats 的第一條），
-- 所以這串組字上屏出來就是打下去的數字。
local pending_digits = false
local digit_run = false        -- 小狼毫那條路用：這一串 Control 組合鍵裡已經打過數字了

local function flush_digits(context)
  pending_digits = false
  if not pcall(function() context:commit() end) then context:clear() end
end

function digit_commit(key, env)
  local context = env.engine.context
  local repr = key:repr()
  local name = repr:match("([^+]+)$") or repr
  local digit = (not key:release()) and CONTROL_DIGITS[repr] or nil
  local punct = (not key:release()) and CONTROL_PUNCT[repr] or nil
  -- 放開 Control 就結束這一串，下一次按 Control+. 才會是原本的全形切換
  if key:release() and (name == "Control_L" or name == "Control_R") then digit_run = false end
  if not control_held then digit_run = false end

  -- 累積中的數字組字：再來一個數字就接上去，放開 Control 或改按別的鍵就上屏
  if pending_digits then
    if not context:is_composing() then
      pending_digits = false           -- 組字被別的元件清掉了，當作沒在累積
    elseif digit or punct then
      context:push_input(digit or punct)
      return 1
    elseif key:release() then
      if name == "Control_L" or name == "Control_R" then
        flush_digits(context)
        return 1
      end
      return 2
    elseif name == "Escape" then
      pending_digits = false           -- 反悔：整串丟掉，不要上屏
      context:clear()
      return 1
    elseif name == "BackSpace" then
      return 2                         -- 交給編輯器退掉最後一個數字
    elseif not MODIFIER_KEYS[name] then
      flush_digits(context)            -- 先把數字送出去，這個鍵再照常處理
      return 2
    else
      return 2
    end
  end

  if punct and digit_run and not context:is_composing() then
    env.engine:commit_text(punct)
    return 1
  end

  if not digit then return 2 end

  if context:is_composing() then
    if not control_held then return 2 end   -- key_binder 轉送來選字的，讓它過
    -- context:commit() 走的是正常上屏路徑，選字會計入詞頻學習；舊版 librime-lua
    -- 沒有綁這個方法，退回手動上屏再清空。
    local ok = pcall(function() context:commit() end)
    if not ok then
      -- 退路要拿整串待上屏的文字，不能只拿選中的候選——已經確認過的前段會掉。
      local text
      pcall(function() text = context:get_commit_text() end)
      if not text or text == "" then
        local candidate = context:has_menu() and context:get_selected_candidate()
        text = candidate and candidate.text
      end
      if text and text ~= "" then env.engine:commit_text(text) end
      context:clear()
    end
    env.engine:commit_text(digit)
    return 1
  end

  if COMMIT_NEEDS_COMPOSITION then
    context:clear()
    context:push_input("#" .. digit)
    pending_digits = true
    return 1
  end

  env.engine:commit_text(digit)
  digit_run = true
  return 1
end

-- 注意：Squirrel 0.18 的 SquirrelInputController.m 在 NSEventTypeKeyDown 一開始就有
-- `if (modifiers & NSEventModifierFlagCommand) break;`（註解為 ignore Command+X hotkeys），
-- 所有「Command＋其他鍵」都不會送進 librime，因此 Super+Right 永遠觸發不到。
-- 簡體上屏改用 Option+→（Alt+Right）；Control+→ 不可用，會被 macOS 的切換桌面空間攔走。
-- Windows 上 Alt + 方向鍵到不了輸入法（Windows 把 Alt 當選單鍵，Parallels 還會轉成
-- Win 鍵，而 Win+→ 是系統的視窗貼齊快捷鍵）。Control 配方向鍵兩個平台都正常，
-- 所以主鍵位用 Control+←；Alt+→ 保留給 macOS 的既有習慣。
local SIMPLIFIED_KEYS = {
  ["Control+Right"] = true,  -- 兩個平台都可用
  ["Alt+Right"] = true,      -- macOS 既有鍵位
  ["Super+Right"] = true,
}

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
-- 英文釋義刻意沒有直接組合鍵：唯一可用的會是 Alt+方向鍵，而那在 Windows 上到不了
-- 輸入法（Alt 的按住狀態在方向鍵抵達前就被放開）。英文一律走「按 Option 開預覽、
-- 再按 →」，兩個平台操作完全一致。
local READING_KEYS = {
  ["Shift+Right"]   = "bopomofo",  -- 選中候選的完整注音
  ["Control+Left"]  = "pinyin",    -- 選中候選的漢語拼音
  ["Control+Up"]    = "raw",       -- 所打鍵碼原樣轉注音符號（要單獨打出「ㄅ」就用這個）
  ["Alt+Up"]        = "raw",       -- 同上，macOS 既有鍵位
}

function special_commit(key, env)
  local repr = key:repr()
  local mode = READING_KEYS[repr]
  local to_simplified = SIMPLIFIED_KEYS[repr]
  local context = env.engine.context

  -- 預覽開著時，單按 → 就輸出目前預覽的內容。
  --
  -- 這條路徑是為了 Windows：實測 Alt + 方向鍵完全到不了輸入法
  -- （Windows 把 Alt 當選單鍵，Parallels 還會轉成 Win 鍵，而 Win+→ 是系統的視窗貼齊），
  -- Shift 與 Control 配方向鍵則正常。改用「修飾鍵選模式、方向鍵輸出」就不依賴任何
  -- Alt 組合鍵，兩個平台行為一致。
  if not mode and not to_simplified and repr == "Right" and not key:release() then
    for _, entry in ipairs(PREVIEW_OPTIONS) do
      if context:get_option(entry.option) then
        mode = entry.mode
        break
      end
    end
  end

  if not mode and not to_simplified then
    return 2
  end

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

  local reading
  if mode == "english" then
    -- 預覽可以顯示多個義項，上屏只取第一個，免得整串分號跟著出去
    local gloss = gloss_of(candidate.text)
    reading = gloss and gloss:match("^([^;]+)")
    if reading then reading = reading:gsub("^%s+", ""):gsub("%s+$", "") end
  else
    reading = reading_of(candidate.text, mode)
  end
  if reading then
    env.engine:commit_text(reading)
    for _, entry in ipairs(PREVIEW_OPTIONS) do
      if context:get_option(entry.option) then
        context:set_option(entry.option, false)
      end
    end
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
