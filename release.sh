#!/bin/bash
set -euo pipefail

: "${MACOS_SIGN_IDENTITY:?Set MACOS_SIGN_IDENTITY to a Developer ID Application identity}"
export MACOS_SIGN_IDENTITY

if [[ -n ${MACOS_NOTARY_KEY_PATH:-} ]]; then
    : "${MACOS_NOTARY_KEY_ID:?Set MACOS_NOTARY_KEY_ID for the team API key}"
    : "${MACOS_NOTARY_ISSUER_ID:?Set MACOS_NOTARY_ISSUER_ID for the team API key}"
    notary_args=(--key "$MACOS_NOTARY_KEY_PATH" --key-id "$MACOS_NOTARY_KEY_ID" --issuer "$MACOS_NOTARY_ISSUER_ID")
else
    : "${MACOS_NOTARY_PROFILE:?Set MACOS_NOTARY_PROFILE to a notarytool Keychain profile}"
    notary_args=(--keychain-profile "$MACOS_NOTARY_PROFILE")
fi

source_dir="$(cd "$(dirname "$0")" && pwd)"
app="$("$source_dir/build.sh")"
info="$app/Contents/Info.plist"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info")"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info")"
if [[ ! $version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    printf 'Invalid release version: %s\n' "$version" >&2
    exit 1
fi
if [[ -n ${EXPECTED_RELEASE_TAG:-} && $EXPECTED_RELEASE_TAG != "v$version" ]]; then
    printf 'Tag %s does not match app version %s.\n' "$EXPECTED_RELEASE_TAG" "$version" >&2
    exit 1
fi
signing_info="$(/usr/bin/codesign -dv --verbose=4 "$app" 2>&1)"
if [[ $signing_info != *"Authority=Developer ID Application:"* ]]; then
    printf 'A Developer ID Application signature is required for distribution.\n' >&2
    exit 1
fi

staging="$(mktemp -d -t dock-shortcut-release)"
trap '/usr/bin/find "$staging" -depth -delete' EXIT
artifact="Dock.Shortcut.$version.dmg"
image="$staging/$artifact"
mkdir "$staging/volume"
/usr/bin/ditto "$app" "$staging/volume/${app##*/}"
ln -s /Applications "$staging/volume/Applications"
cp "$source_dir/LICENSE" "$staging/volume/LICENSE.txt"
/usr/bin/hdiutil create -volname 'Dock Shortcut' -srcfolder "$staging/volume" -format UDZO "$image"
/usr/bin/codesign --timestamp --identifier "$bundle_id.disk-image" --sign "$MACOS_SIGN_IDENTITY" "$image"

/usr/bin/xcrun notarytool submit "$image" "${notary_args[@]}" --wait --timeout 20m --output-format json \
    | tee "$staging/notarization.json"
if [[ "$(/usr/bin/plutil -extract status raw "$staging/notarization.json")" != Accepted ]]; then
    printf 'Apple did not accept the disk image for notarization.\n' >&2
    exit 1
fi

/usr/bin/xcrun stapler staple "$image"
/usr/bin/xcrun stapler validate "$image"
/usr/bin/codesign --verify --strict "$image"
/usr/sbin/spctl --assess --type open --context context:primary-signature --verbose "$image"
/usr/sbin/spctl --assess --type execute --verbose "$app"
/usr/bin/hdiutil verify "$image"
(
    cd "$staging"
    /usr/bin/shasum -a 256 "$artifact" > SHA256SUMS.txt
)

mkdir -p "$source_dir/dist"
mv "$image" "$staging/SHA256SUMS.txt" "$source_dir/dist/"
printf 'Verified release: %s/dist/%s\n' "$source_dir" "$artifact"
