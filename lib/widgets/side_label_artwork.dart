import 'dart:math' as math;
import 'dart:ui' show Shader;

import 'package:flutter/material.dart';

enum SideLabelStyle { crown, electric, garden, gold, alloy }

class SideLabelArtwork extends StatelessWidget {
  const SideLabelArtwork(this.id, {super.key});

  // These IDs are also stored in projects saved before the Canvas migration.
  final String id;
  static final _styles = {
    for (final side in ['A', 'B'])
      for (final style in SideLabelStyle.values)
        'assets/label_bars/${side.toLowerCase()}_side/${side}_Side_Style_${style.index + 1}.png':
            (side == 'A', style),
  };

  static bool supports(String id) => _styles.containsKey(id);

  @override
  Widget build(BuildContext context) {
    final design = _styles[id];
    if (design == null) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: SideLabelPainter(sideA: design.$1, style: design.$2),
    );
  }
}

class SideLabelPainter extends CustomPainter {
  const SideLabelPainter({required this.sideA, required this.style});

  final bool sideA;
  final SideLabelStyle style;

  static const _gold = Color(0xffffbd17);
  static const _cream = Color(0xffffffb0);
  static const _bronze = Color(0xff894201);
  static const _ink = Color(0xff080406);
  static const _goldStops = [0.0, .21, .39, .56, .77, 1.0];
  static const _goldColors = [
    _bronze,
    _gold,
    _cream,
    Color(0xffb27206),
    Color(0xffffe071),
    _bronze,
  ];

  Size get referenceSize => Size(
    sideA ? 637 : 634,
    const [106, 100, 102, 101, 109][style.index].toDouble(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final target = Alignment.center.inscribe(
      applyBoxFit(BoxFit.contain, referenceSize, size).destination,
      Offset.zero & size,
    );
    canvas.save();
    canvas.translate(target.left, target.top);
    canvas.scale(target.width / 640, target.height / 105);
    const rect = Rect.fromLTWH(0, 0, 640, 105);
    final corners = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(31),
    );
    final (base, edge, flare) = sideA
        ? switch (style) {
            SideLabelStyle.crown => (0xff5d0300, 0xffd11800, 0xffff5c0b),
            SideLabelStyle.electric => (0xff330306, 0xffb30012, 0xffff1743),
            SideLabelStyle.garden => (0xff49010e, 0xffac0020, 0xffff305d),
            SideLabelStyle.gold => (0xff242320, 0xffa36102, 0xffffcb3e),
            SideLabelStyle.alloy => (0xff500407, 0xffaf0012, 0xffff223a),
          }
        : switch (style) {
            SideLabelStyle.crown => (0xff042800, 0xff236604, 0xff85c21e),
            SideLabelStyle.electric => (0xff00262e, 0xff00757c, 0xff08ffe2),
            SideLabelStyle.garden => (0xff00361c, 0xff117600, 0xff9df12d),
            SideLabelStyle.gold => (0xff0c2118, 0xffa46a03, 0xffffcd44),
            SideLabelStyle.alloy => (0xff001e42, 0xff006693, 0xff00dbff),
          };
    final body = Color(base), rim = Color(edge), light = Color(flare);
    canvas.clipRRect(corners);
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(
        colors: [rim, body, _ink, body, rim],
        stops: const [0, .18, .5, .81, 1],
      ).createShader(rect),
    );
    canvas.drawPath(
      _polygon(const [0, 17, 182, 17, 229, 47, 434, 47, 492, 12, 640, 12, 640, 0, 0, 0]),
      Paint()..color = body.withAlpha(114),
    );
    canvas.drawPath(
      _polygon(const [124, 105, 187, 59, 456, 59, 525, 105]),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [body, style == SideLabelStyle.gold ? Colors.black : _ink.withAlpha(165)],
      ).createShader(const Rect.fromLTWH(0, 59, 640, 46)),
    );

    switch (style) {
      case SideLabelStyle.crown:
        _crownBanner(canvas, rect, rim);
      case SideLabelStyle.electric:
        _ends(canvas, (end) => _electric(end, rim, light));
      case SideLabelStyle.garden:
        _ends(canvas, (end) {
          if (sideA) {
            _hearts(end);
          } else {
            _leaves(end);
          }
        });
      case SideLabelStyle.gold:
        _ends(canvas, (end) => _metal(end, light, gold: true));
      case SideLabelStyle.alloy:
        _ends(canvas, (end) => _metal(end, light, gold: false));
    }

    final accent = switch (style) {
      SideLabelStyle.gold || SideLabelStyle.crown => _gold,
      _ => light,
    };
    canvas.drawRRect(
      corners.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = LinearGradient(
          colors: [rim, accent, Colors.white, accent, rim],
          stops: const [0, .2, .5, .8, 1],
        ).createShader(rect),
    );
    // Narrow reflected highlights along the upper and lower bevel.
    for (final (x, y, width) in [(344.0, 3.0, 104.0), (236.0, 101.0, 66.0)]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width, height: 7),
        Paint()
          ..color = accent.withAlpha(175)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.restore();
  }

  Path _polygon(List<double> coordinates, {bool close = true}) {
    final path = Path()..moveTo(coordinates[0], coordinates[1]);
    for (var i = 2; i < coordinates.length; i += 2) {
      path.lineTo(coordinates[i], coordinates[i + 1]);
    }
    if (close) path.close();
    return path;
  }

  Shader _goldShader(Rect bounds) => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _goldColors,
    stops: _goldStops,
  ).createShader(bounds);

  void _ends(Canvas canvas, void Function(Canvas) draw) {
    draw(canvas);
    canvas.save();
    canvas.translate(640, 0);
    canvas.scale(-1, 1);
    draw(canvas);
    canvas.restore();
  }

  void _crownBanner(Canvas canvas, Rect rect, Color rim) {
    final band = _polygon(const [
      52, 1, 565, 1, 614, 51, 568, 104, 51, 104, 12, 51,
    ]);
    canvas.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = _goldShader(rect),
    );
    canvas.drawPath(
      _polygon(const [
        569, 0, 589, 0, 639, 54, 601, 105, 522, 105, 536, 91, 582, 91, 622, 53,
      ]),
      Paint()..shader = _goldShader(const Rect.fromLTWH(540, 4, 100, 100)),
    );
    canvas.drawPath(
      _polygon(const [0, 71, 18, 71, 33, 87, 92, 87, 111, 105, 0, 105]),
      Paint()..shader = _goldShader(const Rect.fromLTWH(0, 68, 113, 37)),
    );
    final shine = Rect.fromCircle(center: const Offset(123, 56), radius: 46);
    canvas.drawRect(
      shine,
      Paint()..shader = RadialGradient(colors: [rim, Colors.transparent]).createShader(shine),
    );
    final crown = _polygon(const [
      89, 72, 80, 36, 102, 53, 102, 31, 111, 52, 125, 14,
      136, 51, 150, 29, 149, 54, 169, 36, 155, 74,
    ]);
    const crownRect = Rect.fromLTWH(80, 14, 90, 70);
    canvas.drawPath(crown, Paint()..shader = _goldShader(crownRect));
    canvas.drawPath(
      crown,
      Paint()..color = _cream..strokeWidth = 1.2..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      _polygon(const [101, 71, 125, 20, 143, 70]),
      Paint()..shader = _goldShader(const Rect.fromLTWH(105, 60, 44, 12)),
    );
    for (final tip in const [
      Offset(80, 36), Offset(102, 31), Offset(125, 14),
      Offset(150, 29), Offset(169, 36),
    ]) {
      canvas.drawCircle(tip, 3.7, Paint()..shader = _goldShader(Rect.fromCircle(center: tip, radius: 4)));
    }
    final foot = Rect.fromCenter(center: const Offset(122, 79), width: 72, height: 13);
    canvas.drawOval(foot, Paint()..shader = _goldShader(foot));
    for (final x in [105.0, 122.0, 140.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 68), width: 6, height: 8),
        Paint()..color = const Color(0xff643500));
    }
  }

  void _electric(Canvas canvas, Color rim, Color light) {
    canvas.drawPath(
      _polygon(const [0, 0, 63, 0, 28, 52, 72, 105, 0, 105]),
      Paint()..shader = LinearGradient(colors: [rim, light, rim]).createShader(const Rect.fromLTWH(0, 11, 70, 80)),
    );
    for (final x in [43.0, 62.0]) {
      final ray = _polygon([x, 26, x - 24, 52, x, 79], close: false);
      canvas.drawPath(ray, Paint()
        ..color = light..strokeWidth = 13..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawPath(ray, Paint()
        ..color = light..strokeWidth = 7..style = PaintingStyle.stroke);
      canvas.drawPath(ray, Paint()
        ..color = const Color(0xffffeeee)..strokeWidth = 2..style = PaintingStyle.stroke);
    }
    final random = math.Random(235);
    for (var branch = 0; branch < 13; branch++) {
      final y = 9 + random.nextDouble() * 87;
      final x = 65 + random.nextDouble() * 79;
      final crack = _polygon([x, y, x + 14, y - 4, x + 21, y + 1, x + 48, y - 3], close: false);
      canvas.drawPath(crack, Paint()
        ..color = light.withAlpha(branch % 3 == 0 ? 125 : 44)
        ..style = PaintingStyle.stroke..strokeWidth = 1);
    }
  }

  void _hearts(Canvas canvas) {
    for (final (x, y, radius) in [(30.0, 76.0, 20.0), (58.0, 38.0, 19.0), (79.0, 21.0, 11.0)]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-.24);
      canvas.scale(radius);
      final heart = Path()
        ..moveTo(0, .87)
        ..cubicTo(-2, -.44, -.7, -1.41, 0, -.54)
        ..cubicTo(.7, -1.41, 2, -.44, 0, .87)..close();
      canvas.drawPath(heart, Paint()
        ..color = const Color(0xffff184a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .28));
      canvas.drawPath(heart, Paint()..shader = const RadialGradient(
        center: Alignment(-.33, -.48),
        colors: [Color(0xffffe2bf), Color(0xffff647c), Color(0xffed0034)],
      ).createShader(const Rect.fromLTWH(-1, -1, 2, 2)));
      canvas.restore();
    }
  }

  void _leaves(Canvas canvas) {
    final random = math.Random(783);
    for (var i = 0; i < 20; i++) {
      final x = 11 + random.nextDouble() * (147 - i * 4);
      final y = 13.0 + i * 4.3;
      final angle = random.nextDouble() * 2.4 - 1.35;
      final length = 16 + random.nextDouble() * 17;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-13, -length * .5, 1, -length)
        ..quadraticBezierTo(15, -length * .48, 0, 0)..close();
      canvas.drawPath(leaf, Paint()..shader = const LinearGradient(
        colors: [Color(0xff205900), Color(0xffb5eb28), Color(0xff459600)],
      ).createShader(Rect.fromLTWH(-9, -length, 19, length)));
      canvas.drawLine(Offset.zero, Offset(1, -length + 4), Paint()..color = const Color(0x99ebff89));
      canvas.restore();
    }
    for (var i = 0; i < 5; i++) {
      final bounds = Rect.fromCenter(center: Offset(112 + (i % 3) * 5, 85 + i * 3), width: 12, height: 6);
      canvas.drawOval(bounds, Paint()..color = const Color(0xfffcb47c));
    }
  }

  void _metal(Canvas canvas, Color light, {required bool gold}) {
    final shape = gold
        ? _polygon(const [0, 0, 38, 0, 123, 105, 0, 105])
        : _polygon(const [0, 0, 59, 0, 25, 52, 47, 105, 24, 105, 0, 52]);
    const bounds = Rect.fromLTWH(0, 0, 155, 105);
    final shader = gold
        ? _goldShader(bounds)
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xff485660), Colors.white, Color(0xff697279)],
          ).createShader(bounds);
    canvas.drawPath(shape, Paint()..shader = shader);
    final accent = gold
        ? _polygon(const [19, 0, 111, 105], close: false)
        : _polygon(const [40, 1, 10, 51, 31, 104], close: false);
    canvas.drawPath(accent, Paint()
      ..color = gold ? const Color(0xd9301e05) : light
      ..style = PaintingStyle.stroke..strokeWidth = gold ? 6 : 4);
    final random = math.Random(630);
    for (var i = 0; i < 540; i++) {
      final y = 6 + random.nextDouble() * 92;
      final center = gold ? 55 + y * .58 : 63 + (53 - (y - 53).abs()) * .33;
      final x = center + (random.nextDouble() - .24) * 77;
      final opacity = 28 + random.nextInt(179);
      canvas.drawCircle(Offset(x, y), .38 + random.nextDouble() * 1.35,
        Paint()..color = (gold && i.isEven ? _ink : light).withAlpha(opacity));
    }
  }

  @override
  bool shouldRepaint(SideLabelPainter oldDelegate) =>
      sideA != oldDelegate.sideA || style != oldDelegate.style;
}
