import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart' as voting_pro;
import 'package:voting_pro/widgets/bg_remover_page.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Photo Tools share one dock and keep A and B independent', (
    tester,
  ) async {
    final directory = await getTemporaryDirectory();
    Future<File> fixture(String side, bool transparent) async {
      final photo = img.Image(width: 160, height: 200, numChannels: 4);
      for (final pixel in photo) {
        pixel
          ..r = side == 'A' ? 218 : 44
          ..g = 125
          ..b = side == 'A' ? 46 : 220
          ..a = transparent && pixel.x < 55 ? 0 : 255;
      }
      return File('${directory.path}/photo-tools-$side.png')
          .writeAsBytes(img.encodePng(photo));
    }

    final a = await fixture('A', true);
    final b = await fixture('B', false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'voting_pro_project_v1',
      jsonEncode({'imageA': a.path, 'imageB': b.path}),
    );
    await voting_pro.main();
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    final normal = find.byKey(const PageStorageKey('main-toolbar'));
    final toolbar = find.byKey(const ValueKey('photo-toolbar'));
    final scroll = find.byKey(const ValueKey('photo-tool-scroll'));
    final back = find.descendant(of: toolbar, matching: find.text('Back'));
    final remover = find.byType(BackgroundRemoverPage);
    final bounds = tester.getRect(normal);

    Finder action(String title) =>
        find.descendant(of: toolbar, matching: find.text(title));

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> capture(String filename) async {
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await binding.takeScreenshot(filename);
    }

    Finder imageFor(String side) => find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                    'editor-photo-$side-',
                  ),
        );
    String pathOf(String side) =>
        (tester.widget<Image>(imageFor(side)).image as FileImage).file.path;

    await capture('photo-01-default');
    await tap(imageFor('A'));
    expect(normal, findsNothing);
    expect(tester.getRect(toolbar), bounds);
    expect(find.byKey(const ValueKey('photo-selection-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-selection-B')), findsNothing);
    final backBounds = tester.getRect(back);
    expect(backBounds.right, lessThan(tester.getRect(scroll).left));
    await capture('photo-02-side-a');

    final bSize = tester.getSize(imageFor('B'));
    final aSize = tester.getRect(imageFor('A')).width;
    await tap(action('Zoom In'));
    expect(tester.getRect(imageFor('A')).width, greaterThan(aSize));
    expect(tester.getSize(imageFor('B')), bSize);
    await tap(action('Zoom Out'));
    await tap(action('Backgrounds'));
    await tap(find.text('Ocean'));
    expect(tester.getRect(toolbar), bounds);
    expect(tester.getRect(back), backBounds);
    await capture('photo-03-side-a-backgrounds');
    await tap(action('Remove Background'));
    expect(find.text('Remove Background — A Side'), findsOneWidget);
    await capture('photo-08-side-a-inline-remover');
    await tap(find.descendant(of: remover, matching: find.byTooltip('Close')));
    expect(pathOf('A'), a.path);
    expect(pathOf('B'), b.path);

    await tap(imageFor('B'));
    expect(find.text('Backgrounds — A Side'), findsNothing);
    expect(find.byKey(const ValueKey('photo-selection-B')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-selection-A')), findsNothing);
    await capture('photo-04-side-b');
    await tap(action('Backgrounds'));
    expect(
      find.text('Use Remove Background first to reveal a photo background.'),
      findsOneWidget,
    );
    await tap(action('Remove Background'));
    expect(find.text('Remove Background — B Side'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.getRect(toolbar), bounds);
    expect(tester.getRect(back), backBounds);
    await capture('photo-05-side-b-inline-remover');

    await tap(find.descendant(of: remover, matching: find.text('Erase')));
    final preview = find.byKey(const ValueKey('inline-cutout-brush'));
    await tester.ensureVisible(preview);
    await tester.pumpAndSettle();
    final touch = tester.getCenter(preview);
    final stroke = await tester.startGesture(touch - const Offset(16, 0));
    await stroke.moveTo(touch + const Offset(16, 0));
    await tester.pump();
    await stroke.moveTo(touch + const Offset(32, 0));
    await stroke.up();
    await tester.pumpAndSettle();

    expect(find.descendant(of: remover, matching: find.text('Apply')), findsNothing);
    expect(remover, findsOneWidget);
    expect(pathOf('A'), a.path);
    expect(pathOf('B'), isNot(b.path));
    final cutout = img.decodePng(await File(pathOf('B')).readAsBytes())!;
    expect(cutout.any((pixel) => pixel.a == 0), isTrue);
    await capture('photo-06-side-b-cutout-applied');

    await tap(back);
    expect(toolbar, findsNothing);
    expect(tester.getRect(normal), bounds);
    expect(find.byKey(const ValueKey('photo-selection-B')), findsNothing);
    await capture('photo-07-back-restored');
  });
}
