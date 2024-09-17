import Flutter
import ReplayKit

public final class ReplayKitLauncherPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {


    static let kStatusChannel = "replay_kit_launcher/status"
    static let kBufferChannel = "replay_kit_launcher/buffer"
    static let kStartChannel = "replay_kit_launcher/start"
    static let kStopChannel = "replay_kit_launcher/stop"
    
    var statusEventSink: FlutterEventSink?
    var bufferEventSink: FlutterEventSink?  // Отдельный eventSink для буфера

    static var shared: ReplayKitLauncherPlugin = {
        return ReplayKitLauncherPlugin()
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "replay_kit_launcher", binaryMessenger: registrar.messenger())
        let instance = ReplayKitLauncherPlugin.shared
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let statusChannel = FlutterEventChannel(name: kStatusChannel, binaryMessenger: registrar.messenger())
        statusChannel.setStreamHandler(instance)

        let bufferChannel = FlutterEventChannel(name: kBufferChannel, binaryMessenger: registrar.messenger())
        bufferChannel.setStreamHandler(instance)  // Зарегистрируем буферный канал
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
    
    // StreamHandler для общего статуса
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if arguments as? String == ReplayKitLauncherPlugin.kStatusChannel {
            statusEventSink = events
        } else if arguments as? String == ReplayKitLauncherPlugin.kBufferChannel {
            bufferEventSink = events  // Обрабатываем отдельно eventSink для буфера
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if arguments as? String == ReplayKitLauncherPlugin.kStatusChannel {
            statusEventSink = nil
        } else if arguments as? String == ReplayKitLauncherPlugin.kBufferChannel {
            bufferEventSink = nil  // Освобождаем eventSink для буфера
        }
        return nil
    }
    
    // Отправка статуса в основной eventSink
    func sendStatus(_ status: String) {
        statusEventSink?(status)
    }
    
    // Отправка данных буфера
    func sendBuffer(_ buffer: Data) {
        let base64Buffer = buffer.base64EncodedString()
        bufferEventSink?(base64Buffer)
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
    if let userInfo = userInfo as? [String: Any],
       let base64String = userInfo["sampleBufferData"] as? String,
       let bufferData = Data(base64Encoded: base64String) {
        ReplayKitLauncherPlugin.shared.sendBuffer(bufferData)
    } else {
        print("Error: Invalid buffer data")
    }
}
