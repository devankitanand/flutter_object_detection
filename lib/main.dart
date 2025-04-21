import 'package:flutter/material.dart';
import 'detection_widget.dart';

void main() {
  // Ensure Flutter bindings are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime Object Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DetectionWidget(),
    );
  }
}
