// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:google_maps_places_platform_interface/types/autoCompletePlace.dart';

/// The response for a [GoogleMapsPlacesPlatform.findPlacesAutoComplete] request
class FindPlacesAutoCompleteResponse {
  const FindPlacesAutoCompleteResponse(this.places);

  /// the AutocompletePrediction list returned by the response.
  final List<AutoCompletePlace> places;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FindPlacesAutoCompleteResponse &&
          runtimeType == other.runtimeType &&
          listEquals(places, other.places);

  @override
  int get hashCode => places.hashCode;

  @override
  String toString() =>
      'FindPlacesAutoCompleteResponse{predictions: $places}';
}