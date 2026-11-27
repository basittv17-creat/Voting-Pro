import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/widgets/procedural_frame_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Original frame remains the default renderer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 240,
          height: 180,
          child: FrameArtwork(
            'assets/stylish_frames/04_modern_gold_frame.png',
            fit: BoxFit.contain,
            preview: false,
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gallery decodes within the physical tile size', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: 2),
        child: Center(
          child: SizedBox(
            width: 80,
            height: 60,
            child: FrameArtwork(
              'assets/stylish_frames/04_modern_gold_frame.png',
              fit: BoxFit.contain,
              preview: false,
              thumbnail: true,
            ),
          ),
        ),
      ),
    );
    final provider = tester.widget<Image>(find.byType(Image)).image;
    final resize = provider as ResizeImage;
    expect(resize.width, 160);
    expect(resize.height, 120);
    expect(resize.policy, ResizeImagePolicy.fit);
  });

  test('Compare candidate frame pixels with original', () async {
    for (final frame in ProceduralFrame.values) {
      final data = await rootBundle.load(frame.asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final original = (await codec.getNextFrame()).image;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      ProceduralFramePainter(frame).paint(
        canvas,
        Size(original.width.toDouble(), original.height.toDouble()),
      );
      final picture = recorder.endRecording();
      final candidate = await picture.toImage(original.width, original.height);
      final a = (await original.toByteData())!.buffer.asUint8List();
      final b = (await candidate.toByteData())!.buffer.asUint8List();
      var changedPixels = 0;
      for (var i = 0; i < a.length; i += 4) {
        if (a[i] != b[i] ||
            a[i + 1] != b[i + 1] ||
            a[i + 2] != b[i + 2] ||
            a[i + 3] != b[i + 3]) {
          changedPixels++;
        }
      }
      // Diagnostic only: candidates are not approved for the release bundle.
      // Do not lower the design-fidelity requirement to pass this test.
      debugPrint(
        '${frame.name}: $changedPixels / '
        '${original.width * original.height} differing pixels',
      );
      expect(a.length, b.length);
      expect(b.any((channel) => channel != 0), isTrue);
      original.dispose();
      candidate.dispose();
      picture.dispose();
      codec.dispose();
    }
  });
}
