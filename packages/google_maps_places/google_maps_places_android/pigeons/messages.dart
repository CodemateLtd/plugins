// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  input: 'pigeons/messages.dart',
  kotlinOut:
      'android/src/main/kotlin/io/flutter/plugins/google_maps_places_android/Messages.kt',
  kotlinOptions:
      KotlinOptions(package: 'io.flutter.plugins.google_maps_places_android'),
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/messages_test.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
enum TypeFilter {
  address,
  cities,
  establishment,
  geocode,
  regions,
  all,
}

enum PlaceType {
  accounting,
  administrativeAreaLevel1,
  administrativeAreaLevel2,
  administrativeAreaLevel3,
  administrativeAreaLevel4,
  administrativeAreaLevel5,
  airport,
  amusementPark,
  aquarium,
  archipelago,
  artGallery,
  atm,
  bakery,
  bank,
  bar,
  beautySalon,
  bicycleStore,
  bookStore,
  bowlingAlley,
  busStation,
  cafe,
  campground,
  carDealer,
  carRental,
  carRepair,
  carWash,
  casino,
  cemetery,
  church,
  cityHall,
  clothingStore,
  colloquialArea,
  continent,
  convenienceStore,
  country,
  courthouse,
  dentist,
  departmentStore,
  doctor,
  drugstore,
  electrician,
  electronicsStore,
  embassy,
  establishment,
  finance,
  fireStation,
  floor,
  florist,
  food,
  funeralHome,
  furnitureStore,
  gasStation,
  generalContractor,
  geocode,
  groceryOrSupermarket,
  gym,
  hairCare,
  hardwareStore,
  health,
  hinduTemple,
  homeGoodsStore,
  hospital,
  insuranceAgency,
  intersection,
  jewelryStore,
  laundry,
  lawyer,
  library,
  lightRailStation,
  liquorStore,
  locality,
  localGovernmentOffice,
  locksmith,
  lodging,
  mealDelivery,
  mealTakeaway,
  mosque,
  movieRental,
  movieTheater,
  movingCompany,
  museum,
  naturalFeature,
  neighborhood,
  nightClub,
  other,
  painter,
  park,
  parking,
  petStore,
  pharmacy,
  physiotherapist,
  placeOfWorship,
  plumber,
  plusCode,
  pointOfInterest,
  police,
  political,
  postalCode,
  postalCodePrefix,
  postalCodeSuffix,
  postalTown,
  postBox,
  postOffice,
  premise,
  primarySchool,
  realEstateAgency,
  restaurant,
  roofingContractor,
  room,
  route,
  rvPark,
  school,
  secondarySchool,
  shoeStore,
  shoppingMall,
  spa,
  stadium,
  storage,
  store,
  streetAddress,
  streetNumber,
  sublocality,
  sublocalityLevel1,
  sublocalityLevel2,
  sublocalityLevel3,
  sublocalityLevel4,
  sublocalityLevel5,
  subpremise,
  subwayStation,
  supermarket,
  synagogue,
  taxiStand,
  touristAttraction,
  townSquare,
  trainStation,
  transitStation,
  travelAgency,
  university,
  veterinaryCare,
  zoo,
}

class LatLng {
  double? latitude;
  double? longitude;
}

class LatLngBounds {
  LatLng? southwest;
  LatLng? northeast;
}

class FindAutocompletePredictionsRequest {
  FindAutocompletePredictionsRequest({
    this.query = "",
  });
  String query;
  LatLngBounds? locationBias;
  LatLngBounds? locationRestriction;
  LatLng? origin;
  List<String?>? countries;
  List<int?>? typeFilter;
  bool? refreshToken;
}

class AutocompletePrediction {
  AutocompletePrediction({
    this.distanceMeters,
    this.fullText = "",
    this.placeId = "",
    this.placeTypes = const <int?>[],
    this.primaryText = "",
    this.secondaryText = "",
  });
  int? distanceMeters;
  String fullText;
  String placeId;
  List<int?> placeTypes;
  String primaryText;
  String secondaryText;
}

class FindAutocompletePredictionsResponse {
  FindAutocompletePredictionsResponse({
    this.results = const <AutocompletePrediction>[],
  });
  List<AutocompletePrediction?> results;
}

@HostApi(dartHostTestHandler: 'TestGoogleMapsPlacesApi')
abstract class GoogleMapsPlacesApi {
  FindAutocompletePredictionsResponse findAutocompletePredictions(
      FindAutocompletePredictionsRequest request);
}
