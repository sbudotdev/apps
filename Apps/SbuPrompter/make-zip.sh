#!/bin/zsh
# Builds SbuPrompter-<version>.zip: universal Release Mac app, Developer ID signature, notarised and stapled (ADR-0022).
# Needs SBU_TEAM_ID and the App Store Connect API key used by fastlane: ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID.
# Usage: ./make-zip.sh [version]   (default 1.0). Output in build/dist/.
set -euo pipefail
cd "${0:A:h}"

VERSION=${1:-1.0}
: ${SBU_TEAM_ID:?} ${ASC_KEY_PATH:?} ${ASC_KEY_ID:?} ${ASC_ISSUER_ID:?}
IDENTITY="Developer ID Application"
OUT=build/dist
ZIP=$OUT/SbuPrompter-$VERSION.zip
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

# Notarise a zip of the app, staple the ticket to the app, then zip the stapled app for the download.
ditto -c -k --keepParent $APP $OUT/notarize.zip
xcrun notarytool submit $OUT/notarize.zip --key $ASC_KEY_PATH --key-id $ASC_KEY_ID --issuer $ASC_ISSUER_ID --wait
xcrun stapler staple $APP
rm $OUT/notarize.zip
ditto -c -k --keepParent $APP $ZIP
spctl -a -vvv -t exec $APP
echo "Ready: $ZIP"
