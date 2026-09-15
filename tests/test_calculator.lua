-- 計算與單位換算：number_formats 翻譯器（Ctrl + \ 之後的輸入）。
local H = dofile((arg[0]:match("^(.*)/[^/]*$") or ".") .. "/harness.lua")
H.install()

local function candidates(text)
  H.collected = {}
  number_formats("#" .. text, { start = 0, _end = #text + 1 },
                 { engine = { context = H.context() } })
  local out = {}
  for _, c in ipairs(H.collected) do out[#out + 1] = c.text end
  -- 分隔符一定要用單位元組的字元：Lua 的字元類是逐位元組比對，
  -- 用全形的「│」會連帶把 ℃ 這種開頭位元組相同的字切掉。
  return table.concat(out, "\t")
end

local function first(text)
  return (candidates(text):match("^([^\t]*)")) or ""
end

print("四則運算")
H.check("12+5", first("12+5"), "17")
H.check("先乘除後加減", first("1+2*3"), "7")
H.check("括號", first("(1+2)*3"), "9")
H.check("小數", first("1.5*4"), "6")
H.check("負數", first("-3+10"), "7")
H.check("次方右結合", first("2^3^2"), "512")
H.check("取餘數", first("10%3"), "1")
H.check("千分位逗號會被忽略", first("1,000*2"), "2000")
H.check("除不盡取四位小數", first("(10/3)*1"), "3.3333")
H.check("除以零不給候選", candidates("5/0+1"), "")
H.check("不是算式就不給", candidates("1+"), "")

print("\n單位換算")
H.check("100cm → 英寸優先", first("100cm"), "39.3701 in")
H.check("公分也換得到公尺", candidates("100cm"):find("1 m", 1, true) ~= nil, true)
H.check("1m", first("1m"), "39.3701 in")
H.check("5kg → 磅", first("5kg"), "11.0231 lb")
H.check("華氏轉攝氏", first("98f"), "36.6667 ℃")
H.check("攝氏轉華氏", first("100c"), "212 ℉")
H.check("坪", first("10ping"), "33.0579 m2")
H.check("時速", first("100kmh"), "62.1371 mph")
H.check("大小寫都可以", first("100CM"), "39.3701 in")
H.check("inch 這種全名也認得", first("10inch"), "0.8333 ft")
H.check("不認得的單位就不給", candidates("100xyz"), "")

print("\n算式＋單位：整條鏈一起顯示")
H.check("12*3cm", first("12*3cm"), "12*3=36cm=14.1732 in")
H.check("攝氏算完再換", first("(20+5)c"), "(20+5)=25c=77 ℉")
H.check("除法也算算式", first("50/2kg"), "50/2=25kg=55.1156 lb")
H.check("算不出來就不給", candidates("1+*2cm"), "")
H.check("沒有單位就只給結果", first("100+20"), "120")
H.check("沒有算式就不掛鏈", first("100cm"), "39.3701 in")

print("\n匯率（lua/rates.lua 不在就整段跳過）")
local has_rates = candidates("100usd") ~= ""
if not has_rates then
  print("  －未安裝匯率表，跳過（跑 generate/rates.py 就會有）")
else
  H.check("美金轉台幣是第一個", first("100usd"):match("TWD$") ~= nil, true)
  H.check("金額兩位小數加千分位", first("100usd"):match("^[%d,]+%.%d%d ") ~= nil, true)
  H.check("美金轉加幣在候選裡", candidates("100usd"):find("CAD", 1, true) ~= nil, true)
  H.check("日圓不帶小數", candidates("100usd"):match("[%d,]+ JPY") ~= nil, true)
  H.check("台幣起算也可以", first("1000twd"):match("USD$") ~= nil, true)
  H.check("候選旁邊標著匯率日期", (function()
    H.collected = {}
    number_formats("#100usd", { start = 0, _end = 1 }, { engine = { context = H.context() } })
    return H.collected[1].comment:match("^〔匯率 ") ~= nil
  end)(), true)
  H.check("不認得的貨幣代碼不給", candidates("100zzz"), "")
  H.check("算式＋貨幣的鏈：100+20=120USD=…",
    first("100+20usd"):match("^100%+20=120USD=[%d,]+%.%d%d TWD$") ~= nil, true)
  H.check("加幣在鏈裡", candidates("100+20usd"):find("=120USD=", 1, true) ~= nil, true)
end

print("\n原有的數字格式沒被影響")
H.check("純數字仍是阿拉伯數字優先", first("2026"), "2026")
H.check("中文數字仍在", candidates("2026"):find("二千零二十六", 1, true) ~= nil, true)
H.check("日期原樣優先", first("2026/09/15"), "2026/09/15")
H.check("日期後面才是計算結果", candidates("2026/09/15"):find("15", 1, true) ~= nil, true)
H.check("1. 仍是原樣", first("1."), "1.")

H.report("計算與換算")
