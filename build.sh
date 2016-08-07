mkdir build
xcodebuild -project DisplayBrightness.xcodeproj -scheme DisplayBrightness -archivePath build/DisplayBrightness.xarchive archive
xcodebuild -exportArchive -archivePath build/DisplayBrightness.xarchive.xcarchive -exportPath build/ -exportOptionsPlist export.plist
zip -r DisplayBrightness.zip build/DisplayBrightness.app/
rm -r build
