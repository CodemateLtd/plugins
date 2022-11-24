// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import GooglePlaces

/** GoogleMapsPlacesIOSPlugin */
public class SwiftGoogleMapsPlacesIosPlugin: NSObject, FlutterPlugin, GoogleMapsPlacesApiIOS {
    
    private var placesClient: GMSPlacesClient!
    private var previousSessionToken: GMSAutocompleteSessionToken?
    
    /// Register Flutter API communications
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : GoogleMapsPlacesApiIOS & NSObjectProtocol = SwiftGoogleMapsPlacesIosPlugin.init()
        GoogleMapsPlacesApiIOSSetup.setUp(binaryMessenger: messenger, api: api)
    }
    
    /// Find Autocomplete Predictions
    /// ref: https://developers.google.com/maps/documentation/places/ios-sdk/autocomplete#get_place_predictions
    func findAutocompletePredictionsIOS(query: String, locationBias: LatLngBoundsIOS?, locationRestriction: LatLngBoundsIOS?, origin: LatLngIOS?, countries: [String?]?, typeFilter: [Int32?]?, refreshToken: Bool?, completion: @escaping ([AutocompletePredictionIOS?]?) -> Void) {
        
        let filter = GMSAutocompleteFilter()
        filter.type = Convert.convertTypeFiltersToSingle(typeFilter);
        filter.countries = countries as? [String]
        filter.origin = Convert.convertLatLng(origin)
        
        // Only locationBias or locationRestriction is allowed
        if (locationBias != nil && locationRestriction == nil) {
            filter.locationBias = Convert.convertLocationBias(locationBias)
        } else if (locationBias == nil && locationRestriction != nil) {
            filter.locationRestriction = Convert.convertLocationRestrction(locationRestriction)
        }
        
        let sessionToken = initialize(refreshToken == true)
        guard sessionToken != nil else {
            print("failed to initialize API CLIENT")
            completion(nil)
            return
        }
        placesClient.findAutocompletePredictions(
            fromQuery: query, filter: filter, sessionToken: sessionToken,
            callback: { (results, error) in
                if let error = error {
                    print("findPlacesAutoComplete error: \(error)")
                    // Pigeon does not generate flutter error callback at the moment so returning nil
                    /*completion(FlutterError(
                     code: "API_ERROR",
                     message: error.localizedDescription,
                     details: nil
                     ))*/
                    completion(nil)
                } else {
                    self.previousSessionToken = sessionToken
                    completion(Convert.convertResults(results))
                }
            })
        
    }
    
    /// Initialize Places client
    private func initialize(_ refresh: Bool) -> GMSAutocompleteSessionToken? {
        guard (placesClient == nil) else {
            return getSessionToken(refresh)
        }
        placesClient = GMSPlacesClient.shared()
        return getSessionToken(refresh)
    }
    
    /// Fetch new session token if needed
    private func getSessionToken(_ refresh: Bool) -> GMSAutocompleteSessionToken? {
        let localToken = previousSessionToken
        if (refresh || localToken == nil) {
            return GMSAutocompleteSessionToken.init()
        }
        return localToken
    }
}
