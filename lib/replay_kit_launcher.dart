import 'dart:async';
import 'package:flutter/services.dart';

enum ReplayKitLauncherEnum {
  started,
  stoped,
}

class ReplayKitLauncher {
  static const MethodChannel _channel = const MethodChannel('replay_kit_launcher');

  /// This function will directly create a free RPSystemBroadcastPickerView and automatically click the View to launch ReplayKit
  ///
  /// [extensionName] is your `BroadCast Upload Extension` target's `Product Name`,
  /// or to be precise, the file name of the `.appex` product of the extension
  static Future<bool?> launchReplayKitBroadcast(String extensionName) async {
    return await _channel.invokeMethod('launchReplayKitBroadcast', {'extensionName': extensionName});
  }

  static Future<bool?> checkToggle(String toggleName) async {
    return await _channel.invokeMethod('checkToggle', {'toggleName': toggleName});
  }

  /// This function will post a notification by `CFNotificationCenterPostNotification()` with `notificationName`
  ///
  /// Developers need to implement the logic to finish broadcast after receiving the notification
  /// That is, invoke `-[RPBroadcastSampleHandler finishBroadcastWithError:]` when received the notification
  ///
  /// For specific implementation, please refer to `example/ios/BroadcastDemoExtension/SampleHandler.m`
  static Future<bool?> finishReplayKitBroadcast(String notificationName) async {
    if (notificationName.length <= 0) {
      return false;
    }

    return await _channel.invokeMethod('finishReplayKitBroadcast', {'notificationName': notificationName});
  }

  static const EventChannel _statusChannel = const EventChannel('replay_kit_launcher/status');

  static const EventChannel _bufferChannel = const EventChannel('replay_kit_launcher/buffer');
  static const EventChannel _logChannel = const EventChannel('replay_kit_launcher/log');
  static const EventChannel _toggleChannel = const EventChannel('replay_kit_launcher/toggle');

  static ReplayKitLauncherEnum? _intToStatus(String status) {
    switch (status) {
      case "0":
        return ReplayKitLauncherEnum.started;
      case "1":
        return ReplayKitLauncherEnum.stoped;
      default:
        return null;
    }
  }

  static Stream<ReplayKitLauncherEnum?> get statusEvent {
    return _statusChannel
        .receiveBroadcastStream('replay_kit_launcher/status')
        .distinct()
        .map((dynamic event) => _intToStatus(event as String));
  }

  static Stream<String> get bufferChannel {
    return _bufferChannel.receiveBroadcastStream('replay_kit_launcher/buffer').map((v) => v.toString());
  }

  static Stream<String> get logChannel {
    return _logChannel.receiveBroadcastStream('replay_kit_launcher/log').map((v) => v.toString());
  }

  static Stream<String> get toggleChannel {
    return _toggleChannel.receiveBroadcastStream('replay_kit_launcher/toggle').map((v) => v.toString());
  }
}
