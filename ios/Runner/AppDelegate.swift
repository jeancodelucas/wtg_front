import UIKit
import Flutter
import GoogleMaps // 1. Importe a biblioteca do Google Maps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 2. Adicione esta linha com a sua chave de API do iOS
    GMSServices.provideAPIKey("AIzaSyDNE-vOY-834Xe9iN1DDTRYSDiAKK6QsLw")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}