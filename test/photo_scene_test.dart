import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/widgets/photo_background_settings.dart';
import 'package:voting_pro/widgets/photo_scene.dart';

void main() {
  testWidgets('All twenty stable scene IDs paint in both portrait slots', (
    tester,
  ) async {
    expect(PhotoScene.byId.length, 20);
    for (final scene in PhotoScene.values) {
      expect(PhotoScene.byId[scene.id], scene);
      for (final side in [true, false]) {
        await tester.pumpWidget(
          Center(
            child: SizedBox(
              width: 88,
              height: 138,
              child: PhotoSceneArt(scene, sideA: side),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: scene.id);
      }
    }
  });

  testWidgets('Portrait card uses localized label and selects its scene', (
    tester,
  ) async {
    AppLanguage.current = 'ur';
    addTearDown(() => AppLanguage.current = 'en');
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 112,
              height: 124,
              child: PhotoSceneCard(
                scene: PhotoScene.pakistan,
                sideA: false,
                selected: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('پاکستان کی شان'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.byType(PhotoSceneCard));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
