#!/bin/zsh
# Builds SbuPrompter-<version>.dmg: universal Release Mac app, Developer ID signature, app and dmg notarised and stapled (ADR-0022).
# Needs SBU_TEAM_ID and the App Store Connect API key used by fastlane: ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID.
# Usage: ./make-dmg.sh [version]   (default 1.0). Output in build/dist/.
set -euo pipefail
cd "${0:A:h}"

VERSION=${1:-1.0}
: ${SBU_TEAM_ID:?} ${ASC_KEY_PATH:?} ${ASC_KEY_ID:?} ${ASC_ISSUER_ID:?}
IDENTITY="Developer ID Application"
OUT=build/dist
DMG=$OUT/SbuPrompter-$VERSION.dmg
rm -rf build/SbuPrompter.xcarchive $OUT && mkdir -p $OUT

xcodegen
xcodebuild archive -scheme SbuPrompter -configuration Release -destination 'generic/platform=macOS' \
  -archivePath build/SbuPrompter.xcarchive -derivedDataPath build/dd \
  MARKETING_VERSION=$VERSION ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM=$SBU_TEAM_ID

cat > build/export.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>developer-id</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>$IDENTITY</string>
  <key>teamID</key><string>$SBU_TEAM_ID</string>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath build/SbuPrompter.xcarchive -exportOptionsPlist build/export.plist -exportPath $OUT/app

APP=$OUT/app/SbuPrompter.app
lipo -archs $APP/Contents/MacOS/SbuPrompter | grep -q 'x86_64 arm64\|arm64 x86_64' || { echo "not universal"; exit 1; }

# Notarise a zip of the app and staple it, so the copy dragged to Applications works offline too.
ditto -c -k --keepParent $APP $OUT/notarize.zip
xcrun notarytool submit $OUT/notarize.zip --key $ASC_KEY_PATH --key-id $ASC_KEY_ID --issuer $ASC_ISSUER_ID --wait
xcrun stapler staple $APP
rm $OUT/notarize.zip

# Disk image with the app and a link to Applications, signed, notarised and stapled too.
mkdir $OUT/dmg && ditto $APP $OUT/dmg/SbuPrompter.app && ln -s /Applications $OUT/dmg/Applications
hdiutil create -volname "Sbu Prompter" -srcfolder $OUT/dmg -fs HFS+ -format UDZO -ov $DMG
rm -rf $OUT/dmg
codesign --force --sign "$IDENTITY" --timestamp $DMG
xcrun notarytool submit $DMG --key $ASC_KEY_PATH --key-id $ASC_KEY_ID --issuer $ASC_ISSUER_ID --wait
xcrun stapler staple $DMG

spctl -a -vvv -t exec $APP
spctl -a -vv -t open --context context:primary-signature $DMG
xcrun stapler validate $DMG
shasum -a 256 $DMG
echo "Ready: $DMG"
