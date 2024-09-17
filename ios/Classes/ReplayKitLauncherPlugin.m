#import "ReplayKitLauncherPlugin.h"
#import <ReplayKit/ReplayKit.h>

static NSString *const kStatusChannel = @"replay_kit_launcher/status";
static NSString *const kBufferChannel = @"replay_kit_launcher/buffer";
static NSString *const kStartChannel = @"replay_kit_launcher/start";
static NSString *const kStopChannel = @"replay_kit_launcher/stop";


@implementation ReplayKitLauncherPlugin{
    FlutterEventSink eventSink;
}

static id _instance;

+ (ReplayKitLauncherPlugin *)sharedInstance {
  if (_instance == nil) {
    _instance = [[ReplayKitLauncherPlugin alloc] init];
  }
  return _instance;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
      FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"replay_kit_launcher" binaryMessenger:[registrar messenger]];
      ReplayKitLauncherPlugin *instance = [ReplayKitLauncherPlugin sharedInstance];
      
      [registrar addMethodCallDelegate:instance channel:channel];

      FlutterEventChannel *statusChannel =
      [FlutterEventChannel eventChannelWithName:kStatusChannel
                                binaryMessenger:[registrar messenger]];
      [statusChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

    if ([@"launchReplayKitBroadcast" isEqualToString:call.method]) {

        [self launchReplayKitBroadcast:call.arguments[@"extensionName"] result:result];

    } else if ([@"finishReplayKitBroadcast" isEqualToString:call.method]) {

        NSString *notificationName = call.arguments[@"notificationName"];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)notificationName, NULL, nil, YES);
        result(@(YES));

    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)launchReplayKitBroadcast:(NSString *)extensionName result:(FlutterResult)result {
    if (@available(iOS 12.0, *)) {

        RPSystemBroadcastPickerView *broadcastPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:extensionName ofType:@"appex" inDirectory:@"PlugIns"];
        if (!bundlePath) {
            NSString *nullBundlePathErrorMessage = [NSString stringWithFormat:@"Can not find path for bundle `%@.appex`", extensionName];
            NSLog(@"%@", nullBundlePathErrorMessage);
            result([FlutterError errorWithCode:@"NULL_BUNDLE_PATH" message:nullBundlePathErrorMessage details:nil]);
            return;
        }

        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        if (!bundle) {
            NSString *nullBundleErrorMessage = [NSString stringWithFormat:@"Can not find bundle at path: `%@`", bundlePath];
            NSLog(@"%@", nullBundleErrorMessage);
            result([FlutterError errorWithCode:@"NULL_BUNDLE" message:nullBundleErrorMessage details:nil]);
            return;
        }

        broadcastPickerView.preferredExtension = bundle.bundleIdentifier;


        // Traverse the subviews to find the button to skip the step of clicking the system view

        // This solution is not officially recommended by Apple, and may be invalid in future system updates

        // The safe solution is to directly add RPSystemBroadcastPickerView as subView to your view

        for (UIView *subView in broadcastPickerView.subviews) {
            if ([subView isMemberOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)subView;
                [button sendActionsForControlEvents:UIControlEventAllEvents];
            }
        }
        result(@(YES));

    } else {
        NSString *notAvailiableMessage = @"RPSystemBroadcastPickerView is only available on iOS 12.0 or above";
        NSLog(@"%@", notAvailiableMessage);
        result([FlutterError errorWithCode:@"NOT_AVAILIABLE" message:notAvailiableMessage details:nil]);
    }

}
- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)eventSinks {
  eventSink = eventSinks;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                  (__bridge const void *)(self),
                                  onStart,
                                  (CFStringRef)kStartChannel,
                                  NULL,
                                  CFNotificationSuspensionBehaviorDeliverImmediately);
     CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                  (__bridge const void *)(self),
                                  onStop,
                                  (CFStringRef)kStopChannel,
                                  NULL,
                                  CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                     (__bridge const void *)(self),
                                     onBuffer,
                                     (CFStringRef)kBufferChannel,
                                     NULL,
                                     CFNotificationSuspensionBehaviorDeliverImmediately);                                  
                             
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       (__bridge const void *)(self),
                                       (CFStringRef)kStartChannel,
                                       NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       (__bridge const void *)(self),
                                       (CFStringRef)kStopChannel,
                                       NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)(self),
                                        (CFStringRef)kBufferChannel,
                                        NULL);     
  eventSink = nil;
  return nil;
}


- (void) sendStatus:(NSString *)status{
    eventSink(status);
}

void onStart(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[ReplayKitLauncherPlugin sharedInstance] sendStatus:@"0"];
}
void onStop(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[ReplayKitLauncherPlugin sharedInstance] sendStatus:@"1"];
}


void onBuffer(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    // Преобразуйте CFDictionaryRef в NSDictionary
    NSDictionary *userInfoDict = (__bridge NSDictionary *)userInfo;
    
    // Извлеките base64String из словаря
    NSString *base64String = userInfoDict[@"sampleBufferData"];
    
    // Преобразуйте base64String обратно в NSData
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    
    // Убедитесь, что ReplayKitLauncherPlugin доступен
    ReplayKitLauncherPlugin *plugin = [ReplayKitLauncherPlugin sharedInstance];
    if (plugin) {
        // Отправьте данные во Flutter
        [plugin sendStatus:[imageData base64EncodedStringWithOptions:0]];
    } else {
        NSLog(@"ReplayKitLauncherPlugin instance is not available");
    }
}

@end
