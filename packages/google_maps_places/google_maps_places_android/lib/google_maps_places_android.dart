import 'package:flutter/services.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';
import 'package:google_maps_places_platform_interface/types/types.dart';

/// An implementation of [GoogleMapsPlacesPlatform] for Android.
class GoogleMapsPlacesAndroid extends GoogleMapsPlacesPlatform {
  static const MethodChannel _channel =
      MethodChannel('plugins.flutter.io/google_maps_places_android');

  /// Registers this class as the default platform implementation.
  static void registerWith() {
    GoogleMapsPlacesPlatform.instance = GoogleMapsPlacesAndroid();
  }

  @override
  Future<FindPlacesAutoCompleteResponse> findPlacesAutoComplete(
    String query, {
    List<String>? countries,
    PlaceTypeFilter placeTypeFilter = PlaceTypeFilter.ALL,
    bool? newSessionToken,
    LatLng? origin,
    LatLngBounds? locationBias,
    LatLngBounds? locationRestriction,
  }) {
    if (query.isEmpty) {
      throw ArgumentError('Argument query can not be empty');
    }
    return _channel.invokeListMethod<Map<dynamic, dynamic>>(
      'findPlacesAutoComplete',
      {
        'query': query,
        'countries': countries ?? [],
        'typeFilter': placeTypeFilter.value,
        'newSessionToken': newSessionToken,
        'origin': origin?.toJson(),
        'locationBias': locationBias?.toJson(),
        'locationRestriction': locationRestriction?.toJson(),
      },
    ).then(_responseFromResult);
  }

  FindPlacesAutoCompleteResponse _responseFromResult(
    List<Map<dynamic, dynamic>>? value,
  ) {
    final items = value
            ?.map((item) => item.cast<String, dynamic>())
            .map((map) => AutoCompletePlace.fromJson(map))
            .toList(growable: false) ??
        [];
    return FindPlacesAutoCompleteResponse(items);
  }
}
