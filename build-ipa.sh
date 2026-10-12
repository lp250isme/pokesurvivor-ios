#!/usr/bin/env bash
# 建出未簽名 .ipa。AltStore / SideStore / Feather / Sideloadly 安裝時才簽。
# 每次 build 會把 project.yml 的版號末位 +1、build number +1。
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="PokeSurvivor"

CUR_VER=$(grep -m1 'MARKETING_VERSION:' project.yml | sed -E 's/.*"([0-9.]+)".*/\1/')
CUR_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION:' project.yml | sed -E 's/.*"([0-9]+)".*/\1/')
NEW_VER=$(echo "$CUR_VER" | awk -F. 'BEGIN{OFS="."}{ $NF=$NF+1; print }')
NEW_BUILD=$((CUR_BUILD + 1))
sed -i '' -E "s/MARKETING_VERSION: \"[0-9.]+\"/MARKETING_VERSION: \"$NEW_VER\"/g" project.yml
sed -i '' -E "s/CURRENT_PROJECT_VERSION: \"[0-9]+\"/CURRENT_PROJECT_VERSION: \"$NEW_BUILD\"/g" project.yml
echo "version $CUR_VER -> $NEW_VER (build $NEW_BUILD)"

xcodegen generate

# -target 走 legacy 路徑，跳過 destination 枚舉（網路上的新裝置會讓 Xcode 報 no destinations）
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -target "$APP_NAME" \
  -configuration Release \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  SYMROOT="$PWD/build/sym" \
  build

APP="build/sym/Release-iphoneos/$APP_NAME.app"
[ -d "$APP" ] || { echo "build failed: $APP not found"; exit 1; }

rm -rf build/Payload "build/$APP_NAME.ipa"
mkdir -p build/Payload
cp -R "$APP" build/Payload/
( cd build && zip -qr "$APP_NAME.ipa" Payload )
echo "unsigned IPA: $(pwd)/build/$APP_NAME.ipa"

ARCHIVE="$HOME/Library/Mobile Documents/com~apple~CloudDocs/ipa/$APP_NAME"
mkdir -p "$ARCHIVE"
cp "build/$APP_NAME.ipa" "$ARCHIVE/$APP_NAME-$NEW_VER.ipa"
echo "archived: $ARCHIVE/$APP_NAME-$NEW_VER.ipa"
