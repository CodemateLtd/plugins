// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';
import 'package:google_maps_places_platform_interface/method_channel/method_channel_google_maps_places.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$GoogleMapsPlacesPlatform', () {
    test('$GoogleMapsPlacesMethodChannel() is the default instance', () {
      expect(GoogleMapsPlacesPlatform.instance,
          isInstanceOf<GoogleMapsPlacesMethodChannel>());
    });
  });
}
