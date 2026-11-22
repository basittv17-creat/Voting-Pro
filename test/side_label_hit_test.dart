import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';

void main() {
  testWidgets('A/B side name taps outrank overlapping letter and sticker', (
    tester,
  ) async {
    AppLanguage.current = 'en';
    addTearDown(() => AppLanguage.current = 'en');
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'aSideLabelText': 'A SIDE',
        'bSideLabelText': 'B SIDE',
        'selectedASideLabel':
            'assets/label_bars/a_side/A_Side_Style_1.png',
        'selectedBSideLabel':
            'assets/label_bars/b_side/B_Side_Style_1.png',
        'letterOverlays': [
          {
            'asset': 'assets/a_letter_styles/A_Style_01.png',
            'sideA': true,
            'position': [100, 390],
            'scale': 1.0,
          },
        ],
        'tagraStickerOverlays': [
          {
            'asset':
                'assets/tagra_muqabla_stickers/Tagra_Muqabla_01_Royal_Gold.png',
            'position': [390, 380],
            'scale': 1.0,
          },
        ],
        'showVs': false,
      }),
    });
    tester.view.physicalSize = const Size(688, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final editor = tester.state(find.byType(Editor)) as dynamic;
    final a = find.byKey(const ValueKey('a-side-label-hit-target'));
    final b = find.byKey(const ValueKey('b-side-label-hit-target'));
    expect(a, findsOneWidget);
    expect(b, findsOneWidget);
    expect(editor.letterOverlays, hasLength(1));
    expect(editor.tagraStickerOverlays, hasLength(1));

    await tester.tap(a);
    await tester.pumpAndSettle();
    expect(find.text('Edit A Side Name'), findsOneWidget);
    expect(find.text('Edit B Side Name'), findsNothing);
    expect(editor.selectedLetterOverlayIndex, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(b);
    await tester.pumpAndSettle();
    expect(find.text('Edit B Side Name'), findsOneWidget);
    expect(find.text('Edit A Side Name'), findsNothing);
    expect(editor.selectedTagraStickerIndex, isNull);
    expect(editor.letterOverlays, hasLength(1));
    expect(editor.tagraStickerOverlays, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Classic side labels remain editable without style images', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.current = 'en';
    tester.view.physicalSize = const Size(688, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('b-side-label-hit-target')));
    await tester.pumpAndSettle();
    expect(find.text('Edit B Side Name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
