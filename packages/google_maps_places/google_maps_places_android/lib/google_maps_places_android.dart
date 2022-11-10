
import 'google_maps_places_android_platform_interface.dart';

class GoogleMapsPlacesAndroid {
  Future<String?> getPlatformVersion() {
    return GoogleMapsPlacesAndroidPlatform.instance.getPlatformVersion();
  }
}
