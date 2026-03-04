# macOS DMG Release Pipeline

This repo now includes a local + CI release pipeline for signed/notarized macOS DMG builds.

## Files

- `scripts/release-macos.sh`: local release script (build, sign, notarize, staple, DMG).
- `.github/workflows/macos-release.yml`: GitHub Actions workflow for tagged releases.

## Prerequisites

1. Apple Developer membership.
2. `Developer ID Application` certificate in Keychain.
3. App-specific password for notarization.
4. `create-dmg` installed locally (`brew install create-dmg`).
5. A real Xcode app project in this repo (`.xcodeproj` or `.xcworkspace`).

## Local release

Run from repo root:

```bash
export APP_NAME="NewsletterAudio"
export SCHEME="NewsletterAudio"
export SIGNING_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="TEAMID"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"

./scripts/release-macos.sh
```

Optional:

- `PROJECT_PATH` (example: `NewsletterAudio.xcodeproj`)
- `WORKSPACE_PATH` (example: `NewsletterAudio.xcworkspace`)
- `VOLNAME` (DMG volume label)

Output artifact:

- `dist/NewsletterAudio.dmg`

## GitHub Actions setup

Create these repository secrets:

1. `MACOS_CERT_P12`: base64-encoded Developer ID Application cert `.p12`.
2. `MACOS_CERT_PASSWORD`: password used to export the `.p12`.
3. `KEYCHAIN_PASSWORD`: temporary keychain password for CI.
4. `SIGNING_IDENTITY`: full cert identity text from Keychain.
5. `APPLE_ID`: Apple account email.
6. `APPLE_TEAM_ID`: Apple team ID.
7. `APPLE_APP_PASSWORD`: app-specific password.

Create these repository variables (if app names differ):

1. `APP_NAME`
2. `SCHEME`
3. `PROJECT_PATH` or `WORKSPACE_PATH`
4. `VOLNAME` (optional)

Trigger:

- Push a tag like `v0.1.0`, or run workflow manually (`workflow_dispatch`).
