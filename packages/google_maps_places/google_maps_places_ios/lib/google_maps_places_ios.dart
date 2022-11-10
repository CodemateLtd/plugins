
import 'google_maps_places_ios_platform_interface.dart';

class GoogleMapsPlacesIos {
  Future<String?> getPlatformVersion() {
    return GoogleMapsPlacesIosPlatform.instance.getPlatformVersion();
  }
}
