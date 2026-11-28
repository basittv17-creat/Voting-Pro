import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/photo_background_settings.dart';
import 'package:voting_pro/widgets/photo_scene.dart';

const _projectKey = 'voting_pro_project_v1';

File _transparentPhoto(Directory directory, String name, int red) {
  final image = img.Image(width: 48, height: 64, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = red
      ..g = 120
      ..b = 210
      ..a = pixel.x < 24 ? 0 : 255;
  }
  final file = File('${directory.path}/$name.png');
  file.writeAsBytesSync(img.encodePng(image));
  return file;
}

void main() {
  setUp(() => AppLanguage.current = 'en');
  tearDown(() => AppLanguage.current = 'en');

  testWidgets(
      'Ready-made templates open independent A/B background panels after cutout',
      (
    tester,
  ) async {
    final directory =
        Directory.systemTemp.createTempSync('voting-template-bg-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final photoA = _transparentPhoto(directory, 'photo-a', 220);
    final photoB = _transparentPhoto(directory, 'photo-b', 40);

    SharedPreferences.setMockInitialValues({
      _projectKey: jsonEncode({
        'imageA': photoA.path,
        'imageB': photoB.path,
        'selectedReadyMadeTemplate': 'royal_a_vs_b_battle',
      }),
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A BG'));
    await tester.pump();
    expect(find.text('Backgrounds — A Side'), findsOneWidget);
    expect(find.byType(PhotoBackgroundSettings), findsOneWidget);

    await tester.tap(find.text('B BG'));
    await tester.pump();
    expect(find.text('Backgrounds — B Side'), findsOneWidget);
    expect(find.byType(PhotoBackgroundSettings), findsOneWidget);

    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Backgrounds — B Side'), findsNothing);
    expect(find.byType(PhotoBackgroundSettings), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Every ready-made template renders selected photo backgrounds under both photos',
      (
    tester,
  ) async {
    final directory =
        Directory.systemTemp.createTempSync('voting-template-art-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final photoA = _transparentPhoto(directory, 'photo-a', 220);
    final photoB = _transparentPhoto(directory, 'photo-b', 40);
    const templates = [
      'royal_a_vs_b_battle',
      'tagra_muqabla',
      'neon_purple_showdown',
      'metallic_vs_battle',
      'royal_blue_pink',
      'classic_crown',
      'neon_battle',
      'red_gold_arena',
      'blue_gold_classic',
      'tagra_royal_thunder',
      'tagra_emerald_fire',
    ];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final template in templates) {
      SharedPreferences.setMockInitialValues({
        _projectKey: jsonEncode({
          'imageA': photoA.path,
          'imageB': photoB.path,
          'selectedReadyMadeTemplate': template,
          'photoBackgrounds': {'a': 'scene-arena', 'b': 'scene-cage'},
        }),
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: Editor()));
      await tester.pumpAndSettle();

      for (final side in ['A', 'B']) {
        final background =
            find.byKey(ValueKey('template-photo-background-$side'));
        expect(background, findsOneWidget, reason: template);
        expect(
          find.descendant(
            of: background,
            matching: find.byType(PhotoSceneArt),
          ),
          findsOneWidget,
          reason: '$template side $side',
        );
      }
      expect(tester.takeException(), isNull, reason: template);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
