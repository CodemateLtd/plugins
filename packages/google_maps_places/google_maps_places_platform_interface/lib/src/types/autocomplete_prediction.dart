// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class AutocompletePrediction {
  AutocompletePrediction({
    this.distanceMeters,
    required this.fullText,
    required this.placeId,
    required this.placeTypes,
    required this.primaryText,
    required this.secondaryText,
  });

  int? distanceMeters;
  String fullText;
  String placeId;
  List<int?> placeTypes;
  String primaryText;
  String secondaryText;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['distanceMeters'] = distanceMeters;
    pigeonMap['fullText'] = fullText;
    pigeonMap['placeId'] = placeId;
    pigeonMap['placeTypes'] = placeTypes;
    pigeonMap['primaryText'] = primaryText;
    pigeonMap['secondaryText'] = secondaryText;
    return pigeonMap;
  }

  static AutocompletePrediction decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return AutocompletePrediction(
      distanceMeters: pigeonMap['distanceMeters'] as int?,
      fullText: pigeonMap['fullText']! as String,
      placeId: pigeonMap['placeId']! as String,
      placeTypes: (pigeonMap['placeTypes'] as List<Object?>?)!.cast<int?>(),
      primaryText: pigeonMap['primaryText']! as String,
      secondaryText: pigeonMap['secondaryText']! as String,
    );
  }
}
