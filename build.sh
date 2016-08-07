git push origin master
mkdir build
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "Info.plist")
xcodebuild -project DisplayBrightness.xcodeproj -scheme DisplayBrightness -archivePath build/DisplayBrightness.xarchive archive
xcodebuild -exportArchive -archivePath build/DisplayBrightness.xarchive.xcarchive -exportPath build/ -exportOptionsPlist export.plist
zip -r "DisplayBrightness_${VERSION}.zip" build/DisplayBrightness.app/
rm -r build
# https://developer.github.com/v3/repos/releases/#create-a-release 


