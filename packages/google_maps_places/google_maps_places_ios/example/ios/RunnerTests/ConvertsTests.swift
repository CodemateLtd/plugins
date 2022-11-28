// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest
@testable import google_maps_places_ios
@testable import GooglePlaces

final class ConvertsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testConvertsLatLng() {
        let data:LatLngIOS = LatLngIOS(latitude: 65.0121, longitude: 25.4651)
        let converted = Converts.convertsLatLng(data)
        XCTAssertNotNil(converted)
        XCTAssertNotNil(converted?.coordinate)
        XCTAssertEqual(converted?.coordinate.latitude, data.latitude)
        XCTAssertEqual(converted?.coordinate.longitude, data.longitude)
        XCTAssertNil(Converts.convertsLatLng(nil))
        XCTAssertNil(Converts.convertsLatLng(LatLngIOS(latitude: 65.0121, longitude: nil)))
        XCTAssertNil(Converts.convertsLatLng(LatLngIOS(latitude: nil, longitude: 25.4651)))
        XCTAssertNil(Converts.convertsLatLng(LatLngIOS(latitude: nil, longitude: nil)))
    }
    
    func testConvertsLocationBias() {
        XCTAssertNotNil(Converts.convertsLocationBias(LatLngBoundsIOS(
            southwest: LatLngIOS(latitude: 60.4518, longitude: 22.2666),
            northeast: LatLngIOS(latitude: 70.0821, longitude: 27.8718)
        )))
        XCTAssertNil(Converts.convertsLocationBias(nil))
        XCTAssertNil(Converts.convertsLocationBias(LatLngBoundsIOS(
            southwest: nil,
            northeast: LatLngIOS(latitude: 70.0821, longitude: 27.8718)
        )))
        XCTAssertNil(Converts.convertsLocationBias(LatLngBoundsIOS(
            southwest: LatLngIOS(latitude: 60.4518, longitude: 22.2666),
            northeast: nil
        )))
        XCTAssertNil(Converts.convertsLocationBias(LatLngBoundsIOS(
            southwest: LatLngIOS(latitude: nil, longitude: 22.2666),
            northeast: LatLngIOS(latitude: 70.0821, longitude: 27.8718)
        )))
        XCTAssertNil(Converts.convertsLocationBias(LatLngBoundsIOS(
            southwest: nil,
            northeast: nil
        )))
    }
    
    func testConvertsLocationRestriction() {
        XCTAssertNotNil(Converts.convertsLocationRestrction(LatLngBoundsIOS(
            southwest: LatLngIOS(latitude: 60.4518, longitude: 22.2666),
            northeast: LatLngIOS(latitude: 70.0821, longitude: 27.8718)
        )))
        XCTAssertNil(Converts.convertsLocationRestrction(nil))
        XCTAssertNil(Converts.convertsLocationRestrction(LatLngBoundsIOS(
            southwest: nil,
            northeast: LatLngIOS(latitude: 70.0821, longitude: 27.8718)
        )))
        XCTAssertNil(Converts.convertsLocationRestrction(LatLngBoundsIOS(
            southwest: LatLngIOS(latitude: 60.4518, longitude: 22.2666),
            northeast: nil
        )))
        XCTAssertNil(Converts.convertsLocationRestrction(LatLngBoundsIOS(
            southwest: LatLngIOS(latitude: nil, longitude: 22.2666),
            northeast: LatLngIOS(latitude: 70.0821, longitude: 27.8718)
        )))
        XCTAssertNil(Converts.convertsLocationRestrction(LatLngBoundsIOS(
            southwest: nil,
            northeast: nil
        )))
    }
    
    func testConvertsTypeFilters() {
        let values:[Int32] = [Int32(TypeFilterIOS.address.rawValue)]
        XCTAssertNotNil(Converts.convertsTypeFilters(values))
        XCTAssertEqual(Converts.convertsTypeFilters(values), [GMSPlacesAutocompleteTypeFilter.address])
        XCTAssertNil(Converts.convertsTypeFilters(nil))
    }
    
    func testConvertsTypeFiltersToSingle() {
        let values:[Int32] = [Int32(TypeFilterIOS.address.rawValue)]
        XCTAssertNotNil(Converts.convertsTypeFiltersToSingle(values))
        XCTAssertEqual(Converts.convertsTypeFiltersToSingle(values), GMSPlacesAutocompleteTypeFilter.address)
        XCTAssertNotNil(Converts.convertsTypeFiltersToSingle([]))
        XCTAssertEqual(Converts.convertsTypeFiltersToSingle(nil), GMSPlacesAutocompleteTypeFilter.noFilter)
    }
    
    func testConvertsTypeFilter() {
        XCTAssertEqual(Converts.convertsTypeFilter(Int32(TypeFilterIOS.address.rawValue)), GMSPlacesAutocompleteTypeFilter.address)
        XCTAssertEqual(Converts.convertsTypeFilter(Int32(TypeFilterIOS.cities.rawValue)), GMSPlacesAutocompleteTypeFilter.city)
        XCTAssertEqual(Converts.convertsTypeFilter(Int32(TypeFilterIOS.establishment.rawValue)), GMSPlacesAutocompleteTypeFilter.establishment)
        XCTAssertEqual(Converts.convertsTypeFilter(Int32(TypeFilterIOS.geocode.rawValue)), GMSPlacesAutocompleteTypeFilter.geocode)
        XCTAssertEqual(Converts.convertsTypeFilter(Int32(TypeFilterIOS.regions.rawValue)), GMSPlacesAutocompleteTypeFilter.region)
        XCTAssertEqual(Converts.convertsTypeFilter(nil), GMSPlacesAutocompleteTypeFilter.noFilter)
    }
    
    func testConvertsPlaceTypes() {
        let values:[String] = [kGMSPlaceTypeGeocode]
        XCTAssertNotNil(Converts.convertsPlaceTypes(values))
        XCTAssertEqual(Converts.convertsPlaceTypes(values), [Int32(PlaceTypeIOS.geocode.rawValue)])
        XCTAssertNotNil(Converts.convertsPlaceTypes([""]))
        XCTAssertEqual(Converts.convertsPlaceTypes([""]), [-1])
    }
    
    func testConvertsPlaceType() {
        XCTAssertNotNil(Converts.convertsPlaceType(kGMSPlaceTypeGeocode))
        XCTAssertEqual(Converts.convertsPlaceType(kGMSPlaceTypeGeocode), PlaceTypeIOS.geocode)
        XCTAssertNil(Converts.convertsPlaceType(""))
    }
}
