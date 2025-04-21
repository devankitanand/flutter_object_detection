import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DetectionWidget extends StatefulWidget {
  const DetectionWidget({Key? key}) : super(key: key);

  @override
  State<DetectionWidget> createState() => _DetectionWidgetState();
}

class _DetectionWidgetState extends State<DetectionWidget> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  String _detectionResult = "Waiting for detection...";
  bool _isDetecting = false;
  DateTime? _lastDetectionTime;

  // This MethodChannel name must match the Android side.
  static const MethodChannel _channel = MethodChannel("object_detection");

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController.initialize();

    // Start streaming images after initialization.
    _startImageStream();

    if (!mounted) return;
    setState(() {});
  }

  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) async {
      debugPrint("Received frame: ${image.width} x ${image.height}");

      // Throttle processing to about one frame per 500ms.
      if (_isDetecting) return;
      if (_lastDetectionTime != null &&
          DateTime.now().difference(_lastDetectionTime!) <
              const Duration(milliseconds: 500)) {
        return;
      }
      _isDetecting = true;
      _lastDetectionTime = DateTime.now();

      try {
        // Convert the YUV420 image from the camera into NV21 format.
        final nv21Bytes = convertYUV420toNV21(image);
        debugPrint("NV21 byte length: ${nv21Bytes.length}");

        // Set a fixed rotation (0, 90, 180, 270). Adjust if your device requires a different value.
        const int rotation = 0;

        // Invoke the native method.
        final String result =
            await _channel.invokeMethod("detectObjectsFromStream", {
          "bytes": nv21Bytes,
          "width": image.width,
          "height": image.height,
          "rotation": rotation,
        });
        setState(() {
          _detectionResult = result;
        });
      } on PlatformException catch (e) {
        debugPrint("PlatformException: ${e.message}");
        setState(() {
          _detectionResult = "Platform error: ${e.message}";
        });
      } catch (e) {
        debugPrint("Error during detection: $e");
        setState(() {
          _detectionResult = "Error: $e";
        });
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Robust conversion from YUV420 (from camera) to NV21 format.
  /// This function takes into account the row stride and pixel stride.
  Uint8List convertYUV420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;

    // Calculate size based on UV planes (assuming both have the same dimensions)
    // The U and V planes are subsampled 2x so their width is width/2 and height is height/2.
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;
    final int uvSize =
        uvWidth * uvHeight; // expected number of U (or V) samples

    // Allocate buffer for NV21: Y plane + interleaved VU plane (2 bytes per UV pixel)
    final Uint8List nv21 = Uint8List(ySize + 2 * uvSize);

    // 1. Copy the Y plane.
    final Uint8List yBuffer = image.planes[0].bytes;
    nv21.setRange(0, ySize, yBuffer);

    // 2. Interleave the UV data.
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    // Use actual row and pixel stride from the U and V planes.
    final int rowStrideU = planeU.bytesPerRow;
    final int pixelStrideU = planeU.bytesPerPixel ?? 1;
    final int rowStrideV = planeV.bytesPerRow;
    final int pixelStrideV = planeV.bytesPerPixel ?? 1;

    int uvIndex = ySize;
    // Iterate over each row of the subsampled UV data.
    for (int row = 0; row < uvHeight; row++) {
      int offsetU = row * rowStrideU;
      int offsetV = row * rowStrideV;
      for (int col = 0; col < uvWidth; col++) {
        // For NV21, the expected order is V then U.
        nv21[uvIndex++] = planeU.bytes[offsetU + col * pixelStrideU];
        nv21[uvIndex++] = planeV.bytes[offsetV + col * pixelStrideV];
      }
    }

    debugPrint(
        "Converted NV21 length: ${nv21.length} (expected: ${ySize + 2 * uvSize})");
    return nv21;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Realtime Object Detection")),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                _detectionResult,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
