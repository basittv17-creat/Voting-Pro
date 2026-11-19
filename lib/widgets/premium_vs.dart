import 'package:flutter/material.dart';

enum _Accent {
  crown,
  flame,
  rails,
  chevrons,
  bolt,
  crystal,
  spectrum,
  shine,
  rays,
  crest,
}

class VsStyleDefinition {
  const VsStyleDefinition._(
    this.name,
    this.palette,
    this.edge,
    this.depth,
    this.light,
    this._accent, {
    this.bevel = 2,
    this.extrusion = 4,
    this.glow = 4,
  });

  final String name;
  final List<Color> palette;
  final Color edge;
  final Color depth;
  final Color light;
  final _Accent _accent;
  final double bevel;
  final int extrusion;
  final double glow;

  static const styles = [
    VsStyleDefinition._(
      'Royal Gold',
      [
        Color(0xfffff5b5),
        Color(0xfff8bf31),
        Color(0xff885005),
        Color(0xffffd853),
      ],
      Color(0xff482504),
      Color(0xff794005),
      Color(0xffffe289),
      _Accent.crown,
      extrusion: 6,
    ),
    VsStyleDefinition._(
      'Fire',
      [
        Color(0xffffffe1),
        Color(0xffffbe25),
        Color(0xfff64017),
        Color(0xffa71215),
      ],
      Color(0xff55080b),
      Color(0xff8b1615),
      Color(0xffff8a28),
      _Accent.flame,
      glow: 7,
    ),
    VsStyleDefinition._(
      'Blue Neon',
      [
        Color(0xffedffff),
        Color(0xff6cffff),
        Color(0xff229bff),
        Color(0xff3048dc),
      ],
      Color(0xff101b77),
      Color(0xff1129a4),
      Color(0xff43e8ff),
      _Accent.rails,
      glow: 8,
    ),
    VsStyleDefinition._(
      'Green Neon',
      [
        Color(0xfff4ffd2),
        Color(0xffc2ff31),
        Color(0xff3ff55e),
        Color(0xff159c60),
      ],
      Color(0xff153d21),
      Color(0xff166334),
      Color(0xffb6ff5e),
      _Accent.chevrons,
      bevel: 3,
      glow: 6,
    ),
    VsStyleDefinition._(
      'Electric',
      [
        Color(0xffc6fdff),
        Color(0xff705fff),
        Color(0xffd328f0),
        Color(0xffff97f6),
      ],
      Color(0xff401065),
      Color(0xff432098),
      Color(0xff79efff),
      _Accent.bolt,
      glow: 7,
    ),
    VsStyleDefinition._(
      'Diamond',
      [
        Color(0xffffffff),
        Color(0xffafddeb),
        Color(0xff375b83),
        Color(0xfff4feff),
      ],
      Color(0xff283b56),
      Color(0xff476785),
      Color(0xffd6f9ff),
      _Accent.crystal,
      extrusion: 6,
    ),
    VsStyleDefinition._(
      'Rainbow',
      [
        Color(0xffffdd58),
        Color(0xffff5272),
        Color(0xffad75ff),
        Color(0xff48d7ff),
        Color(0xff8cffa7),
      ],
      Color(0xff29144e),
      Color(0xff58235d),
      Color(0xffffbafb),
      _Accent.spectrum,
      bevel: 2.5,
    ),
    VsStyleDefinition._(
      'Luxury',
      [
        Color(0xfffff0d6),
        Color(0xffd7aa75),
        Color(0xff825239),
        Color(0xffffd5a3),
      ],
      Color(0xff422219),
      Color(0xff604132),
      Color(0xffeac7a2),
      _Accent.shine,
      extrusion: 3,
      glow: 2,
    ),
    VsStyleDefinition._(
      'Golden Glow',
      [
        Color(0xffffffec),
        Color(0xffffe861),
        Color(0xffffa211),
        Color(0xffffd455),
      ],
      Color(0xff794205),
      Color(0xffab5509),
      Color(0xffffbf2e),
      _Accent.rays,
      glow: 10,
    ),
    VsStyleDefinition._(
      'Black & Gold',
      [
        Color(0xff697386),
        Color(0xff2b303b),
        Color(0xff090b12),
        Color(0xff30343d),
      ],
      Color(0xff402404),
      Color(0xff291a10),
      Color(0xfff9ca58),
      _Accent.crest,
      bevel: 4,
      extrusion: 6,
      glow: 3,
    ),
  ];

  static VsStyleDefinition fromName(String name) => styles.firstWhere(
        (style) => style.name == name,
        orElse: () => styles.first,
      );
}

class PremiumVsRenderer extends StatelessWidget {
  const PremiumVsRenderer({super.key, required this.style, this.width = 88});

  final VsStyleDefinition style;
  final double width;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(width, width * 0.64), painter: _VsPainter(style));
}

class _VsPainter extends CustomPainter {
  const _VsPainter(this.style);

  final VsStyleDefinition style;
  static final Path _letters = Path()
    ..moveTo(19, 15)
    ..lineTo(30, 15)
    ..lineTo(34, 42)
    ..lineTo(48, 15)
    ..lineTo(60, 15)
    ..lineTo(38, 51)
    ..lineTo(26, 51)
    ..close()
    ..moveTo(66, 15)
    ..lineTo(89, 15)
    ..lineTo(86, 24)
    ..lineTo(69, 24)
    ..lineTo(67, 28)
    ..lineTo(81, 31)
    ..lineTo(84, 36)
    ..lineTo(80, 46)
    ..lineTo(73, 51)
    ..lineTo(49, 51)
    ..lineTo(53, 42)
    ..lineTo(71, 42)
    ..lineTo(73, 38)
    ..lineTo(59, 35)
    ..lineTo(55, 30)
    ..lineTo(59, 21)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 64);
    _paintAccent(canvas);
    canvas.drawPath(
      _letters,
      Paint()
        ..color = style.light.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.glow),
    );
    final outline = Paint()
      ..color = style.edge
      ..strokeWidth = style.bevel + 3
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final depth = Paint()..color = style.depth;
    for (var step = style.extrusion; step > 0; step--) {
      canvas.save();
      canvas.translate(-step * 0.45, step.toDouble());
      if (step == style.extrusion) canvas.drawPath(_letters, outline);
      canvas.drawPath(_letters, depth);
      canvas.restore();
    }
    canvas.drawPath(_letters, outline);
    canvas.drawPath(
      _letters,
      Paint()
        ..shader = LinearGradient(
          colors: [style.light, style.depth, style.light],
        ).createShader(const Rect.fromLTWH(18, 14, 72, 38))
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = style.bevel,
    );
    canvas.drawPath(
      _letters,
      Paint()
        ..shader = LinearGradient(
          begin: style._accent == _Accent.spectrum
              ? Alignment.topLeft
              : Alignment.topCenter,
          end: style._accent == _Accent.spectrum
              ? Alignment.bottomRight
              : Alignment.bottomCenter,
          colors: style.palette,
        ).createShader(const Rect.fromLTWH(19, 15, 70, 36)),
    );
    canvas.drawLine(
      const Offset(21, 16),
      const Offset(28, 16),
      Paint()..color = style.light,
    );
    canvas.drawLine(
      const Offset(67, 16),
      const Offset(86, 16),
      Paint()..color = style.light,
    );
    canvas.restore();
  }

  void _paintAccent(Canvas canvas) {
    final line = Paint()
      ..color = style.light.withValues(alpha: 0.74)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    void trace(List<Offset> points) {
      canvas.drawPath(Path()..addPolygon(points, false), line);
    }

    void sparkle(double x, double y, double radius) {
      trace([Offset(x - radius, y), Offset(x + radius, y)]);
      trace([Offset(x, y - radius), Offset(x, y + radius)]);
    }

    switch (style._accent) {
      case _Accent.crown:
        trace(const [
          Offset(36, 11),
          Offset(33, 5),
          Offset(41, 8),
          Offset(48, 3),
          Offset(54, 8),
          Offset(62, 5),
          Offset(59, 11),
          Offset(36, 11),
        ]);
      case _Accent.flame:
        trace(const [
          Offset(14, 47),
          Offset(8, 39),
          Offset(16, 25),
          Offset(17, 34),
          Offset(22, 30),
        ]);
        trace(const [
          Offset(87, 45),
          Offset(95, 34),
          Offset(94, 24),
          Offset(89, 30),
          Offset(90, 21),
        ]);
      case _Accent.rails:
        trace(const [Offset(7, 26), Offset(16, 13), Offset(36, 13)]);
        trace(const [Offset(69, 55), Offset(87, 55), Offset(96, 42)]);
      case _Accent.chevrons:
        trace(const [Offset(14, 19), Offset(7, 29), Offset(13, 44)]);
        trace(const [Offset(94, 21), Offset(98, 34), Offset(90, 48)]);
      case _Accent.bolt:
        trace(const [
          Offset(59, 4),
          Offset(42, 21),
          Offset(54, 19),
          Offset(42, 41),
          Offset(58, 31),
          Offset(46, 60),
        ]);
        sparkle(88, 8, 4);
      case _Accent.crystal:
        sparkle(15, 11, 5);
        sparkle(89, 50, 7);
        sparkle(78, 8, 3);
      case _Accent.spectrum:
        for (var i = 0; i < style.palette.length; i++) {
          line.color = style.palette[i];
          canvas.drawLine(Offset(10 + i * 8, 57), Offset(15 + i * 8, 57), line);
        }
      case _Accent.shine:
        sparkle(80, 11, 4);
        trace(const [
          Offset(20, 56),
          Offset(35, 59),
          Offset(69, 59),
          Offset(80, 56),
        ]);
      case _Accent.rays:
        for (var i = 0; i < 4; i++) {
          final x = 32.0 + i * 11;
          canvas.drawLine(Offset(x, 10), Offset(x + (i - 1.5) * 3, 4), line);
        }
        sparkle(91, 49, 5);
      case _Accent.crest:
        trace(const [
          Offset(12, 13),
          Offset(49, 5),
          Offset(94, 13),
          Offset(87, 47),
          Offset(49, 60),
          Offset(17, 51),
          Offset(12, 13),
        ]);
    }
  }

  @override
  bool shouldRepaint(_VsPainter oldDelegate) => style != oldDelegate.style;
}
