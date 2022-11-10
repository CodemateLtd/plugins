import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'google_maps_places_android_method_channel.dart';

abstract class GoogleMapsPlacesAndroidPlatform extends PlatformInterface {
  /// Constructs a GoogleMapsPlacesAndroidPlatform.
  GoogleMapsPlacesAndroidPlatform() : super(token: _token);

  static final Object _token = Object();

  static GoogleMapsPlacesAndroidPlatform _instance = MethodChannelGoogleMapsPlacesAndroid();

  /// The default instance of [GoogleMapsPlacesAndroidPlatform] to use.
  ///
  /// Defaults to [MethodChannelGoogleMapsPlacesAndroid].
  static GoogleMapsPlacesAndroidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GoogleMapsPlacesAndroidPlatform] when
  /// they register themselves.
  static set instance(GoogleMapsPlacesAndroidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
