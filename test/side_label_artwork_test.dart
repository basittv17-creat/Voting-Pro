import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_pro/main.dart';
import 'package:voting_pro/widgets/side_label_artwork.dart';

String _id(String side, int style) =>
    'assets/label_bars/${side.toLowerCase()}_side/${side}_Side_Style_$style.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every legacy label resolves to a distinct, full-size Canvas design', () async {
    final preview = Platform.environment['SIDE_LABEL_PREVIEW_DIR'];
    final recorder = ui.PictureRecorder();
    final sheet = Canvas(recorder);
    sheet.drawColor(const Color(0xff253042), BlendMode.src);
    final fingerprints = <int>{};
    for (final (column, side) in ['A', 'B'].indexed) {
      for (final style in SideLabelStyle.values) {
        final id = _id(side, style.index + 1);
        expect(SideLabelArtwork.supports(id), isTrue);
        final painter = SideLabelPainter(sideA: side == 'A', style: style);
        final size = painter.referenceSize;
        final recording = ui.PictureRecorder();
        painter.paint(Canvas(recording), size);
        final picture = recording.endRecording();
        final rendered = await picture.toImage(size.width.toInt(), size.height.toInt());
        final data = (await rendered.toByteData())!.buffer.asUint8List();
        expect(data[(size.width.toInt() * (size.height.toInt() ~/ 2) + 320) * 4 + 3], 255);
        expect(data[3], lessThan(12));
        fingerprints.add(Object.hashAll(data));
        if (preview != null) {
          final codec = await ui.instantiateImageCodec(await File(id).readAsBytes());
          final original = (await codec.getNextFrame()).image;
          final x = column * 650.0 + 4;
          final y = style.index * 236.0 + 5;
          sheet.drawImage(original, Offset(x, y), Paint());
          sheet.drawImage(rendered, Offset(x, y + 112), Paint());
          original.dispose();
          codec.dispose();
        }
        rendered.dispose();
        picture.dispose();
      }
    }
    expect(fingerprints, hasLength(10));
    final sheetPicture = recorder.endRecording();
    if (preview != null) {
      final image = await sheetPicture.toImage(1300, 1180);
      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final directory = await Directory(preview).create(recursive: true);
      await File('${directory.path}/side-label-comparisons.png').writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      image.dispose();
    }
    sheetPicture.dispose();
  });

  testWidgets('Saved A/B labels still paint and export with their names', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'voting_pro_project_v1': jsonEncode({
        'selectedASideLabel': _id('A', 5),
        'selectedBSideLabel': _id('B', 3),
        'aSideLabelText': 'پاکستان',
        'bSideLabelText': 'B SIDE',
      }),
    });
    tester.view.physicalSize = const Size(688, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Editor()));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(Editor)) as dynamic;
    expect(find.byType(SideLabelArtwork), findsNWidgets(2));
    expect(find.text('پاکستان'), findsOneWidget);
    expect(find.text('B SIDE'), findsOneWidget);
    final bytes = await tester.runAsync(() async {
      final capture = state.capturePosterWithoutControls() as Future<List<int>?>;
      await tester.pump();
      return capture.timeout(const Duration(seconds: 8));
    });
    expect(bytes?.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    await tester.pumpAndSettle();
    expect(find.byType(SideLabelArtwork), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
