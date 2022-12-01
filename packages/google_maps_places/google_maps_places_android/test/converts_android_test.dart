// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_android/google_maps_places_android.dart';
import 'package:google_maps_places_android/src/messages.g.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';

import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('converts', () {
    test('convertsLatLng', () async {
      final LatLngAndroid? converted = convertsLatLng(mockOrigin);
      expect(converted, isNotNull);
      expect(converted?.latitude, equals(mockOrigin.latitude));
      expect(converted?.longitude, equals(mockOrigin.longitude));

      expect(convertsLatLng(null), isNull);
    });
    test('convertsLatLngBounds', () async {
      final LatLngBoundsAndroid? converted =
          convertsLatLngBounds(mockLocationBias);
      expect(converted, isNotNull);
      expect(converted?.northeast?.latitude,
          equals(mockLocationBias.northeast.latitude));
      expect(converted?.northeast?.longitude,
          equals(mockLocationBias.northeast.longitude));
      expect(converted?.southwest?.latitude,
          equals(mockLocationBias.southwest.latitude));
      expect(converted?.southwest?.longitude,
          equals(mockLocationBias.southwest.longitude));

      expect(convertsLatLng(null), isNull);
    });
    test('convertsTypeFilter', () async {
      for (int i = 0; i < TypeFilter.values.length; i++) {
        final List<int>? converted =
            convertsTypeFilter(<TypeFilter>[TypeFilter.values[i]]);
        expect(converted, isNotNull);
        expect(converted?.length, equals(1));
        expect(TypeFilterAndroid.values[converted![0]].name,
            equals(TypeFilter.values[i].name));
      }
      expect(convertsTypeFilter(null), isNull);
    });
    test('convertsPlaceTypes', () async {
      for (int i = 0; i < PlaceTypeAndroid.values.length; i++) {
        final List<PlaceType> converted = convertsPlaceTypes(<int?>[i]);
        expect(converted.length, equals(1));
        expect(converted[0].name, equals(PlaceTypeAndroid.values[i].name));
      }
    });
    test('convertsPrediction', () async {
      final AutocompletePrediction converted =
          convertsPrediction(mockPrediction);
      expect(converted.distanceMeters, mockPrediction.distanceMeters);
      expect(converted.fullText, mockPrediction.fullText);
      expect(converted.placeId, mockPrediction.placeId);
      expect(converted.placeTypes.length, mockPrediction.placeTypes.length);
      expect(converted.primaryText, mockPrediction.primaryText);
      expect(converted.secondaryText, mockPrediction.secondaryText);
    });
    test('convertsReponse', () async {
      final List<AutocompletePrediction> converted =
          convertsReponse(<AutocompletePredictionAndroid>[mockPrediction]);
      expect(converted.length, equals(1));
    });
  });
}
