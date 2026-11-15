#!/bin/zsh
# Builds SbuSeasons-<version>.dmg: universal Release app, Developer ID signature, notarised and stapled (ADR-0022).
# Needs SBU_TEAM_ID and the App Store Connect API key used by fastlane: ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID.
# Usage: ./make-dmg.sh [version]   (default 1.0). Output in build/dist/.
set -euo pipefail
cd "${0:A:h}"

VERSION=${1:-1.0}
: ${SBU_TEAM_ID:?} ${ASC_KEY_PATH:?} ${ASC_KEY_ID:?} ${ASC_ISSUER_ID:?}
IDENTITY="Developer ID Application"
OUT=build/dist
DMG=$OUT/SbuSeasons-$VERSION.dmg
rm -rf build/SbuSeasons.xcarchive $OUT && mkdir -p $OUT

xcodegen
xcodebuild archive -scheme SbuSeasons -configuration Release -destination 'generic/platform=macOS' \
  -archivePath build/SbuSeasons.xcarchive -derivedDataPath build/dd \
  MARKETING_VERSION=$VERSION ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM=$SBU_TEAM_ID

cat > build/export.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>developer-id</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>$IDENTITY</string>
  <key>teamID</key><string>$SBU_TEAM_ID</string>
</dict></plist>
EOF
xcodebuild -exportArchive -archivePath build/SbuSeasons.xcarchive -exportOptionsPlist build/export.plist -exportPath $OUT/app

APP=$OUT/app/SbuSeasons.app
lipo -archs $APP/Contents/MacOS/SbuSeasons | grep -q 'x86_64 arm64\|arm64 x86_64' || { echo "not universal"; exit 1; }

# The image: the app next to a link to /Applications, so the user drags it across.
STAGE=$OUT/stage && mkdir -p $STAGE
ditto $APP $STAGE/SbuSeasons.app
ln -s /Applications $STAGE/Applications
hdiutil create -volname "Sbu Seasons" -srcfolder $STAGE -fs HFS+ -format UDZO -ov $DMG
codesign --sign "$IDENTITY" --timestamp $DMG

xcrun notarytool submit $DMG --key $ASC_KEY_PATH --key-id $ASC_KEY_ID --issuer $ASC_ISSUER_ID --wait
xcrun stapler staple $DMG
spctl -a -vvv -t install $DMG
echo "Ready: $DMG"
