// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';
import 'messages.g.dart' as messages;

FindAutocompletePredictionsResponse convertReponse(
    messages.FindAutocompletePredictionsResponseAndroid reponse) {
  return FindAutocompletePredictionsResponse(
      results: reponse.results.map((e) => convertPredicion(e)).toList());
}

AutocompletePrediction? convertPredicion(
    messages.AutocompletePredictionAndroid? prediction) {
  if (prediction == null) return null;
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
  Future<FindAutocompletePredictionsResponse> findAutocompletePredictions(
      FindAutocompletePredictionsRequest request) async {
    final messages.FindAutocompletePredictionsResponseAndroid response =
        await _api.findAutocompletePredictionsAndroid(
            messages.FindAutocompletePredictionsRequestAndroid.decode(
                request.encode()));
    return convertReponse(response);
  }
}
