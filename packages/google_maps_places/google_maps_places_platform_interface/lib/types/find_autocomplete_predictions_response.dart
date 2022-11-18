// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'autocomplete_prediction.dart';

class FindAutocompletePredictionsResponse {
  FindAutocompletePredictionsResponse({
    required this.results,
  });

  List<AutocompletePrediction?> results;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['results'] = results;
    return pigeonMap;
  }

  static FindAutocompletePredictionsResponse decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return FindAutocompletePredictionsResponse(
      results: (pigeonMap['results'] as List<Object?>?)!.cast<AutocompletePrediction?>(),
    );
  }
}
