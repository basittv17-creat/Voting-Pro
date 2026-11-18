import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/widgets/bg_remover_page.dart';

void main() {
  Widget page() {
    return MaterialApp(
      home: BackgroundRemoverPage(
        initialPhotoA: null,
        initialPhotoB: null,
        onApply: (bool sideA, File result) async {},
      ),
    );
  }

  testWidgets('BG Remover fits a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(page());
    expect(find.text('BG REMOVER'), findsOneWidget);
    expect(find.text('Upload Your Picture'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Manual image brush does not throw a Positioned layout error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final folder = await Directory.systemTemp.createTemp('voting_brush_test_');
    addTearDown(() => folder.delete(recursive: true));
    final photo = File('${folder.path}/source.png');
    await photo.writeAsBytes(
      img.encodePng(img.Image(width: 40, height: 40)),
    );

    await tester.pumpWidget(MaterialApp(
      home: BackgroundRemoverPage(
        initialPhotoA: photo,
        initialPhotoB: null,
        onApply: (sideA, result) async {},
      ),
    ));
    // Preparing the image uses a background isolate rather than a fake timer.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Image ready'), findsOneWidget);

    await tester.ensureVisible(find.text('Manual'));
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    final preview = find.byType(Image).first;
    await tester.tapAt(tester.getCenter(preview));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Selecting Photo B changes the target', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(page());
    await tester.tap(find.text('Photo B'));
    await tester.pumpAndSettle();
    expect(find.text('Upload picture for side B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
