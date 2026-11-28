import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:voting_pro/main.dart' as voting_pro;
import 'package:voting_pro/widgets/premium_vs.dart';
import 'package:voting_pro/widgets/vs_styles_panel.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('VS previews and poster agree on Android', (tester) async {
    tester.view.physicalSize = const Size(590, 1278);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await voting_pro.main();
    await tester.pumpAndSettle();
    // Android starts with a surface-backed Flutter view whose test geometry
    // is zero until it is converted for integration screenshots. Convert
    // before reading bounds or tapping the toolbar, as the other Android
    // integration suites already do.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    final toolbar = find.byKey(const PageStorageKey('main-toolbar'));
    final poster = find.byType(Screenshot);
    final toolLabel = find.descendant(
      of: toolbar,
      matching: find.text('VS Styles'),
    );
    final tool = find.ancestor(
      of: toolLabel,
      matching: find.byType(InkWell),
    );
    expect(tool, findsOneWidget);
    final toolbarBounds = tester.getRect(toolbar);
    final posterBounds = tester.getRect(poster);

    await tester.ensureVisible(tool);
    await tester.pumpAndSettle();
    await tester.tap(tool);
    await tester.pumpAndSettle();

    final panel = find.byType(VsStylesPanel);
    expect(panel, findsOneWidget);
    final grid = find.descendant(of: panel, matching: find.byType(Scrollable));
    expect(grid, findsOneWidget);
    final canvasVs = find.byKey(const ValueKey('poster-vs'));
    final vsBounds = tester.getRect(canvasVs);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.getRect(toolbar), toolbarBounds);
    expect(tester.getRect(poster), posterBounds);

    for (final (style, screen) in const [
      ('Fire', 'vs-styles-fire'),
      ('Black & Gold', 'vs-styles-black-and-gold'),
    ]) {
      final card = find.byKey(ValueKey('vs-style-$style'));
      await tester.scrollUntilVisible(card, 72, scrollable: grid);
      // A lazily built grid child can exist while its center remains beneath
      // the fixed toolbar. Align it inside the grid before sending a tap.
      await Scrollable.ensureVisible(
        tester.element(card),
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(grid).contains(tester.getCenter(card)), isTrue);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(tester.widget<PremiumVsRenderer>(canvasVs).style.name, style);
      expect(tester.getRect(canvasVs), vsBounds);
      await binding.takeScreenshot(screen);
    }

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    expect(tester.getRect(toolbar), toolbarBounds);
  });
}
