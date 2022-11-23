// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.google_maps_places_android

import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.places.api.model.AutocompletePrediction
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.model.RectangularBounds
import com.google.android.libraries.places.api.model.TypeFilter
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsResponse

/** Convert */
object Convert {

  /// Convert [LatLngAndroid] to [LatLng]
  fun convertLatLng(latLng: LatLngAndroid?): LatLng? {
    if (latLng?.latitude == null || latLng.longitude == null) {
      return null
    }
    return LatLng(latLng.latitude, latLng.longitude)
  }

  /// Convert [LatLngBoundsAndroid] to [RectangularBounds]
  fun convertLatLngBounds(latLngBounds: LatLngBoundsAndroid?): RectangularBounds? {
    if (latLngBounds?.northeast == null || latLngBounds.southwest == null) {
      return null
    }
    val northeast = convertLatLng(latLngBounds.northeast)
    val southwest = convertLatLng(latLngBounds.southwest)
    if (northeast == null || southwest == null) {
      return null
    }
    return RectangularBounds.newInstance(southwest, northeast)
  }


  /// Convert list of [String?] to list of [String]
  fun convertCountries(countries: List<String?>?): List<String>? {
    if (countries == null) {
      return null
    }
    return countries.map { country ->  country.toString() }
  }

  /// Convert list of [TypeFilterAndroid] to list of [String]
  fun convertTypeFilters(filters: List<Long?>?): List<String?>? {
    if (filters == null) {
      return null
    }
    return filters.map { filter ->  convertTypeFilter(filter) }
  }

  /// Convert [TypeFilterAndroid] to [TypeFilter]
  private fun convertTypeFilter(filter: Long?): String {
    return when (val formatted = filter?.let { TypeFilterAndroid.ofRaw(it.toInt()) }) {
      TypeFilterAndroid.ADDRESS -> TypeFilter.ADDRESS.toString()
      TypeFilterAndroid.CITIES -> TypeFilter.CITIES.toString()
      TypeFilterAndroid.ESTABLISHMENT -> TypeFilter.ESTABLISHMENT.toString()
      TypeFilterAndroid.GEOCODE -> TypeFilter.GEOCODE.toString()
      TypeFilterAndroid.REGIONS -> TypeFilter.REGIONS.toString()
      else -> throw IllegalArgumentException("Invalid TypeFilter: $formatted")
    }
  }

  /// Converts [FindAutocompletePredictionsResponse] to list of [AutocompletePredictionAndroid]
  fun convertResponse(result: FindAutocompletePredictionsResponse): List<AutocompletePredictionAndroid?> {
    return result.autocompletePredictions.map { item -> convertPrediction(item) }
  }

  /// Converts [AutocompletePrediction] to of [AutocompletePredictionAndroid]
  private fun convertPrediction(prediction: AutocompletePrediction): AutocompletePredictionAndroid {
    return AutocompletePredictionAndroid(
      prediction.distanceMeters?.toLong(),
      prediction.getFullText(null).toString(),
      prediction.placeId,
      convertPlaceTypes(prediction.placeTypes),
      prediction.getPrimaryText(null).toString(),
      prediction.getSecondaryText(null).toString()
    )
  }

  /// Converts list of [Place.Type] to list of [Long]
  private fun convertPlaceTypes(types: List<Place.Type>): List<Long?> {
    return types.map { type -> convertPlaceType(type) }
  }

  /// Convert [Place.Type] to [Long] value of [PlaceTypeAndroid]
  private fun convertPlaceType(type: Place.Type): Long? {
    return when (type) {
      Place.Type.ACCOUNTING -> PlaceTypeAndroid.ACCOUNTING.raw.toLong()
      Place.Type.ADMINISTRATIVE_AREA_LEVEL_1 -> PlaceTypeAndroid.ADMINISTRATIVEAREALEVEL1.raw.toLong()
      Place.Type.ADMINISTRATIVE_AREA_LEVEL_2 -> PlaceTypeAndroid.ADMINISTRATIVEAREALEVEL2.raw.toLong()
      Place.Type.ADMINISTRATIVE_AREA_LEVEL_3 -> PlaceTypeAndroid.ADMINISTRATIVEAREALEVEL3.raw.toLong()
      Place.Type.ADMINISTRATIVE_AREA_LEVEL_4 -> PlaceTypeAndroid.ADMINISTRATIVEAREALEVEL4.raw.toLong()
      Place.Type.ADMINISTRATIVE_AREA_LEVEL_5 -> PlaceTypeAndroid.ADMINISTRATIVEAREALEVEL5.raw.toLong()
      Place.Type.AIRPORT -> PlaceTypeAndroid.AIRPORT.raw.toLong()
      Place.Type.AMUSEMENT_PARK -> PlaceTypeAndroid.AMUSEMENTPARK.raw.toLong()
      Place.Type.AQUARIUM -> PlaceTypeAndroid.AQUARIUM.raw.toLong()
      Place.Type.ARCHIPELAGO -> PlaceTypeAndroid.ARCHIPELAGO.raw.toLong()
      Place.Type.ART_GALLERY -> PlaceTypeAndroid.ARTGALLERY.raw.toLong()
      Place.Type.ATM -> PlaceTypeAndroid.ATM.raw.toLong()
      Place.Type.BAKERY -> PlaceTypeAndroid.BAKERY.raw.toLong()
      Place.Type.BANK -> PlaceTypeAndroid.BANK.raw.toLong()
      Place.Type.BAR -> PlaceTypeAndroid.BAR.raw.toLong()
      Place.Type.BEAUTY_SALON -> PlaceTypeAndroid.BEAUTYSALON.raw.toLong()
      Place.Type.BICYCLE_STORE -> PlaceTypeAndroid.BICYCLESTORE.raw.toLong()
      Place.Type.BOOK_STORE -> PlaceTypeAndroid.BOOKSTORE.raw.toLong()
      Place.Type.BOWLING_ALLEY -> PlaceTypeAndroid.BOWLINGALLEY.raw.toLong()
      Place.Type.BUS_STATION -> PlaceTypeAndroid.BUSSTATION.raw.toLong()
      Place.Type.CAFE -> PlaceTypeAndroid.CAFE.raw.toLong()
      Place.Type.CAMPGROUND -> PlaceTypeAndroid.CAMPGROUND.raw.toLong()
      Place.Type.CAR_DEALER -> PlaceTypeAndroid.CARDEALER.raw.toLong()
      Place.Type.CAR_RENTAL -> PlaceTypeAndroid.CARRENTAL.raw.toLong()
      Place.Type.CAR_REPAIR -> PlaceTypeAndroid.CARREPAIR.raw.toLong()
      Place.Type.CAR_WASH -> PlaceTypeAndroid.CARWASH.raw.toLong()
      Place.Type.CASINO -> PlaceTypeAndroid.CASINO.raw.toLong()
      Place.Type.CEMETERY -> PlaceTypeAndroid.CEMETERY.raw.toLong()
      Place.Type.CHURCH -> PlaceTypeAndroid.CHURCH.raw.toLong()
      Place.Type.CITY_HALL -> PlaceTypeAndroid.CITYHALL.raw.toLong()
      Place.Type.CLOTHING_STORE -> PlaceTypeAndroid.CLOTHINGSTORE.raw.toLong()
      Place.Type.COLLOQUIAL_AREA -> PlaceTypeAndroid.COLLOQUIALAREA.raw.toLong()
      Place.Type.CONTINENT -> PlaceTypeAndroid.CONTINENT.raw.toLong()
      Place.Type.CONVENIENCE_STORE -> PlaceTypeAndroid.CONVENIENCESTORE.raw.toLong()
      Place.Type.COUNTRY -> PlaceTypeAndroid.COUNTRY.raw.toLong()
      Place.Type.COURTHOUSE -> PlaceTypeAndroid.COURTHOUSE.raw.toLong()
      Place.Type.DENTIST -> PlaceTypeAndroid.DENTIST.raw.toLong()
      Place.Type.DEPARTMENT_STORE -> PlaceTypeAndroid.DEPARTMENTSTORE.raw.toLong()
      Place.Type.DOCTOR -> PlaceTypeAndroid.DOCTOR.raw.toLong()
      Place.Type.DRUGSTORE -> PlaceTypeAndroid.DRUGSTORE.raw.toLong()
      Place.Type.ELECTRICIAN -> PlaceTypeAndroid.ELECTRICIAN.raw.toLong()
      Place.Type.ELECTRONICS_STORE -> PlaceTypeAndroid.ELECTRONICSSTORE.raw.toLong()
      Place.Type.EMBASSY -> PlaceTypeAndroid.EMBASSY.raw.toLong()
      Place.Type.ESTABLISHMENT -> PlaceTypeAndroid.ESTABLISHMENT.raw.toLong()
      Place.Type.FINANCE -> PlaceTypeAndroid.FINANCE.raw.toLong()
      Place.Type.FIRE_STATION -> PlaceTypeAndroid.FIRESTATION.raw.toLong()
      Place.Type.FLOOR -> PlaceTypeAndroid.FLOOR.raw.toLong()
      Place.Type.FLORIST -> PlaceTypeAndroid.FLORIST.raw.toLong()
      Place.Type.FOOD -> PlaceTypeAndroid.FOOD.raw.toLong()
      Place.Type.FUNERAL_HOME -> PlaceTypeAndroid.FUNERALHOME.raw.toLong()
      Place.Type.FURNITURE_STORE -> PlaceTypeAndroid.FURNITURESTORE.raw.toLong()
      Place.Type.GAS_STATION -> PlaceTypeAndroid.GASSTATION.raw.toLong()
      Place.Type.GENERAL_CONTRACTOR -> PlaceTypeAndroid.GENERALCONTRACTOR.raw.toLong()
      Place.Type.GEOCODE -> PlaceTypeAndroid.GEOCODE.raw.toLong()
      Place.Type.GROCERY_OR_SUPERMARKET -> PlaceTypeAndroid.GROCERYORSUPERMARKET.raw.toLong()
      Place.Type.GYM -> PlaceTypeAndroid.GYM.raw.toLong()
      Place.Type.HAIR_CARE -> PlaceTypeAndroid.HAIRCARE.raw.toLong()
      Place.Type.HARDWARE_STORE -> PlaceTypeAndroid.HARDWARESTORE.raw.toLong()
      Place.Type.HEALTH -> PlaceTypeAndroid.HEALTH.raw.toLong()
      Place.Type.HINDU_TEMPLE -> PlaceTypeAndroid.HINDUTEMPLE.raw.toLong()
      Place.Type.HOME_GOODS_STORE -> PlaceTypeAndroid.HOMEGOODSSTORE.raw.toLong()
      Place.Type.HOSPITAL -> PlaceTypeAndroid.HOSPITAL.raw.toLong()
      Place.Type.INSURANCE_AGENCY -> PlaceTypeAndroid.INSURANCEAGENCY.raw.toLong()
      Place.Type.INTERSECTION -> PlaceTypeAndroid.INTERSECTION.raw.toLong()
      Place.Type.JEWELRY_STORE -> PlaceTypeAndroid.JEWELRYSTORE.raw.toLong()
      Place.Type.LAUNDRY -> PlaceTypeAndroid.LAUNDRY.raw.toLong()
      Place.Type.LAWYER -> PlaceTypeAndroid.LAWYER.raw.toLong()
      Place.Type.LIBRARY-> PlaceTypeAndroid.LIBRARY.raw.toLong()
      Place.Type.LIGHT_RAIL_STATION -> PlaceTypeAndroid.LIGHTRAILSTATION.raw.toLong()
      Place.Type.LIQUOR_STORE -> PlaceTypeAndroid.LIQUORSTORE.raw.toLong()
      Place.Type.LOCALITY -> PlaceTypeAndroid.LOCALITY.raw.toLong()
      Place.Type.LOCAL_GOVERNMENT_OFFICE -> PlaceTypeAndroid.LOCALGOVERNMENTOFFICE.raw.toLong()
      Place.Type.LOCKSMITH -> PlaceTypeAndroid.LOCKSMITH.raw.toLong()
      Place.Type.LODGING -> PlaceTypeAndroid.LODGING.raw.toLong()
      Place.Type.MEAL_DELIVERY -> PlaceTypeAndroid.MEALDELIVERY.raw.toLong()
      Place.Type.MEAL_TAKEAWAY -> PlaceTypeAndroid.MEALTAKEAWAY.raw.toLong()
      Place.Type.MOSQUE -> PlaceTypeAndroid.MOSQUE.raw.toLong()
      Place.Type.MOVIE_RENTAL -> PlaceTypeAndroid.MOVIERENTAL.raw.toLong()
      Place.Type.MOVIE_THEATER -> PlaceTypeAndroid.MOVIETHEATER.raw.toLong()
      Place.Type.MOVING_COMPANY -> PlaceTypeAndroid.MOVINGCOMPANY.raw.toLong()
      Place.Type.MUSEUM -> PlaceTypeAndroid.MUSEUM.raw.toLong()
      Place.Type.NATURAL_FEATURE -> PlaceTypeAndroid.NATURALFEATURE.raw.toLong()
      Place.Type.NEIGHBORHOOD -> PlaceTypeAndroid.NEIGHBORHOOD.raw.toLong()
      Place.Type.NIGHT_CLUB -> PlaceTypeAndroid.NIGHTCLUB.raw.toLong()
      Place.Type.OTHER -> PlaceTypeAndroid.OTHER.raw.toLong()
      Place.Type.PAINTER -> PlaceTypeAndroid.PAINTER.raw.toLong()
      Place.Type.PARK -> PlaceTypeAndroid.PARK.raw.toLong()
      Place.Type.PARKING -> PlaceTypeAndroid.PARKING.raw.toLong()
      Place.Type.PET_STORE -> PlaceTypeAndroid.PETSTORE.raw.toLong()
      Place.Type.PHARMACY -> PlaceTypeAndroid.PHARMACY.raw.toLong()
      Place.Type.PHYSIOTHERAPIST -> PlaceTypeAndroid.PHYSIOTHERAPIST.raw.toLong()
      Place.Type.PLACE_OF_WORSHIP -> PlaceTypeAndroid.PLACEOFWORSHIP.raw.toLong()
      Place.Type.PLUMBER -> PlaceTypeAndroid.PLUMBER.raw.toLong()
      Place.Type.PLUS_CODE -> PlaceTypeAndroid.PLUSCODE.raw.toLong()
      Place.Type.POINT_OF_INTEREST -> PlaceTypeAndroid.POINTOFINTEREST.raw.toLong()
      Place.Type.POLICE -> PlaceTypeAndroid.POLICE.raw.toLong()
      Place.Type.POLITICAL -> PlaceTypeAndroid.POLITICAL.raw.toLong()
      Place.Type.POSTAL_CODE -> PlaceTypeAndroid.POSTALCODE.raw.toLong()
      Place.Type.POSTAL_CODE_PREFIX -> PlaceTypeAndroid.POSTALCODEPREFIX.raw.toLong()
      Place.Type.POSTAL_CODE_SUFFIX -> PlaceTypeAndroid.POSTALCODESUFFIX.raw.toLong()
      Place.Type.POSTAL_TOWN -> PlaceTypeAndroid.POSTALTOWN.raw.toLong()
      Place.Type.POST_BOX -> PlaceTypeAndroid.POSTBOX.raw.toLong()
      Place.Type.POST_OFFICE -> PlaceTypeAndroid.POSTOFFICE.raw.toLong()
      Place.Type.PREMISE -> PlaceTypeAndroid.PREMISE.raw.toLong()
      Place.Type.PRIMARY_SCHOOL -> PlaceTypeAndroid.PRIMARYSCHOOL.raw.toLong()
      Place.Type.REAL_ESTATE_AGENCY -> PlaceTypeAndroid.REALESTATEAGENCY.raw.toLong()
      Place.Type.RESTAURANT -> PlaceTypeAndroid.RESTAURANT.raw.toLong()
      Place.Type.ROOFING_CONTRACTOR -> PlaceTypeAndroid.ROOFINGCONTRACTOR.raw.toLong()
      Place.Type.ROOM -> PlaceTypeAndroid.ROOM.raw.toLong()
      Place.Type.ROUTE -> PlaceTypeAndroid.ROUTE.raw.toLong()
      Place.Type.RV_PARK -> PlaceTypeAndroid.RVPARK.raw.toLong()
      Place.Type.SCHOOL -> PlaceTypeAndroid.SCHOOL.raw.toLong()
      Place.Type.SECONDARY_SCHOOL -> PlaceTypeAndroid.SECONDARYSCHOOL.raw.toLong()
      Place.Type.SHOE_STORE -> PlaceTypeAndroid.SHOESTORE.raw.toLong()
      Place.Type.SHOPPING_MALL -> PlaceTypeAndroid.SHOPPINGMALL.raw.toLong()
      Place.Type.SPA -> PlaceTypeAndroid.SPA.raw.toLong()
      Place.Type.STADIUM -> PlaceTypeAndroid.STADIUM.raw.toLong()
      Place.Type.STORAGE -> PlaceTypeAndroid.STORAGE.raw.toLong()
      Place.Type.STORE -> PlaceTypeAndroid.STORE.raw.toLong()
      Place.Type.STREET_ADDRESS -> PlaceTypeAndroid.STREETADDRESS.raw.toLong()
      Place.Type.STREET_NUMBER -> PlaceTypeAndroid.STREETNUMBER.raw.toLong()
      Place.Type.SUBLOCALITY -> PlaceTypeAndroid.SUBLOCALITY.raw.toLong()
      Place.Type.SUBLOCALITY_LEVEL_1 -> PlaceTypeAndroid.SUBLOCALITYLEVEL1.raw.toLong()
      Place.Type.SUBLOCALITY_LEVEL_2 -> PlaceTypeAndroid.SUBLOCALITYLEVEL2.raw.toLong()
      Place.Type.SUBLOCALITY_LEVEL_3 -> PlaceTypeAndroid.SUBLOCALITYLEVEL3.raw.toLong()
      Place.Type.SUBLOCALITY_LEVEL_4 -> PlaceTypeAndroid.SUBLOCALITYLEVEL4.raw.toLong()
      Place.Type.SUBLOCALITY_LEVEL_5 -> PlaceTypeAndroid.SUBLOCALITYLEVEL5.raw.toLong()
      Place.Type.SUBPREMISE -> PlaceTypeAndroid.SUBPREMISE.raw.toLong()
      Place.Type.SUBWAY_STATION -> PlaceTypeAndroid.SUBWAYSTATION.raw.toLong()
      Place.Type.SUPERMARKET -> PlaceTypeAndroid.SUPERMARKET.raw.toLong()
      Place.Type.SYNAGOGUE -> PlaceTypeAndroid.SYNAGOGUE.raw.toLong()
      Place.Type.TAXI_STAND -> PlaceTypeAndroid.TAXISTAND.raw.toLong()
      Place.Type.TOURIST_ATTRACTION -> PlaceTypeAndroid.TOURISTATTRACTION.raw.toLong()
      Place.Type.TOWN_SQUARE -> PlaceTypeAndroid.TOWNSQUARE.raw.toLong()
      Place.Type.TRAIN_STATION -> PlaceTypeAndroid.TRAINSTATION.raw.toLong()
      Place.Type.TRANSIT_STATION -> PlaceTypeAndroid.TRANSITSTATION.raw.toLong()
      Place.Type.TRAVEL_AGENCY -> PlaceTypeAndroid.TRAVELAGENCY.raw.toLong()
      Place.Type.UNIVERSITY -> PlaceTypeAndroid.UNIVERSITY.raw.toLong()
      Place.Type.VETERINARY_CARE -> PlaceTypeAndroid.VETERINARYCARE.raw.toLong()
      Place.Type.ZOO -> PlaceTypeAndroid.ZOO.raw.toLong()
      else -> {throw IllegalArgumentException("Invalid PlaceType: $type")}
    }
  }
}
