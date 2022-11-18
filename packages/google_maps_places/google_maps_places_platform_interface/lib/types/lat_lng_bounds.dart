// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'lat_lng.dart';

class LatLngBounds {
  LatLngBounds({
    this.southwest,
    this.northeast,
  });

  LatLng? southwest;
  LatLng? northeast;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['southwest'] = southwest?.encode();
    pigeonMap['northeast'] = northeast?.encode();
    return pigeonMap;
  }

  static LatLngBounds decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return LatLngBounds(
      southwest: pigeonMap['southwest'] != null
          ? LatLng.decode(pigeonMap['southwest']!)
          : null,
      northeast: pigeonMap['northeast'] != null
          ? LatLng.decode(pigeonMap['northeast']!)
          : null,
    );
  }
}