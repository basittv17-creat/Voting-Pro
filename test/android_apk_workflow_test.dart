import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android UI artifacts contain a launcher app, not a test runner', () {
    final workflow = File(
      '.github/workflows/android-ui-smoke.yml',
    ).readAsStringSync();

    final integration = workflow.indexOf(
      '--target=integration_test/text_toolbar_android_test.dart',
    );
    final iconGeneration = workflow.indexOf(
      'dart run flutter_launcher_icons',
    );
    final normalBuild = workflow.indexOf(
      'flutter build apk --debug --target lib/main.dart',
    );
    final apkUpload = workflow.indexOf(
      'name: voting-pro-normal-app-debug-apk',
    );

    expect(integration, greaterThanOrEqualTo(0));
    expect(iconGeneration, greaterThan(integration));
    expect(normalBuild, greaterThan(iconGeneration));
    expect(apkUpload, greaterThan(normalBuild));

    expect(workflow, contains('android:label="Voting Pro"'));
    expect(workflow, contains('mipmap-xxxhdpi/ic_launcher.png'));
    expect(workflow, contains('adb -s emulator-5554 install -r'));
    expect(workflow, contains(r'pidof -s "$PACKAGE"'));
    expect(workflow, contains('text-09-normal-app-launch.png'));
  });
}
