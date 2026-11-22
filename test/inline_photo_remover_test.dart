import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:voting_pro/widgets/bg_remover_page.dart';

class _Documents extends PathProviderPlatform {
  _Documents(this.directory);
  final Directory directory;

  @override
  Future<String?> getApplicationDocumentsPath() async => directory.path;
}

void main() {
  testWidgets('Compact remover applies a manual stroke only to its B target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = Directory.systemTemp.createTempSync('inline-cutout-');
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Documents(directory);
    addTearDown(() {
      PathProviderPlatform.instance = original;
      directory.deleteSync(recursive: true);
    });
    final file = File('${directory.path}/source.png');
    final originalImage = img.Image(width: 120, height: 150);
    file.writeAsBytesSync(img.encodePng(originalImage));
    File? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 232,
          width: 393,
          child: BackgroundRemoverPage(
            initialPhotoA: null,
            initialPhotoB: file,
            initialSideA: false,
            onClose: () {},
            onApply: (sideA, cutout) async {
              expect(sideA, isFalse);
              result = cutout;
            },
          ),
        ),
      ),
    ));

    Future<void> waitFor(bool Function() done) async {
      for (var attempt = 0; attempt < 100 && !done(); attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(done(), isTrue);
    }

    final preview = find.byKey(const ValueKey('inline-cutout-brush'));
    await waitFor(() => preview.evaluate().isNotEmpty);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Erase'));
    await tester.pump();
    final center = tester.getCenter(preview);
    final stroke = await tester.startGesture(center - const Offset(16, 0));
    await stroke.moveTo(center + const Offset(16, 0));
    await tester.pump();
    await stroke.moveTo(center + const Offset(32, 0));
    await stroke.up();
    await tester.pump();

    final apply = find.widgetWithText(OutlinedButton, 'Apply');
    await waitFor(() => tester.widget<OutlinedButton>(apply).onPressed != null);
    await tester.ensureVisible(apply);
    await tester.pump();
    await tester.tap(apply);
    await tester.pump();
    await waitFor(() => result != null);
    final cutout = img.decodePng(result!.readAsBytesSync())!;
    expect(cutout.any((pixel) => pixel.a == 0), isTrue);
  });
}
