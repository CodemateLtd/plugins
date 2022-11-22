// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';
import 'messages.g.dart' as messages;

messages.LatLngIOS? convertLatLng(LatLng? latLng) {
  if (latLng == null) {
    return null;
  }
  return messages.LatLngIOS(
      latitude: latLng.latitude, longitude: latLng.longitude);
}

messages.LatLngBoundsIOS? convertLatLngBounds(LatLngBounds? bounds) {
  if (bounds == null) {
    return null;
  }
  return messages.LatLngBoundsIOS(
      northeast: convertLatLng(bounds.northeast),
      southwest: convertLatLng(bounds.southwest));
}

List<AutocompletePrediction> convertReponse(
    List<messages.AutocompletePredictionIOS?> results) {
  return results
      .map((messages.AutocompletePredictionIOS? e) => convertPrediction(e!))
      .toList();
}

AutocompletePrediction convertPrediction(
    messages.AutocompletePredictionIOS prediction) {
  return AutocompletePrediction(
      distanceMeters: prediction.distanceMeters,
      fullText: prediction.fullText,
      placeId: prediction.placeId,
      placeTypes: prediction.placeTypes,
      primaryText: prediction.primaryText,
      secondaryText: prediction.secondaryText);
}

/// An implementation of [GoogleMapsPlacesPlatform] for IOS.
class GoogleMapsPlacesIOS extends GoogleMapsPlacesPlatform {
  final messages.GoogleMapsPlacesApiIOS _api =
      messages.GoogleMapsPlacesApiIOS();

  /// Registers this class as the default platform implementation.
  static void registerWith() {
    GoogleMapsPlacesPlatform.instance = GoogleMapsPlacesIOS();
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
    final List<messages.AutocompletePredictionIOS?>? response =
        await _api.findAutocompletePredictionsIOS(
            query,
            convertLatLngBounds(locationBias),
            convertLatLngBounds(locationBias),
            convertLatLng(origin),
            countries,
            typeFilter,
            refreshToken);
    if (response == null) {
      throw ArgumentError(
          'API returned empty response. Check log for details.');
    }
    return convertReponse(response);
  }
}
