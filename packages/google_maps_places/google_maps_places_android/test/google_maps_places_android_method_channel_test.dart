import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_android/google_maps_places_android_method_channel.dart';

void main() {
  MethodChannelGoogleMapsPlacesAndroid platform = MethodChannelGoogleMapsPlacesAndroid();
  const MethodChannel channel = MethodChannel('google_maps_places_android');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
