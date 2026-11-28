import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';

void main() {
  tearDown(() => AppLanguage.current = 'en');

  testWidgets('Built-in font persists after reopen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Voting Pro'],
        'textOverlayIds': [0],
        'textPositions': {
          '0': [25, 30],
        },
      }),
    });
    AppLanguage.current = 'en';
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final overlay = find.byWidgetPredicate(
      (widget) =>
          widget is AdvancedTextOverlay && widget.text == 'Voting Pro',
    );
    await tester.tap(overlay);
    await tester.pumpAndSettle();

    final textMode = find.text('Text');
    await tester.ensureVisible(textMode);
    await tester.tap(textMode);
    await tester.pumpAndSettle();

    final font = find.text('Font');
    await tester.ensureVisible(font);
    await tester.tap(font);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elegant'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AdvancedTextOverlay>(overlay).style.fontFamily,
      'PlayfairDisplayLocal',
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(
      preferences.getString('voting_pro_project_v1')!,
    ) as Map<String, dynamic>;
    expect(
      (saved['textFonts'] as Map<String, dynamic>)['0'],
      'PlayfairDisplayLocal',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final restored = tester.widget<AdvancedTextOverlay>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AdvancedTextOverlay && widget.text == 'Voting Pro',
      ),
    );
    expect(restored.style.fontFamily, 'PlayfairDisplayLocal');
    expect(tester.takeException(), isNull);
  });
}
