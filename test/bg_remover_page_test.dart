import 'dart:io';

import 'package:flutter/material.dart';
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
