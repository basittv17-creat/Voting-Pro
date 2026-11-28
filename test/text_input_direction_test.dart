import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';

void main() {
  tearDown(() => AppLanguage.current = 'en');

  testWidgets('Add Text follows the typed script in an Urdu interface', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.current = 'ur';
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final textMode = find.text(AppLanguage.tr('Text'));
    await tester.ensureVisible(textMode);
    await tester.tap(textMode);
    await tester.pumpAndSettle();

    final addText = find.text(AppLanguage.tr('Add Text'));
    await tester.ensureVisible(addText);
    await tester.tap(addText);
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    TextField input() => tester.widget<TextField>(field);

    expect(input().textDirection, TextDirection.rtl);
    expect(input().textAlign, TextAlign.right);

    await tester.enterText(field, 'Voting Pro');
    await tester.pumpAndSettle();
    expect(input().textDirection, TextDirection.ltr);
    expect(input().textAlign, TextAlign.left);

    await tester.enterText(field, 'वोटिंग प्रो');
    await tester.pumpAndSettle();
    expect(input().textDirection, TextDirection.ltr);
    expect(input().textAlign, TextAlign.left);

    await tester.enterText(field, 'ووٹنگ پرو');
    await tester.pumpAndSettle();
    expect(input().textDirection, TextDirection.rtl);
    expect(input().textAlign, TextAlign.right);

    await tester.tap(
      find.widgetWithText(FilledButton, AppLanguage.tr('Add')),
    );
    await tester.pumpAndSettle();

    final overlay = tester.widget<AdvancedTextOverlay>(
      find.byType(AdvancedTextOverlay),
    );
    expect(overlay.text, 'ووٹنگ پرو');
    expect(overlay.direction, TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit Text changes direction as the replacement text changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Voting Pro'],
        'textOverlayIds': [0],
        'textPositions': {
          '0': [30, 35],
        },
      }),
    });
    AppLanguage.current = 'ur';
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final selectedOverlay = find.byKey(const ValueKey('text-overlay-0'));
    expect(selectedOverlay, findsOneWidget);
    final renderedText = find.descendant(
      of: selectedOverlay,
      matching: find.byType(AdvancedTextOverlay),
    );
    expect(renderedText, findsOneWidget);
    await tester.ensureVisible(renderedText);
    await tester.tap(renderedText);
    await tester.pumpAndSettle();

    final textMode = find.text(AppLanguage.tr('Text'));
    await tester.ensureVisible(textMode);
    await tester.tap(textMode);
    await tester.pumpAndSettle();

    final editText = find.text(AppLanguage.tr('Edit Text'));
    await tester.ensureVisible(editText);
    await tester.tap(editText);
    await tester.pumpAndSettle();

    final field = find.byType(TextFormField);
    final editable = find.byType(EditableText);
    EditableText input() => tester.widget<EditableText>(editable);

    expect(input().textDirection, TextDirection.ltr);
    expect(input().textAlign, TextAlign.left);

    await tester.enterText(field, 'ووٹنگ پرو');
    await tester.pumpAndSettle();
    expect(input().textDirection, TextDirection.rtl);
    expect(input().textAlign, TextAlign.right);

    await tester.enterText(field, 'Voting Pro');
    await tester.pumpAndSettle();
    expect(input().textDirection, TextDirection.ltr);
    expect(input().textAlign, TextAlign.left);

    await tester.enterText(field, 'ووٹنگ پرو');
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, AppLanguage.tr('Save')),
    );
    await tester.pumpAndSettle();

    final overlay = tester.widget<AdvancedTextOverlay>(
      find.byType(AdvancedTextOverlay),
    );
    expect(overlay.text, 'ووٹنگ پرو');
    expect(overlay.direction, TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
