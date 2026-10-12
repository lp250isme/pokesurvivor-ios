#!/bin/bash
# iPhone Duo letterboxes an app whose Mach-O SDK stamp is below 27.1 and fills
# the leftover display with black. iOS reads LC_BUILD_VERSION at launch.
# This keeps the deployment target and only raises the sdk field, so the same
# binary still runs on iOS 17. Xcode 26.2 cannot write 27.1 itself.
set -euo pipefail

APP="${TARGET_BUILD_DIR:-}/${WRAPPER_NAME:-}"
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "stamp-duo-sdk: app bundle not found"
  exit 0
fi

stamp() {
  local bin="$1"
  [ -f "$bin" ] || return 0
  local show platform minos sdk toolver plat
  show=$(xcrun vtool -show-build "$bin")
  platform=$(printf '%s\n' "$show" | awk '/^ *platform / { print $2; exit }')
  minos=$(printf '%s\n' "$show" | awk '/^ *minos / { print $2; exit }')
  sdk=$(printf '%s\n' "$show" | awk '/^ *sdk / { print $2; exit }')
  toolver=$(printf '%s\n' "$show" | awk '/^ *version / { print $2; exit }')
  case "$platform" in
    IOS) plat=ios ;;
    IOSSIMULATOR) plat=iossim ;;
    *)
      echo "stamp-duo-sdk: skip $bin ($platform)"
      return 0
      ;;
  esac
  if [ "$(printf '%s\n%s\n' "$sdk" 27.1 | sort -V | head -1)" = "27.1" ]; then
    echo "stamp-duo-sdk: $bin already sdk $sdk"
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  xcrun vtool -set-build-version "$plat" "$minos" 27.1 -tool ld "$toolver" -replace -output "$tmp" "$bin"
  mv "$tmp" "$bin"
  chmod +x "$bin"
  echo "stamp-duo-sdk: $bin sdk $sdk -> 27.1"
}

stamp "$APP/${EXECUTABLE_NAME:-PokeSurvivor}"
stamp "$APP/${EXECUTABLE_NAME:-PokeSurvivor}.debug.dylib"
