# Dock Shortcut releases

1. Update the version in the Xcode project and in [dock-shortcut-Info.plist](dock-shortcut-Info.plist). Increment the Xcode build number.
2. Merge the release commit into `main`, then push a matching tag such as `v1.4`.
3. Check **Release macOS** in GitHub Actions. It builds the universal app with its login helper, signs both bundles and the DMG, notarizes the DMG, and publishes the verified installer and checksum.

Run **Release macOS** manually from `main` to validate the pipeline. The manual run produces a signed DMG and checksum as a workflow artifact. Check launching the app and toggling launch at login on a physical Mac.

The workflow uses Xcode 26.4.1 for the macOS 11 deployment target. The `macos-release` environment stores the Developer ID secrets `DEVELOPER_ID_P12_BASE64` and `DEVELOPER_ID_P12_PASSWORD`, and the App Store Connect team key secrets `ASC_KEY_P8_BASE64`, `ASC_KEY_ID`, and `ASC_ISSUER_ID`.

For a local build with a compatible Xcode version, run `./build.sh`. To package locally, run `./release.sh` with `MACOS_SIGN_IDENTITY` and `MACOS_NOTARY_PROFILE` set. The result is written to `dist/`.
