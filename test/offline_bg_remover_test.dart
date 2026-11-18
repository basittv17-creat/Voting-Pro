import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:voting_pro/services/offline_bg_remover.dart';

void main() {
  test('Erase brush affects only the selected circular area', () {
    final alpha = Uint8List.fromList(List<int>.filled(100, 255));
    OfflineBgRemover.brush(alpha, 10, 10, 4.5, 4.5, 2, erase: true);
    expect(alpha[4 * 10 + 4], 0);
    expect(alpha[0], 255);
    expect(alpha[99], 255);
  });

  test('Restore brush recovers erased region without modifying corners', () {
    final alpha = Uint8List(100);
    OfflineBgRemover.brush(alpha, 10, 10, 4.5, 4.5, 2, erase: false);
    expect(alpha[4 * 10 + 4], 255);
    expect(alpha[0], 0);
    expect(alpha[99], 0);
  });

  test('Offline PNG composition produces correct transparent alpha', () async {
    final source = img.Image(width: 2, height: 1, numChannels: 4);
    source.setPixelRgba(0, 0, 255, 0, 0, 255);
    source.setPixelRgba(1, 0, 0, 255, 0, 255);
    final png = Uint8List.fromList(img.encodePng(source));
    final cutout = await OfflineBgRemover.compose(
      png,
      Uint8List.fromList([255, 0]),
    );
    final image = img.decodeImage(cutout)!;
    expect(image.width, 2);
    expect(image.height, 1);
    expect(image.getPixel(0, 0).a, 255);
    expect(image.getPixel(1, 0).a, 0);
  });
}
