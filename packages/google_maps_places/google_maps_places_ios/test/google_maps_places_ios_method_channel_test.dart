import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_ios/google_maps_places_ios_method_channel.dart';

void main() {
  MethodChannelGoogleMapsPlacesIos platform = MethodChannelGoogleMapsPlacesIos();
  const MethodChannel channel = MethodChannel('google_maps_places_ios');

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
