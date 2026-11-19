import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';

void main() {
  testWidgets(
      'Poster capture produces the same PNG with text selected or deselected', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Vote — ووٹ'],
        'textOverlayIds': [0],
        'showVs': false,
        'textPositions': {
          '0': [70, 55],
        },
        'textColors': {'0': 0xFF00E5FF},
        'textGlowStrengths': {'0': 25.0},
      }),
    });
    tester.view.physicalSize = const Size(640, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    Future<Uint8List> save() async {
      final state = tester.state(find.byType(Editor)) as dynamic;
      final result = await tester.runAsync(() async {
        final capture =
            state.capturePosterWithoutControls() as Future<Uint8List?>;
        await tester.pump();
        return capture.timeout(const Duration(seconds: 8));
      });
      await tester.pumpAndSettle();
      return result!;
    }

    final plain = await save();
    expect(plain.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.tap(find.text('Vote — ووٹ'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsOneWidget);
    final selected = await save();
    expect(selected, orderedEquals(plain));
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
