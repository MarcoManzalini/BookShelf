import Flutter
import UIKit
import UserNotifications
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show reading reminders.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TextRecognition") {
      TextRecognition.register(messenger: registrar.messenger())
    }
  }
}

/// Reads the text of a photographed page, for saving quotes. Returns the
/// recognized lines in reading order.
enum TextRecognition {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "bookshelf/text_recognition",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        let image = UIImage(contentsOfFile: path),
        let cgImage = image.cgImage
      else {
        result(FlutterError(code: "bad_image", message: "Unreadable image", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if #available(iOS 16.0, *) {
          request.automaticallyDetectsLanguage = true
        } else {
          request.recognitionLanguages = ["it-IT", "en-US"]
        }
        let handler = VNImageRequestHandler(
          cgImage: cgImage,
          orientation: orientation(of: image),
          options: [:]
        )
        do {
          try handler.perform([request])
          let lines = (request.results ?? []).compactMap {
            $0.topCandidates(1).first?.string
          }
          DispatchQueue.main.async { result(lines) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private static func orientation(of image: UIImage) -> CGImagePropertyOrientation {
    switch image.imageOrientation {
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upMirrored: return .upMirrored
    case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
  }
}
