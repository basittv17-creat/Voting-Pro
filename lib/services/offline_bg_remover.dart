import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

/// All processing is local to the device. No upload, account, API or network.
class OfflineBgRemover {
  OfflineBgRemover._();

  static const modelAsset = 'assets/models/selfie_segmenter.tflite';

  /// Limit editor memory on low-end devices; keep a good poster-resolution PNG.
  static Future<Uint8List> prepare(Uint8List original) =>
      compute(_prepareImage, original);

  static Future<PreparedCutout> open(Uint8List source, Uint8List? applied) =>
      compute(_openCutout, (source, applied));

  static Future<Uint8List> compose(
    Uint8List sourcePng,
    Uint8List alpha,
  ) =>
      compute(_composeImage, <Object>[sourcePng, alpha]);

  /// MediaPipe's selfie segmentation graph uses the [0,1] float range.
  static double normalizeMediaPipeChannel(double channel) =>
      (channel / 255.0).clamp(0.0, 1.0).toDouble();

  /// Predict a person mask with the model bundled inside the installed APK.
  /// Other subjects can still be cut out using the manual Erase/Restore tools.
  static Future<Uint8List> autoMask(
    Uint8List sourcePng,
    int width,
    int height,
  ) async {
    final model = await rootBundle.load(modelAsset);
    return compute(_inferMask, (model.buffer.asUint8List(model.offsetInBytes, model.lengthInBytes), sourcePng, width, height));
  }

  static Uint8List _inferMask((Uint8List, Uint8List, int, int) inputData) {
    final (model, sourcePng, width, height) = inputData;
    final image = img.decodeImage(sourcePng);
    if (image == null) throw const FormatException('Cannot read image');
    final options = InterpreterOptions()..addMediaPipeCustomOps();
    late final Interpreter interpreter;
    try {
      interpreter = Interpreter.fromBuffer(model, options: options);
    } finally {
      options.delete();
    }
    try {
      final inputShape = interpreter.getInputTensor(0).shape;
      if (inputShape.length != 4 ||
          inputShape.first != 1 ||
          inputShape[3] != 3) {
        throw StateError('Unsupported selfie model input shape: $inputShape');
      }
      final w = inputShape[2];
      final h = inputShape[1];
      final small = img.copyResize(
        image, width: w, height: h, interpolation: img.Interpolation.linear,
      );
      // MediaPipe ImageToTensorCalculator feeds the model RGB in [0, 1].
      // Feeding [-1, 1] here corrupts the person-mask predictions.
      final input = <List<List<List<double>>>>[
        List.generate(h, (y) => List.generate(w, (x) {
          final px = small.getPixel(x, y);
          return <double>[
            normalizeMediaPipeChannel(px.r.toDouble()),
            normalizeMediaPipeChannel(px.g.toDouble()),
            normalizeMediaPipeChannel(px.b.toDouble()),
          ];
        })),
      ];
      final shape = interpreter.getOutputTensor(0).shape;
      if (shape.first != 1 || (shape.length != 4 && shape.length != 3)) {
        throw StateError('Unsupported selfie model output shape: $shape');
      }
      final mh = shape[1];
      final mw = shape[2];
      final channels = shape.length == 4 ? shape[3] : 1;
      if (channels < 1 || channels > 2) {
        throw StateError('Unexpected segmentation channels: $channels');
      }
      final Object output = shape.length == 4
          ? [List.generate(
              mh, (_) => List.generate(
                mw, (_) => List<double>.filled(channels, 0),
              ),
            )]
          : [List.generate(mh, (_) => List<double>.filled(mw, 0))];
      interpreter.run(input, output);
      final dynamic values = output;
      final result = Float32List(mw * mh);
      for (var y = 0; y < mh; y++) {
        for (var x = 0; x < mw; x++) {
          final double value = channels == 1
              ? (shape.length == 4
                  ? (values[0][y][x][0] as num).toDouble()
                  : (values[0][y][x] as num).toDouble())
              : (values[0][y][x][1] as num).toDouble();
          // Feather the hard edge; keep small uncertain areas manually editable.
          result[y * mw + x] = ((value - 0.12) / 0.76)
              .clamp(0.0, 1.0).toDouble();
        }
      }
      final alpha = resizeSoftMask(result, mw, mh, width, height);
      if (image.width == width && image.height == height) {
        refineSoftEdges(alpha, image);
      }
      return alpha;
    } finally {
      interpreter.close();
    }
  }

  /// Smooth only uncertain model edges. Neighbours across a strong RGB
  /// boundary have little influence on the hair or clothing pixel being refined.
  static void refineSoftEdges(Uint8List mask, img.Image source) {
    final width = source.width;
    final height = source.height;
    if (mask.length != width * height) throw const FormatException('Mask size mismatch');
    final original = Uint8List.fromList(mask);
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final i = y * width + x;
        final value = original[i];
        if (value < 8 || value > 247) continue;
        final center = source.getPixel(x, y);
        double sum = value * 4.0, weights = 4;
        for (final (dx,dy) in const [(-1,0),(1,0),(0,-1),(0,1)]) {
          final neighbor = source.getPixel(x+dx,y+dy);
          final distance = (center.r-neighbor.r).abs() + (center.g-neighbor.g).abs() + (center.b-neighbor.b).abs();
          final weight = 1 / (1 + distance / 24);
          sum += original[i+dy*width+dx]*weight;
          weights += weight;
        }
        mask[i] = (sum/weights).round();
      }
    }
  }

  /// Bilinearly scale the foreground mask without mixing edge pixels with
  /// nonexistent neighbours. The output is a device-local 8-bit alpha mask.
  static Uint8List resizeSoftMask(
    Float32List source,
    int sourceWidth,
    int sourceHeight,
    int targetWidth,
    int targetHeight,
  ) {
    if (sourceWidth < 1 || sourceHeight < 1 ||
        targetWidth < 1 || targetHeight < 1 ||
        source.length != sourceWidth * sourceHeight) {
      throw const FormatException('Invalid segmentation mask dimensions');
    }
    final alpha = Uint8List(targetWidth * targetHeight);
    for (var y = 0; y < targetHeight; y++) {
      final fy = ((y + 0.5) * sourceHeight / targetHeight - 0.5)
          .clamp(0.0, (sourceHeight - 1).toDouble());
      final y0 = fy.floor();
      final y1 = math.min(y0 + 1, sourceHeight - 1);
      final dy = fy - y0;
      for (var x = 0; x < targetWidth; x++) {
        final fx = ((x + 0.5) * sourceWidth / targetWidth - 0.5)
            .clamp(0.0, (sourceWidth - 1).toDouble());
        final x0 = fx.floor();
        final x1 = math.min(x0 + 1, sourceWidth - 1);
        final dx = fx - x0;
        final top = source[y0 * sourceWidth + x0] * (1 - dx) +
            source[y0 * sourceWidth + x1] * dx;
        final bottom = source[y1 * sourceWidth + x0] * (1 - dx) +
            source[y1 * sourceWidth + x1] * dx;
        final value = top * (1 - dy) + bottom * dy;
        alpha[y * targetWidth + x] =
            (value.clamp(0.0, 1.0) * 255).round();
      }
    }
    return alpha;
  }

  /// Draw an anti-aliased circular manual brush into the alpha mask.
  /// Brush coordinates and radius are expressed in image pixels.
  static void brush(
    Uint8List alpha, int width, int height,
    double cx, double cy, double radius, {
    required bool erase,
  }) {
    final r = math.max(radius, 1.0);
    final x0 = (cx - r).floor().clamp(0, width - 1);
    final x1 = (cx + r).ceil().clamp(0, width - 1);
    final y0 = (cy - r).floor().clamp(0, height - 1);
    final y1 = (cy + r).ceil().clamp(0, height - 1);
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final dx = x + 0.5 - cx;
        final dy = y + 0.5 - cy;
        final distance = math.sqrt(dx * dx + dy * dy);
        final coverage = (r + 0.5 - distance).clamp(0.0, 1.0);
        if (coverage <= 0) continue;
        final i = y * width + x;
        alpha[i] = erase
            ? (alpha[i] * (1 - coverage)).round().clamp(0, 255)
            : (alpha[i] + (255 - alpha[i]) * coverage)
                .round().clamp(0, 255);
      }
    }
  }
}

img.Image _preparePixels(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image format');
  final oriented = img.bakeOrientation(decoded);
  final maxSide = math.max(oriented.width, oriented.height);
  final picture = maxSide > 1600
      ? img.copyResize(
          oriented,
          // Preserve at least one pixel for extreme portrait/wide photos.
          width: math.max(1, (oriented.width * 1600 / maxSide).round()),
          height: math.max(1, (oriented.height * 1600 / maxSide).round()),
          interpolation: img.Interpolation.linear,
        )
      : oriented;
  return picture;
}

Uint8List _prepareImage(Uint8List bytes) => img.encodePng(_preparePixels(bytes));

typedef PreparedCutout = ({
  Uint8List source, Uint8List preview, Uint8List mask, int width, int height,
});

PreparedCutout _openCutout((Uint8List, Uint8List?) files) {
  final original = _preparePixels(files.$1);
  final source = img.encodePng(original);
  final count = original.width * original.height;
  final mask = Uint8List(count)..fillRange(0, count, 255);
  var preview = source;
  final applied = files.$2;
  if (applied != null) {
    final cutout = _preparePixels(applied);
    if (cutout.width == original.width && cutout.height == original.height) {
      preview = img.encodePng(cutout);
      for (var y = 0; y < original.height; y++) {
        for (var x = 0; x < original.width; x++) {
          final alpha = original.getPixel(x, y).a;
          if (alpha != 0) {
            mask[y * original.width + x] =
                (cutout.getPixel(x, y).a * 255 / alpha).round().clamp(0, 255);
          }
        }
      }
    }
  }
  return (source: source, preview: preview, mask: mask,
      width: original.width, height: original.height);
}

Uint8List _composeImage(List<Object> parts) {
  final png = parts[0] as Uint8List;
  final alpha = parts[1] as Uint8List;
  final picture = img.decodeImage(png);
  if (picture == null || alpha.length != picture.width * picture.height) {
    throw const FormatException('Mask size does not match image');
  }
  final output = img.Image(
    width: picture.width, height: picture.height, numChannels: 4,
  );
  for (var y = 0; y < picture.height; y++) {
    for (var x = 0; x < picture.width; x++) {
      final pixel = picture.getPixel(x, y);
      final a = (pixel.a.toDouble() * alpha[y * picture.width + x] / 255)
          .round().clamp(0, 255);
      output.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, a);
    }
  }
  return Uint8List.fromList(img.encodePng(output));
}
