// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';
import 'messages.g.dart' as messages;

messages.LatLngAndroid? convertLatLng(LatLng? latLng) {
  if (latLng == null) {
    return null;
  }
  return messages.LatLngAndroid(
      latitude: latLng.latitude, longitude: latLng.longitude);
}

messages.LatLngBoundsAndroid? convertLatLngBounds(LatLngBounds? bounds) {
  if (bounds == null) {
    return null;
  }
  return messages.LatLngBoundsAndroid(
      northeast: convertLatLng(bounds.northeast),
      southwest: convertLatLng(bounds.southwest));
}

List<AutocompletePrediction> convertReponse(
    List<messages.AutocompletePredictionAndroid?> results) {
  return results
      .map((messages.AutocompletePredictionAndroid? e) => convertPrediction(e!))
      .toList();
}

AutocompletePrediction convertPrediction(
    messages.AutocompletePredictionAndroid prediction) {
  return AutocompletePrediction(
      distanceMeters: prediction.distanceMeters,
      fullText: prediction.fullText,
      placeId: prediction.placeId,
      placeTypes: prediction.placeTypes,
      primaryText: prediction.primaryText,
      secondaryText: prediction.secondaryText);
}

/// An implementation of [GoogleMapsPlacesPlatform] for Android.
class GoogleMapsPlacesAndroid extends GoogleMapsPlacesPlatform {
  final messages.GoogleMapsPlacesApiAndroid _api =
      messages.GoogleMapsPlacesApiAndroid();

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
    final List<messages.AutocompletePredictionAndroid?> response =
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
