import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart' as voting_pro;
import 'package:voting_pro/widgets/bg_remover_page.dart';
import 'package:voting_pro/widgets/photo_scene.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Photo Tools share one dock and keep A and B independent', (
    tester,
  ) async {
    final frameTimings = <ui.FrameTiming>[];
    void collectFrameTimings(List<ui.FrameTiming> timings) {
      frameTimings.addAll(timings);
    }

    binding.addTimingsCallback(collectFrameTimings);
    addTearDown(() => binding.removeTimingsCallback(collectFrameTimings));

    void mark(String step) {
      var worstBuildMs = 0;
      var worstRasterMs = 0;
      for (final timing in frameTimings) {
        if (timing.buildDuration.inMilliseconds > worstBuildMs) {
          worstBuildMs = timing.buildDuration.inMilliseconds;
        }
        if (timing.rasterDuration.inMilliseconds > worstRasterMs) {
          worstRasterMs = timing.rasterDuration.inMilliseconds;
        }
      }
      debugPrint(
        'PHOTO_TOOLS_STEP: $step | frames=${frameTimings.length} '
        'maxBuild=${worstBuildMs}ms maxRaster=${worstRasterMs}ms',
      );
    }

    mark('test-start');
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
    mark('fixtures-ready');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'voting_pro_project_v1',
      jsonEncode({'imageA': a.path, 'imageB': b.path}),
    );
    await voting_pro.main();
    mark('app-main-returned');
    await tester.pumpAndSettle();
    mark('initial-layout-settled');
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
      mark('screenshot-start:$filename');
      await binding.takeScreenshot(filename);
      mark('screenshot-complete:$filename');
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
    mark('default-screen-captured');
    final mainRemoverButton = find.descendant(of: normal, matching: find.text('BG Remover'));
    await tester.scrollUntilVisible(mainRemoverButton, 180, scrollable: find.descendant(of: normal, matching: find.byType(Scrollable)));
    mark('main-remover-open-start');
    await tap(mainRemoverButton);
    mark('main-remover-open-complete');
    final mainDock = find.byKey(const ValueKey('main-remover-dock'));
    expect(mainDock, findsOneWidget);
    expect(normal, findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Auto Remove Background'), findsOneWidget);
    expect(find.text('Custom Remove'), findsOneWidget);
    await tap(find.text('Photo B'));
    mark('remover-target-b-selected');
    await tap(find.text('Custom Remove'));
    mark('custom-remover-opened');
    expect(find.byKey(const ValueKey('inline-cutout-brush')), findsOneWidget);
    await tap(find.byKey(const ValueKey('main-remover-back')));
    mark('main-remover-closed');
    expect(mainDock, findsNothing);
    expect(normal, findsOneWidget);
    expect(pathOf('A'), a.path);
    expect(pathOf('B'), b.path);
    await tap(imageFor('A'));
    mark('photo-a-selected');
    expect(normal, findsNothing);
    expect(tester.getRect(toolbar), bounds);
    expect(find.byKey(const ValueKey('photo-selection-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-selection-B')), findsNothing);
    final backBounds = tester.getRect(back);
    expect(backBounds.right, lessThan(tester.getRect(scroll).left));
    await capture('photo-02-side-a');
    mark('photo-a-captured');

    final bSize = tester.getSize(imageFor('B'));
    final aSize = tester.getRect(imageFor('A')).width;
    await tap(action('Zoom In'));
    expect(tester.getRect(imageFor('A')).width, greaterThan(aSize));
    expect(tester.getSize(imageFor('B')), bSize);
    await tap(action('Zoom Out'));
    await tap(action('Backgrounds'));
    mark('photo-a-backgrounds-opened');
    await tap(find.text('Ocean'));
    mark('photo-a-ocean-selected');
    expect(tester.getRect(toolbar), bounds);
    expect(tester.getRect(back), backBounds);
    await capture('photo-03-side-a-backgrounds');
    await tap(action('Remove Background'));
    mark('photo-a-inline-remover-opened');
    expect(find.text('Remove Background — A Side'), findsOneWidget);
    await capture('photo-08-side-a-inline-remover');
    final close = find.byKey(const ValueKey('inline-remover-close'));
    expect(tester.getCenter(close).dx, greaterThan(tester.getCenter(remover).dx));
    await tap(close);
    mark('photo-a-inline-remover-closed');
    expect(remover, findsNothing);
    expect(toolbar, findsOneWidget);
    expect(tester.getRect(toolbar), bounds);
    expect(pathOf('A'), a.path);
    expect(pathOf('B'), b.path);

    await tap(imageFor('B'));
    mark('photo-b-selected');
    expect(find.text('Backgrounds — A Side'), findsNothing);
    expect(find.byKey(const ValueKey('photo-selection-B')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-selection-A')), findsNothing);
    await capture('photo-04-side-b');
    await tap(action('Backgrounds'));
    mark('photo-b-backgrounds-opened');
    expect(
      find.text('Use Remove Background first to reveal a photo background.'),
      findsOneWidget,
    );
    await tap(action('Remove Background'));
    mark('photo-b-inline-remover-opened');
    expect(find.text('Remove Background — B Side'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.getRect(toolbar), bounds);
    expect(tester.getRect(back), backBounds);
    await capture('photo-05-side-b-inline-remover');

    await tap(find.descendant(of: remover, matching: find.text('Erase')));
    mark('photo-b-erase-mode-selected');
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
    mark('photo-b-erase-stroke-complete');

    expect(find.descendant(of: remover, matching: find.text('Apply')), findsNothing);
    expect(remover, findsOneWidget);
    expect(pathOf('A'), a.path);
    expect(pathOf('B'), isNot(b.path));
    mark('photo-b-cutout-written');
    final cutout = img.decodePng(await File(pathOf('B')).readAsBytes())!;
    mark('photo-b-cutout-decoded');
    expect(cutout.any((pixel) => pixel.a == 0), isTrue);
    await capture('photo-06-side-b-cutout-applied');
    final appliedPath = pathOf('B');
    await tap(close);
    mark('photo-b-inline-remover-closed');
    expect(remover, findsNothing);
    expect(toolbar, findsOneWidget);
    expect(pathOf('B'), appliedPath);

    await tap(back);
    mark('photo-toolbar-closed');
    expect(toolbar, findsNothing);
    expect(tester.getRect(normal), bounds);
    expect(find.byKey(const ValueKey('photo-selection-B')), findsNothing);
    await capture('photo-07-back-restored');

    // Capture the real procedural painter on Android, not a generated
    // reference image. The two sheets expose every A/B scene for review.
    mark('scene-contact-sheets-start');
    for (final side in [true, false]) {
      mark(side ? 'scene-contact-sheet-a-start' : 'scene-contact-sheet-b-start');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xff101827),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    for (var row = 0; row < 5; row++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var column = 0; column < 4; column++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
                                          child: SizedBox.expand(
                                            child: PhotoSceneArt(
                                              PhotoScene.values[row * 4 + column],
                                              sideA: side,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 24,
                                        child: Center(
                                          child: Text(
                                            PhotoScene.values[row * 4 + column].en,
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhotoSceneArt), findsNWidgets(20));
      expect(tester.takeException(), isNull);
      await capture(side ? 'photo-09-all-scenes-a' : 'photo-10-all-scenes-b');
      mark(side ? 'scene-contact-sheet-a-complete' : 'scene-contact-sheet-b-complete');
    }
  });
}
