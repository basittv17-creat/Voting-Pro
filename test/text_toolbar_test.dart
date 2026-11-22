import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';
import 'package:voting_pro/widgets/premium_text_editor_panel.dart';

void main() {
  testWidgets('Text replaces the main toolbar in the same slot at 320 dp', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final main = find.byKey(const PageStorageKey('main-toolbar'));
    final text = find.byKey(const ValueKey('text-toolbar'));
    final poster = find.byType(Screenshot);
    final toolbarBounds = tester.getRect(main);
    final posterBounds = tester.getRect(poster);

    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    expect(main, findsNothing);
    expect(find.text('Add Photo A'), findsNothing);
    expect(
      find.descendant(of: text, matching: find.text('More')),
      findsNothing,
    );
    expect(
      find.descendant(of: text, matching: find.text('Color Palette')),
      findsOneWidget,
    );
    expect(tester.getRect(text), toolbarBounds);
    expect(find.byType(PremiumTextEditorPanel), findsNothing);

    // Back is pinned to the LEFT, outside the horizontally scrolling tools.
    final textScroll = find.byKey(const ValueKey('text-tool-scroll'));
    final back = find.descendant(of: text, matching: find.text('Back'));
    expect(textScroll, findsOneWidget);
    expect(back, findsOneWidget);
    expect(
      tester.getRect(back).right,
      lessThanOrEqualTo(tester.getRect(textScroll).left),
    );
    final fixedBackPosition = tester.getRect(back);
    final delete = find.descendant(
      of: text,
      matching: find.text('Delete Text'),
    );
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    expect(tester.getRect(back), fixedBackPosition);
    expect(
      tester.getCenter(find.widgetWithText(InkWell, 'Back')).dy,
      tester.getCenter(find.widgetWithText(InkWell, 'Add Text')).dy,
    );

    final glow = find.descendant(of: text, matching: find.text('Glow'));
    await tester.ensureVisible(glow);
    await tester.tap(glow);
    await tester.pumpAndSettle();
    final settings = find.byType(PremiumTextEditorPanel);
    expect(find.text('Glow intensity'), findsOneWidget);
    expect(
      tester.getTopLeft(settings).dy,
      greaterThanOrEqualTo(posterBounds.bottom),
    );
    expect(find.descendant(of: poster, matching: settings), findsNothing);
    expect(tester.getRect(poster), posterBounds);
    expect(tester.getRect(text), toolbarBounds);

    final background = find.descendant(
      of: text,
      matching: find.text('Text Background'),
    );
    await tester.ensureVisible(background);
    await tester.tap(background);
    await tester.pumpAndSettle();
    expect(find.text('Background opacity'), findsOneWidget);
    expect(find.text('Glow intensity'), findsNothing);
    expect(tester.getRect(text), toolbarBounds);

    await tester.ensureVisible(find.text('Back'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(text, findsNothing);
    expect(settings, findsNothing);
    expect(tester.getRect(main), toolbarBounds);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 360.0, 393.0, 412.0, 768.0]) {
    testWidgets('All text actions remain reachable at $width dp in Urdu', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      AppLanguage.current = 'ur';
      addTearDown(() => AppLanguage.current = 'en');
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(const MaterialApp(home: Editor()));
      await tester.pumpAndSettle();
      final main = find.byKey(const PageStorageKey('main-toolbar'));
      final tools = find.byKey(const ValueKey('text-tool-scroll'));
      final back = find.text(AppLanguage.tr('Back'));
      for (var cycle = 0; cycle < 2; cycle++) {
        final entry = find.text(AppLanguage.tr('Text'));
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();

        expect(main, findsNothing);
        final backPosition = tester.getRect(back);
        expect(backPosition.center.dx, lessThan(width / 2));
        final cards = find.descendant(
          of: tools,
          matching: find.byType(InkWell),
        );
        expect(cards, findsNWidgets(38));
        for (final index in [0, 18, 37, 0]) {
          await tester.ensureVisible(cards.at(index));
          await tester.pumpAndSettle();
          final hitPoint = tester.getCenter(cards.at(index));
          expect(tester.getRect(tools).contains(hitPoint), isTrue);
          expect(tester.getRect(back), backPosition);
        }

        if (cycle == 0) {
          for (var index = 0; index < 38; index++) {
            await tester.ensureVisible(cards.at(index));
            await tester.pump();
            expect(
              tester.getRect(tools).contains(tester.getCenter(cards.at(index))),
              isTrue,
            );
          }
        }
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(main, findsOneWidget);
        expect(tools, findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Color Palette opens the existing color studio directly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Vote'],
        'textOverlayIds': [0],
      }),
    });
    AppLanguage.current = 'en';
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final overlay = find.byType(AdvancedTextOverlay);
    await tester.tap(overlay);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    final toolbar = find.byKey(const ValueKey('text-toolbar'));
    final tools = find.byKey(const ValueKey('text-tool-scroll'));
    expect(
      find.descendant(of: toolbar, matching: find.text('More')),
      findsNothing,
    );
    final palette = find.descendant(
      of: tools,
      matching: find.text('Color Palette'),
    );
    expect(palette, findsOneWidget);
    await tester.ensureVisible(palette);
    await tester.tap(palette);
    await tester.pumpAndSettle();

    expect(find.text('Text Color Studio'), findsOneWidget);
    expect(find.byType(PremiumTextEditorPanel), findsNothing);
    expect(toolbar, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete with no text selection explains what to do', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['★'],
        'stickerOverlayIds': [0],
      }),
    });
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete Text'));
    await tester.tap(find.text('Delete Text'));
    await tester.pumpAndSettle();
    expect(find.text('Select text to delete'), findsOneWidget);
    expect(find.text('★'), findsOneWidget);
  });

  testWidgets('Opening text settings reveals controls on a short viewport', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    final toolbar = find.byKey(const ValueKey('text-toolbar'));
    final bounds = tester.getRect(toolbar);
    for (final (section, control) in [
      ('Glow', 'Glow intensity'),
      ('Text Background', 'Background opacity'),
    ]) {
      final action = find.descendant(of: toolbar, matching: find.text(section));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text(control)).bottom, lessThan(bounds.top));
      expect(tester.getRect(toolbar), bounds);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shadow changes the poster overlay and supports undo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Voting'],
        'textOverlayIds': [0],
        'gradientTextOverlayIds': [0],
      }),
    });
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();

    final overlay = find.byType(AdvancedTextOverlay);
    expect(tester.widget<AdvancedTextOverlay>(overlay).shadow, isNull);
    await tester.tap(overlay);
    await tester.pumpAndSettle();

    Future<void> tapToolbar(String label) async {
      final button = find.descendant(
        of: find.byKey(const ValueKey('text-toolbar')),
        matching: find.text(label),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tapToolbar('Shadow');
    final toggle = find.byType(Switch);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final rendered = tester.widget<AdvancedTextOverlay>(overlay);
    expect(rendered.gradient, isTrue);
    expect(rendered.shadow?.offset, isNot(Offset.zero));
    await tapToolbar('Undo Text');
    expect(tester.widget<AdvancedTextOverlay>(overlay).shadow, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Text Back releases the selection lock for sticker editing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Vote', '★'],
        'textOverlayIds': [0],
        'stickerOverlayIds': [1],
        'textPositions': {
          '0': [45, 45],
          '1': [45, 145],
        },
      }),
    });
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Text'));
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    Future<void> tapCanvas(String label) async {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    }

    final textEdit = find.descendant(
      of: find.byType(Screenshot),
      matching: find.byIcon(Icons.edit),
    );
    await tapCanvas('Vote');
    expect(textEdit, findsOneWidget);
    await tapCanvas('★');
    expect(textEdit, findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(textEdit, findsNothing);
    await tapCanvas('★');
    expect(textEdit, findsNothing);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('Text resize and delete handles work after zooming', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'overlays': ['Delete me', 'Keep me'],
        'textOverlayIds': [0, 1],
        'textPositions': {
          '0': [40, 40],
          '1': [40, 140],
        },
      }),
    });
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete me'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    final resize = find.descendant(
      of: find.byType(Screenshot),
      matching: find.byIcon(Icons.open_in_full),
    );
    final originalWidth = tester.getRect(find.text('Delete me')).width;
    final drag = await tester.startGesture(
      tester.getCenter(resize) + const Offset(4, 4),
    );
    await drag.moveBy(const Offset(0, 25));
    await tester.pump();
    await drag.moveBy(const Offset(0, 30));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Delete me')).width,
      greaterThan(originalWidth),
    );

    final handle = find.descendant(
      of: find.byType(Screenshot),
      matching: find.byIcon(Icons.delete),
    );
    expect(handle, findsOneWidget);
    await tester.tapAt(tester.getCenter(handle) + const Offset(5, -5));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Delete me'), findsNothing);
    expect(find.text('Keep me'), findsOneWidget);
  });

  for (final index in [0, 2, 3]) {
    testWidgets('Deleting overlay $index restores its editing target on Undo', (
      tester,
    ) async {
      final values = ['First', '★', 'Middle', 'Last'];
      SharedPreferences.setMockInitialValues({
        'voting_pro_project_v1': jsonEncode({
          'overlays': values,
          'textOverlayIds': [0, 2, 3],
          'stickerOverlayIds': [1],
          'textPositions': {
            '0': [20, 25],
            '1': [20, 85],
            '2': [20, 145],
            '3': [20, 205],
          },
          'textColors': {'$index': 0xFFFF243A},
          'boldTextOverlayIds': [index],
        }),
      });
      await tester.pumpWidget(const MaterialApp(home: Editor()));
      await tester.pumpAndSettle();

      final target = find.byWidgetPredicate(
        (widget) =>
            widget is AdvancedTextOverlay && widget.text == values[index],
      );
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Text'));
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();

      Future<void> action(String label) async {
        final button = find.text(label);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      final originalPosition = tester.getTopLeft(target);
      for (var cycle = 0; cycle < 2; cycle++) {
        await action(cycle == 0 ? 'Delete Text' : 'Redo Text');
        expect(target, findsNothing);
        expect(find.byType(AdvancedTextOverlay), findsNWidgets(3));
        await action('Undo Text');
        expect(target, findsOneWidget);
        final restored = tester.widget<AdvancedTextOverlay>(target);
        expect(restored.style.color, const Color(0xFFFF243A));
        expect(restored.style.fontWeight, FontWeight.w900);
        expect(tester.getTopLeft(target), originalPosition);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      }
      // The restored selection must be usable, including when a sticker shares
      // the index space and indices shifted during deletion.
      await action('Delete Text');
      expect(target, findsNothing);
      expect(find.text('★'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
