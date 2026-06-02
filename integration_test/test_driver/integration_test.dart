import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for the store-screenshot integration test.
///
/// Receives every `binding.takeScreenshot(<name>)` call from the running app
/// and writes the raw PNG bytes to `docs/store/android/screenshots/<name>.png`
/// so the captured assets land straight in the versioned store folder.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('docs/store/android/screenshots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
