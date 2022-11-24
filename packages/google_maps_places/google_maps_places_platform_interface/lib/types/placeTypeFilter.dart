// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Filter to restrict the result set of autocomplete predictions to certain types.
///
/// Ref: https://developers.google.com/maps/documentation/places/android-sdk/reference/com/google/android/libraries/places/api/model/TypeFilter
enum PlaceTypeFilter {
  /// Only return geocoding results with a precise address.
  ADDRESS,

  /// Return any result matching the following place types:
  ///
  /// LOCALITY
  /// ADMINISTRATIVE_AREA_LEVEL_3
  CITIES,

  /// Only return results that are classified as businesses.
  ESTABLISHMENT,

  /// Only return geocoding results, rather than business results.
  /// For example, parks, cities and street addresses.
  GEOCODE,

  /// Return any result matching the following place types:
  ///
  /// LOCALITY
  /// SUBLOCALITY
  /// POSTAL_CODE
  /// COUNTRY
  /// ADMINISTRATIVE_AREA_LEVEL_1
  /// ADMINISTRATIVE_AREA_LEVEL_2
  REGIONS,

  /// All types are returned
  ALL,
}

//
extension PlaceTypeFilterDescriptor on PlaceTypeFilter {
  String get value => describeEnum(this);
}
