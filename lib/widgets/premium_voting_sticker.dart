import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fully code-rendered voting emblems. No voting-sticker image file is used.
@immutable
class VotingStickerDesign {
  const VotingStickerDesign(
    this.id,
    this.name,
    this.glyph,
    this.start,
    this.end,
  );

  final String id;
  final String name;
  final String glyph;
  final Color start;
  final Color end;
}

class VotingStickerCatalog {
  VotingStickerCatalog._();

  static const designs = <VotingStickerDesign>[
    VotingStickerDesign('vector:lion', 'Lion King', '🦁',
        Color(0xFFFFAD22), Color(0xFF9C3100)),
    VotingStickerDesign('vector:cheetah', 'Royal Cheetah', '🐆',
        Color(0xFFFFCF5A), Color(0xFF91501B)),
    VotingStickerDesign('vector:tiger', 'Tiger Champion', '🐯',
        Color(0xFFFF7C22), Color(0xFFB51A05)),
    VotingStickerDesign('vector:elephant', 'Royal Elephant', '🐘',
        Color(0xFF8ED7E7), Color(0xFF25598C)),
    VotingStickerDesign('vector:eagle', 'Victory Eagle', '🦅',
        Color(0xFFFFDD6C), Color(0xFF976C12)),
    VotingStickerDesign('vector:wolf', 'Silver Wolf', '🐺',
        Color(0xFFCEEBFF), Color(0xFF43729B)),
    VotingStickerDesign('vector:panther', 'Black Panther', '🐈‍⬛',
        Color(0xFFCBA0FF), Color(0xFF552BA1)),
    VotingStickerDesign('vector:bear', 'Royal Bear', '🐻',
        Color(0xFFDDA977), Color(0xFF713E2E)),
    VotingStickerDesign('vector:cobra', 'Cobra Strike', '🐍',
        Color(0xFF7EF4A5), Color(0xFF007F53)),
    VotingStickerDesign('vector:swords', 'Victory Swords', '⚔️',
        Color(0xFFF4F4FF), Color(0xFF6471AF)),
    VotingStickerDesign('vector:horse', 'Royal Horse', '🐎',
        Color(0xFFFFDA9F), Color(0xFF925326)),
    VotingStickerDesign('vector:falcon', 'Golden Falcon', '🦅',
        Color(0xFFFFED9A), Color(0xFFA9620E)),
    VotingStickerDesign('vector:crown', 'King Crown', '👑',
        Color(0xFFFFEE83), Color(0xFFC48A13)),
    VotingStickerDesign('vector:trophy', 'Victory Trophy', '🏆',
        Color(0xFFFFD85E), Color(0xFFAC6014)),
    VotingStickerDesign('vector:thunder', 'Thunder Power', '⚡',
        Color(0xFF81DBFF), Color(0xFF2150C3)),
    VotingStickerDesign('vector:shield', 'Royal Shield', '🛡️',
        Color(0xFF8BF6E6), Color(0xFF087D8E)),
  ];

  static VotingStickerDesign? find(String? id) {
    for (final design in designs) {
      if (design.id == id) return design;
    }
    return null;
  }

  /// Old poster snapshots stored an asset pathname. Map these to stable IDs
  /// BEFORE legacy PNGs are retired, retaining both A/B sticker selections.
  static String? migrate(String? stored) {
    if (stored == null) return null;
    if (find(stored) != null) return stored;
    const legacy = [
      '01_lion.png',
      '02_cheetah.png',
      '03_tiger.png',
      '04_elephant.png',
      '05_eagle.png',
      '06_wolf.png',
      '07_panther.png',
      '08_bear.png',
      '09_cobra.png',
      '10_crossed_swords.png',
    ];
    for (var i = 0; i < legacy.length; i++) {
      if (stored == 'assets/voting_stickers/' + legacy[i]) {
        return designs[i].id;
      }
    }
    return null;
  }
}

/// Consistent code-based badge used in both the poster and the picker.
/// Vector rings, crown and ornaments scale smoothly; a device font draws the
/// familiar animal/symbol glyph without shipping any voting-sticker PNG.
class PremiumVotingSticker extends StatelessWidget {
  const PremiumVotingSticker({
    super.key,
    required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    final design = VotingStickerCatalog.find(id);
    if (design == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: size.isFinite ? size : 42,
            child: CustomPaint(painter: _VotingBadgePainter(design)),
          ),
        );
      },
    );
  }
}

class _VotingBadgePainter extends CustomPainter {
  const _VotingBadgePainter(this.design);

  final VotingStickerDesign design;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 100, side / 100);

    // Layer 1: twelve gold foil peaks behind a dark enamel medallion.
    final star = Path();
    for (var i = 0; i < 32; i++) {
      final angle = i * math.pi / 16 - math.pi / 2;
      final radius = i.isEven ? 49.0 : 43.0;
      final x = 50 + radius * math.cos(angle);
      final y = 52 + radius * math.sin(angle);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    canvas.drawShadow(star, design.start.withOpacity(0.8), 6, true);
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8BD),
            Color(0xFFFFC940),
            Color(0xFF87460E),
            Color(0xFFFFED91),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    canvas.drawCircle(
      const Offset(50, 52),
      42,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.4),
          radius: 1.1,
          colors: [
            design.start.withOpacity(0.95),
            design.end,
            const Color(0xFF070E22),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(const Rect.fromLTWH(8, 10, 84, 84)),
    );
    canvas.drawCircle(
      const Offset(50, 52),
      40,
      Paint()
        ..color = const Color(0xFFF7DE86)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      const Offset(50, 52),
      35.5,
      Paint()
        ..color = const Color(0xAAFFFFFF)
        ..strokeWidth = 0.55
        ..style = PaintingStyle.stroke,
    );

    // Layer 2: tiny rays and gold pinpoints add depth at sticker scale.
    for (var i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) - math.pi / 2;
      final start = Offset(
        50 + 36 * math.cos(angle),
        52 + 36 * math.sin(angle),
      );
      final end = Offset(
        50 + 40 * math.cos(angle),
        52 + 40 * math.sin(angle),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFDE5A1)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Layer 3: large recognizable emblem, framed by the metallic rings.
    final icon = TextPainter(
      text: TextSpan(
        text: design.glyph,
        style: const TextStyle(
          fontSize: 47,
          height: 1.0,
          shadows: [
            Shadow(
              color: Color(0xCC080B20),
              blurRadius: 5,
              offset: Offset(1, 3),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 85);
    icon.paint(canvas, Offset(
      50 - icon.width / 2,
      50 - icon.height / 2 + 7,
    ));

    // Layer 4: a three-point crown drawn in paths, not raster artwork.
    final crown = Path()
      ..moveTo(31, 28)
      ..lineTo(28, 11)
      ..lineTo(40, 17)
      ..lineTo(50, 6)
      ..lineTo(60, 17)
      ..lineTo(72, 11)
      ..lineTo(69, 28)
      ..close();
    canvas.drawShadow(crown, Colors.black, 2, true);
    canvas.drawPath(
      crown,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF9C9),
            Color(0xFFFFCE40),
            Color(0xFFB16A13),
          ],
        ).createShader(const Rect.fromLTWH(26, 4, 48, 27)),
    );
    canvas.drawPath(
      crown,
      Paint()
        ..color = const Color(0xFFFFF1AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    for (final point in [
      const Offset(28, 11),
      const Offset(50, 6),
      const Offset(72, 11),
    ]) {
      canvas.drawCircle(point, 2.1, Paint()..color = Colors.white);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 26, 40, 6),
        const Radius.circular(1.8),
      ),
      Paint()..color = const Color(0xFF9D5B11),
    );
    canvas.drawLine(
      const Offset(32, 27),
      const Offset(68, 27),
      Paint()
        ..color = const Color(0xFFFFF0A7)
        ..strokeWidth = 1.3,
    );

    // Layer 5: tiny light-reflection highlights.
    for (final dot in [
      const Offset(14, 52),
      const Offset(86, 52),
      const Offset(50, 92),
    ]) {
      canvas.drawCircle(dot, 1.9, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VotingBadgePainter oldDelegate) =>
      oldDelegate.design.id != design.id;
}
