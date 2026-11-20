import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';
import 'package:voting_pro/widgets/editor_options_panel.dart';

final _toolbar = find.byKey(const ValueKey('text-toolbar'));
final _panel = find.byType(EditorOptionsPanel);
final _overlay = find.byType(AdvancedTextOverlay);

Future<void> _tapToolbar(WidgetTester tester, String title) async {
  final control = find.descendant(
    of: _toolbar,
    matching: find.text(AppLanguage.tr(title)),
  );
  await tester.ensureVisible(control);
  await tester.tap(control);
  await tester.pumpAndSettle();
}

Future<void> _openSelectedText(WidgetTester tester, String text) async {
  SharedPreferences.setMockInitialValues({
    'voting_pro_project_v1': jsonEncode({
      'overlays': [text],
      'textOverlayIds': [0],
    }),
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const MaterialApp(home: Editor()));
  await tester.pumpAndSettle();
  final mainToolbar = find.byKey(const PageStorageKey('main-toolbar'));
  final textTool = find.descendant(
    of: mainToolbar,
    matching: find.text(AppLanguage.tr('Text')),
  );
  await tester.ensureVisible(textTool);
  await tester.tap(textTool);
  await tester.pumpAndSettle();
  await tester.tap(_overlay);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AppLanguage.current = 'en');
  tearDown(() => AppLanguage.current = 'en');

  testWidgets('Font, presets and colors share the fixed Text Toolbar slot', (
    tester,
  ) async {
    await _openSelectedText(tester, 'Voting');
    final toolbarBounds = tester.getRect(_toolbar);
    final back = find.descendant(of: _toolbar, matching: find.text('Back'));
    final backBounds = tester.getRect(back);
    AdvancedTextOverlay artwork() =>
        tester.widget<AdvancedTextOverlay>(_overlay);

    await _tapToolbar(tester, 'Font');
    final handwriting = find.descendant(
      of: _panel,
      matching: find.text('Handwriting'),
    );
    await tester.ensureVisible(handwriting);
    await tester.tap(handwriting);
    await tester.pumpAndSettle();
    expect(artwork().style.fontFamily, 'PacificoLocal');
    expect(tester.getRect(_toolbar), toolbarBounds);

    await _tapToolbar(tester, 'Text Presets');
    expect(_panel, findsOneWidget);
    await tester.tap(find.text('Headline'));
    await tester.pumpAndSettle();
    expect(artwork().style.fontWeight, FontWeight.w900);

    await _tapToolbar(tester, 'Color');
    expect(_panel, findsNothing);
    final moreColors = find.text('More colors');
    await tester.ensureVisible(moreColors);
    await tester.tap(moreColors);
    await tester.pumpAndSettle();
    expect(find.text('Text Color Studio'), findsOneWidget);
    final paletteGold = find.byTooltip('#FFD700');
    await tester.ensureVisible(paletteGold);
    await tester.tap(paletteGold);
    await tester.pumpAndSettle();
    expect(artwork().style.color, const Color(0xffffd700));
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.getRect(back), backBounds);
    expect(tester.getBottomLeft(_panel).dy, lessThan(toolbarBounds.top));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_panel, findsNothing);
    expect(_toolbar, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Urdu text retains its supported Urdu font', (tester) async {
    AppLanguage.current = 'ur';
    await _openSelectedText(tester, 'علی');
    await _tapToolbar(tester, 'Font');
    final urdu = find.descendant(
      of: _panel,
      matching: find.text('اردو نستعلیق'),
    );
    expect(urdu, findsOneWidget);
    await tester.tap(urdu);
    await tester.pumpAndSettle();
    final artwork = tester.widget<AdvancedTextOverlay>(_overlay);
    expect(artwork.style.fontFamily, 'NotoNastaliqUrdu');
    expect(artwork.direction, TextDirection.rtl);
  });
}
