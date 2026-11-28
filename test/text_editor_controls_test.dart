import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';
import 'package:voting_pro/widgets/premium_text_editor_panel.dart';
import 'package:voting_pro/widgets/scaled_overlay.dart';

void main() {
  testWidgets(
    'Style and Layout actions update only the selected text',
    (tester) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Voting Pro'],
        'textOverlayIds': [0],
        'textPositions': {
          '0': [25, 30],
        },
      }),
    });
    tester.view.physicalSize = const Size(560, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final overlay = find.byType(AdvancedTextOverlay);
    await tester.tap(find.text('Voting Pro'));
    await tester.pumpAndSettle();

    final mainToolbar = find.byKey(const PageStorageKey('main-toolbar'));
    final textMode = find.descendant(
      of: mainToolbar,
      matching: find.text('Text'),
    );
    await tester.ensureVisible(textMode);
    await tester.tap(textMode);
    await tester.pumpAndSettle();

    final toolbar = find.byKey(const ValueKey('text-toolbar'));
    Future<void> toolbarAction(String label) async {
      final target = find.descendant(
        of: toolbar,
        matching: find.text(label),
      );
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await toolbarAction('Style');
    final panel = find.byType(PremiumTextEditorPanel);
    expect(
      tester.widget<PremiumTextEditorPanel>(panel).section,
      TextToolSection.style,
    );

    Future<void> styleAction(String label) async {
      final target = find.descendant(
        of: panel,
        matching: find.text(label),
      );
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await styleAction('Bold');
    expect(
      tester.widget<AdvancedTextOverlay>(overlay).style.fontWeight,
      FontWeight.w900,
    );
    await styleAction('Italic');
    expect(
      tester.widget<AdvancedTextOverlay>(overlay).style.fontStyle,
      FontStyle.italic,
    );
    await styleAction('Underline');
    expect(
      tester
          .widget<AdvancedTextOverlay>(overlay)
          .style
          .decoration!
          .contains(TextDecoration.underline),
      isTrue,
    );
    await styleAction('Strike');
    expect(
      tester
          .widget<AdvancedTextOverlay>(overlay)
          .style
          .decoration!
          .contains(TextDecoration.lineThrough),
      isTrue,
    );

    final scaled = find.byType(ScaledOverlay);
    await styleAction('Zoom +');
    expect(tester.widget<ScaledOverlay>(scaled).scale, closeTo(1.2, 0.001));
    await styleAction('Reset Style');
    expect(tester.widget<ScaledOverlay>(scaled).scale, 1.0);
    final reset = tester.widget<AdvancedTextOverlay>(overlay);
    expect(reset.text, 'Voting Pro');
    expect(reset.style.fontWeight, FontWeight.normal);
    expect(reset.style.fontStyle, FontStyle.normal);
    expect(reset.style.decoration, TextDecoration.none);

    await toolbarAction('Layout');
    expect(
      tester.widget<PremiumTextEditorPanel>(panel).section,
      TextToolSection.layout,
    );
    Future<void> layoutAction(String label) async {
      final target = find.descendant(
        of: panel,
        matching: find.text(label),
      );
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await layoutAction('Alignment');
    expect(
      tester.widget<AdvancedTextOverlay>(overlay).alignment,
      TextAlign.left,
    );
    await layoutAction('Line Height +');
    expect(
      tester.widget<AdvancedTextOverlay>(overlay).style.height,
      closeTo(1.3, 0.001),
    );
    await layoutAction('Letter Space +');
    expect(
      tester.widget<AdvancedTextOverlay>(overlay).style.letterSpacing,
      closeTo(0.5, 0.001),
    );
    await layoutAction('Curve Up');
    expect(
      tester.widget<AdvancedTextOverlay>(overlay).curve,
      closeTo(0.2, 0.001),
    );

    await layoutAction('Duplicate');
    expect(find.byType(AdvancedTextOverlay), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
