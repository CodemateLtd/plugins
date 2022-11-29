package io.flutter.plugins.google_maps_places_android

import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.model.TypeFilter
import junit.framework.TestCase.*

import org.junit.Test

class ConvertsTests {

    @Test
    fun testConvertsLatLng() {
        val data = LatLngAndroid(65.0121, 25.4651)
        val converted = Converts.convertsLatLng(data)
        assertNotNull(converted)
        assertEquals(converted?.latitude, data.latitude)
        assertEquals(converted?.longitude, data.longitude)
        assertNull(Converts.convertsLatLng(null))
        assertNull(Converts.convertsLatLng(LatLngAndroid(65.0121, null)))
        assertNull(Converts.convertsLatLng(LatLngAndroid(null, 25.4651)))
        assertNull(Converts.convertsLatLng(LatLngAndroid(null, null)))
    }

    @Test
    fun testConvertsLatLngBounds() {
        assertNotNull(Converts.convertsLatLngBounds(LatLngBoundsAndroid(
            LatLngAndroid(60.4518, 22.2666),
            LatLngAndroid(70.0821, 27.8718)
        )))
        assertNull(Converts.convertsLatLngBounds(null))
        assertNull(Converts.convertsLatLngBounds(LatLngBoundsAndroid(
            null,
            LatLngAndroid(70.0821, 27.8718)
        )))
        assertNull(Converts.convertsLatLngBounds(LatLngBoundsAndroid(
            LatLngAndroid(60.4518, 22.2666),
            null
        )))
        assertNull(Converts.convertsLatLngBounds(LatLngBoundsAndroid(
            LatLngAndroid(null, 22.2666),
            LatLngAndroid(70.0821, 27.8718)
        )))
        assertNull(Converts.convertsLatLngBounds(LatLngBoundsAndroid(
            null,
            null
        )))
    }

    @Test
    fun testConvertsCountries() {
        val countries = mutableListOf<String?>()
        assertNull(Converts.convertsCountries(null))
        assertNotNull(Converts.convertsCountries(countries))
        countries.add(0, null)
        assertNotNull(Converts.convertsCountries(countries))
        countries.removeAt(0)
        countries.addAll(listOf("fi", "us"))
        val converted = Converts.convertsCountries(countries)
        assertNotNull(converted)
        assertEquals(converted?.size, countries.size)
    }

    @Test
    fun testConvertsTypeFilters() {
        val typeFilters = mutableListOf<Long?>()
        assertNull(Converts.convertsTypeFilters(null))
        assertNotNull(Converts.convertsTypeFilters(typeFilters))
        typeFilters.add(0, null)
        assertNotNull(Converts.convertsTypeFilters(typeFilters))
        typeFilters.removeAt(0)
        typeFilters.addAll(listOf(1, 2))
        val converted = Converts.convertsTypeFilters(typeFilters)
        assertNotNull(converted)
        assertEquals(converted?.size, typeFilters.size)
    }

    @Test
    fun testConvertsTypeFiltersToSingle() {
        val typeFilters = mutableListOf<Long?>()
        assertNull(Converts.convertsTypeFiltersToSingle(null))
        assertNull(Converts.convertsTypeFiltersToSingle(typeFilters))
        typeFilters.add(0, null)
        assertNull(Converts.convertsTypeFiltersToSingle(typeFilters))
        typeFilters.removeAt(0)
        typeFilters.addAll(listOf(1, 2))
        val converted = Converts.convertsTypeFiltersToSingle(typeFilters)
        assertNotNull(converted)
        assertEquals(converted.toString(), TypeFilterAndroid.ofRaw(1).toString())
    }

    @Test
    fun testConvertsTypeFilter() {
        assertEquals(Converts.convertsTypeFilter(TypeFilterAndroid.ADDRESS.raw).toString(),
            TypeFilter.ADDRESS.toString())
        assertEquals(Converts.convertsTypeFilter(TypeFilterAndroid.CITIES.raw).toString(),
            TypeFilter.CITIES.toString())
        assertEquals(Converts.convertsTypeFilter(TypeFilterAndroid.ESTABLISHMENT.raw).toString(),
            TypeFilter.ESTABLISHMENT.toString())
        assertEquals(Converts.convertsTypeFilter(TypeFilterAndroid.GEOCODE.raw).toString(),
            TypeFilter.GEOCODE.toString())
        assertEquals(Converts.convertsTypeFilter(TypeFilterAndroid.REGIONS.raw).toString(),
            TypeFilter.REGIONS.toString())
    }

    @Test
    fun testConvertsPlaceTypes() {
        val types = listOf(Place.Type.ACCOUNTING, Place.Type.GEOCODE)
        val converted = Converts.convertsPlaceTypes(types)
        assertNotNull(converted)
        assertEquals(types.size, converted.size)
        assertEquals(types[0].toString(), PlaceTypeAndroid.ofRaw(converted[0].toInt()).toString())
    }

    @Test
    fun testConvertsPlaceType() {
        assertEquals(Converts.convertsPlaceType(Place.Type.GEOCODE).toString(),
            Place.Type.GEOCODE.toString())
    }
}