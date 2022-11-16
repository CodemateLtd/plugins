import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_android/google_maps_places_android.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';

void main() {

  test('registers instance', () async {
    GoogleMapsPlacesAndroid.registerWith();
    expect(GoogleMapsPlacesPlatform.instance, isA<GoogleMapsPlacesAndroid>());
  });
}
