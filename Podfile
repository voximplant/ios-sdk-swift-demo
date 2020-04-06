platform :ios, '9.0'
use_frameworks!
inhibit_all_warnings!

project 'Swift.xcodeproj'

def common_pods
  pod 'MBProgressHUD', '~> 1.1.0'
end

def voximplant
   pod 'CocoaLumberjack/Swift', '~> 3.5'
   pod 'VoxImplantSDK/CocoaLumberjackLogger', '2.30.0'
end

target 'Voximplant Demo' do
  pod 'SkyFloatingLabelTextField', '~> 3.0'
  common_pods
  voximplant
end

target 'AudioCall' do
  common_pods
  voximplant
end

target 'AudioCallKit' do
  common_pods
  voximplant
end

target 'Conference' do
   voximplant
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
