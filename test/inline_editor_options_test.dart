import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/editor_options_panel.dart';

final _toolbar = find.byKey(const PageStorageKey('main-toolbar'));
final _panel = find.byType(EditorOptionsPanel);

Future<void> _tapTool(WidgetTester tester, String title) async {
  final action = find.descendant(
    of: _toolbar,
    matching: find.text(AppLanguage.tr(title)),
  );
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppLanguage.current = 'en';
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Main tool options share one panel at 320 dp', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final toolbarBounds = tester.getRect(_toolbar);
    final posterBounds = tester.getRect(find.byType(Screenshot));

    for (final (tool, title) in const [
      ('VS Styles', 'VS Styles'),
      ('A Style', 'A Style'),
      ('B Style', 'B Style'),
      ('A Side Label', 'A Side Label'),
      ('B Side Label', 'B Side Label'),
      ('3D Backgrounds', 'Background'),
      ('Stickers', 'Stickers'),
      ('Frame', 'Frame'),
      ('Emoji', 'Emoji'),
      ('Canvas', 'Canvas'),
      ('Voting Sticker', 'Voting Sticker'),
      ('Stylish Frames', 'Stylish Frames'),
      ('تگڑا مقابلہ اسٹیکرز', 'تگڑا مقابلہ اسٹیکرز'),
      ('Ready-made Templates', 'Ready-made Templates'),
    ]) {
      await _tapTool(tester, tool);
      expect(_panel, findsOneWidget);
      expect(
        find.descendant(of: _panel, matching: find.text(title)),
        findsOneWidget,
      );
      expect(tester.getRect(_toolbar), toolbarBounds);
      expect(tester.getRect(find.byType(Screenshot)), posterBounds);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.getBottomLeft(_panel).dy, lessThan(toolbarBounds.top));
      expect(tester.takeException(), isNull);
    }

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_panel, findsNothing);
    expect(tester.getRect(_toolbar), toolbarBounds);
  });

  testWidgets('Template grid exposes all nine choices and selects Royal Battle',
      (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    await _tapTool(tester, 'Ready-made Templates');
    final grid = tester.widget<GridView>(
      find.descendant(of: _panel, matching: find.byType(GridView)),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 9);
    await tester.tap(find.text('Royal Battle'));
    await tester.pumpAndSettle();
    expect(_panel, findsNothing);
    expect(find.text('Classic Editor'), findsOneWidget);
    expect(find.byType(Screenshot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Canvas choices and emoji update the poster immediately', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await _tapTool(tester, 'Canvas');
    final banner = find.text('Banner 2:1');
    await tester.ensureVisible(banner);
    await tester.tap(banner);
    await tester.pumpAndSettle();
    final poster = find.byType(Screenshot);
    final size = tester.getSize(poster);
    expect(size.width / size.height, closeTo(2, 0.001));
    await _tapTool(tester, 'Emoji');
    await tester.tap(find.byTooltip('⭐'));
    await tester.pumpAndSettle();
    expect(
        find.descendant(of: poster, matching: find.text('⭐')), findsOneWidget);
    expect(_panel, findsOneWidget);
  });
}
