// Mocks generated by Mockito 5.3.2 from annotations
// in google_maps_places_ios/example/ios/.symlinks/plugins/google_maps_places_ios/test/google_maps_places_ios_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:google_maps_places_ios/src/messages.g.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;

import 'messages_test.g.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [TestGoogleMapsPlacesApi].
///
/// See the documentation for Mockito's code generation for more information.
class MockTestGoogleMapsPlacesApi extends _i1.Mock
    implements _i2.TestGoogleMapsPlacesApi {
  MockTestGoogleMapsPlacesApi() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<List<_i4.AutocompletePredictionIOS?>?>
      findAutocompletePredictionsIOS(
    String? query,
    _i4.LatLngBoundsIOS? locationBias,
    _i4.LatLngBoundsIOS? locationRestriction,
    _i4.LatLngIOS? origin,
    List<String?>? countries,
    List<int?>? typeFilter,
    bool? refreshToken,
  ) =>
          (super.noSuchMethod(
            Invocation.method(
              #findAutocompletePredictionsIOS,
              [
                query,
                locationBias,
                locationRestriction,
                origin,
                countries,
                typeFilter,
                refreshToken,
              ],
            ),
            returnValue:
                _i3.Future<List<_i4.AutocompletePredictionIOS?>?>.value(),
          ) as _i3.Future<List<_i4.AutocompletePredictionIOS?>?>);
}
