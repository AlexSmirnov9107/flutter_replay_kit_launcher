Pod::Spec.new do |s|
  s.name             = 'replay_kit_launcher'
  s.version          = '1.0.5'
  s.summary          = 'A Flutter plugin to open RPSystemBroadcastPickerView for iOS'
  s.description      = <<-DESC
A Flutter plugin to open RPSystemBroadcastPickerView for iOS, rewritten in Swift.
                       DESC
  s.homepage         = 'https://lombard-b.kz'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'A|M Smirnov' => 'smirnov.a.n.9107@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'replay_kit_launcher/Sources/**/*.{swift}'  # Указываем Swift файлы
  s.dependency 'Flutter'
    s.xcconfig = {
      'LIBRARY_SEARCH_PATHS' => '$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)/ $(SDKROOT)/usr/lib/swift',
      'LD_RUNPATH_SEARCH_PATHS' => '/usr/lib/swift',
  }
  s.dependency 'Flutter'
  s.swift_version = '5.0'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # Установки для поддержки Swift
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }
end
