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
    await voting_pro.main();
    await tester.pumpAndSettle();
    final toolbar = find.byKey(const PageStorageKey('main-toolbar'));
    final poster = find.byType(Screenshot);
    final tool = find.descendant(of: toolbar, matching: find.text('VS Styles'));
    final toolbarBounds = tester.getRect(toolbar);
    final posterBounds = tester.getRect(poster);

    await tester.ensureVisible(tool);
    await tester.tap(tool);
    await tester.pumpAndSettle();

    final panel = find.byType(VsStylesPanel);
    final grid = find.descendant(of: panel, matching: find.byType(Scrollable));
    final canvasVs = find.byKey(const ValueKey('poster-vs'));
    final vsBounds = tester.getRect(canvasVs);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.getRect(toolbar), toolbarBounds);
    expect(tester.getRect(poster), posterBounds);

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    for (final (style, screen) in const [
      ('Fire', 'vs-styles-fire'),
      ('Black & Gold', 'vs-styles-black-and-gold'),
    ]) {
      final card = find.byKey(ValueKey('vs-style-$style'));
      await tester.scrollUntilVisible(card, 72, scrollable: grid);
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
