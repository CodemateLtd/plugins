import UIKit
import Flutter
import GooglePlaces

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      var mapsApiKey = ProcessInfo.processInfo.environment["MAPS_API_KEY"] ?? ""
      if (mapsApiKey.isEmpty) {
          mapsApiKey = "YOUR_API_KEY"
      }
      GMSPlacesClient.provideAPIKey(mapsApiKey)
      GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
