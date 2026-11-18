import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:voting_pro/services/offline_bg_remover.dart';

void main() {
  test('MediaPipe RGB normalization uses float range [0, 1]', () {
    expect(OfflineBgRemover.normalizeMediaPipeChannel(0), 0);
    expect(OfflineBgRemover.normalizeMediaPipeChannel(255), 1);
    expect(OfflineBgRemover.normalizeMediaPipeChannel(127.5), 0.5);
    expect(OfflineBgRemover.normalizeMediaPipeChannel(-1), 0);
    expect(OfflineBgRemover.normalizeMediaPipeChannel(300), 1);
  });

  test('Mask resize preserves the four corners on enlarged images', () {
    final original = Float32List.fromList([1, 0, 0, 1]);
    final enlarged =
        OfflineBgRemover.resizeSoftMask(original, 2, 2, 6, 6);
    expect(enlarged[0], 255);
    expect(enlarged[5], 0);
    expect(enlarged[30], 0);
    expect(enlarged[35], 255);
    expect(enlarged[2 * 6 + 2], greaterThan(0));
    expect(enlarged[2 * 6 + 2], lessThan(255));
  });

  test('Single-pixel mask expands without leaking transparency', () {
    final singlePixel = Float32List.fromList([1]);
    final resized =
        OfflineBgRemover.resizeSoftMask(singlePixel, 1, 1, 3, 5);
    expect(resized, everyElement(255));
  });

  test('Invalid soft mask dimensions are rejected', () {
    expect(
      () => OfflineBgRemover.resizeSoftMask(Float32List(1), 2, 2, 6, 6),
      throwsFormatException,
    );
  });

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

  test('Thin panorama and portrait images retain nonzero dimensions', () async {
    for (final original in [
      img.Image(width: 1, height: 5000),
      img.Image(width: 5000, height: 1),
    ]) {
      final png = Uint8List.fromList(img.encodePng(original));
      final prepared = await OfflineBgRemover.prepare(png);
      final result = img.decodeImage(prepared)!;
      expect(result.width, greaterThanOrEqualTo(1));
      expect(result.height, greaterThanOrEqualTo(1));
      expect(result.width, lessThanOrEqualTo(1600));
      expect(result.height, lessThanOrEqualTo(1600));
    }
  });

  test('Brush accepts a stroke that touches the image edge', () {
    final alpha = Uint8List.fromList(List<int>.filled(16, 255));
    OfflineBgRemover.brush(alpha, 4, 4, 0, 0, 3, erase: true);
    expect(alpha[0], lessThan(255));
    expect(alpha[15], 255);
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
