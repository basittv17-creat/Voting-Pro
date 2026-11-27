import 'package:flutter/material.dart';

/// Presets are keyed by stable names in saved projects.
const premiumTextBackgrounds = <String, (int, int, int, double)>{
  'Royal Gold': (0xFF211604, 0xFF6A420E, 0xFFF7CB56, 7),
  'Black & Gold': (0xFF08090B, 0xFF28231A, 0xFFFFD46B, 4),
  'Mint Neon': (0xFF002D2A, 0xFF00776D, 0xFF64FFDA, 14),
  'Blue Neon': (0xFF031536, 0xFF17466F, 0xFF50CFFF, 12),
  'Fire': (0xFF440D1D, 0xFF9A3915, 0xFFFF9A53, 5),
  'Metallic Silver': (0xFF263340, 0xFF536B7D, 0xFFDCE9F4, 6),
  'Emerald': (0xFF092926, 0xFF1B6043, 0xFF7DDEA2, 9),
  'Rose Ceremony': (0xFF482137, 0xFF78425F, 0xFFFFBBCA, 14),
  'Rally Red': (0xFF5E1022, 0xFFA02032, 0xFFFFC891, 4),
  'Tagra Muqabla': (0xFF522407, 0xFF883D10, 0xFFFFE263, 8),
  'Gold Ribbon': (0xFF52350B, 0xFF8B5413, 0xFFFFDC86, 20),
  'Violet Glass': (0xFF1D144A, 0xFF4D2A73, 0xFFC6A7FF, 16),
  'Calligraphy Panel': (0xFF152534, 0xFF294658, 0xFF9EC8B5, 3),
  'Nastaliq Nameplate': (0xFF2F1726, 0xFF64384B, 0xFFD8AD88, 7),
  'Sapphire Seal': (0xFF112149, 0xFF23366F, 0xFFD1CDFF, 20),
  'Copper Patina': (0xFF173C3C, 0xFF2F5A4E, 0xFFE4A470, 4),
};

class TextBackgroundPlate extends StatelessWidget {
  const TextBackgroundPlate({
    super.key,
    required this.child,
    required this.color,
    this.design,
    this.opacity = .85,
    this.padding = 6,
    this.radius = 8,
    this.borderWidth = 0,
    this.shadowBlur = 0,
    this.gradient = false,
  });

  final Widget child;
  final Color color;
  final String? design;
  final double opacity, padding, radius, borderWidth, shadowBlur;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final preset = premiumTextBackgrounds[design];
    final alpha = opacity.clamp(0.0, 1.0);
    final second = preset == null
        ? Color.lerp(color, Colors.purpleAccent, .55)!
        : Color(preset.$2);
    final stroke = preset == null ? Colors.white70 : Color(preset.$3);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        gradient: gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: alpha),
                  second.withValues(alpha: alpha),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(radius.clamp(0, 32)),
        border: borderWidth > 0
            ? Border.all(
                color: stroke.withValues(alpha: alpha),
                width: borderWidth.clamp(0, 6),
              )
            : null,
        boxShadow: shadowBlur <= 0 || alpha == 0
            ? null
            : [
                BoxShadow(
                  color: stroke.withValues(alpha: alpha * .4),
                  blurRadius: shadowBlur,
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding.clamp(0, 24)),
        child: child,
      ),
    );
  }
}

/// Constrains the measured artwork, not its invisible editing touch margin.
class TextCanvasPlacement extends SingleChildLayoutDelegate {
  const TextCanvasPlacement(this.anchor, this.touchInset);

  final Offset anchor;
  final double touchInset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  double _axis(double position, double extent, double childExtent) {
    final last = (extent - childExtent + touchInset)
        .clamp(-touchInset, double.infinity)
        .toDouble();
    return (position - touchInset).clamp(-touchInset, last).toDouble();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
        _axis(anchor.dx, size.width, childSize.width),
        _axis(anchor.dy, size.height, childSize.height),
      );

  @override
  bool shouldRelayout(TextCanvasPlacement oldDelegate) =>
      anchor != oldDelegate.anchor || touchInset != oldDelegate.touchInset;
}

/// Keeps editing controls inside the canvas independently of the artwork.
class TextHandlePlacement extends SingleChildLayoutDelegate {
  const TextHandlePlacement({
    required this.placement,
    required this.canvasSize,
    required this.alignment,
    this.margin = 0,
  });

  final TextCanvasPlacement placement;
  final Size canvasSize;
  final Alignment alignment;
  final double margin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final origin = placement.getPositionForChild(canvasSize, size);
    final desired = origin +
        alignment
            .inscribe(childSize, (Offset.zero & size).deflate(margin))
            .topLeft;
    final x = desired.dx
        .clamp(0.0, (canvasSize.width - childSize.width).clamp(0.0, double.infinity))
        .toDouble();
    final y = desired.dy
        .clamp(0.0, (canvasSize.height - childSize.height).clamp(0.0, double.infinity))
        .toDouble();
    return Offset(x, y) - origin;
  }

  @override
  bool shouldRelayout(TextHandlePlacement oldDelegate) =>
      placement.shouldRelayout(oldDelegate.placement) ||
      canvasSize != oldDelegate.canvasSize ||
      alignment != oldDelegate.alignment ||
      margin != oldDelegate.margin;
}
