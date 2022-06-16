import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'src/application.dart';

void main() {
  runApp(
    DevicePreview(
      builder: (context) => const MyApp(), // Wrap your app
    ),
  );
}
