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
  Future<FindPlacesAutoCompleteResponse> findPlacesAutoComplete(
    String query, {
    List<String>? countries,
    PlaceTypeFilter placeTypeFilter = PlaceTypeFilter.ALL,
    bool? newSessionToken,
    LatLng? origin,
    LatLngBounds? locationBias,
    LatLngBounds? locationRestriction,
  }) {
    if (query.isEmpty) {
      throw ArgumentError('Argument query can not be empty');
    }
    return _channel.invokeListMethod<Map<dynamic, dynamic>>(
      'findPlacesAutoComplete',
      {
        'query': query,
        'countries': countries ?? [],
        'typeFilter': placeTypeFilter.value,
        'newSessionToken': newSessionToken,
        'origin': origin?.toJson(),
        'locationBias': locationBias?.toJson(),
        'locationRestriction': locationRestriction?.toJson(),
      },
    ).then(_responseFromResult);
  }

  FindPlacesAutoCompleteResponse _responseFromResult(
    List<Map<dynamic, dynamic>>? value,
  ) {
    final items = value
            ?.map((item) => item.cast<String, dynamic>())
            .map((map) => AutoCompletePlace.fromJson(map))
            .toList(growable: false) ??
        [];
    return FindPlacesAutoCompleteResponse(items);
  }
}
