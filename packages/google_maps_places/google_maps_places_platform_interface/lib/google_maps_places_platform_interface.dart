// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel/method_channel_google_maps_places.dart';
import 'types/types.dart';

export 'types/types.dart';

/// The interface that implementations of google_maps_platform must implement.
///
/// Platform implementations should extend this class rather than implement it as `google_maps_places`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [GoogleMapsPlacesPlatform] methods.
abstract class GoogleMapsPlacesPlatform extends PlatformInterface {
  /// Constructs a GoogleMapsPlacesPlatform.
  GoogleMapsPlacesPlatform() : super(token: _token);

  static final Object _token = Object();

  static GoogleMapsPlacesPlatform _instance = GoogleMapsPlacesMethodChannel();

  /// The instance of [GoogleMapsPlacesPlatform] to use.
  ///
  /// Defaults to a placeholder that does not override any methods, and thus
  /// throws `UnimplementedError` in most cases.
  static GoogleMapsPlacesPlatform get instance => _instance;

  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [GoogleMapsPlacesPlatform] when they
  /// register themselves.
  static set instance(GoogleMapsPlacesPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Fetches autocomplete predictions based on a query.
  Future<FindAutocompletePredictionsResponse> findAutocompletePredictions(
    FindAutocompletePredictionsRequest request) async {
    throw UnimplementedError(
        'findAutocompletePredictions() has not been implemented.');
  }
}
