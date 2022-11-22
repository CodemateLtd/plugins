// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_classes_with_only_static_members

import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';

export 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart'
    show AutocompletePrediction, LatLng, LatLngBounds, TypeFilter, PlaceType;

/// Document this
class GoogleMapsPlaces {
  static final GoogleMapsPlacesPlatform _instance =
      GoogleMapsPlacesPlatform.instance;

  /// Comment
  static Future<List<AutocompletePrediction>> findAutocompletePredictions({
    required String query,
    LatLngBounds? locationBias,
    LatLngBounds? locationRestriction,
    LatLng? origin,
    List<String?>? countries,
    List<int?>? typeFilter,
    bool? refreshToken,
  }) async {
    return await _instance.findAutocompletePredictions(
        query: query,
        countries: countries,
        origin: origin,
        locationBias: locationBias,
        locationRestriction: locationRestriction,
        typeFilter: typeFilter,
        refreshToken: refreshToken);
  }
}
