#!/bin/bash

set -e

APP_NAME="LinguaFloat"
BUNDLE_ID="com.pingzi.LinguaFloat"
SCHEME="LinguaFloat"
CONFIGURATION="Release"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
NOTARIZATION_PROFILE="LinguaFloat-Notarization"

echo "=== LinguaFloat Release Build Script ==="
echo ""

cleanup() {
    echo "Cleaning up..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

build_archive() {
    echo "Building archive..."
    xcodebuild archive \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="$DEVELOPER_ID" \
        OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime"
}

export_app() {
    echo "Exporting app..."
    
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
}

notarize_app() {
    echo "Submitting for notarization..."
    
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
    
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    
    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$NOTARIZATION_PROFILE" \
        --wait
    
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    
    rm "$ZIP_PATH"
}

create_dmg() {
    echo "Creating DMG..."
    
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$APP_PATH" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    codesign --sign "$DEVELOPER_ID" --timestamp "$DMG_PATH"
    
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARIZATION_PROFILE" \
        --wait
    
    xcrun stapler staple "$DMG_PATH"
}

generate_appcast() {
    echo "Generating appcast..."
    
    VERSION=$(defaults read "$EXPORT_PATH/$APP_NAME.app/Contents/Info.plist" CFBundleShortVersionString)
    BUILD=$(defaults read "$EXPORT_PATH/$APP_NAME.app/Contents/Info.plist" CFBundleVersion)
    
    DMG_SIZE=$(stat -f%z "$DMG_PATH")
    DMG_SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
    
    SPARKLE_SIGN=$(sparkle/bin/sign_update "$DMG_PATH")
    
    cat > "$BUILD_DIR/appcast.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>LinguaFloat Updates</title>
        <link>https://linguafloat.com/appcast.xml</link>
        <description>LinguaFloat update feed</description>
        <language>en</language>
        <item>
            <title>Version $VERSION</title>
            <pubDate>$(date -R)</pubDate>
            <sparkle:version>$BUILD</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://linguafloat.com/releases/$APP_NAME-$VERSION.dmg"
                sparkle:edSignature="$SPARKLE_SIGN"
                length="$DMG_SIZE"
                type="application/octet-stream"/>
            <description><![CDATA[
                <h2>What's New in $VERSION</h2>
                <ul>
                    <li>Bug fixes and improvements</li>
                </ul>
            ]]></description>
        </item>
    </channel>
</rss>
EOF
    
    echo "Appcast generated at $BUILD_DIR/appcast.xml"
}

print_summary() {
    echo ""
    echo "=== Build Complete ==="
    echo "DMG: $DMG_PATH"
    echo "Appcast: $BUILD_DIR/appcast.xml"
    echo ""
    echo "Next steps:"
    echo "1. Upload $DMG_PATH to your server"
    echo "2. Upload $BUILD_DIR/appcast.xml to your server"
    echo "3. Test the update by installing an older version"
}

case "${1:-all}" in
    clean)
        cleanup
        ;;
    build)
        build_archive
        export_app
        ;;
    notarize)
        notarize_app
        ;;
    dmg)
        create_dmg
        ;;
    appcast)
        generate_appcast
        ;;
    all)
        cleanup
        build_archive
        export_app
        notarize_app
        create_dmg
        generate_appcast
        print_summary
        ;;
    *)
        echo "Usage: $0 {clean|build|notarize|dmg|appcast|all}"
        exit 1
        ;;
esac
