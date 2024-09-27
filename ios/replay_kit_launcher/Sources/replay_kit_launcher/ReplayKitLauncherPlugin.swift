import Flutter
import ReplayKit

public class ReplayKitLauncherPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    static let kStatusChannel = "replay_kit_launcher/status"
    static let kBufferChannel = "replay_kit_launcher/buffer"
    static let kStartChannel = "replay_kit_launcher/start"
    static let kStopChannel = "replay_kit_launcher/stop"
    static let kLogChannel = "replay_kit_launcher/log"
    static let kDataChannel = "replay_kit_launcher/data"

    
    
    var statusEventSink: FlutterEventSink?
    var bufferEventSink: FlutterEventSink?
    var logEventSink: FlutterEventSink?


    public static var shared: ReplayKitLauncherPlugin = {
        return ReplayKitLauncherPlugin()
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "replay_kit_launcher", binaryMessenger: registrar.messenger())
        let instance = ReplayKitLauncherPlugin.shared
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let statusChannel = FlutterEventChannel(name: kStatusChannel, binaryMessenger: registrar.messenger())
        statusChannel.setStreamHandler(instance)

        let bufferChannel = FlutterEventChannel(name: kBufferChannel, binaryMessenger: registrar.messenger())
        bufferChannel.setStreamHandler(instance)
        
        let logChannel = FlutterEventChannel(name: kLogChannel, binaryMessenger: registrar.messenger())
        logChannel.setStreamHandler(instance)
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "launchReplayKitBroadcast":
            if let args = call.arguments as? [String: Any],
               let extensionName = args["extensionName"] as? String {
                launchReplayKitBroadcast(extensionName: extensionName, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing extension name", details: nil))
            }
        case "getData":
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                                 CFNotificationName(ReplayKitLauncherPlugin.kDataChannel as CFString),
                                                 nil, nil, true)
            result(true)
           
        case "finishReplayKitBroadcast":
            if let args = call.arguments as? [String: Any],
               let notificationName = args["notificationName"] as? String {
                CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                                     CFNotificationName(notificationName as CFString),
                                                     nil, nil, true)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing notification name", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func launchReplayKitBroadcast(extensionName: String, result: @escaping FlutterResult) {
        if #available(iOS 12.0, *) {
            let broadcastPickerView = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            guard let bundlePath = Bundle.main.path(forResource: extensionName, ofType: "appex", inDirectory: "PlugIns") else {
                let message = "Cannot find path for bundle \(extensionName).appex"
                print(message)
                result(FlutterError(code: "NULL_BUNDLE_PATH", message: message, details: nil))
                return
            }
            guard let bundle = Bundle(path: bundlePath) else {
                let message = "Cannot find bundle at path: \(bundlePath)"
                print(message)
                result(FlutterError(code: "NULL_BUNDLE", message: message, details: nil))
                return
            }
            
            broadcastPickerView.preferredExtension = bundle.bundleIdentifier
            if let button = broadcastPickerView.subviews.compactMap({ $0 as? UIButton }).first {
                button.sendActions(for: .allEvents)
            }
            result(true)
        } else {
            let message = "RPSystemBroadcastPickerView is only available on iOS 12.0 or above"
            print(message)
            result(FlutterError(code: "NOT_AVAILABLE", message: message, details: nil))
        }
    }
    
    // Добавляем наблюдателей для событий через CFNotificationCenter
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if arguments as? String == ReplayKitLauncherPlugin.kStatusChannel {
            statusEventSink = events
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            Unmanaged.passUnretained(self).toOpaque(),
                                            onStart,
                                            ReplayKitLauncherPlugin.kStartChannel as CFString,
                                            nil,
                                            .deliverImmediately)
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            Unmanaged.passUnretained(self).toOpaque(),
                                            onStop,
                                            ReplayKitLauncherPlugin.kStopChannel as CFString,
                                            nil,
                                            .deliverImmediately)
           
        } else if arguments as? String == ReplayKitLauncherPlugin.kBufferChannel {
            bufferEventSink = events
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            Unmanaged.passUnretained(self).toOpaque(),
                                            onBuffer,
                                            ReplayKitLauncherPlugin.kBufferChannel as CFString,
                                            nil,
                                            .deliverImmediately)
          
        } else if arguments as? String == ReplayKitLauncherPlugin.kLogChannel {
            logEventSink = events
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            Unmanaged.passUnretained(self).toOpaque(),
                                            onLog,
                                            ReplayKitLauncherPlugin.kLogChannel as CFString,
                                            nil,
                                            .deliverImmediately)
          
        }
        
        print("onListen @arguments: \(String(describing: arguments))")
     
       
        return nil
    }
    
    // Удаляем наблюдателей при отмене подписки
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("onCancel @arguments: \(String(describing: arguments))")
        if arguments as? String == ReplayKitLauncherPlugin.kStatusChannel {
            statusEventSink = nil
            CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                               Unmanaged.passUnretained(self).toOpaque(),
                                               CFNotificationName(ReplayKitLauncherPlugin.kStartChannel as CFString),
                                               nil)
            CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                               Unmanaged.passUnretained(self).toOpaque(),
                                               CFNotificationName(ReplayKitLauncherPlugin.kStopChannel as CFString),  // Преобразование к CFString
                                               nil)
           
        } else if arguments as? String == ReplayKitLauncherPlugin.kBufferChannel {
            bufferEventSink = nil
            CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                               Unmanaged.passUnretained(self).toOpaque(),
                                               CFNotificationName(ReplayKitLauncherPlugin.kBufferChannel as CFString),  // Преобразование к CFString
                                               nil)
        } else if arguments as? String == ReplayKitLauncherPlugin.kLogChannel {
            logEventSink = nil
            CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                               Unmanaged.passUnretained(self).toOpaque(),
                                               CFNotificationName(ReplayKitLauncherPlugin.kLogChannel as CFString),  // Преобразование к CFString
                                               nil)
        }
        
      
      
        return nil
    }
    
    public func sendStatus(_ status: String) {
        if let eventSink = statusEventSink {
                eventSink(status)
        } else {
            print("bufferEventSink is not set")
        }
    }
    
    
    public func sendBuffer(text: String) {
        
        if let eventSink = bufferEventSink {
                eventSink(text)
        } else {
            print("bufferEventSink is not set")
        }
    }
    public func sendLog(text: String) {
        
        if let eventSink = logEventSink {
                eventSink(text)
        } else {
            print("logEventSink is not set")
        }
    }
    
    
}

// Уведомление при старте
func onStart(center: CFNotificationCenter?, observer: UnsafeMutableRawPointer?, name: CFNotificationName?, object: UnsafeRawPointer?, userInfo: CFDictionary?) {
    ReplayKitLauncherPlugin.shared.sendStatus("0")
}

// Уведомление при остановке
func onStop(center: CFNotificationCenter?, observer: UnsafeMutableRawPointer?, name: CFNotificationName?, object: UnsafeRawPointer?, userInfo: CFDictionary?) {
    ReplayKitLauncherPlugin.shared.sendStatus("1")
}
// Уведомление для буфера
func onBuffer(center: CFNotificationCenter?, observer: UnsafeMutableRawPointer?, name: CFNotificationName?, object: UnsafeRawPointer?, userInfo: CFDictionary?) {
    if let userDefaults = UserDefaults(suiteName: "group.kz.white.broadcast") {
           if let text = userDefaults.string(forKey: "recognizedText") {
               // Отправляем текст в Flutter
               print("text: \(text)")
               ReplayKitLauncherPlugin.shared.sendBuffer(text:text)
               
               // Очищаем сохраненный текст
               userDefaults.removeObject(forKey: "recognizedText")
               userDefaults.synchronize()
           }
       }
     // Возвращаем буфер в виде строки Base64
}

func onLog(center: CFNotificationCenter?, observer: UnsafeMutableRawPointer?, name: CFNotificationName?, object: UnsafeRawPointer?, userInfo: CFDictionary?) {
    if let userDefaults = UserDefaults(suiteName: "group.kz.white.broadcast") {
           if let text = userDefaults.string(forKey: "log") {
               // Отправляем текст в Flutter
               ReplayKitLauncherPlugin.shared.sendLog(text:text)
               // Очищаем сохраненный текст
               userDefaults.removeObject(forKey: "log")
               userDefaults.synchronize()
           }
       }
     // Возвращаем буфер в виде строки Base64
}