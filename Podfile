platform :ios, '8.0'
use_frameworks!
inhibit_all_warnings!

def common_pods
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'CocoaLumberjack/Swift', '~> 3.4.0'
  pod 'SkyFloatingLabelTextField', '~> 3.0'
end

sdk_version = '2.18.0'

target 'Voximplant Demo' do
  common_pods

  pod 'VoxImplantSDK', sdk_version
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
