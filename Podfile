source 'https://github.com/CocoaPods/Specs.git'
platform :osx, '13.0'

inhibit_all_warnings!

target 'Easydict' do
  use_frameworks!
  
  pod 'AFNetworking', '~> 3.2.1'
  pod 'Masonry', '~> 1.1.0'
  pod 'ReactiveObjC', '~> 3.1.1'
  pod 'KVOController', '~> 1.2.0'
  pod 'JLRoutes', '~> 2.1'
  
  # Swift format and linting migrated to Swift Package Manager
  # See scripts/format.sh and scripts/lint.sh

end

target 'EasydictTests' do
  use_frameworks!
  
  pod 'AFNetworking', '~> 3.2.1'
  pod 'Masonry', '~> 1.1.0'
  pod 'ReactiveObjC', '~> 3.1.1'
  pod 'KVOController', '~> 1.2.0'
  pod 'JLRoutes', '~> 2.1'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
      
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
    end
  end
end
