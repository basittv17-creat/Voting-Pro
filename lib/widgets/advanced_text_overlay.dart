import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'text_background_plate.dart';

List<String> _curveRuns(String text) {
  // Shape Arabic and Devanagari words together, including joining marks.
  if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0900-\u097F]').hasMatch(text)) {
    return RegExp(r'\S+|\s').allMatches(text).map((m) => m[0]!).toList();
  }
  return text.characters.toList();
}

/// Renderer shared by classic text overlays, canvas preview and poster export.
/// Curved text supports Latin characters and shaped Urdu/Arabic word runs.
/// Keeping RTL words intact preserves joining, ligatures and diacritics.
class AdvancedTextOverlay extends StatelessWidget {
  const AdvancedTextOverlay({
    super.key,
    required this.text,
    required this.style,
    required this.alignment,
    required this.direction,
    this.gradient = false,
    this.shadow,
    this.outlineWidth = 0,
    this.outlineColor = Colors.black,
    this.curve = 0,
    this.backgroundColor,
    this.backgroundDesign,
    this.backgroundRadius = 8,
    this.backgroundOpacity = 0.8,
    this.backgroundExpansion = 0,
    this.backgroundGradient = false,
    this.backgroundShadowBlur = 0,
    this.backgroundBorderWidth = 0,
  });

  final String text;
  final TextStyle style;
  final TextAlign alignment;
  final TextDirection direction;
  final bool gradient;
  final Shadow? shadow;
  final double outlineWidth;
  final Color outlineColor;
  final double curve;
  final Color? backgroundColor;
  final String? backgroundDesign;
  final double backgroundRadius;
  final double backgroundOpacity;
  final double backgroundExpansion;
  final bool backgroundGradient;
  final double backgroundShadowBlur;
  final double backgroundBorderWidth;

  static const LinearGradient _fill = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF478B), Color(0xFF00E5FF)],
  );

  @override
  Widget build(BuildContext context) {
    final legacyBackground = backgroundDesign == null ? backgroundColor : null;
    Widget artwork = _buildArtwork(legacyBackground);
    final color = backgroundColor;
    if (backgroundDesign != null && color != null && backgroundOpacity > 0) {
      artwork = TextBackgroundPlate(
        color: color,
        design: backgroundDesign,
        opacity: backgroundOpacity,
        padding: math.max(2, backgroundExpansion),
        radius: backgroundRadius,
        borderWidth: backgroundBorderWidth,
        shadowBlur: backgroundShadowBlur,
        gradient: backgroundGradient,
        child: artwork,
      );
    }
    final hasBackground = color != null && backgroundOpacity > 0;
    final effect = math.max(
      outlineWidth,
      hasBackground ? backgroundShadowBlur * 2 : 0.0,
    );
    final shadows = [...?style.shadows, if (shadow != null) shadow!];
    final shadowInset = shadows.fold<double>(
        0,
        (inset, value) =>
            math.max(inset, value.blurRadius + value.offset.distance));
    final inset = math.max(effect, shadowInset);
    return Padding(padding: EdgeInsets.all(inset), child: artwork);
  }

  double get _glyphInset =>
      direction == TextDirection.rtl ? (style.fontSize ?? 14) * .14 : 0;

  Widget _line(TextStyle paintStyle) => Padding(
        padding: EdgeInsets.all(_glyphInset),
        child: Text(
          text,
          textAlign: alignment,
          textDirection: direction,
          style: paintStyle,
        ),
      );

  Widget _buildArtwork(Color? backgroundColor) {
    final canCurve = curve.abs() > 0.01 && !text.contains('\n');
    if (canCurve) {
      final chars = _curveRuns(text);
      double width = 0;
      double lineHeight = 0;
      for (final char in chars) {
        final painter = TextPainter(
          text: TextSpan(text: char, style: style),
          textDirection: direction,
        )..layout();
        width += painter.width;
        lineHeight = math.max(lineHeight, painter.height);
        painter.dispose();
      }
      final canvasWidth = math.max(1.0, width + outlineWidth * 2 + 32);
      final canvasHeight =
          math.max(1.0, lineHeight + 120 * curve.abs() + outlineWidth * 2 + 24);
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomPaint(
          size: Size(canvasWidth, canvasHeight),
          painter: _CurvedTextPainter(
            text: text,
            style: style,
            curve: curve,
            outlineWidth: outlineWidth,
            outlineColor: outlineColor,
            gradient: gradient,
            shadow: shadow,
            direction: direction,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            backgroundExpansion: backgroundExpansion,
            backgroundGradient: backgroundGradient,
            backgroundShadowBlur: backgroundShadowBlur,
            backgroundBorderWidth: backgroundBorderWidth,
          ),
        ),
      );
    }

    Widget fill = _line(style);
    if (gradient) {
      fill = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: _fill.createShader,
        child: fill,
      );
    }
    // Match the actual shaped letter outlines, never a rectangular strip.
    final hasBg = backgroundColor != null && backgroundOpacity > 0;
    if (outlineWidth <= 0 && !hasBg && shadow == null) return fill;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = backgroundExpansion.clamp(0.0, 24.0).toDouble() * 2 + 2
      ..color = (backgroundColor ?? Colors.transparent)
          .withOpacity(backgroundOpacity.clamp(0.0, 1.0).toDouble());
    if (backgroundGradient && backgroundColor != null) {
      bgPaint.shader = LinearGradient(colors: [
        backgroundColor
            .withOpacity(backgroundOpacity.clamp(0.0, 1.0).toDouble()),
        Color.lerp(backgroundColor, Colors.purpleAccent, 0.55)!
            .withOpacity(backgroundOpacity.clamp(0.0, 1.0).toDouble()),
      ]).createShader(const Rect.fromLTWH(0, 0, 500, 120));
    }
    if (backgroundShadowBlur > 0) {
      bgPaint.maskFilter = MaskFilter.blur(
          BlurStyle.normal, backgroundShadowBlur.clamp(0.0, 24.0).toDouble());
    }
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (shadow case final shadow?)
          ExcludeSemantics(
            child: _line(
              style.copyWith(
                foreground: Paint()..color = Colors.transparent,
                shadows: [shadow],
              ),
            ),
          ),
        // Keep the border wrapped around the actual shaped text glyphs.
        if (hasBg && backgroundBorderWidth > 0)
          _line(
            style.copyWith(
              shadows: const <Shadow>[],
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..strokeWidth = (backgroundExpansion
                                .clamp(0.0, 24.0)
                                .toDouble() +
                            backgroundBorderWidth.clamp(0.0, 6.0).toDouble()) *
                        2 +
                    2
                ..color = Colors.white70,
            ),
          ),
        if (hasBg)
          _line(
            style.copyWith(
              shadows: const <Shadow>[],
              foreground: bgPaint,
            ),
          ),
        if (outlineWidth > 0)
          _line(
            style.copyWith(
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
    required this.shadow,
    required this.direction,
    this.backgroundColor,
    this.backgroundOpacity = 0.8,
    this.backgroundExpansion = 0,
    this.backgroundGradient = false,
    this.backgroundShadowBlur = 0,
    this.backgroundBorderWidth = 0,
  });

  final String text;
  final TextStyle style;
  final double curve;
  final double outlineWidth;
  final Color outlineColor;
  final bool gradient;
  final Shadow? shadow;
  final TextDirection direction;
  final Color? backgroundColor;
  final double backgroundOpacity;
  final double backgroundExpansion;
  final bool backgroundGradient;
  final double backgroundShadowBlur;
  final double backgroundBorderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final logicalRuns = _curveRuns(text);
    // RTL is painted right-to-left while each word stays joined.
    final characters = direction == TextDirection.rtl
        ? logicalRuns.reversed.toList()
        : logicalRuns;
    final painters = <TextPainter>[];
    var totalWidth = 0.0;
    var tallest = 0.0;
    for (final char in characters) {
      final painter = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: direction,
      )..layout();
      painters.add(painter);
      totalWidth += painter.width;
      tallest = math.max(tallest, painter.height);
    }
    if (totalWidth == 0) {
      for (final p in painters) {
        p.dispose();
      }
      return;
    }
    final shader = gradient
        ? AdvancedTextOverlay._fill
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        : null;
    var cursor = (size.width - totalWidth) / 2;
    for (var i = 0; i < characters.length; i++) {
      final painter = painters[i];
      final mid = cursor + painter.width / 2;
      final normalized = ((mid - size.width / 2) / (totalWidth / 2))
          .clamp(-1.0, 1.0)
          .toDouble();
      final bend = curve * 55 * (1 - normalized * normalized);
      final angle = -curve * 110 * normalized / math.max(totalWidth, 1);
      final positionY = (size.height - tallest) / 2 - bend;
      canvas.save();
      canvas.translate(mid, positionY + painter.height / 2);
      canvas.rotate(angle);
      final origin = Offset(-painter.width / 2, -painter.height / 2);
      if (backgroundColor != null && backgroundOpacity > 0) {
        if (backgroundBorderWidth > 0) {
          final borderPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..strokeWidth = (backgroundExpansion.clamp(0.0, 24.0).toDouble() +
                        backgroundBorderWidth.clamp(0.0, 6.0).toDouble()) *
                    2 +
                2
            ..color = Colors.white70;
          final borderPainter = TextPainter(
            text: TextSpan(
                text: characters[i],
                style: style.copyWith(
                    shadows: const <Shadow>[], foreground: borderPaint)),
            textDirection: direction,
          )..layout();
          borderPainter.paint(canvas, origin);
          borderPainter.dispose();
        }
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth =
              backgroundExpansion.clamp(0.0, 24.0).toDouble() * 2 + 2
          ..color = backgroundColor!
              .withOpacity(backgroundOpacity.clamp(0.0, 1.0).toDouble());
        if (backgroundGradient) {
          paint.shader = LinearGradient(colors: [
            backgroundColor!
                .withOpacity(backgroundOpacity.clamp(0.0, 1.0).toDouble()),
            Color.lerp(backgroundColor!, Colors.purpleAccent, 0.55)!
                .withOpacity(backgroundOpacity.clamp(0.0, 1.0).toDouble()),
          ]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        }
        if (backgroundShadowBlur > 0) {
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal,
              backgroundShadowBlur.clamp(0.0, 24.0).toDouble());
        }
        final bgPainter = TextPainter(
          text: TextSpan(
              text: characters[i],
              style:
                  style.copyWith(shadows: const <Shadow>[], foreground: paint)),
          textDirection: direction,
        )..layout();
        bgPainter.paint(canvas, origin);
        bgPainter.dispose();
      }
      if (shadow case final shadow?) {
        final shadowPainter = TextPainter(
          text: TextSpan(
            text: characters[i],
            style: style.copyWith(
              foreground: Paint()..color = Colors.transparent,
              shadows: [shadow],
            ),
          ),
          textDirection: direction,
        )..layout();
        shadowPainter.paint(canvas, origin);
        shadowPainter.dispose();
      }
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
          textDirection: direction,
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
          textDirection: direction,
        )..layout();
        fill.paint(canvas, origin);
        fill.dispose();
      }
      canvas.restore();
      cursor += painter.width;
    }
    for (final p in painters) {
      p.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedTextPainter old) =>
      text != old.text ||
      style != old.style ||
      curve != old.curve ||
      outlineWidth != old.outlineWidth ||
      outlineColor != old.outlineColor ||
      gradient != old.gradient ||
      direction != old.direction ||
      shadow != old.shadow ||
      backgroundColor != old.backgroundColor ||
      backgroundOpacity != old.backgroundOpacity ||
      backgroundExpansion != old.backgroundExpansion ||
      backgroundGradient != old.backgroundGradient ||
      backgroundShadowBlur != old.backgroundShadowBlur ||
      backgroundBorderWidth != old.backgroundBorderWidth;
}
