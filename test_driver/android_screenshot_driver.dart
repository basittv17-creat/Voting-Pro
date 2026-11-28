import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Collect all on-device screenshots in one VM-service response. The extended
/// driver requests a separate response for every screenshot; on slower
/// emulators those repeated round trips can stall the driver channel. The
/// standard integration driver transfers the completed test report once,
/// with an explicit generous timeout, while retaining every screenshot.
Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 20),
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    if (data == null) return;

    final screenshots = data['screenshots'];
    if (screenshots is List) {
      final directory = Directory('build/android-screenshots');
      await directory.create(recursive: true);
      for (final item in screenshots) {
        if (item is! Map) {
          throw const FormatException('Invalid integration screenshot record.');
        }
        final name = item['screenshotName'];
        final bytes = item['bytes'];
        if (name is! String ||
            name.isEmpty ||
            name.contains('/') ||
            name.contains('\\\\') ||
            name.contains('..') ||
            bytes is! List) {
          throw const FormatException('Invalid integration screenshot payload.');
        }
        await File('${directory.path}/$name.png').writeAsBytes(
          bytes.cast<int>(),
          flush: true,
        );
      }
    }

    final report = File('build/integration_response_data.json');
    await report.parent.create(recursive: true);
    await report.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  },
);
