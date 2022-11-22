// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of google_maps_places_ios;

/// Converts [LatLng] to [LatLngIOS]
LatLngIOS? convertLatLng(LatLng? latLng) {
  if (latLng == null) {
    return null;
  }
  return LatLngIOS(latitude: latLng.latitude, longitude: latLng.longitude);
}

/// Converts [LatLngBounds] to [LatLngBoundsIOS]
LatLngBoundsIOS? convertLatLngBounds(LatLngBounds? bounds) {
  if (bounds == null) {
    return null;
  }
  return LatLngBoundsIOS(
      northeast: convertLatLng(bounds.northeast),
      southwest: convertLatLng(bounds.southwest));
}

/// Converts list of [AutocompletePredictionIOS] to list of [AutocompletePrediction]
List<AutocompletePrediction> convertReponse(
    List<AutocompletePredictionIOS?> results) {
  return results
      .map((AutocompletePredictionIOS? e) => convertPrediction(e!))
      .toList();
}

/// Converts [AutocompletePredictionIOS] to [AutocompletePrediction]
AutocompletePrediction convertPrediction(AutocompletePredictionIOS prediction) {
  return AutocompletePrediction(
      distanceMeters: prediction.distanceMeters,
      fullText: prediction.fullText,
      placeId: prediction.placeId,
      placeTypes: prediction.placeTypes,
      primaryText: prediction.primaryText,
      secondaryText: prediction.secondaryText);
}