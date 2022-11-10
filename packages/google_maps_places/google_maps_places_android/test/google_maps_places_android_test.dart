import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_android/google_maps_places_android.dart';
import 'package:google_maps_places_android/google_maps_places_android_platform_interface.dart';
import 'package:google_maps_places_android/google_maps_places_android_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGoogleMapsPlacesAndroidPlatform
    with MockPlatformInterfaceMixin
    implements GoogleMapsPlacesAndroidPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GoogleMapsPlacesAndroidPlatform initialPlatform = GoogleMapsPlacesAndroidPlatform.instance;

  test('$MethodChannelGoogleMapsPlacesAndroid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGoogleMapsPlacesAndroid>());
  });

  test('getPlatformVersion', () async {
    GoogleMapsPlacesAndroid googleMapsPlacesAndroidPlugin = GoogleMapsPlacesAndroid();
    MockGoogleMapsPlacesAndroidPlatform fakePlatform = MockGoogleMapsPlacesAndroidPlatform();
    GoogleMapsPlacesAndroidPlatform.instance = fakePlatform;

    expect(await googleMapsPlacesAndroidPlugin.getPlatformVersion(), '42');
  });
}
