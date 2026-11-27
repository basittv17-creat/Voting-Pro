import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart' as app;
import 'package:voting_pro/widgets/bg_remover_page.dart';
import 'package:voting_pro/widgets/tagra_arena.dart';

/// Deterministic gallery responses exercise the actual editor import/copy path.
class _Gallery extends ImagePickerPlatform {
  XFile? next;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      next;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Both Tagra arenas edit and restore independent portraits', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    const project = 'voting_pro_project_v1';
    await prefs.remove(project);
    final dir = await getTemporaryDirectory();
    final gallery = _Gallery();
    final originalPicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = gallery;
    addTearDown(() => ImagePickerPlatform.instance = originalPicker);
    // Two original, geometric landscape fixtures, with transparent sky.
    Future<XFile> landscape(int seed) async {
      final bitmap = img.Image(width: 240, height: 240, numChannels: 4);
      for (final p in bitmap) {
        final ridge = (p.x - 116 + seed * 12).abs() * .48 + 68;
        final near = (p.x - seed * 65).abs() * .32 + 125;
        final shade = p.y >= near ? 40 : 110;
        p
          ..r = shade + seed * 30
          ..g = shade + 42
          ..b = 120 + seed * 9
          ..a = p.y < ridge && p.y < near ? 0 : 255;
      }
      final file = File('${dir.path}/arena-landscape-$seed.png');
      await file.writeAsBytes(img.encodePng(bitmap));
      return XFile(file.path);
    }

    final fixtures = [
      await landscape(1),
      await landscape(2),
      await landscape(3),
    ];
    await app.main();
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Finder control(String id) => find.byKey(ValueKey(id));
    TagraArenaPoster poster() => tester.widget(find.byType(TagraArenaPoster));
    for (final theme in TagraArena.values) {
      await tap(find.text('Ready-made Templates'));
      final galleryView = find.byType(GridView);
      final name =
          theme == TagraArena.thunder ? 'Royal Thunder' : 'Emerald Fire';
      final tile = find.descendant(
        of: galleryView,
        matching: find.text('Tagra Muqabla — $name'),
      );
      await tester.scrollUntilVisible(
        tile,
        90,
        scrollable: find.descendant(
          of: galleryView,
          matching: find.byType(Scrollable),
        ),
      );
      await tap(tile);
      for (final side in ['A', 'B']) {
        final left = side == 'A';
        gallery.next = fixtures[left ? 0 : 1];
        if ((left ? poster().photoA : poster().photoB) == null) {
          await tap(control('arena-photo-$side'));
        } else {
          await tap(find.text('Change Photo $side'));
        }
        for (var i = 0;
            i < 30 && (left ? poster().photoA : poster().photoB) == null;
            i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(left ? poster().photoA : poster().photoB, isNotNull);
        await tap(control('arena-name-$side'));
        await tester.enterText(
          find.byType(TextFormField),
          left ? 'شاہین' : 'ستارہ',
        );
        await tap(find.text('Save'));
        await tap(control('arena-photo-$side'));
        await tap(find.text('BG Remover'));
        expect(
          tester
              .widget<BackgroundRemoverPage>(find.byType(BackgroundRemoverPage))
              .initialSideA,
          left,
        );
        final priorPath = (left ? poster().photoA! : poster().photoB!).path;
        await tap(find.text('Custom Remove'));
        final brush = control('inline-cutout-brush');
        await tester.ensureVisible(brush);
        await tester.tap(brush);
        for (var i = 0; i < 80 &&
            (left ? poster().photoA! : poster().photoB!).path == priorPath; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((left ? poster().photoA! : poster().photoB!).path, isNot(priorPath));
        await tap(control('main-remover-back'));
        expect(find.byType(BackgroundRemoverPage), findsNothing);
        final result = left ? poster().photoA! : poster().photoB!;
        expect(result.path, contains('voting_pro_cutout_'));
        expect(img.decodePng(await result.readAsBytes())!.any((p) => p.a == 0),
            isTrue);
      }
      final bPath = poster().photoB!.path;
      gallery.next = null;
      await tap(find.text('Change Photo B'));
      expect(poster().photoB!.path, bPath);
      gallery.next = fixtures[2];
      final aPath = poster().photoA!.path;
      await tap(find.text('Change Photo A'));
      for (var i = 0; i < 30 && poster().photoA!.path == aPath; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(poster().photoA!.path, isNot(aPath));
      expect(poster().photoB!.path, bPath);
      final center = tester.getCenter(control('arena-photo-A'));
      final first = await tester.startGesture(center - const Offset(10, 0));
      final second = await tester.startGesture(center + const Offset(10, 0));
      for (final dx in [10.0, 12.0, 14.0]) {
        await first.moveBy(Offset(-dx, 0));
        await second.moveBy(Offset(dx, 0));
        await tester.pump();
      }
      await second.up();
      await first.up();
      await tester.pumpAndSettle();
      expect(poster().scales[true], greaterThan(1));
      expect(poster().scales[false], 1);
      final dynamic editor = tester.state(find.byType(app.Editor));
      final capture =
          editor.capturePosterWithoutControls() as Future<Uint8List?>;
      await tester.pump();
      final bytes = await capture;
      expect(img.decodePng(bytes!)!.width, greaterThan(300));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(theme.id);
      await tap(find.text('Save Poster ↓'));
      for (var i = 0; i < 60 && editor.busy == true; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(editor.busy, false);
      final beforeShare = await dir
          .list()
          .where((f) => f.path.contains('voting_pro_poster_'))
          .length;
      final share = editor.share() as Future<void>;
      await tester.pump();
      await share.timeout(const Duration(seconds: 40));
      expect(
          await dir
              .list()
              .where((f) => f.path.contains('voting_pro_poster_'))
              .length,
          greaterThan(beforeShare));
      await tester.pump(const Duration(seconds: 1));
      for (var i = 0; i < 40; i++) {
        final snapshot = jsonDecode(prefs.getString(project) ?? '{}');
        if (snapshot['selectedReadyMadeTemplate'] == theme.id &&
            (snapshot['templatePhotoScales']['a'] as num) > 1) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: app.Editor()));
      await tester.pumpAndSettle();
      expect(poster().arena, theme);
      expect(poster().nameA, 'شاہین');
      expect(poster().nameB, 'ستارہ');
      expect(poster().scales[true], greaterThan(1));
      expect(poster().photoA, isNotNull);
      expect(poster().photoB, isNotNull);
      await tap(find.text('Classic Editor'));
    }
  });
}
