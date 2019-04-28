source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.3'
ENV['COCOAPODS_DISABLE_STATS'] = "true"
use_frameworks!

# https://stackoverflow.com/a/13209057
inhibit_all_warnings!

def app_pods
    pod 'AppCenter', '1.14.0'
    pod 'RxCocoa', '4.5.0'
    pod 'RxSwift', '4.5.0'
    pod 'SnapKit', '4.2.0'
    pod 'SocketRocket', '0.5.1'
end

target 'MusicPimp' do
    app_pods
end

target 'MusicPimpTests' do
    app_pods
end
