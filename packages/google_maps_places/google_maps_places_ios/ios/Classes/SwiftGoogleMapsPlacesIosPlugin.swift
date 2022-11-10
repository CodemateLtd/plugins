import Flutter
import UIKit
import GooglePlaces

public class SwiftGoogleMapsPlacesIosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "google_maps_places_ios", binaryMessenger: registrar.messenger())
    let instance = SwiftGoogleMapsPlacesIosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
