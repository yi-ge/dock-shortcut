#!/bin/bash
set -euo pipefail

source_dir="$(cd "$(dirname "$0")" && pwd)"
derived_data="$source_dir/build/Xcode"
products="$derived_data/Build/Products/Release"
app="$products/dock shortcut.app"
helper="$app/Contents/Library/LoginItems/LaunchAtLoginHelper.app"

/usr/bin/xcodebuild -quiet -project "$source_dir/dock shortcut.xcodeproj" -scheme 'dock shortcut' \
    -configuration Release -destination 'generic/platform=macOS' -derivedDataPath "$derived_data" \
    -onlyUsePackageVersionsFromResolvedFile 'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO build >&2

for bundle in "$app" "$helper"; do
    executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$bundle/Contents/Info.plist")"
    /usr/bin/xcrun lipo "$bundle/Contents/MacOS/$executable" -verify_arch arm64 x86_64
done

sign_args=(--force --options runtime --sign "${MACOS_SIGN_IDENTITY:--}")
if [[ -n ${MACOS_SIGN_IDENTITY:-} ]]; then
    sign_args+=(--timestamp)
fi

# The vendored helper starts with development entitlements. Use its release entitlements.
helper_entitlements="$products/LaunchAtLogin_LaunchAtLogin.bundle/Contents/Resources/LaunchAtLogin.entitlements"
/usr/bin/codesign "${sign_args[@]}" --entitlements "$helper_entitlements" "$helper"
/usr/bin/codesign "${sign_args[@]}" --entitlements "$source_dir/dock shortcut/dock_shortcut.entitlements" "$app"
/usr/bin/codesign --verify --deep --strict "$app"
printf '%s\n' "$app"
