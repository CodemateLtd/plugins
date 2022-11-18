// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'lat_lng.dart';
import 'lat_lng_bounds.dart';

class FindAutocompletePredictionsRequest {
  FindAutocompletePredictionsRequest({
    required this.query,
    this.locationBias,
    this.locationRestriction,
    this.origin,
    this.countries,
    this.typeFilter,
    this.refreshToken,
  });

  String query;
  LatLngBounds? locationBias;
  LatLngBounds? locationRestriction;
  LatLng? origin;
  List<String?>? countries;
  List<int?>? typeFilter;
  bool? refreshToken;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['query'] = query;
    pigeonMap['locationBias'] = locationBias?.encode();
    pigeonMap['locationRestriction'] = locationRestriction?.encode();
    pigeonMap['origin'] = origin?.encode();
    pigeonMap['countries'] = countries;
    pigeonMap['typeFilter'] = typeFilter;
    pigeonMap['refreshToken'] = refreshToken;
    return pigeonMap;
  }

  static FindAutocompletePredictionsRequest decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return FindAutocompletePredictionsRequest(
      query: pigeonMap['query']! as String,
      locationBias: pigeonMap['locationBias'] != null
          ? LatLngBounds.decode(pigeonMap['locationBias']!)
          : null,
      locationRestriction: pigeonMap['locationRestriction'] != null
          ? LatLngBounds.decode(pigeonMap['locationRestriction']!)
          : null,
      origin: pigeonMap['origin'] != null
          ? LatLng.decode(pigeonMap['origin']!)
          : null,
      countries: (pigeonMap['countries'] as List<Object?>?)?.cast<String?>(),
      typeFilter: (pigeonMap['typeFilter'] as List<Object?>?)?.cast<int?>(),
      refreshToken: pigeonMap['refreshToken'] as bool?,
    );
  }
}
