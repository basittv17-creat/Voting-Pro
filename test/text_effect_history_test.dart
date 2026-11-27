import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';
import 'package:voting_pro/widgets/premium_text_editor_panel.dart';

void main() {
  testWidgets('Independent text effects survive Undo, Redo, and reopening', (
    tester,
  ) async {
    const projectKey = 'voting_pro_project_v1';
    const target = 'میرے ووٹ — My vote';
    const other = 'Other text';
    SharedPreferences.setMockInitialValues({
      projectKey: jsonEncode({
        'overlays': [target, other],
        'textOverlayIds': [0, 1],
        'textPositions': {
          '0': [25, 40],
          '1': [25, 120],
        },
      }),
    });
    tester.view.physicalSize = const Size(560, 930);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap(find.text(target));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tap(find.text('Text'));
    final toolbar = find.byKey(const ValueKey('text-toolbar'));
    final panel = find.byType(PremiumTextEditorPanel);
    Future<void> action(String label) => tap(
          find.descendant(of: toolbar, matching: find.text(label)),
        );

    Future<void> toggle(String section) async {
      await action(section);
      await tap(find.descendant(of: panel, matching: find.byType(Switch)));
    }

    AdvancedTextOverlay overlay(String text) =>
        tester.widget<AdvancedTextOverlay>(
          find.byWidgetPredicate(
            (widget) => widget is AdvancedTextOverlay && widget.text == text,
          ),
        );

    await toggle('Glow');
    await toggle('Shadow');
    await toggle('Outline');
    await toggle('Gradient');
    await action('Text Background');
    final dock = find.byKey(const ValueKey('text-background-dock'));
    await tap(
      find.descendant(of: dock, matching: find.byType(Switch)).first,
    );
    final backgroundToolbar = find.byKey(
      const ValueKey('text-background-toolbar'),
    );
    await tap(
      find.descendant(of: backgroundToolbar, matching: find.text('Back')),
    );

    void expectEffects(AdvancedTextOverlay text, bool enabled) {
      expect(text.style.shadows?.isNotEmpty ?? false, enabled);
      expect(text.shadow != null, enabled);
      expect(text.outlineWidth > 0, enabled);
      expect(text.gradient, enabled);
      expect(text.backgroundColor != null, enabled);
    }

    expectEffects(overlay(target), true);
    expectEffects(overlay(other), false);
    for (var i = 0; i < 5; i++) {
      await action('Undo Text');
    }
    expectEffects(overlay(target), false);
    for (var i = 0; i < 5; i++) {
      await action('Redo Text');
    }
    expectEffects(overlay(target), true);
    expectEffects(overlay(other), false);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    expectEffects(overlay(target), true);
    expectEffects(overlay(other), false);
    expect(tester.takeException(), isNull);
  });
}
