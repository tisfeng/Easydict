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
  pod 'JLRoutes', '~> 2.1'
  
  # Add the Firebase pod for Google Analytics
  pod 'FirebaseAnalytics'
  pod 'AppCenter'
  
end

target 'EasydictTests' do
  use_frameworks!
  
  pod 'AFNetworking', '~> 3.2.1'
  pod 'MJExtension', '~> 3.2.1'
  pod 'Masonry', '~> 1.1.0'
  pod 'ReactiveObjC', '~> 3.1.1'
  pod 'MASShortcut', '~> 2.4.0'
  pod 'MASPreferences', '~> 1.4.1'
  pod 'CocoaLumberjack/Swift', '~> 3.6.0'
  pod 'SSZipArchive', '~> 2.2.2'
  pod 'KVOController'
  pod 'JLRoutes', '~> 2.1'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
      
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
    end
  end
end
