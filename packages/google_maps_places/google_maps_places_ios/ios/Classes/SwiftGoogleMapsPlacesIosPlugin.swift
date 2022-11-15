// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import GooglePlaces

public class SwiftGoogleMapsPlacesIosPlugin: NSObject, FlutterPlugin {
        
    private var placesClient: GMSPlacesClient!
    private var lastSessionToken: GMSAutocompleteSessionToken?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "plugins.flutter.io/google_maps_places_ios", binaryMessenger: registrar.messenger())
        let instance = SwiftGoogleMapsPlacesIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

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
    
    private func responseToList(results: [GMSAutocompletePrediction]?) -> [Dictionary<String, Any?>]? {
        guard let results = results else {
            return nil;
        }
        
        return results.map { (prediction: GMSAutocompletePrediction) in
            return predictionToMap(prediction: prediction) }
    }
    
    private func predictionToMap(prediction: GMSAutocompletePrediction) -> Dictionary<String, Any?> {
        return [
            "placeId": prediction.placeID,
            "distanceMeters": prediction.distanceMeters,
            "primaryText": prediction.attributedPrimaryText.string,
            "secondaryText": prediction.attributedSecondaryText?.string ?? "",
            "fullText": prediction.attributedFullText.string
        ];
    }
}
