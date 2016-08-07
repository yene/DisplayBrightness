#!/bin/sh
APIKEY=$(<apikey.txt)
git push origin master
mkdir build
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "Info.plist")
xcodebuild -project DisplayBrightness.xcodeproj -scheme DisplayBrightness -archivePath build/DisplayBrightness.xarchive archive
xcodebuild -exportArchive -archivePath build/DisplayBrightness.xarchive.xcarchive -exportPath build/ -exportOptionsPlist export.plist
cd build
zip -r "DisplayBrightness_${VERSION}.zip" DisplayBrightness.app/
# https://developer.github.com/v3/repos/releases/#create-a-release 


