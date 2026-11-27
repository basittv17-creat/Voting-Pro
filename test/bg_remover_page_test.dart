import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/app_language.dart';
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

  testWidgets('Live manual brush cursor remains valid Stack parent data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cursor = ValueNotifier<Offset?>(null);
    addTearDown(cursor.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 280,
          height: 340,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.black)),
              BackgroundBrushCursor(
                cursor: cursor,
                enabled: true,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    cursor.value = const Offset(90, 130);
    await tester.pump();
    expect(tester.takeException(), isNull);
    cursor.value = const Offset(140, 175);
    await tester.pump();
    expect(tester.takeException(), isNull);
    cursor.value = null;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact main remover keeps Back visible in Urdu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    AppLanguage.current = 'ur';
    addTearDown(() => AppLanguage.current = 'en');
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 144,
            child: BackgroundRemoverPage(
              initialPhotoA: null,
              initialPhotoB: null,
              onClose: () => closed = true,
              onSelectSide: (_) {},
              onUpload: () {},
              onApply: (_, _) async {},
            ),
          ),
        ),
      ),
    );
    final back = find.byKey(const ValueKey('main-remover-back'));
    final before = tester.getRect(back);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(tester.getRect(back), before);
    expect(find.text('واپس'), findsOneWidget);
    await tester.tap(back);
    expect(closed, isTrue);
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
