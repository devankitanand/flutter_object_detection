# flutter_object_detection

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Setup Instructions

Follow these steps to set up and run the project:

### Prerequisites
1. Install [Flutter](https://docs.flutter.dev/get-started/install) on your system.
2. Ensure you have an editor like [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio) installed.
3. Set up an emulator or connect a physical device for testing.

### Steps
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd flutter_object_detection
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. To build the app for release, follow the [Flutter build documentation](https://docs.flutter.dev/deployment).

## Approach

This project uses the following approach for object detection:

1. **Camera Integration**:
   - The app uses the `camera` package to access the device's camera and capture images.
   - The camera is initialized with specific settings, such as resolution and flash mode.

2. **Image Processing**:
   - Use native ML Kit APIs on both Android and iOS via platform channels.
   - Captured images are analyzed to detect the darkest part of the image.
   - The app processes the image data to calculate brightness values for each pixel and identifies the darkest region.

3. **Object Marking**:
   - A bounding box is drawn around the detected region using Flutter's `CustomPainter`.
   - The bounding box dynamically updates based on the detected object's location.

4. **Realtime Updates**:
   - The app captures images at regular intervals (every 0.5 seconds) to provide real-time object detection.
   - Results are displayed on the screen, including a label and bounding box for the detected object.

5. **Cross-Platform Support**:
   - The app is designed to work on multiple platforms, including Android, iOS, Windows, macOS, Linux, and Web.
   - Platform-specific configurations are handled in respective directories (e.g., `android/`, `ios/`, `web/`).
