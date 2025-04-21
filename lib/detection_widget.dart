import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
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
  bool _isCameraInitialized = false;
  String _detectionResult = "Waiting for detection...";
  ui.Image? _capturedImage;
  Timer? _timer;
  Rect _focusPoint = Rect.zero;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cameraController.initialize();

    // Disable flashlight explicitly.
    await _cameraController.setFlashMode(FlashMode.off);

    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _startTakingPictures() async {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted || !_isCameraInitialized) {
        timer.cancel();
        return;
      }
      try {
        final XFile picture = await _cameraController.takePicture();
        final bytes = await picture.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        setState(() {
          _capturedImage = frame.image;
        });

        // Analyze the image to find the darkest part.
        final ByteData? imageData = await _capturedImage!
            .toByteData(format: ui.ImageByteFormat.rawRgba);
        if (imageData == null) {
          debugPrint("Failed to retrieve image data");
          return;
        }
        final Uint8List pixels = imageData.buffer.asUint8List();
        int darkestValue = 255;
        int darkestIndex = 0;

        for (int i = 0; i < pixels.length; i += 4) {
          final int r = pixels[i];
          final int g = pixels[i + 1];
          final int b = pixels[i + 2];
          final int brightness = (r + g + b) ~/ 3;

          if (brightness < darkestValue) {
            darkestValue = brightness;
            darkestIndex = i;
          }
        }

        final int x = (darkestIndex ~/ 4) % _capturedImage!.width;
        final int y = (darkestIndex ~/ 4) ~/ _capturedImage!.width;

        // Set the bounding box around the darkest part.
        const double boxSize = 50;
        final double boxLeft = x - (boxSize / 2);
        final double boxTop = y - (boxSize / 2);
        setState(() {
          _focusPoint = Rect.fromLTWH(boxLeft, boxTop, boxSize, boxSize);
          _detectionResult = "Object detected";
        });
      } catch (e) {
        debugPrint("Error taking picture: $e");
      }
    });
  }

  void _stopTakingPictures() {
    _timer?.cancel();
    setState(() {
      _detectionResult = "Detection stopped";
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Realtime Object Detection")),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          if (_capturedImage != null)
            CustomPaint(
              painter: ObjectPainter(_capturedImage!, _focusPoint),
              child: Container(),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: Colors.black54,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _detectionResult,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _startTakingPictures,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blue, // Set the background color
                        foregroundColor: Colors.white, // Set the text color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Rounded corners
                        ),
                        elevation: 5, // Add shadow for depth
                      ),
                      child: const Text(
                        "Start",
                        style: TextStyle(
                          fontSize: 18, // Set the font size
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _stopTakingPictures,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Stop",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  final ui.Image image;
  final Rect objectBoundingBox;

  ObjectPainter(this.image, this.objectBoundingBox);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);

    // Draw a bounding box for the detected object.
    final rectPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRect(objectBoundingBox, rectPaint);

    // Add a label for the detected object.
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "Object",
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(objectBoundingBox.left, objectBoundingBox.top - 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
