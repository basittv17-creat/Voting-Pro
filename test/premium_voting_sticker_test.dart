import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/premium_voting_sticker.dart';

void main() {
  test('all old voting PNG IDs migrate to persistent vector IDs', () {
    const legacy = [
      '01_lion.png',
      '02_cheetah.png',
      '03_tiger.png',
      '04_elephant.png',
      '05_eagle.png',
      '06_wolf.png',
      '07_panther.png',
      '08_bear.png',
      '09_cobra.png',
      '10_crossed_swords.png',
    ];
    expect(VotingStickerCatalog.designs.length, 16);
    for (var i = 0; i < legacy.length; i++) {
      expect(
        VotingStickerCatalog.migrate('assets/voting_stickers/' + legacy[i]),
        VotingStickerCatalog.designs[i].id,
      );
    }
    expect(VotingStickerCatalog.migrate(null), isNull);
    expect(VotingStickerCatalog.migrate('assets/other.png'), isNull);
  });

  testWidgets('A/B sticker selection and replacement are independent', (
    tester,
  ) async {
    AppLanguage.current = 'en';
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final tool = find.text('Voting Sticker');
    await tester.ensureVisible(tool);
    await tester.tap(tool);
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(Editor)) as dynamic;
    final lion = find.byKey(
      const ValueKey('voting-sticker-choice-vector:lion'),
    );
    await tester.ensureVisible(lion);
    await tester.tap(lion);
    await tester.pumpAndSettle();
    expect(state.leftVotingSticker, 'vector:lion');
    expect(state.rightVotingSticker, isNull);

    await tester.tap(find.byKey(const ValueKey('voting-sticker-side-B')));
    await tester.pumpAndSettle();
    final tiger = find.byKey(
      const ValueKey('voting-sticker-choice-vector:tiger'),
    );
    await tester.ensureVisible(tiger);
    await tester.tap(tiger);
    await tester.pumpAndSettle();
    expect(state.leftVotingSticker, 'vector:lion');
    expect(state.rightVotingSticker, 'vector:tiger');

    await tester.tap(find.byKey(const ValueKey('remove-voting-sticker')));
    await tester.pumpAndSettle();
    expect(state.leftVotingSticker, 'vector:lion');
    expect(state.rightVotingSticker, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('previously saved PNG stickers render as vector badges', (
    tester,
  ) async {
    AppLanguage.current = 'en';
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'leftVotingSticker': 'assets/voting_stickers/01_lion.png',
        'rightVotingSticker': 'assets/voting_stickers/05_eagle.png',
      }),
    });
    tester.view.physicalSize = const Size(393, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(Editor)) as dynamic;
    expect(state.leftVotingSticker, 'vector:lion');
    expect(state.rightVotingSticker, 'vector:eagle');
    expect(find.byKey(const ValueKey('voting-sticker-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('voting-sticker-B')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
