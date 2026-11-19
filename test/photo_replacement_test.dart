import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final editor = tester.state(find.byType(Editor)) as dynamic;

    Future<void> pick(XFile file, {required bool sideA}) async {
      gallery.nextImage = file;
      await tester.runAsync(() => editor.pick(sideA) as Future<void>);
      await tester.pumpAndSettle();
    }

    Finder photo(String side) => find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>)
                  .value
                  .startsWith('editor-photo-$side-'),
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
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
