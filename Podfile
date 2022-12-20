source 'https://github.com/CocoaPods/Specs.git'
platform :osx, '11.0'

inhibit_all_warnings!

target 'Easydict' do
  use_frameworks!
  
  pod 'AFNetworking', '~> 3.2.1'
  pod 'MJExtension', '~> 3.2.1'
  pod 'Masonry', '~> 1.1.0'
  pod 'ReactiveObjC', '~> 3.1.1'
  pod 'MASShortcut', '~> 2.4.0'
  pod 'MASPreferences', '~> 1.4.1'
  pod 'CocoaLumberjack/Swift', '~> 3.6.0'
  pod 'SSZipArchive', '~> 2.2.2'
  pod 'Sparkle', '~> 1.24.0'
  pod 'KVOController'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
