import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renderer shared by classic text overlays, canvas preview and poster export.
/// Curve mode is restricted to single-line Latin text: splitting Arabic/Urdu
/// into glyphs would break contextual joining and must use the normal layout.
class AdvancedTextOverlay extends StatelessWidget {
  const AdvancedTextOverlay({
    super.key,
    required this.text,
    required this.style,
    required this.alignment,
    required this.direction,
    this.gradient = false,
    this.outlineWidth = 0,
    this.outlineColor = Colors.black,
    this.curve = 0,
  });

  final String text;
  final TextStyle style;
  final TextAlign alignment;
  final TextDirection direction;
  final bool gradient;
  final double outlineWidth;
  final Color outlineColor;
  final double curve;

  static const LinearGradient _fill = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF478B), Color(0xFF00E5FF)],
  );

  @override
  Widget build(BuildContext context) {
    final canCurve = curve.abs() > 0.01 &&
        !text.contains('\n') &&
        !RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (canCurve) {
      final chars = text.runes.map(String.fromCharCode).toList();
      double width = 0;
      double lineHeight = 0;
      for (final char in chars) {
        final painter = TextPainter(
          text: TextSpan(text: char, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        width += painter.width;
        lineHeight = math.max(lineHeight, painter.height);
        painter.dispose();
      }
      final canvasWidth = math.max(1.0, width + outlineWidth * 2 + 32);
      final canvasHeight = math.max(1.0, lineHeight + 120 * curve.abs() + outlineWidth * 2 + 24);
      return CustomPaint(
        size: Size(canvasWidth, canvasHeight),
        painter: _CurvedTextPainter(
          text: text,
          style: style,
          curve: curve,
          outlineWidth: outlineWidth,
          outlineColor: outlineColor,
          gradient: gradient,
        ),
      );
    }

    Widget fill = Text(
      text,
      textAlign: alignment,
      textDirection: direction,
      style: style,
    );
    if (gradient) {
      fill = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: _fill.createShader,
        child: fill,
      );
    }
    if (outlineWidth <= 0) return fill;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: alignment,
          textDirection: direction,
          style: style.copyWith(
            shadows: const <Shadow>[],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = outlineWidth * 2
              ..color = outlineColor,
          ),
        ),
        fill,
      ],
    );
  }
}

class _CurvedTextPainter extends CustomPainter {
  _CurvedTextPainter({
    required this.text,
    required this.style,
    required this.curve,
    required this.outlineWidth,
    required this.outlineColor,
    required this.gradient,
  });

  final String text;
  final TextStyle style;
  final double curve;
  final double outlineWidth;
  final Color outlineColor;
  final bool gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final characters = text.runes.map(String.fromCharCode).toList();
    final painters = <TextPainter>[];
    var totalWidth = 0.0;
    var tallest = 0.0;
    for (final char in characters) {
      final painter = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(painter);
      totalWidth += painter.width;
      tallest = math.max(tallest, painter.height);
    }
    if (totalWidth == 0) {
      for (final p in painters) { p.dispose(); }
      return;
    }
    final shader = gradient
        ? AdvancedTextOverlay._fill.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height))
        : null;
    var cursor = (size.width - totalWidth) / 2;
    for (var i = 0; i < characters.length; i++) {
      final painter = painters[i];
      final mid = cursor + painter.width / 2;
      final normalized = ((mid - size.width / 2) / (totalWidth / 2))
          .clamp(-1.0, 1.0).toDouble();
      final bend = curve * 55 * (1 - normalized * normalized);
      final angle = -curve * 110 * normalized / math.max(totalWidth, 1);
      final positionY = (size.height - tallest) / 2 - bend;
      canvas.save();
      canvas.translate(mid, positionY + painter.height / 2);
      canvas.rotate(angle);
      final origin = Offset(-painter.width / 2, -painter.height / 2);
      if (outlineWidth > 0) {
        final strokeStyle = style.copyWith(
          shadows: const <Shadow>[],
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = outlineWidth * 2
            ..strokeJoin = StrokeJoin.round
            ..color = outlineColor,
        );
        final stroke = TextPainter(
          text: TextSpan(text: characters[i], style: strokeStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        stroke.paint(canvas, origin);
        stroke.dispose();
      }
      if (shader == null) {
        painter.paint(canvas, origin);
      } else {
        final fillStyle = style.copyWith(
          foreground: Paint()..shader = shader,
          shadows: const <Shadow>[],
        );
        final fill = TextPainter(
          text: TextSpan(text: characters[i], style: fillStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        fill.paint(canvas, origin);
        fill.dispose();
      }
      canvas.restore();
      cursor += painter.width;
    }
    for (final p in painters) { p.dispose(); }
  }

  @override
  bool shouldRepaint(covariant _CurvedTextPainter old) =>
      text != old.text || style != old.style || curve != old.curve ||
      outlineWidth != old.outlineWidth || outlineColor != old.outlineColor ||
      gradient != old.gradient;
}
