import 'package:flutter/material.dart';

/// Experimental recreations of the original frame art. Never use a candidate
/// in production until the reference comparison and owner review are complete.
const proceduralFramePreviewEnabled = bool.fromEnvironment(
  'VOTING_PRO_FRAME_PREVIEW',
);

enum ProceduralFrame {
  modernGold('assets/stylish_frames/04_modern_gold_frame.png'),
  diamond('assets/stylish_frames/10_diamond_frame.png');

  const ProceduralFrame(this.asset);
  final String asset;
  static ProceduralFrame? forAsset(String asset) {
    for (final frame in values) {
      if (frame.asset == asset) return frame;
    }
    return null;
  }
}

/// Uses the same fit and original 1200x900 coordinate space in thumbnails,
/// posters and exports. The default route remains the original asset.
class FrameArtwork extends StatelessWidget {
  const FrameArtwork(
    this.asset, {
    super.key,
    required this.fit,
    this.width,
    this.height,
    this.gaplessPlayback = false,
    this.preview = proceduralFramePreviewEnabled,
    this.thumbnail = false,
  });

  final String asset;
  final BoxFit fit;
  final double? width, height;
  final bool gaplessPlayback, preview;
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final frame = ProceduralFrame.forAsset(asset);
    if (!preview || frame == null) {
      if (thumbnail && fit == BoxFit.contain) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final ratio = MediaQuery.devicePixelRatioOf(context);
            if (!constraints.hasBoundedWidth ||
                !constraints.hasBoundedHeight ||
                constraints.biggest.isEmpty) {
              return Image.asset(asset, fit: fit);
            }
            return Image(
              image: ResizeImage(
                AssetImage(asset),
                width: (constraints.maxWidth * ratio).ceil(),
                height: (constraints.maxHeight * ratio).ceil(),
                policy: ResizeImagePolicy.fit,
              ),
              fit: fit,
            );
          },
        );
      }
      return Image.asset(
        asset,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: gaplessPlayback,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
            return Image.asset(asset, fit: fit);
          }
          return RepaintBoundary(
            child: CustomPaint(
              size: constraints.biggest,
              painter: ProceduralFramePainter(frame, fit: fit),
            ),
          );
        },
      ),
    );
  }
}

class ProceduralFramePainter extends CustomPainter {
  const ProceduralFramePainter(this.frame, {this.fit = BoxFit.fill});
  final ProceduralFrame frame;
  final BoxFit fit;
  static const referenceSize = Size(1200, 900);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final fitted = applyBoxFit(fit, referenceSize, size);
    final source = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & referenceSize,
    );
    final target = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(target.left, target.top);
    canvas.scale(target.width / source.width, target.height / source.height);
    canvas.translate(-source.left, -source.top);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    void band(Rect outside, Rect inside, Color color) {
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outside)
        ..addRect(inside);
      canvas.drawPath(path, Paint()..color = color);
    }

    void trace(List<Offset> points, Color color, double width, {
      bool closed = false,
    }) {
      final path = Path()..addPolygon(points, closed);
      canvas.drawPath(
        path,
        paint
          ..color = color
          ..strokeWidth = width,
      );
    }

    void diamond(double x, double y, double rx, double ry) {
      final points = [
        Offset(x, y - ry),
        Offset(x + rx, y),
        Offset(x, y + ry),
        Offset(x - rx, y),
      ];
      trace(points, const Color(0xff6d3900), 5, closed: true);
      trace(points, const Color(0xffffcc31), 3, closed: true);
      trace(points, const Color(0xfffff4b2), 1, closed: true);
    }

    final turquoise = frame == ProceduralFrame.diamond;
    final outer = turquoise
        ? const Color(0xff005745)
        : const Color(0xff6b3500);
    final rim = turquoise
        ? const Color(0xff00eabb)
        : const Color(0xffffa51b);
    final highlight = turquoise
        ? const Color(0xffb5fff0)
        : const Color(0xfffff1ac);
    // The two axes have different bevel widths in the source artwork.
    const edge = Rect.fromLTRB(48, 28.8, 1152.5, 871.5);
    const face = Rect.fromLTRB(53, 31.8, 1147, 868.5);
    const lip = Rect.fromLTRB(57.8, 34.8, 1142.5, 865.5);
    const opening = Rect.fromLTRB(60, 36, 1140, 864);
    band(edge, face, turquoise ? const Color(0xff007354) : const Color(0xffa15c00));
    band(face, lip, turquoise ? const Color(0xff1affbb) : const Color(0xffffcf42));
    band(lip, opening, turquoise ? const Color(0xffffe04c) : const Color(0xfffff8cb));
    band(
      const Rect.fromLTRB(71, 42.4, 1129.5, 858),
      const Rect.fromLTRB(73, 44, 1127.5, 856),
      turquoise ? const Color(0xdc1affb9) : const Color(0xdcffcf41),
    );

    if (turquoise) {
      for (final sx in [1.0, -1.0]) {
        for (final sy in [1.0, -1.0]) {
          canvas.save();
          canvas.translate(sx < 0 ? 1200 : 0, sy < 0 ? 900 : 0);
          canvas.scale(sx, sy);
          final corner = [
            const Offset(73, 83),
            const Offset(164, 83),
            const Offset(200, 114),
          ];
          trace(corner, outer, 7);
          trace(corner, rim, 4);
          trace(corner, highlight, 1);
          diamond(143, 98, 14, 8);
          canvas.restore();
        }
      }
      diamond(600, 41, 33, 20);
      diamond(600, 859, 33, 20);
    } else {
      for (final x in [108.0, 1092.0]) {
        for (final y in [65.0, 835.0]) {
          diamond(x, y, 14, 8);
        }
      }
      // Asymmetric top-left ornament in the original modern gold frame.
      const ornament = [
        Offset(0, 40),
        Offset(150, 40),
        Offset(178, 20),
        Offset(178, 0),
      ];
      const lower = [
        Offset(150, 40),
        Offset(178, 63),
        Offset(178, 98),
      ];
      for (final points in [ornament, lower]) {
        trace(points, outer, 7);
        trace(points, rim, 4);
        trace(points, highlight, 1.5);
      }
    }
    diamond(59, 450, 10, 7);
    diamond(1141, 450, 10, 7);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ProceduralFramePainter oldDelegate) =>
      frame != oldDelegate.frame || fit != oldDelegate.fit;
}
