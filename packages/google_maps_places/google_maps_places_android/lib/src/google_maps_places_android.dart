// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of google_maps_places_android;

/// An implementation of [GoogleMapsPlacesPlatform] for Android.
class GoogleMapsPlacesAndroid extends GoogleMapsPlacesPlatform {
  final GoogleMapsPlacesApiAndroid _api = GoogleMapsPlacesApiAndroid();

  /// Registers this class as the default platform implementation.
  static void registerWith() {
    GoogleMapsPlacesPlatform.instance = GoogleMapsPlacesAndroid();
  }

  @override
  Future<List<AutocompletePrediction>> findAutocompletePredictions({
    required String query,
    LatLngBounds? locationBias,
    LatLngBounds? locationRestriction,
    LatLng? origin,
    List<String?>? countries,
    List<int?>? typeFilter,
    bool? refreshToken,
  }) async {
    final List<AutocompletePredictionAndroid?> response =
        await _api.findAutocompletePredictionsAndroid(
            query,
            convertLatLngBounds(locationBias),
            convertLatLngBounds(locationBias),
            convertLatLng(origin),
            countries,
            typeFilter,
            refreshToken);
    return convertReponse(response);
  }
}
