import 'package:flutter_test/flutter_test.dart';

void main() {
  // const MethodChannel channel = MethodChannel('replay_kit_launcher');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // channel.setMockMethodCallHandler((MethodCall methodCall) async {
    //   return '42';
    // });
  });

  tearDown(() {
    // channel.setMockMethodCallHandler(null);
  });
}
