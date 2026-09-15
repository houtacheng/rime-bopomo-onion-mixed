#!/bin/sh
# 跑完全部測試。需要獨立的 Lua 直譯器（brew install lua），與輸入法本身無關——
# 測試是以假的 librime-lua API 載入 rime.lua，不必部署也不會動到你的設定。
#
#   tests/run.sh
#   LUA=/usr/local/bin/lua5.4 tests/run.sh

cd "$(dirname "$0")" || exit 1

LUA="${LUA:-}"
if [ -z "$LUA" ]; then
  for candidate in lua lua5.4 lua5.3 luajit; do
    if command -v "$candidate" >/dev/null 2>&1; then LUA=$(command -v "$candidate"); break; fi
  done
fi
if [ -z "$LUA" ]; then
  echo "找不到 lua，請先安裝（brew install lua）或用 LUA=... 指定路徑" >&2
  exit 127
fi

failed=0

LUAC=""
for candidate in luac luac5.4 luac5.3; do
  if command -v "$candidate" >/dev/null 2>&1; then LUAC=$(command -v "$candidate"); break; fi
done

if [ -n "$LUAC" ]; then
  if "$LUAC" -p ../rime.lua; then
    echo "語法檢查：rime.lua ✓"
  else
    echo "語法檢查：rime.lua ✗"
    failed=1
  fi
fi

for test in test_*.lua; do
  echo
  echo "── $test ──────────────────────────────────────────"
  "$LUA" "$test" || failed=1
done

# 數字上屏的方式依平台而異，macOS 那條在上面跑過了，這裡補 Windows 那條
echo
echo "── test_digit.lua（APPDATA=... 模擬 Windows）──────"
APPDATA=/tmp "$LUA" test_digit.lua || failed=1

echo
if [ "$failed" -eq 0 ]; then
  echo "全部通過"
else
  echo "有測試失敗"
fi
exit "$failed"
