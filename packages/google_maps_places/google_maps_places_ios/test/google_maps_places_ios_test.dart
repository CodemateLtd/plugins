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
          .thenAnswer((Invocation _) async =>
              Future<List<AutocompletePredictionIOS?>?>.value(
                  <AutocompletePredictionIOS?>[mockPrediction]));
    });
    test('passes the accepted type groups correctly', () async {
      await plugin.findAutocompletePredictions(query: 'koulu');
      final VerificationResult result = verify(
          mockApi.findAutocompletePredictionsIOS(captureAny, captureAny,
              captureAny, captureAny, captureAny, captureAny, captureAny));
      expect(result.captured[0], 'koulu');
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
