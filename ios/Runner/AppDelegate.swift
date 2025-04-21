import UIKit
import Flutter
import MLKitObjectDetection
import MLKitVision

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "object_detection"
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
    
    methodChannel.setMethodCallHandler { (call, result) in
      if call.method == "detectObjects" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path is required", details: nil))
          return
        }
        self.detectObjects(imagePath: imagePath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func detectObjects(imagePath: String, result: @escaping FlutterResult) {
    // Create a UIImage from the given file path.
    guard let image = UIImage(contentsOfFile: imagePath) else {
      result(FlutterError(code: "FILE_NOT_FOUND", message: "Image file not found", details: nil))
      return
    }
    
    let visionImage = VisionImage(image: image)
    visionImage.orientation = image.imageOrientation

    // Configure the object detector.
    let options = ObjectDetectorOptions()
    options.shouldEnableClassification = true // Optional: enables label classification.
    options.shouldEnableMultipleObjects = true
    options.detectorMode = .stream
    
    let objectDetector = ObjectDetector.objectDetector(options: options)
    
    objectDetector.process(visionImage) { detectedObjects, error in
      if let error = error {
        result(FlutterError(code: "DETECTION_ERROR", message: error.localizedDescription, details: nil))
        return
      }
      
      guard let detectedObjects = detectedObjects else {
        result("No objects detected")
        return
      }
      
      var output = ""
      for object in detectedObjects {
        if let firstLabel = object.labels.first {
          output += "Detected: \(firstLabel.text)\n"
        } else {
          output += "Detected: Unknown\n"
        }
      }
      result(output)
    }
  }
}
