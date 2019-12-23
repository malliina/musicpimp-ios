[![Build status](https://build.appcenter.ms/v0.1/apps/1125aac7-1f28-428f-9bd7-da743a53af8c/branches/master/badge)](https://appcenter.ms)

# MusicPimp-iOS

This is the MusicPimp app for iOS. For more information, see www.musicpimp.org.

## Tests

To run tests:

    pod install
    xcodebuild test -workspace MusicPimp.xcworkspace -scheme MusicPimp -destination 'platform=iOS Simulator,name=iPhone 11,OS=13.3'
