import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
