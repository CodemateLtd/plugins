import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_ios/google_maps_places_ios.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';

void main() {

  test('registers instance', () async {
    GoogleMapsPlacesIOS.registerWith();
    expect(GoogleMapsPlacesPlatform.instance, isA<GoogleMapsPlacesIOS>());
  });
}
