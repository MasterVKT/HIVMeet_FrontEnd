import UIKit
import Flutter
import Vision

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let captureChannel = FlutterMethodChannel(
        name: "hivmeet/kyc_capture",
        binaryMessenger: controller.binaryMessenger
      )
      captureChannel.setMethodCallHandler { call, result in
        guard call.method == "assessDocument" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let arguments = call.arguments as? [String: Any],
              let path = arguments["path"] as? String,
              !path.isEmpty else {
          result(false)
          return
        }
        Self.assessKycDocument(at: URL(fileURLWithPath: path), result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Vision only checks that an identity/medical capture contains a sufficiently
  /// large document-like rectangle. It performs no face detection, biometric
  /// comparison, OCR transmission, or external KYC request.
  private static func assessKycDocument(
    at url: URL,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let request = VNDetectRectanglesRequest()
      request.minimumConfidence = 0.5
      request.minimumSize = 0.15
      request.maximumObservations = 1
      let handler = VNImageRequestHandler(url: url, options: [:])
      do {
        try handler.perform([request])
        let rectangle = request.results?.first
        let isLargeEnough = rectangle.map {
          $0.boundingBox.width * $0.boundingBox.height >= 0.15
        } ?? false
        DispatchQueue.main.async { result(isLargeEnough) }
      } catch {
        // A decode failure is already rejected by the Flutter quality check.
        // Do not expose a file path or image-derived detail to Dart.
        DispatchQueue.main.async { result(false) }
      }
    }
  }
}
