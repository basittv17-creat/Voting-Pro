import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';
import 'package:voting_pro/widgets/premium_text_editor_panel.dart';

void main() {
  testWidgets('Text replaces the main toolbar in the same slot at 320 dp', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final main = find.byKey(const PageStorageKey('main-toolbar'));
    final text = find.byKey(const ValueKey('text-toolbar'));
    final poster = find.byType(Screenshot);
    final toolbarBounds = tester.getRect(main);
    final posterBounds = tester.getRect(poster);

    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    expect(main, findsNothing);
    expect(find.text('Add Photo A'), findsNothing);
    expect(tester.getRect(text), toolbarBounds);
    expect(find.byType(PremiumTextEditorPanel), findsNothing);

    // Back is pinned to the RIGHT, outside the horizontally scrolling tools.
    final textScroll = find.byKey(const ValueKey('text-tool-scroll'));
    final back = find.descendant(of: text, matching: find.text('Back'));
    expect(textScroll, findsOneWidget);
    expect(back, findsOneWidget);
    expect(
      tester.getRect(back).left,
      greaterThanOrEqualTo(tester.getRect(textScroll).right),
    );
    final fixedBackPosition = tester.getRect(back);
    final delete = find.descendant(
      of: text,
      matching: find.text('Delete Text'),
    );
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    expect(tester.getRect(back), fixedBackPosition);
    expect(
      tester.getCenter(find.text('Back')).dy,
      tester.getCenter(find.text('Add Text')).dy,
    );

    final glow = find.descendant(of: text, matching: find.text('Glow'));
    await tester.ensureVisible(glow);
    await tester.tap(glow);
    await tester.pumpAndSettle();
    final settings = find.byType(PremiumTextEditorPanel);
    expect(find.text('Glow intensity'), findsOneWidget);
    expect(
      tester.getTopLeft(settings).dy,
      greaterThanOrEqualTo(posterBounds.bottom),
    );
    expect(find.descendant(of: poster, matching: settings), findsNothing);
    expect(tester.getRect(poster), posterBounds);
    expect(tester.getRect(text), toolbarBounds);

    final background = find.descendant(
      of: text,
      matching: find.text('Text Background'),
    );
    await tester.ensureVisible(background);
    await tester.tap(background);
    await tester.pumpAndSettle();
    expect(find.text('Background opacity'), findsOneWidget);
    expect(find.text('Glow intensity'), findsNothing);
    expect(tester.getRect(text), toolbarBounds);

    await tester.ensureVisible(find.text('Back'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(text, findsNothing);
    expect(settings, findsNothing);
    expect(tester.getRect(main), toolbarBounds);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Shadow changes the poster overlay and supports undo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Voting'],
        'textOverlayIds': [0],
        'gradientTextOverlayIds': [0],
      }),
    });
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final overlay = find.byType(AdvancedTextOverlay);
    expect(tester.widget<AdvancedTextOverlay>(overlay).shadow, isNull);
    await tester.tap(overlay);
    await tester.pumpAndSettle();

    Future<void> tapToolbar(String label) async {
      final button = find.descendant(
        of: find.byKey(const ValueKey('text-toolbar')),
        matching: find.text(label),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tapToolbar('Shadow');
    final toggle = find.byType(Switch);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final rendered = tester.widget<AdvancedTextOverlay>(overlay);
    expect(rendered.gradient, isTrue);
    expect(rendered.shadow?.offset, isNot(Offset.zero));
    await tapToolbar('Undo Text');
    expect(tester.widget<AdvancedTextOverlay>(overlay).shadow, isNull);
    expect(tester.takeException(), isNull);
  });
}
