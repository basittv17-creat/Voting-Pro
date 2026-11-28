import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      // Large on-device UI suites capture several full-screen PNGs. Allow
      // the emulator time to transfer screenshot payloads over the VM service
      // instead of aborting a healthy but temporarily busy device.
      timeout: const Duration(minutes: 5),
      onScreenshot: (name, bytes, [args]) async {
        final directory = Directory('build/android-screenshots');
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png').writeAsBytes(bytes);
        return true;
      },
    );
