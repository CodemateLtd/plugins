// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Autogenerated from Pigeon (v4.2.5), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, unnecessary_import
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;
import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_maps_places_android/src/messages.g.dart';

class _TestGoogleMapsPlacesApiCodec extends StandardMessageCodec {
  const _TestGoogleMapsPlacesApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is AutocompletePredictionAndroid) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is LatLngAndroid) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is LatLngBoundsAndroid) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return AutocompletePredictionAndroid.decode(readValue(buffer)!);

      case 129:
        return LatLngAndroid.decode(readValue(buffer)!);

      case 130:
        return LatLngBoundsAndroid.decode(readValue(buffer)!);

      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class TestGoogleMapsPlacesApi {
  static const MessageCodec<Object?> codec = _TestGoogleMapsPlacesApiCodec();

  Future<List<AutocompletePredictionAndroid?>>
      findAutocompletePredictionsAndroid(
          String query,
          LatLngBoundsAndroid? locationBias,
          LatLngBoundsAndroid? locationRestriction,
          LatLngAndroid? origin,
          List<String?>? countries,
          List<int?>? typeFilter,
          bool? refreshToken);
  static void setup(TestGoogleMapsPlacesApi? api,
      {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.GoogleMapsPlacesApiAndroid.findAutocompletePredictionsAndroid',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMockMessageHandler(null);
      } else {
        channel.setMockMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.GoogleMapsPlacesApiAndroid.findAutocompletePredictionsAndroid was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final String? arg_query = (args[0] as String?);
          assert(arg_query != null,
              'Argument for dev.flutter.pigeon.GoogleMapsPlacesApiAndroid.findAutocompletePredictionsAndroid was null, expected non-null String.');
          final LatLngBoundsAndroid? arg_locationBias =
              (args[1] as LatLngBoundsAndroid?);
          final LatLngBoundsAndroid? arg_locationRestriction =
              (args[2] as LatLngBoundsAndroid?);
          final LatLngAndroid? arg_origin = (args[3] as LatLngAndroid?);
          final List<String?>? arg_countries =
              (args[4] as List<Object?>?)?.cast<String?>();
          final List<int?>? arg_typeFilter =
              (args[5] as List<Object?>?)?.cast<int?>();
          final bool? arg_refreshToken = (args[6] as bool?);
          final List<AutocompletePredictionAndroid?> output =
              await api.findAutocompletePredictionsAndroid(
                  arg_query!,
                  arg_locationBias,
                  arg_locationRestriction,
                  arg_origin,
                  arg_countries,
                  arg_typeFilter,
                  arg_refreshToken);
          return <Object?, Object?>{'result': output};
        });
      }
    }
  }
}
