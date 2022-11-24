// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_ios/google_maps_places_ios.dart';
import 'package:google_maps_places_ios/src/messages.g.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'google_maps_places_ios_test.mocks.dart';

import 'messages_test.g.dart';

final AutocompletePredictionIOS mockPrediction = AutocompletePredictionIOS(
    distanceMeters: 200,
    fullText: 'Koulukatu, Tampere, Finland, placeId',
    placeId:
        'EhtLb3VsdWthdHUsIFRhbXBlcmUsIEZpbmxhbmQiLiosChQKEgmNKrw3sNiORhGUm8jmSvlI4RIUChIJVVwAnVEkj0YRhhoEA3s-vUQ',
    placeTypes: <int?>[110, 54],
    primaryText: 'Koulukatu',
    secondaryText: 'Tampere, Finland');

@GenerateMocks(<Type>[TestGoogleMapsPlacesApi])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final GoogleMapsPlacesIOS plugin = GoogleMapsPlacesIOS();
  late MockTestGoogleMapsPlacesApi mockApi;

  setUp(() {
    mockApi = MockTestGoogleMapsPlacesApi();
    TestGoogleMapsPlacesApi.setup(mockApi);
  });

  test('registers instance', () async {
    GoogleMapsPlacesIOS.registerWith();
    expect(GoogleMapsPlacesPlatform.instance, isA<GoogleMapsPlacesIOS>());
  });

  group('findAutocompletePredictions', () {
    setUp(() {
      when(mockApi.findAutocompletePredictionsIOS(
              any, any, any, any, any, any, any))
          .thenAnswer((Invocation _) async => []);
    });
    test('passes the accepted type groups correctly', () async {
      await plugin.findAutocompletePredictions(query: 'koulu');
      final VerificationResult result = verify(
          mockApi.findAutocompletePredictionsIOS(
              captureAny, captureAny, captureAny, captureAny, captureAny, captureAny, captureAny));
      expect(result.captured[0], 'koulu');
    });
  });

  group('convert', () {
    test('convertLatLng', () async {
      const LatLng latLng = LatLng(65.0121, 25.4651);
      final LatLngIOS? converted = convertLatLng(latLng);
      expect(converted, isNotNull);
      expect(converted?.latitude, equals(latLng.latitude));
      expect(converted?.longitude, equals(latLng.longitude));

      expect(convertLatLng(null), isNull);
    });
    test('convertLatLngBounds', () async {
      final LatLngBounds locationBias = LatLngBounds(
        southwest: const LatLng(60.4518, 22.2666),
        northeast: const LatLng(70.0821, 27.8718),
      );
      final LatLngBoundsIOS? converted = convertLatLngBounds(locationBias);
      expect(converted, isNotNull);
      expect(converted?.northeast?.latitude,
          equals(locationBias.northeast.latitude));
      expect(converted?.northeast?.longitude,
          equals(locationBias.northeast.longitude));
      expect(converted?.southwest?.latitude,
          equals(locationBias.southwest.latitude));
      expect(converted?.southwest?.longitude,
          equals(locationBias.southwest.longitude));

      expect(convertLatLng(null), isNull);
    });
    test('convertTypeFilter', () async {
      for (int i = 0; i < TypeFilter.values.length; i++) {
        final List<int>? converted =
            convertTypeFilter(<TypeFilter>[TypeFilter.values[i]]);
        expect(converted, isNotNull);
        expect(converted?.length, equals(1));
        expect(TypeFilterIOS.values[converted![0]].name,
            equals(TypeFilter.values[i].name));
      }
      expect(convertTypeFilter(null), isNull);
    });
    test('convertPlaceTypes', () async {
      for (int i = 0; i < PlaceTypeIOS.values.length; i++) {
        final List<PlaceType> converted = convertPlaceTypes(<int?>[i]);
        expect(converted.length, equals(1));
        expect(converted[0].name, equals(PlaceTypeIOS.values[i].name));
      }
    });
    test('convertPrediction', () async {
      final AutocompletePrediction converted =
          convertPrediction(mockPrediction);
      expect(converted.distanceMeters, mockPrediction.distanceMeters);
      expect(converted.fullText, mockPrediction.fullText);
      expect(converted.placeId, mockPrediction.placeId);
      expect(converted.placeTypes.length, mockPrediction.placeTypes.length);
      expect(converted.primaryText, mockPrediction.primaryText);
      expect(converted.secondaryText, mockPrediction.secondaryText);
    });
    test('convertReponse', () async {
      final List<AutocompletePrediction> converted =
          convertReponse(<AutocompletePredictionIOS>[mockPrediction]);
      expect(converted.length, equals(1));
    });
  });
}
