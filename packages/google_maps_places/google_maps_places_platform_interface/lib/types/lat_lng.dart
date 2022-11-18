// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class LatLng {
  LatLng({
    this.latitude,
    this.longitude,
  });

  double? latitude;
  double? longitude;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['latitude'] = latitude;
    pigeonMap['longitude'] = longitude;
    return pigeonMap;
  }

  static LatLng decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return LatLng(
      latitude: pigeonMap['latitude'] as double?,
      longitude: pigeonMap['longitude'] as double?,
    );
  }
}
