import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/widgets/tagra_arena.dart';

void main() {
  for (final theme in TagraArena.values) {
    testWidgets('${theme.id} routes both name and photo taps at phone widths', (
      tester,
    ) async {
      final photos = <bool>[], names = <bool>[];
      const longName = 'محمد عبدالرحمن شاہد محمود';
      for (final width in [320.0, 360.0, 393.0, 412.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: width,
                height: width * .75,
                child: TagraArenaPoster(
                  arena: theme,
                  urdu: true,
                  nameA: longName,
                  onPick: photos.add,
                  onName: names.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final side in ['A', 'B']) {
          await tester.tap(find.byKey(ValueKey('arena-photo-$side')));
          await tester.tap(find.byKey(ValueKey('arena-name-$side')));
        }
        expect(photos, [true, false]);
        expect(names, [true, false]);
        photos.clear();
        names.clear();
        expect(find.text(longName), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: TagraArenaPoster(
            arena: theme,
            urdu: true,
            exporting: true,
            onName: names.add,
            onPick: photos.add,
          ),
        ),
      );
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
      expect(find.text('نام لکھیں'), findsNothing);
    });
  }
}
