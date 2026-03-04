#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-NewsletterAudio}"
SCHEME="${SCHEME:-$APP_NAME}"
CONFIGURATION="${CONFIGURATION:-Release}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD:-}"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-build/DerivedData}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
VOLNAME="${VOLNAME:-$APP_NAME}"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "Missing required env var: SIGNING_IDENTITY"
  exit 1
fi

if [[ -z "$APPLE_ID" || -z "$APPLE_TEAM_ID" || -z "$APPLE_APP_PASSWORD" ]]; then
  echo "Missing notary credentials. Set APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_PASSWORD."
  exit 1
fi

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "Missing dependency: create-dmg. Install with: brew install create-dmg"
  exit 1
fi

PROJECT_ARG=()
if [[ -n "${WORKSPACE_PATH:-}" ]]; then
  PROJECT_ARG=(-workspace "$WORKSPACE_PATH")
elif [[ -n "${PROJECT_PATH:-}" ]]; then
  PROJECT_ARG=(-project "$PROJECT_PATH")
else
  first_workspace="$(find . -maxdepth 2 -name "*.xcworkspace" | head -n 1 || true)"
  first_project="$(find . -maxdepth 2 -name "*.xcodeproj" | head -n 1 || true)"
  if [[ -n "$first_workspace" ]]; then
    PROJECT_ARG=(-workspace "$first_workspace")
  elif [[ -n "$first_project" ]]; then
    PROJECT_ARG=(-project "$first_project")
  else
    echo "Could not find .xcworkspace or .xcodeproj. Set WORKSPACE_PATH or PROJECT_PATH."
    exit 1
  fi
fi

mkdir -p "$OUTPUT_DIR"

echo "Building app..."
xcodebuild \
  "${PROJECT_ARG[@]}" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  clean build

APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but app bundle was not found at: $APP_PATH"
  exit 1
fi

echo "Signing app..."
codesign --force --deep --options runtime --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$APP_PATH"

ZIP_PATH="$OUTPUT_DIR/$APP_NAME.zip"
DMG_PATH="$OUTPUT_DIR/$APP_NAME.dmg"

echo "Preparing zip for notarization..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Submitting for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

echo "Stapling app..."
xcrun stapler staple "$APP_PATH"

echo "Creating DMG..."
rm -f "$DMG_PATH"
create-dmg \
  --volname "$VOLNAME" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  "$DMG_PATH" \
  "$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/"

echo "Signing DMG..."
codesign --force --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$DMG_PATH"

echo "Validating notarization and Gatekeeper checks..."
xcrun stapler validate "$APP_PATH"
spctl -a -t open --context context:primary-signature -v "$DMG_PATH"

echo "Release artifact ready: $DMG_PATH"
