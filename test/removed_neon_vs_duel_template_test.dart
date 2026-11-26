import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';

void main() {
  test('Only Neon VS Duel is excluded from ready-made templates', () {
    final editor = File('lib/main.dart').readAsStringSync();

    expect(editor, isNot(contains("key: 'neon_vs_duel'")));
    expect(editor, isNot(contains('Neon_VS_Duel_Template.png')));
    expect(editor, contains("key: 'royal_a_vs_b_battle'"));
    expect(editor, contains("key: 'tagra_muqabla'"));
    expect(editor, contains("key: 'neon_purple_showdown'"));
    expect(editor, contains("key: 'metallic_vs_battle'"));

    expect(
      File('assets/templates/Neon_VS_Duel_Template.png').existsSync(),
      isFalse,
    );
    expect(
      File('lib/widgets/neon_vs_duel_template.dart').existsSync(),
      isFalse,
    );
    expect(
      File('assets/templates/Neon_Purple_VS_Template.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/templates/Metallic_VS_Battle_Template.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/templates/Tagra_Muqabla_Template.png').existsSync(),
      isTrue,
    );
  });

  testWidgets('A removed template restores the classic canvas and saved text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'selectedReadyMadeTemplate': 'neon_vs_duel',
        'overlays': ['میرے ووٹ — My vote'],
        'textOverlayIds': [0],
        'textPositions': {
          '0': [20, 25],
        },
      }),
    });

    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('main-toolbar')), findsOneWidget);
    expect(find.text('میرے ووٹ — My vote'), findsOneWidget);
    expect(find.text('Classic Editor'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'All eleven available templates can be selected from the gallery',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: Editor()));
      await tester.pumpAndSettle();

      const templates = {
        'Royal Battle': true,
        'Tagra Muqabla': true,
        'Neon Purple VS': true,
        'Metallic VS Battle': true,
        'Royal Blue': false,
        'Gold Crown': false,
        'Neon Battle': false,
        'Red & Gold': false,
        'Blue & Gold': false,
        'Tagra Muqabla — Royal Thunder': true,
        'Tagra Muqabla — Emerald Fire': true,
      };
      var dedicatedArtwork = false;
      for (final entry in templates.entries) {
        final gallery = find.text(
          dedicatedArtwork ? 'Templates' : 'Ready-made Templates',
        );
        await tester.ensureVisible(gallery);
        await tester.tap(gallery);
        await tester.pumpAndSettle();

        final list = find.byType(GridView);
        expect(
          tester.widget<GridView>(list).childrenDelegate.estimatedChildCount,
          11,
        );
        final item = find.descendant(of: list, matching: find.text(entry.key));
        final scrollable = find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(item, 100, scrollable: scrollable);
        await Scrollable.ensureVisible(tester.element(item), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(item);
        await tester.pumpAndSettle();
        expect(list, findsNothing);
        dedicatedArtwork = entry.value;
        expect(
          find.text('Classic Editor'),
          dedicatedArtwork ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const PageStorageKey('main-toolbar')),
          dedicatedArtwork ? findsNothing : findsOneWidget,
        );
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .removeCurrentSnackBar();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
