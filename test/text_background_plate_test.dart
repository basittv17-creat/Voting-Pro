import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';
import 'package:voting_pro/widgets/text_background_plate.dart';

void main() {
  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('Swatches and premium presets affect only selected text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['تگڑا مقابلہ', 'Other'],
        'textOverlayIds': [0, 1],
        'textPositions': {
          '0': [25, 25],
          '1': [25, 105],
        },
        'textBgOpacities': {'0': 0},
      }),
    });
    tester.view.physicalSize = const Size(393, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Text'));
    final toolbar = find.byKey(const ValueKey('text-toolbar'));
    Finder action(String name) =>
        find.descendant(of: toolbar, matching: find.text(name));
    final bounds = tester.getRect(toolbar);
    final dock = find.byKey(const ValueKey('text-background-toolbar'));
    final poster = find.byType(Screenshot);
    final plates = find.descendant(
      of: poster,
      matching: find.byType(TextBackgroundPlate),
    );
    await tap(tester, action('Text Background'));
    expect(toolbar, findsNothing);
    expect(tester.getRect(dock), bounds);
    expect(find.text('Tap text on the poster to select'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
    await tap(tester, find.text('تگڑا مقابلہ'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Tap text on the poster to select'), findsNothing);
    expect(plates, findsNothing);
    await tap(tester, find.byTooltip('Color #FFD84D'));
    expect(plates, findsOneWidget);
    final plain = tester.widget<TextBackgroundPlate>(
      plates,
    );
    expect(plain.opacity, .85);
    expect(plain.color, const Color(0xFFFFD84D));

    await tap(
        tester,
        find.descendant(
          of: dock,
          matching: find.text('Advanced Backgrounds'),
        ));
    await tap(tester, find.text('Royal Gold'));
    expect(tester.getRect(dock), bounds);
    final selected = find.byWidgetPredicate(
      (widget) => widget is AdvancedTextOverlay && widget.text == 'تگڑا مقابلہ',
    );
    final other = find.byWidgetPredicate(
      (widget) => widget is AdvancedTextOverlay && widget.text == 'Other',
    );
    AdvancedTextOverlay artwork() =>
        tester.widget<AdvancedTextOverlay>(selected);
    expect(artwork().backgroundDesign, 'Royal Gold');
    expect(tester.widget<AdvancedTextOverlay>(other).backgroundColor, isNull);
    expect(artwork().style.fontFamily, 'NotoNastaliqUrdu');
    await tap(tester, find.byTooltip('Undo Text'));
    expect(artwork().backgroundDesign, 'solid');
    await tap(tester, find.byTooltip('Redo Text'));
    expect(artwork().backgroundDesign, 'Royal Gold');
  });

  for (final width in [320.0, 360.0, 393.0, 412.0]) {
    testWidgets('Measured Urdu overlay stays inside both ratios at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final ratio in [16 / 9, 4 / 3]) {
        SharedPreferences.setMockInitialValues({
          'voting_pro_project_v1': jsonEncode({
            'canvasRatio': ratio,
            'overlays': ['پرو'],
            'textOverlayIds': [0],
            'textPositions': {
              '0': [1000, -1000],
            },
            'textBgColors': {'0': 0xFF152534},
            'textBgDesigns': {'0': 'Calligraphy Panel'},
            'textGlowStrengths': {'0': 1},
          }),
        });
        await tester.pumpWidget(const MaterialApp(home: Editor()));
        await tester.pumpAndSettle();
        final overlay = find.byType(AdvancedTextOverlay);
        final poster = tester.getRect(find.byType(Screenshot));
        final top = tester.getRect(overlay);
        expect(top.top, greaterThanOrEqualTo(poster.top));
        expect(top.right, lessThanOrEqualTo(poster.right));
        await tester.drag(overlay, const Offset(-28, 30));
        await tester.pumpAndSettle();
        final moved = tester.getRect(overlay);
        expect(moved.top, greaterThan(top.top));
        expect(moved.left, lessThan(top.left));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }
}
