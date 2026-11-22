import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart' as voting_pro;
import 'package:voting_pro/widgets/premium_text_editor_panel.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Text mode replaces the original toolbar on Android', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('voting_pro_project_v1');
    await voting_pro.main();
    await tester.pumpAndSettle();

    final main = find.byKey(const PageStorageKey('main-toolbar'));
    final text = find.byKey(const ValueKey('text-toolbar'));
    final tools = find.byKey(const ValueKey('text-tool-scroll'));
    final panel = find.byType(PremiumTextEditorPanel);
    final poster = find.byType(Screenshot);
    final bounds = tester.getRect(main);

    Finder action(Finder toolbar, String label) =>
        find.descendant(of: toolbar, matching: find.text(label));

    Future<void> tap(Finder target) async {
      if (target.hitTestable().evaluate().isEmpty) {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
      }
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      // Allow the Android surface to present the scrolled frame and clear
      // Flutter's transient test-pointer crosshair.
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await binding.takeScreenshot(name);
    }

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await capture('text-01-main');
    await tap(action(main, 'Text'));
    expect(main, findsNothing);
    expect(panel, findsNothing);
    expect(tester.getRect(text), bounds);
    final back = action(text, 'Back');
    final backBounds = tester.getRect(back);
    expect(backBounds.right, lessThanOrEqualTo(tester.getRect(tools).left));
    expect(action(text, 'More'), findsNothing);
    expect(action(text, 'Color Palette'), findsOneWidget);
    await capture('text-02-toolbar');

    await tap(action(text, 'Add Text'));
    await tester.enterText(find.byType(TextField), 'Vote  ووٹ  वोट');
    await tap(find.widgetWithText(FilledButton, 'Add'));

    for (final (label, section, file) in [
      ('Color', TextToolSection.color, 'text-03-color'),
      ('Glow', TextToolSection.glow, 'text-04-glow'),
      ('Style', TextToolSection.style, 'text-05-style'),
    ]) {
      await tap(action(text, label));
      expect(panel, findsOneWidget);
      expect(tester.widget<PremiumTextEditorPanel>(panel).section, section);
      expect(
        tester.getRect(panel).top,
        greaterThanOrEqualTo(tester.getRect(poster).bottom),
      );
      expect(tester.getRect(text), bounds);
      expect(tester.getRect(back), backBounds);
      await capture(file);
    }

    await tap(find.descendant(of: panel, matching: find.byTooltip('Close')));
    expect(panel, findsNothing);

    // The former More-only Color Palette now opens the existing color studio
    // directly from the SAME bottom Text toolbar, without another toolbar.
    await tap(action(text, 'Color Palette'));
    expect(panel, findsNothing);
    expect(find.text('Text Color Studio'), findsOneWidget);
    expect(tester.getRect(text), bounds);
    expect(tester.getRect(back), backBounds);
    await capture('text-06-direct-color-palette');
    await tap(find.byTooltip('Close'));
    expect(find.text('Text Color Studio'), findsNothing);

    await tap(action(text, 'Undo Text'));
    expect(find.text('Vote  ووٹ  वोट'), findsNothing);
    await tap(action(text, 'Redo Text'));
    expect(find.text('Vote  ووٹ  वोट'), findsOneWidget);
    await capture('text-06-history');

    final delete = action(text, 'Delete Text');
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    expect(tester.getRect(tools).contains(tester.getCenter(delete)), isTrue);
    expect(tester.getRect(back), backBounds);
    await capture('text-07-far-scroll');
    await tap(back);
    expect(text, findsNothing);
    expect(panel, findsNothing);
    expect(tester.getRect(main), bounds);
    await capture('text-08-back');
  });
}
