import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

/// All processing is local to the device. No upload, account, API or network.
class OfflineBgRemover {
  OfflineBgRemover._();

  static const modelAsset = 'assets/models/selfie_segmenter.tflite';

  /// Limit editor memory on low-end devices; keep a good poster-resolution PNG.
  static Future<Uint8List> prepare(Uint8List original) =>
      compute(_prepareImage, original);

  static Future<Uint8List> compose(
    Uint8List sourcePng,
    Uint8List alpha,
  ) =>
      compute(_composeImage, <Object>[sourcePng, alpha]);

  /// Predict a person mask with the model bundled inside the installed APK.
  /// Other subjects can still be cut out using the manual Erase/Restore tools.
  static Future<Uint8List> autoMask(
    Uint8List sourcePng,
    int width,
    int height,
  ) async {
    final image = img.decodeImage(sourcePng);
    if (image == null) throw const FormatException('Cannot read image');
    final interpreter = await Interpreter.fromAsset(
      modelAsset,
      options: InterpreterOptions()..addMediaPipeCustomOps(),
    );
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
      // The bundled MediaPipe float model uses RGB normalized to [-1, 1].
      final input = <List<List<List<double>>>>[
        List.generate(h, (y) => List.generate(w, (x) {
          final px = small.getPixel(x, y);
          return <double>[
            px.r.toDouble() / 127.5 - 1,
            px.g.toDouble() / 127.5 - 1,
            px.b.toDouble() / 127.5 - 1,
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
      final mask = Uint8List(width * height);
      for (var y = 0; y < height; y++) {
        final fy = (y + 0.5) * mh / height - 0.5;
        final y0 = fy.floor().clamp(0, mh - 1);
        final y1 = (y0 + 1).clamp(0, mh - 1);
        final ty = (fy - fy.floor()).clamp(0.0, 1.0);
        for (var x = 0; x < width; x++) {
          final fx = (x + 0.5) * mw / width - 0.5;
          final x0 = fx.floor().clamp(0, mw - 1);
          final x1 = (x0 + 1).clamp(0, mw - 1);
          final tx = (fx - fx.floor()).clamp(0.0, 1.0);
          final top = result[y0 * mw + x0] * (1 - tx) +
              result[y0 * mw + x1] * tx;
          final bottom = result[y1 * mw + x0] * (1 - tx) +
              result[y1 * mw + x1] * tx;
          mask[y * width + x] =
              ((top * (1 - ty) + bottom * ty) * 255).round().clamp(0, 255);
        }
      }
      return mask;
    } finally {
      interpreter.close();
    }
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

Uint8List _prepareImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image format');
  final oriented = img.bakeOrientation(decoded);
  final maxSide = math.max(oriented.width, oriented.height);
  final picture = maxSide > 1600
      ? img.copyResize(
          oriented,
          width: (oriented.width * 1600 / maxSide).round(),
          height: (oriented.height * 1600 / maxSide).round(),
          interpolation: img.Interpolation.linear,
        )
      : oriented;
  return Uint8List.fromList(img.encodePng(picture));
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
