import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/app_language.dart';
import 'package:voting_pro/main.dart';

class _Gallery extends ImagePickerPlatform {
  XFile? nextImage;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    expect(source, ImageSource.gallery);
    return nextImage;
  }
}

class _TestProjectDirectory extends PathProviderPlatform {
  _TestProjectDirectory(this.directory);
  final Directory directory;

  @override
  Future<String?> getApplicationSupportPath() async => directory.path;
}

void main() {
  testWidgets('Replacing Photo A preserves Photo B and its drag offset', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('voting-photos-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final gallery = _Gallery();
    final originalPicker = ImagePickerPlatform.instance;
    final originalDirectories = PathProviderPlatform.instance;
    ImagePickerPlatform.instance = gallery;
    PathProviderPlatform.instance = _TestProjectDirectory(directory);
    addTearDown(() {
      ImagePickerPlatform.instance = originalPicker;
      PathProviderPlatform.instance = originalDirectories;
    });
    SharedPreferences.setMockInitialValues({});

    XFile makePhoto(String name, int width, int height) {
      final file = File('${directory.path}/$name.png');
      file.writeAsBytesSync(
        img.encodePng(img.Image(width: width, height: height)),
      );
      return XFile(file.path);
    }

    final originalA = makePhoto('first-a', 20, 12);
    final originalB = makePhoto('first-b', 12, 20);
    final replacement = makePhoto('replacement-a', 24, 16);
    final replacementB = makePhoto('replacement-b', 16, 24);

    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final editor = tester.state(find.byType(Editor)) as dynamic;
    final normal = find.byKey(const PageStorageKey('main-toolbar'));
    final tools = find.byKey(const ValueKey('photo-toolbar'));
    final bounds = tester.getRect(normal);

    Future<void> pick(XFile file, {required bool sideA}) async {
      gallery.nextImage = file;
      await tester.runAsync(() => editor.pick(sideA) as Future<void>);
      await tester.pumpAndSettle();
    }

    Finder photo(String side) => find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                    'editor-photo-$side-',
                  ),
        );
    String path(Finder finder) =>
        (tester.widget<Image>(finder).image as FileImage).file.path;

    await pick(originalA, sideA: true);
    await pick(originalB, sideA: false);
    final photoA = photo('A');
    final photoB = photo('B');
    final originalPathA = path(photoA);
    final originalPathB = path(photoB);
    final originalPositionB = tester.getTopLeft(photoB);
    final drag = await tester.startGesture(tester.getCenter(photoB));
    await drag.moveBy(const Offset(23, 0));
    await tester.pump();
    await drag.moveBy(const Offset(23, 0));
    await drag.up();
    await tester.pumpAndSettle();
    final draggedPositionB = tester.getTopLeft(photoB);
    expect(draggedPositionB.dx, greaterThan(originalPositionB.dx));
    await pick(replacement, sideA: true);

    expect(path(photoA), isNot(originalPathA));
    expect(path(photoB), originalPathB);
    expect(tester.getTopLeft(photoB), draggedPositionB);
    expect(normal, findsNothing);
    expect(tester.getRect(tools), bounds);
    expect(find.byKey(const ValueKey('photo-selection-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-selection-B')), findsNothing);
    final keptA = path(photoA);
    gallery.nextImage = null;
    await tester.runAsync(() => editor.pick(false) as Future<void>);
    await tester.pumpAndSettle();
    expect(path(photoB), originalPathB);
    await pick(replacementB, sideA: false);
    expect(path(photoA), keptA);
    expect(path(photoB), isNot(originalPathB));
    expect(find.byKey(const ValueKey('photo-selection-B')), findsOneWidget);
    Future<Uint8List> exportPoster() async {
      final result = await tester.runAsync(() async {
        final capture =
            editor.capturePosterWithoutControls() as Future<Uint8List?>;
        await tester.pump();
        return capture.timeout(const Duration(seconds: 8));
      });
      await tester.pumpAndSettle();
      return result!;
    }

    final selectedExport = await exportPoster();
    expect(find.byKey(const ValueKey('photo-selection-B')), findsOneWidget);
    final back = find.descendant(of: tools, matching: find.text('Back'));
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(tools, findsNothing);
    expect(tester.getRect(normal), bounds);
    expect(await exportPoster(), orderedEquals(selectedExport));
    addTearDown(() => AppLanguage.current = 'en');
    for (final language in ['en', 'ur']) {
      AppLanguage.current = language;
      for (final width in [320.0, 360.0, 393.0, 412.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpAndSettle();
        final mainBounds = tester.getRect(normal);
        await tester.tap(photoB);
        await tester.pumpAndSettle();
        expect(tester.getRect(tools), mainBounds);
        final fixedBack = find.descendant(
          of: tools,
          matching: find.text(AppLanguage.tr('Back')),
        );
        final backPosition = tester.getRect(fixedBack);
        final row = find.byKey(const ValueKey('photo-tool-scroll'));
        expect(backPosition.right, lessThan(tester.getRect(row).left));
        for (final title in [
          'Replace Photo',
          'Zoom In',
          'Zoom Out',
          'Remove Background',
          'Backgrounds',
        ]) {
          final action = find.descendant(
            of: row,
            matching: find.text(AppLanguage.tr(title)),
          );
          expect(action, findsOneWidget);
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(row).contains(tester.getCenter(action)),
            isTrue,
          );
          expect(tester.getRect(fixedBack), backPosition);
        }
        await tester.tap(fixedBack);
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
