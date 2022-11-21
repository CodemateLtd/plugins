// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';
import 'messages.g.dart' as messages;

FindAutocompletePredictionsResponse convertReponse(
    messages.FindAutocompletePredictionsResponseIOS reponse) {
  return FindAutocompletePredictionsResponse(
      results: reponse.results.map((e) => convertPredicion(e)).toList());
}

AutocompletePrediction? convertPredicion(
    messages.AutocompletePredictionIOS? prediction) {
  if (prediction == null) return null;
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
  Future<FindAutocompletePredictionsResponse> findAutocompletePredictions(
      FindAutocompletePredictionsRequest request) async {
    final messages.FindAutocompletePredictionsResponseIOS? response =
        await _api.findAutocompletePredictionsIOS(
            messages.FindAutocompletePredictionsRequestIOS.decode(
                request.encode()));
    if (response == null) {
      throw ArgumentError('API returned empty response. Check log for details.');
    }
    return convertReponse(response);
  }
}
