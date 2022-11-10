import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'google_maps_places_android_platform_interface.dart';

/// An implementation of [GoogleMapsPlacesAndroidPlatform] that uses method channels.
class MethodChannelGoogleMapsPlacesAndroid extends GoogleMapsPlacesAndroidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('google_maps_places_android');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
