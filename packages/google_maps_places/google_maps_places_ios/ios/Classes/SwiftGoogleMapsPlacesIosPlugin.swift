// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import GooglePlaces

public class SwiftGoogleMapsPlacesIosPlugin: NSObject, FlutterPlugin, GoogleMapsPlacesApiIOS {
   
    private var placesClient: GMSPlacesClient!
    private var lastSessionToken: GMSAutocompleteSessionToken?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : GoogleMapsPlacesApiIOS & NSObjectProtocol = SwiftGoogleMapsPlacesIosPlugin.init()
        GoogleMapsPlacesApiIOSSetup.setUp(binaryMessenger: messenger, api: api)
    }
    
    func findAutocompletePredictionsIOS(query: String, locationBias: LatLngBoundsIOS?, locationRestriction: LatLngBoundsIOS?, origin: LatLngIOS?, countries: [String?]?, typeFilter: [Int32?]?, refreshToken: Bool?, completion: @escaping ([AutocompletePredictionIOS?]?) -> Void) {
        let sessionToken = getSessionToken(force: refreshToken == true)
        
        // Create a type filter.
        let filter = GMSAutocompleteFilter()
        //filter.type = makeTypeFilter(typeFilter: placeTypeFilter);
        filter.countries = countries as? [String]
        //filter.origin = request.origin
        
        initialize()
        placesClient.findAutocompletePredictions(
            fromQuery: query, filter: filter, sessionToken: sessionToken,
            callback: { (results, error) in
                if let error = error {
                    print("findPlacesAutoComplete error: \(error)")
                    /*completion(FlutterError(
                     code: "API_ERROR",
                     message: error.localizedDescription,
                     details: nil
                     ))*/
                    completion(nil)
                } else {
                    self.lastSessionToken = sessionToken
                    completion(self.convertResults(results))
                }
            })
        
    }
    
    private func initialize() {
        guard (placesClient == nil) else {
            return
        }
        placesClient = GMSPlacesClient.shared()
    }
    
    private func getSessionToken(force: Bool) -> GMSAutocompleteSessionToken! {
        let localToken = lastSessionToken
        if (force || localToken == nil) {
            return GMSAutocompleteSessionToken.init()
        }
        return localToken
    }
    
    private func convertResults(_ results: [GMSAutocompletePrediction]?) -> [AutocompletePredictionIOS?] {
        guard let results = results else {
            return []
        }
        var predictions = results.map { (prediction: GMSAutocompletePrediction) in
            return convertPrediction(prediction) }
        return predictions
    }
    
    private func convertPrediction(_ prediction: GMSAutocompletePrediction) -> AutocompletePredictionIOS? {
        return AutocompletePredictionIOS(fullText: prediction.attributedFullText.string, placeId: prediction.placeID, placeTypes: convertPlaceTypes(prediction.types), primaryText: prediction.attributedPrimaryText.string, secondaryText: prediction.attributedSecondaryText?.string ?? "")
    }
    
    private func convertPlaceTypes(_ placeTypes: [String]) -> [Int32?] {
        return []
    }
}
    /*
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "findPlacesAutoComplete":
            let args = call.arguments as! Dictionary<String,Any>
            let query = args["query"] as! String
            let countries = args["countries"] as? [String]? ?? [String]()
            let placeTypeFilter = args["typeFilter"] as? String
            let origin = latLngFromMap(argument: args["origin"] as? Array<Double>)
            let newSessionToken = args["newSessionToken"] as? Bool
            let sessionToken = getSessionToken(force: newSessionToken == true)
            
            // Create a type filter.
            let filter = GMSAutocompleteFilter()
            filter.type = makeTypeFilter(typeFilter: placeTypeFilter);
            filter.countries = countries
            filter.origin = origin
            
            initialize()
            placesClient.findAutocompletePredictions(
                fromQuery: query, filter: filter, sessionToken: sessionToken,
                callback: { (results, error) in
                    if let error = error {
                        print("findPlacesAutoComplete error: \(error)")
                        result(FlutterError(
                            code: "API_ERROR",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    } else {
                        self.lastSessionToken = sessionToken
                        let mappedResult = self.responseToList(results: results)
                        result(mappedResult)
                    }
                })
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func latLngFromMap(argument: Array<Double>?) -> CLLocation? {
        guard argument != nil else {
            return nil
        }
        
        return CLLocation(latitude: argument![0], longitude: argument![1])
    }
    
    private func makeTypeFilter(typeFilter: String?) -> GMSPlacesAutocompleteTypeFilter {
        guard let typeFilter = typeFilter else {
            return GMSPlacesAutocompleteTypeFilter.noFilter
        }
        switch (typeFilter.uppercased()) {
        case "ADDRESS":
            return GMSPlacesAutocompleteTypeFilter.address
        case "CITIES":
            return GMSPlacesAutocompleteTypeFilter.city
        case "ESTABLISHMENT":
            return GMSPlacesAutocompleteTypeFilter.establishment
        case "GEOCODE":
            return GMSPlacesAutocompleteTypeFilter.geocode
        case "REGIONS":
            return GMSPlacesAutocompleteTypeFilter.region
        case "ALL":
            fallthrough
        default:
            return GMSPlacesAutocompleteTypeFilter.noFilter
        }
    }
}*/
