import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';
import 'package:voting_pro/widgets/scaled_overlay.dart';
import 'package:voting_pro/widgets/text_background_plate.dart';

void main() {
  test('Artwork can touch all four canvas edges', () {
    const canvas = Size(300, 200);
    const child = Size(130, 80);
    const inset = 15.0;
    expect(
      const TextCanvasPlacement(Offset(-999, -999), inset)
          .getPositionForChild(canvas, child),
      const Offset(-15, -15),
    );
    expect(
      const TextCanvasPlacement(Offset(999, 999), inset)
          .getPositionForChild(canvas, child),
      const Offset(185, 135),
    );
  });

  testWidgets('Drag text to both vertical edges and keep handles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Voting test'],
        'textOverlayIds': [0],
        'textPositions': {
          '0': [45, 65],
        },
      }),
    });
    tester.view.physicalSize = const Size(393, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    final artwork = find.byType(AdvancedTextOverlay);
    await tester.tap(artwork);
    await tester.pumpAndSettle();
    final layer = find.byKey(const ValueKey('text-overlay-0'));
    final scaled = find.descendant(
      of: layer,
      matching: find.byType(ScaledOverlay),
    );
    final canvas = tester.getRect(layer);
    Future<void> move(Offset delta) async {
      final gesture = await tester.startGesture(tester.getCenter(artwork));
      for (var step = 0; step < 15; step++) {
        await gesture.moveBy(delta / 15);
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    void handlesInside() {
      for (final icon in [Icons.edit, Icons.delete, Icons.open_in_full]) {
        final handle = find.descendant(of: layer, matching: find.byIcon(icon));
        expect(handle, findsOneWidget);
        final rect = tester.getRect(handle);
        expect(rect.top, greaterThanOrEqualTo(canvas.top - 0.1));
        expect(rect.bottom, lessThanOrEqualTo(canvas.bottom + 0.1));
      }
    }

    await move(Offset(0, -canvas.height * 2));
    expect(tester.getRect(scaled).top, closeTo(canvas.top, 0.5));
    handlesInside();
    await move(Offset(0, canvas.height * 2));
    expect(tester.getRect(scaled).bottom, closeTo(canvas.bottom, 0.5));
    handlesInside();

    await move(Offset(-canvas.width * 2, 0));
    expect(tester.getRect(scaled).left, closeTo(canvas.left, 0.5));
    handlesInside();

    await move(Offset(canvas.width * 2, 0));
    expect(tester.getRect(scaled).right, closeTo(canvas.right, 0.5));
    handlesInside();
    expect(tester.takeException(), isNull);
  });
}
