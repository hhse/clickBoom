#!/usr/bin/env bash
#
# 打包发布用的 ClickBoom DMG（arm64 + x86_64 通用二进制，可选签名与公证）
#
# 常用：
#   ./scripts/release.sh                             # 本机自动签名，输出 dist/ClickBoom-<版本>.dmg
#   SKIP_SIGN=1 ./scripts/release.sh                 # 不签名（CI 或本地快速验证）
#
# 正式分发（需要 Developer ID 证书 + 公证凭据）：
#   xcrun notarytool store-credentials clickboom \
#     --apple-id <你的 Apple ID> --team-id <TEAMID> --password <App 专用密码>
#
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE=clickboom \
#   ./scripts/release.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 有些机器 xcode-select 指向 CommandLineTools，xcodebuild 会直接拒绝工作
if [[ "$(xcode-select -p)" == *CommandLineTools* ]]; then
  if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  else
    echo "错误：需要完整 Xcode，请先执行 sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
  fi
fi

VERSION="$(grep -m1 'MARKETING_VERSION = ' clickBoom.xcodeproj/project.pbxproj | sed -E 's/.*= ([0-9.]+);/\1/')"
BUILD_NUMBER="$(grep -m1 'CURRENT_PROJECT_VERSION = ' clickBoom.xcodeproj/project.pbxproj | sed -E 's/.*= ([0-9]+);/\1/')"
APP_NAME="ClickBoom"
OUT_DIR="$ROOT/dist"
OUT_DMG="$OUT_DIR/$APP_NAME-$VERSION.dmg"

# 构建产物放到系统临时目录。仓库若位于 iCloud / 网盘等 File Provider 目录，
# 产物会被加上 FinderInfo 之类扩展属性，codesign 会报
# "resource fork, Finder information, or similar detritus not allowed"。
DERIVED="$(mktemp -d "${TMPDIR:-/tmp}/clickboom-build.XXXXXX")"
trap 'rm -rf "$DERIVED"' EXIT

echo "==> 构建 $APP_NAME $VERSION ($BUILD_NUMBER)  arm64 + x86_64"

BUILD_ARGS=(
  -project clickBoom.xcodeproj
  -scheme clickBoom
  -configuration Release
  -derivedDataPath "$DERIVED"
  ARCHS="arm64 x86_64"
  ONLY_ACTIVE_ARCH=NO
)

if [[ "${SKIP_SIGN:-0}" == "1" ]]; then
  BUILD_ARGS+=(CODE_SIGNING_ALLOWED=NO)
elif [[ -n "${SIGN_IDENTITY:-}" ]]; then
  BUILD_ARGS+=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$SIGN_IDENTITY" OTHER_CODE_SIGN_FLAGS="--timestamp")
fi

LOG="$DERIVED/xcodebuild.log"
if ! xcodebuild "${BUILD_ARGS[@]}" build >"$LOG" 2>&1; then
  echo "构建失败，最后 40 行日志：" >&2
  tail -40 "$LOG" >&2
  exit 1
fi

APP="$DERIVED/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$APP" ]]; then
  echo "错误：找不到构建产物 $APP" >&2
  exit 1
fi

echo "==> 架构：$(lipo -archs "$APP/Contents/MacOS/$APP_NAME")"

if [[ -n "${NOTARY_PROFILE:-}" && -n "${SIGN_IDENTITY:-}" ]]; then
  echo "==> 提交 Apple 公证（通常需要几分钟）"
  ditto -c -k --keepParent "$APP" "$DERIVED/notarize.zip"
  xcrun notarytool submit "$DERIVED/notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
fi

echo "==> 生成 DMG"
STAGE="$DERIVED/dmg"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/$APP_NAME.app"
ln -s /Applications "$STAGE/Applications"

mkdir -p "$OUT_DIR"
rm -f "$OUT_DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov "$OUT_DMG" >/dev/null

SIZE="$(du -h "$OUT_DMG" | awk '{print $1}')"
echo "==> 完成：${OUT_DMG}（${SIZE}）"

if [[ "${SKIP_SIGN:-0}" == "1" ]]; then
  echo "    注意：这是未签名构建，仅适合本地验证，不要直接分发。"
elif [[ -z "${NOTARY_PROFILE:-}" ]]; then
  echo "    提示：当前未做公证，别人下载后会被 Gatekeeper 拦一次（见 README「首次打开」）。"
fi
