package com.example.flutter_object_detection

import androidx.annotation.NonNull
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Import ML Kit packages:
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.objects.ObjectDetection
import com.google.mlkit.vision.objects.defaults.ObjectDetectorOptions

class MainActivity : FlutterActivity() {
    private val CHANNEL = "object_detection"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "detectObjectsFromStream") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    val rotation = call.argument<Int>("rotation") ?: 0

                    if (bytes == null || width == 0 || height == 0) {
                        result.error("INVALID_ARGUMENT", "Missing frame data", null)
                        return@setMethodCallHandler
                    }
                    detectObjectsFromStream(bytes, width, height, rotation, result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun detectObjectsFromStream(
        byteArray: ByteArray,
        width: Int,
        height: Int,
        rotation: Int,
        result: MethodChannel.Result
    ) {
        try {
            Log.d("MLKitStream", "Processing frame: ${width}x$height, rotation: $rotation, byte length: ${byteArray.size}")
            // Create the InputImage from NV21 data.
            val inputImage = InputImage.fromByteArray(
                byteArray,
                width,
                height,
                rotation,   // Ensure this is 0, 90, 180, or 270.
                InputImage.IMAGE_FORMAT_NV21
            )

            // Use STREAM_MODE for real-time processing.
            val options = ObjectDetectorOptions.Builder()
                .setDetectorMode(ObjectDetectorOptions.STREAM_MODE)
                .enableMultipleObjects()
                .enableClassification()
                .build()

            val objectDetector = ObjectDetection.getClient(options)
            objectDetector.process(inputImage)
                .addOnSuccessListener { detectedObjects ->
                    if (detectedObjects.isEmpty()) {
                        Log.d("MLKitStream", "No objects detected")
                    } else {
                        detectedObjects.forEach { obj ->
                            val label = if (obj.labels.isNotEmpty()) obj.labels.first().text else "Unknown"
                            Log.d("MLKitStream", "Detected object: $label")
                        }
                    }
                    val sb = StringBuilder()
                    detectedObjects.forEach { obj ->
                        val label = if (obj.labels.isNotEmpty()) obj.labels.first().text else "Unknown"
                        sb.append("Detected: ").append(label).append("\n")
                    }
                    result.success(sb.toString())
                }
                .addOnFailureListener { e ->
                    Log.e("MLKitStream", "Detection error", e)
                    result.error("DETECTION_ERROR", e.localizedMessage, null)
                }
        } catch (e: Exception) {
            Log.e("MLKitStream", "Processing error", e)
            result.error("PROCESSING_ERROR", e.localizedMessage, null)
        }
    }
}
