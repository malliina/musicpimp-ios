source 'https://cdn.cocoapods.org/'
#source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.3'
ENV['COCOAPODS_DISABLE_STATS'] = "true"
use_frameworks!

# https://stackoverflow.com/a/13209057
inhibit_all_warnings!

def app_pods
    pod 'AppCenter', '4.1.0'
    pod 'RxCocoa', '6.0.0'
    pod 'RxSwift', '6.0.0'
    pod 'SnapKit', '5.0.1'
    pod 'SocketRocket', '0.5.1'
end

target 'MusicPimp' do
    app_pods
end

target 'MusicPimpTests' do
    app_pods
end
