import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'google_maps_places_ios_method_channel.dart';

abstract class GoogleMapsPlacesIosPlatform extends PlatformInterface {
  /// Constructs a GoogleMapsPlacesIosPlatform.
  GoogleMapsPlacesIosPlatform() : super(token: _token);

  static final Object _token = Object();

  static GoogleMapsPlacesIosPlatform _instance = MethodChannelGoogleMapsPlacesIos();

  /// The default instance of [GoogleMapsPlacesIosPlatform] to use.
  ///
  /// Defaults to [MethodChannelGoogleMapsPlacesIos].
  static GoogleMapsPlacesIosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GoogleMapsPlacesIosPlatform] when
  /// they register themselves.
  static set instance(GoogleMapsPlacesIosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
