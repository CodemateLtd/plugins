// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_ios/google_maps_places_ios.dart';
import 'package:google_maps_places_ios/src/messages.g.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('converts', () {
    test('convertsLatLng', () async {
      const LatLng latLng = LatLng(65.0121, 25.4651);
      final LatLngIOS? converted = convertsLatLng(latLng);
      expect(converted, isNotNull);
      expect(converted?.latitude, equals(latLng.latitude));
      expect(converted?.longitude, equals(latLng.longitude));

      expect(convertsLatLng(null), isNull);
    });
    test('convertsLatLngBounds', () async {
      final LatLngBounds locationBias = LatLngBounds(
        southwest: const LatLng(60.4518, 22.2666),
        northeast: const LatLng(70.0821, 27.8718),
      );
      final LatLngBoundsIOS? converted = convertsLatLngBounds(locationBias);
      expect(converted, isNotNull);
      expect(converted?.northeast?.latitude,
          equals(locationBias.northeast.latitude));
      expect(converted?.northeast?.longitude,
          equals(locationBias.northeast.longitude));
      expect(converted?.southwest?.latitude,
          equals(locationBias.southwest.latitude));
      expect(converted?.southwest?.longitude,
          equals(locationBias.southwest.longitude));

      expect(convertsLatLng(null), isNull);
    });
    test('convertsTypeFilter', () async {
      for (int i = 0; i < TypeFilter.values.length; i++) {
        final List<int>? converted =
            convertsTypeFilter(<TypeFilter>[TypeFilter.values[i]]);
        expect(converted, isNotNull);
        expect(converted?.length, equals(1));
        expect(TypeFilterIOS.values[converted![0]].name,
            equals(TypeFilter.values[i].name));
      }
      expect(convertsTypeFilter(null), isNull);
    });
    test('convertsPlaceTypes', () async {
      for (int i = 0; i < PlaceTypeIOS.values.length; i++) {
        final List<PlaceType> converted = convertsPlaceTypes(<int?>[i]);
        expect(converted.length, equals(1));
        expect(converted[0].name, equals(PlaceTypeIOS.values[i].name));
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
          convertsReponse(<AutocompletePredictionIOS>[mockPrediction]);
      expect(converted.length, equals(1));
    });
  });
}

final AutocompletePredictionIOS mockPrediction = AutocompletePredictionIOS(
    distanceMeters: 200,
    fullText: 'Koulukatu, Tampere, Finland, placeId',
    placeId:
        'EhtLb3VsdWthdHUsIFRhbXBlcmUsIEZpbmxhbmQiLiosChQKEgmNKrw3sNiORhGUm8jmSvlI4RIUChIJVVwAnVEkj0YRhhoEA3s-vUQ',
    placeTypes: <int?>[110, 54],
    primaryText: 'Koulukatu',
    secondaryText: 'Tampere, Finland');
