import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/premium_vs.dart';
import 'package:voting_pro/widgets/vs_styles_panel.dart';

const _projectKey = 'voting_pro_project_v1';
final _toolbar = find.byKey(const PageStorageKey('main-toolbar'));
final _posterVs = find.byKey(const ValueKey('poster-vs'));
final _panel = find.byType(VsStylesPanel);

Future<void> _tapTool(WidgetTester tester, String title) async {
  final tool = find.descendant(
    of: _toolbar,
    matching: find.text(AppLanguage.tr(title)),
  );
  await tester.ensureVisible(tool);
  await tester.tap(tool);
  await tester.pumpAndSettle();
}

Future<void> _chooseStyle(WidgetTester tester, VsStyleDefinition style) async {
  final card = find.byKey(ValueKey('vs-style-${style.name}'));
  final grid = find.descendant(of: _panel, matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(card, 70, scrollable: grid);
  final preview = find.descendant(
    of: card,
    matching: find.byType(PremiumVsRenderer),
  );
  final previewRenderer = tester.widget<PremiumVsRenderer>(preview);
  await tester.tap(card);
  await tester.pumpAndSettle();
  final posterRenderer = tester.widget<PremiumVsRenderer>(_posterVs);
  expect(posterRenderer.style, same(style));
  expect(posterRenderer.style, same(previewRenderer.style));
  expect(posterRenderer.width, previewRenderer.width);
}

void main() {
  setUp(() {
    AppLanguage.current = 'en';
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => AppLanguage.current = 'en');

  for (final size in const [
    Size(320, 640),
    Size(360, 760),
    Size(393, 820),
    Size(412, 860),
    Size(800, 1024),
    Size(640, 360),
  ]) {
    testWidgets('VS panel stays in the editor at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const MaterialApp(home: Editor()));
      await tester.pumpAndSettle();
      final toolbar = tester.getRect(_toolbar);
      final poster = find.byType(Screenshot);
      final initialPoster = tester.getRect(poster);
      final initialBarriers = find.byType(ModalBarrier).evaluate().length;
      for (var repeat = 0; repeat < 2; repeat++) {
        await _tapTool(tester, 'VS Styles');
        expect(_panel, findsOneWidget);
        expect(find.byType(ModalBarrier), findsNWidgets(initialBarriers));
        expect(find.byType(BottomSheet), findsNothing);
        expect(tester.getRect(_toolbar), toolbar);
        expect(tester.getBottomLeft(_panel).dy, lessThan(toolbar.top));
        expect(tester.getRect(poster), initialPoster);
        final close = find.byTooltip(AppLanguage.tr('Close'));
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(_panel, findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Every preview selects the shared poster artwork', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _projectKey: jsonEncode({
        'vsStyle': 'Fire',
        'showVs': true,
        'vsOffset': [18.0, -10.0],
        'vsScale': 1.35,
      }),
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final bounds = tester.getRect(_posterVs);
    await _tapTool(tester, 'VS Styles');
    for (final style in VsStyleDefinition.styles) {
      await _chooseStyle(tester, style);
      expect(tester.getRect(_posterVs), bounds);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_panel, findsNothing);
    await _tapTool(tester, 'VS Styles');
    await _tapTool(tester, 'Frame');
    expect(_panel, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('VS drag, pinch and style survive project restoration', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final initial = tester.getRect(_posterVs);
    await tester.drag(_posterVs, const Offset(42, 0));
    await tester.pumpAndSettle();
    final dragged = tester.getRect(_posterVs);
    expect(dragged.center.dx, greaterThan(initial.center.dx));

    final center = dragged.center;
    final left = await tester.startGesture(center - const Offset(11, 0));
    final right = await tester.startGesture(center + const Offset(11, 0));
    await left.moveBy(const Offset(-22, 0));
    await right.moveBy(const Offset(31, 0));
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    final transformed = tester.getRect(_posterVs);
    expect(transformed.width, greaterThan(initial.width));
    expect(transformed.width, lessThanOrEqualTo(initial.width * 3 + 0.01));

    await _tapTool(tester, 'VS Styles');
    final style = VsStyleDefinition.styles.firstWhere((s) => s.name == 'Fire');
    await _chooseStyle(tester, style);
    expect(tester.getRect(_posterVs), transformed);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(_projectKey)!) as Map;
    expect(saved['vsStyle'], 'Fire');
    expect(saved['vsScale'], closeTo(transformed.width / initial.width, 0.001));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    expect(tester.getRect(_posterVs), transformed);
    expect(tester.widget<PremiumVsRenderer>(_posterVs).style, same(style));

    await tester.tap(_posterVs);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-poster-vs')));
    await tester.pumpAndSettle();
    expect(_posterVs, findsNothing);
    await _tapTool(tester, 'VS Styles');
    await _chooseStyle(tester, style);
    expect(tester.getRect(_posterVs), initial);
  });

  testWidgets('Export includes the chosen artwork without selection controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final dynamic state = tester.state(find.byType(Editor));
    Future<Uint8List> capture() async {
      final png = await tester.runAsync(() async {
        final capture =
            state.capturePosterWithoutControls() as Future<Uint8List?>;
        await tester.pump();
        return capture;
      });
      await tester.pumpAndSettle();
      return png!;
    }

    await _tapTool(tester, 'VS Styles');
    await _chooseStyle(tester, VsStyleDefinition.styles.first);
    final gold = await capture();
    await tester.tap(_posterVs);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('delete-poster-vs')), findsOneWidget);
    expect(await capture(), orderedEquals(gold));
    await _chooseStyle(tester, VsStyleDefinition.styles[1]);
    final fire = await capture();
    expect(fire.take(8), orderedEquals([137, 80, 78, 71, 13, 10, 26, 10]));
    expect(fire, isNot(orderedEquals(gold)));
  });

  testWidgets('Urdu VS panel opens and keeps style names readable', (
    tester,
  ) async {
    AppLanguage.current = 'ur';
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await _tapTool(tester, 'VS Styles');
    expect(_panel, findsOneWidget);
    await _chooseStyle(tester, VsStyleDefinition.styles.first);
    expect(find.text('Royal Gold'), findsOneWidget);
  });
}
