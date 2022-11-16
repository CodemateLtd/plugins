package io.flutter.plugins.google_maps_places_android

import android.content.Context
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompletePrediction
import com.google.android.libraries.places.api.model.AutocompleteSessionToken
import com.google.android.libraries.places.api.model.RectangularBounds
import com.google.android.libraries.places.api.model.TypeFilter
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsResponse
import com.google.android.libraries.places.api.net.PlacesClient

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*
import kotlin.collections.ArrayList

/** GoogleMapsPlacesAndroidPlugin */
class GoogleMapsPlacesAndroidPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var client: PlacesClient
  private lateinit var channel : MethodChannel
  private var lastSessionToken: AutocompleteSessionToken? = null
  private lateinit var applicationContext: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
      onAttachedToEngine(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
  }

  private fun onAttachedToEngine(applicationContext: Context, binaryMessenger: BinaryMessenger) {
    this.applicationContext = applicationContext

    channel = MethodChannel(binaryMessenger, "plugins.flutter.io/google_maps_places_android")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "findPlacesAutoComplete" -> {
        val query = call.argument<String>("query")
        val countries = call.argument<List<String>>("countries") ?: emptyList()
        val placeTypeFilter = call.argument<String>("typeFilter")
        val newSessionToken = call.argument<Boolean>("newSessionToken")

        val origin = latLngFromMap(call.argument<ArrayList<Double>>("origin"))
        val locationBias =
          rectangularBoundsFromMap(call.argument<ArrayList<ArrayList<Double>?>?>("locationBias"))
        val locationRestriction =
          rectangularBoundsFromMap(call.argument<ArrayList<ArrayList<Double>?>?>("locationRestriction"))
        val sessionToken = getSessionToken(newSessionToken == true)
        val typeFilter = makeTypeFilter(placeTypeFilter)
        initialize(Locale.ENGLISH)
        val request = FindAutocompletePredictionsRequest.builder()
          .setQuery(query)
          .setLocationBias(locationBias)
          .setLocationRestriction(locationRestriction)
          .setCountries(countries)
          .setTypeFilter(typeFilter)
          .setSessionToken(sessionToken)
          .setOrigin(origin)
          .build()
        client.findAutocompletePredictions(request).addOnCompleteListener { task ->
          if (task.isSuccessful) {
            lastSessionToken = request.sessionToken
            val resultList = responseToList(task.result)
            print("findAutoCompletePredictions Result: $resultList")
            result.success(resultList)
          } else {
            val exception = task.exception
            print("findAutoCompletePredictions Exception: $exception")
            result.error(
              "API_ERROR_AUTOCOMPLETE", exception?.message ?: "Unknown exception",
              mapOf("type" to (exception?.javaClass?.toString() ?: "null"))
            )
          }
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun getSessionToken(force: Boolean): AutocompleteSessionToken {
    val localToken = lastSessionToken
    if (force || localToken == null) {
      return AutocompleteSessionToken.newInstance()
    }
    return localToken
  }

  private fun rectangularBoundsFromMap(argument: ArrayList<ArrayList<Double>?>?): RectangularBounds? {
    if (argument == null) {
      return null
    }

    val latLngBounds = latLngBoundsFromMap(argument) ?: return null
    return RectangularBounds.newInstance(latLngBounds)
  }

  @Suppress("UNCHECKED_CAST")
  private fun latLngBoundsFromMap(argument: ArrayList<ArrayList<Double>?>?): LatLngBounds? {
    if (argument == null) {
      return null
    }

    val southWest = latLngFromMap(argument[0]) ?: return null
    val northEast = latLngFromMap(argument[1]) ?: return null

    return LatLngBounds(southWest, northEast)
  }

  private fun latLngFromMap(argument: ArrayList<Double>?): LatLng? {
    if (argument == null) {
      return null
    }

    val lat = argument[0] as Double?
    val lng = argument[1] as Double?
    if (lat == null || lng == null) {
      return null
    }

    return LatLng(lat, lng)
  }

  private fun responseToList(result: FindAutocompletePredictionsResponse?): List<Map<String, Any?>>? {
    if (result == null) {
      return null
    }

    return result.autocompletePredictions.map { item -> predictionToMap(item) }
  }

  private fun predictionToMap(result: AutocompletePrediction): Map<String, Any?> {
    return mapOf(
      "placeId" to result.placeId,
      "distanceMeters" to result.distanceMeters,
      "primaryText" to result.getPrimaryText(null).toString(),
      "secondaryText" to result.getSecondaryText(null).toString(),
      "fullText" to result.getFullText(null).toString()
    )
  }

  private fun makeTypeFilter(typeFilterStr: String?): TypeFilter? {
    val typeFilterStrUpper = typeFilterStr?.toUpperCase(Locale.getDefault())
    if (typeFilterStrUpper == null || typeFilterStrUpper == "ALL") {
      return null
    }
    return TypeFilter.valueOf(typeFilterStrUpper)
  }

  private fun initialize(locale: Locale?) {
    val applicationInfo =
      applicationContext
      .packageManager
      .getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA);
    var apiKey = ""
    if (applicationInfo.metaData != null) {
      apiKey = applicationInfo.metaData.getString("com.google.android.geo.API_KEY").toString()
    }
    Places.initialize(applicationContext, apiKey, locale)
    client = Places.createClient(applicationContext)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
