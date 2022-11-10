import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_ios/google_maps_places_ios.dart';
import 'package:google_maps_places_ios/google_maps_places_ios_platform_interface.dart';
import 'package:google_maps_places_ios/google_maps_places_ios_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGoogleMapsPlacesIosPlatform
    with MockPlatformInterfaceMixin
    implements GoogleMapsPlacesIosPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GoogleMapsPlacesIosPlatform initialPlatform = GoogleMapsPlacesIosPlatform.instance;

  test('$MethodChannelGoogleMapsPlacesIos is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGoogleMapsPlacesIos>());
  });

  test('getPlatformVersion', () async {
    GoogleMapsPlacesIos googleMapsPlacesIosPlugin = GoogleMapsPlacesIos();
    MockGoogleMapsPlacesIosPlatform fakePlatform = MockGoogleMapsPlacesIosPlatform();
    GoogleMapsPlacesIosPlatform.instance = fakePlatform;

    expect(await googleMapsPlacesIosPlugin.getPlatformVersion(), '42');
  });
}
