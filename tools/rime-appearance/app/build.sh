#!/bin/bash
# 把外觀編輯器打包成 macOS app。
#
#   ./build.sh              # 建置到 build/鼠鬚管外觀編輯器.app
#   ./build.sh --install    # 建置後複製到 /Applications
#
# 需要 Xcode 命令列工具（swiftc）。執行期需要 python3，app 會自己找。

set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$(dirname "$HERE")"
NAME="鼠鬚管外觀編輯器"
OUT="$HERE/build/$NAME.app"

command -v swiftc >/dev/null || { echo "找不到 swiftc，請先執行：xcode-select --install"; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"

echo "編譯…"
swiftc -O -o "$OUT/Contents/MacOS/RimeAppearance" "$HERE/main.swift" \
  -framework AppKit -framework WebKit

cp "$SRC/server.py" "$SRC/index.html" "$OUT/Contents/Resources/"

cat > "$OUT/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>im.rime.appearance-editor</string>
  <key>CFBundleExecutable</key><string>RimeAppearance</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>CC BY-SA 3.0</string>
</dict>
</plist>
PLIST

# 沒有簽名的 app 會被 Gatekeeper 擋下，做一個本機臨時簽名就能直接開
codesign --force --deep --sign - "$OUT" 2>/dev/null || echo "（簽名略過，首次開啟可能需要在系統設定允許）"

echo "完成：$OUT"

if [ "${1:-}" = "--install" ]; then
  rm -rf "/Applications/$NAME.app"
  cp -R "$OUT" /Applications/
  echo "已安裝到 /Applications/$NAME.app"
fi
