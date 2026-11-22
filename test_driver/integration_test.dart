import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves each on-device screenshot to build/phone_screens/.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('build/phone_screens/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
