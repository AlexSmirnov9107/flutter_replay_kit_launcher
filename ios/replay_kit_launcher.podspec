Pod::Spec.new do |s|
  s.name             = 'replay_kit_launcher'
  s.version          = '1.0.2+2'
  s.summary          = 'A Flutter plugin to open RPSystemBroadcastPickerView for iOS'
  s.description      = <<-DESC
A Flutter plugin to open RPSystemBroadcastPickerView for iOS, rewritten in Swift.
                       DESC
  s.homepage         = 'https://lombard-b.kz'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'A|M Smirnov' => 'smirnov.a.n.9107@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{swift}'  # Указываем Swift файлы
  s.platform = :ios, '9.0'
  
  # Укажите версию Swift, если необходимо
  s.swift_version = '5.0'  # Задаем версию Swift

  s.dependency 'Flutter'

  # Установки для поддержки Swift
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0',  # Поддержка версии Swift
  }
end
