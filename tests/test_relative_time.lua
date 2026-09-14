-- 相對時間與符號展開：date_symbol_extras 濾鏡。
-- 重點在小數數量——os.time 與 os.date 的欄位必須是整數，給小數會直接報錯，
-- 整個濾鏡會中斷、候選消失，所以「半天後」這類輸入一定要有測試守著。
local H = dofile((arg[0]:match("^(.*)/[^/]*$") or ".") .. "/harness.lua")
H.install()

-- 展開後的第一個候選（第 1 個是原候選，從第 2 個起才是展開的結果）
local function first(text)
  H.collected = {}
  local ok, err = pcall(date_symbol_extras, H.one(text), { engine = { context = H.context() } })
  if not ok then return "錯誤：" .. tostring(err) end
  local out = H.collected[2]
  if not out then return "（無候選）" end
  return out.text .. " " .. (out.comment or "")
end

local DAY, HOUR = 86400, 3600
local function date_in(seconds) return os.date("%Y.%m.%d", os.time() + seconds) end
local function clock_in(seconds) return os.date("%H:%M", os.time() + seconds) end
local function months_from_now(n)
  local d = os.date("*t")
  local total = d.year * 12 + (d.month - 1) + n
  return string.format("%04d.%02d.%02d", math.floor(total / 12), total % 12 + 1, d.day)
end

print("小數數量：往更細的單位換算，不得讓濾鏡中斷")
H.check("半天後 ＝ 十二小時後（時刻）", first("半天後"), clock_in(12 * HOUR) .. " 〔時間〕")
H.check("半天前 ＝ 十二小時前（時刻）", first("半天前"), clock_in(-12 * HOUR) .. " 〔時間〕")
H.check("半個月後 ＝ 十五天後", first("半個月後"), date_in(15 * DAY) .. " 〔日期〕")
H.check("半年後 ＝ 六個月後", first("半年後"), months_from_now(6) .. " 〔日期〕")
H.check("半週後 ＝ 三天半後（時刻）", first("半週後"), clock_in(3.5 * DAY) .. " 〔時間〕")
H.check("半秒後不報錯", first("半秒後"), clock_in(0) .. " 〔時間〕")
H.check("1.5年後 ＝ 十八個月後", first("1.5年後"), months_from_now(18) .. " 〔日期〕")

print("\n整數數量與其他觸發詞")
H.check("半小時後", first("半小時後"), clock_in(1800) .. " 〔時間〕")
H.check("二十五分鐘後", first("二十五分鐘後"), clock_in(25 * 60) .. " 〔時間〕")
H.check("10分鐘後（阿拉伯數字）", first("10分鐘後"), clock_in(10 * 60) .. " 〔時間〕")
H.check("三個月後", first("三個月後"), months_from_now(3) .. " 〔日期〕")
H.check("十天後", first("十天後"), date_in(10 * DAY) .. " 〔日期〕")
H.check("一百天後", first("一百天後"), date_in(100 * DAY) .. " 〔日期〕")
H.check("兩年前", first("兩年前"), months_from_now(-24) .. " 〔日期〕")
H.check("小時後 ＝ 一小時後", first("小時後"), clock_in(HOUR) .. " 〔時間〕")
H.check("後天", first("後天"), date_in(2 * DAY) .. " 〔日期〕")
H.check("大前天", first("大前天"), date_in(-3 * DAY) .. " 〔日期〕")
H.check("明天", first("明天"), date_in(DAY) .. " 〔日期〕")

print("\n不該被誤判為相對時間")
H.check("然後", first("然後"), "（無候選）")
H.check("以前", first("以前"), "（無候選）")
H.check("午後", first("午後"), "（無候選）")
-- 單字單位省略數量就是常用詞，不是在算日子
H.check("日後", first("日後"), "（無候選）")
H.check("年前", first("年前"), "（無候選）")
H.check("月前", first("月前"), "（無候選）")
H.check("日前", first("日前"), "（無候選）")
H.check("天後", first("天後"), "（無候選）")
-- 但兩個字以上的單位仍可省略數量
H.check("分鐘後 ＝ 一分鐘後", first("分鐘後"), clock_in(60) .. " 〔時間〕")
H.check("個月後 ＝ 一個月後", first("個月後"), months_from_now(1) .. " 〔日期〕")

print("\n符號表")
H.check("公里", first("公里"), "㎞ 〔日期／符號〕")
H.check("美金", first("美金"), "$ 〔日期／符號〕")

H.report("相對時間")
