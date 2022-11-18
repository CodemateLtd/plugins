// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import '../google_maps_places_platform_interface.dart';
import '../types/types.dart';

const MethodChannel _channel =
    MethodChannel('plugins.flutter.io/google_maps_places');

/// The default interface implementation acting as a placeholder for
/// the native implementation to be set.
///
/// This implementation is not used by any of the implementations in this
/// repository, and exists only for backward compatibility with any
/// clients that were relying on internal details of the method channel
/// in the pre-federated plugin.
class GoogleMapsPlacesMethodChannel extends GoogleMapsPlacesPlatform {
  ///
  @override
  Future<FindAutocompletePredictionsResponse> findAutocompletePredictions(
      FindAutocompletePredictionsRequest request) async {
    if (request.query.isEmpty) {
      throw ArgumentError('Argument query can not be empty');
    }
    return await _channel.invokeMethod<Map<Object?, Object?>>(
      'findAutocompletePredictions',
      {
        request.encode(),
      },
    ).then(_responseFromResult);
  }

  FindAutocompletePredictionsResponse _responseFromResult(
    Map<Object?, Object?>? value,
  ) {
    if (value == null) {
      throw ArgumentError('Argument query can not be empty');
    }
    return FindAutocompletePredictionsResponse.decode(value);
  }
}
