import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PhotoScene {
  arena('Neon arena', 'نیون میدان', 0xff102954, 0xffeb4276),
  cage('Steel cage', 'فولادی جالی', 0xff233e59, 0xff50adce),
  football('Football stadium', 'فٹ بال اسٹیڈیم', 0xff12283c, 0xff399e62),
  throne('Royal throne stage', 'شاہی دربار', 0xff321627, 0xffe5b95d),
  lightning('Electric clash', 'بجلی کی چمک', 0xff191e4c, 0xff8ddfff),
  duel('Neon duel stage', 'نیون مقابلہ', 0xff182449, 0xfffc579e),
  stone('Cracked energy stone', 'روشن دراڑیں', 0xff293643, 0xff45cafc),
  boxing('Boxing arena', 'باکسنگ رنگ', 0xff162c46, 0xffdf5559),
  metal('Black gold metal', 'سیاہ اور سنہری دھات', 0xff222426, 0xffcaa75a),
  sunset('Sunset skyline', 'شہر کا غروبِ آفتاب', 0xff703753, 0xfff3a353),
  studio('Luxury gold studio', 'سنہری اسٹوڈیو', 0xff302920, 0xffefd492),
  ice('Fire and ice', 'آگ اور برف', 0xff1c335a, 0xffff814d),
  racing('Racing storm', 'طوفانی ریس', 0xff323848, 0xffc7d8e7),
  pakistan('Pakistan spirit', 'پاکستان کی شان', 0xff073d32, 0xff91d4af),
  victory('Golden victory', 'سنہری فتح', 0xff80452d, 0xffffce70),
  cricket('Cricket stadium', 'کرکٹ اسٹیڈیم', 0xff153d46, 0xff8cb757),
  alpine('Alpine peaks', 'برفانی چوٹیاں', 0xff527796, 0xffd9f3fa),
  city('Neon city', 'نیون شہر', 0xff251d53, 0xffdc69db),
  fortress('Historic fortress', 'تاریخی قلعہ', 0xff805a49, 0xffebbd78),
  tunnel('Purple neon tunnel', 'جامنی نیون سرنگ', 0xff251a4d, 0xffe764ff);

  const PhotoScene(this.en, this.ur, this.base, this.light);
  final String en, ur;
  final int base, light;
  String get id => 'scene-$name';
  static final byId = {for (final scene in values) scene.id: scene};
}

class PhotoSceneArt extends StatelessWidget {
  const PhotoSceneArt(this.scene, {super.key, required this.sideA});
  final PhotoScene scene;
  final bool sideA;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _ScenePainter(scene, sideA),
      size: Size.infinite,
    ),
  );
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene, this.sideA);
  final PhotoScene scene;
  final bool sideA;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final scale = math.max(size.width / 100, size.height / 140);
    canvas.translate(size.width / 2, size.height / 2);
    // Preserve the crescent/star orientation on both sides. Other scenes
    // can mirror their composition to frame the opposing portrait.
    canvas.scale(sideA || scene == PhotoScene.pakistan ? scale : -scale, scale);
    canvas.translate(-50, -70);
    const bounds = Rect.fromLTWH(0, 0, 100, 140);
    final base = Color(scene.base);
    final light = !sideA && const {
      PhotoScene.arena,
      PhotoScene.cage,
      PhotoScene.lightning,
      PhotoScene.duel,
      PhotoScene.stone,
    }.contains(scene) ? const Color(0xff55c8ff) : Color(scene.light);
    final shadow = Color.lerp(base, Colors.black, .67)!;
    final paint = Paint();
    canvas.drawRect(
      bounds,
      paint
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base, shadow],
          stops: const [0, .52, 1],
        ).createShader(bounds),
    );
    paint.shader = RadialGradient(
      center: const Alignment(0, -.55),
      radius: .85,
      colors: [light.withAlpha(55), Colors.transparent],
    ).createShader(bounds);
    canvas.drawRect(bounds, paint);
    paint.shader = null;
    final rng = math.Random(403 + scene.index);
    void line(num x, num y, num u, num v, Color c, [double w = 1]) {
      canvas.drawLine(
        Offset(x.toDouble(), y.toDouble()),
        Offset(u.toDouble(), v.toDouble()),
        paint
          ..color = c
          ..strokeWidth = w,
      );
    }

    void box(num x, num y, num w, num h, Color c) => canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
      paint..color = c,
    );
    void oval(num x, num y, num w, num h, Color c) => canvas.drawOval(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
      paint..color = c,
    );
    void poly(List<num> pts, Color c) {
      final path = Path()..moveTo(pts[0].toDouble(), pts[1].toDouble());
      for (var i = 2; i < pts.length; i += 2) {
        path.lineTo(pts[i].toDouble(), pts[i + 1].toDouble());
      }
      canvas.drawPath(path..close(), paint..color = c);
    }

    void beams() {
      for (final x in [8.0, 92.0]) {
        poly([x, 10, x - 22, 110, x + 34, 108], light.withAlpha(37));
        for (var i = 0; i < 4; i++) {
          oval(x - 6 + i * 3, 8, 2, 2, Colors.white);
        }
      }
    }

    void skyline(bool neon) {
      for (var layer = 0; layer < 2; layer++) {
        for (double x = -4; x < 100;) {
          final w = 4 + rng.nextDouble() * 9, h = 8 + rng.nextDouble() * 33;
          final y = 89 + layer * 15 - h;
          box(x, y, w, h, layer == 0 ? base : shadow);
          if (neon) {
            line(x, y, x + w, y, light, .7);
            line(x, 107, x, 107 + h * .6, light.withAlpha(90), 1.2);
          }
          x += w + 1;
        }
      }
    }

    switch (scene) {
      case PhotoScene.arena:
        beams();
        for (var i = 0; i < 3; i++) {
          oval(
            4 + i * 3,
            99 + i * 3,
            92 - i * 6,
            21 - i * 3,
            i.isEven ? light : shadow,
          );
        }
      case PhotoScene.cage:
        for (double x = -150; x < 240; x += 13) {
          line(x, 0, x + 100, 140, shadow, 1.4);
          line(x, 0, x - 100, 140, light.withAlpha(110));
        }
      case PhotoScene.football:
      case PhotoScene.cricket:
        beams();
        oval(-26, 63, 152, 68, shadow);
        oval(-21, 72, 142, 60, light.withAlpha(130));
        oval(-18, 84, 136, 70, const Color(0xff368050));
        if (scene == PhotoScene.cricket) {
          poly([45, 96, 55, 96, 64, 133, 36, 133], const Color(0xffbcac76));
          for (var i = 0; i < 3; i++) {
            line(48 + i * 1.8, 92, 48 + i * 1.8, 97, Colors.white, .8);
          }
        } else {
          line(0, 107, 100, 107, Colors.white60, .8);
          oval(39, 103, 22, 8, Colors.white54);
          oval(40, 104, 20, 6, const Color(0xff368050));
        }
      case PhotoScene.throne:
      case PhotoScene.fortress:
        for (final x in [0.0, 72.0]) {
          box(x, 30, 28, 91, base);
          for (var i = 0; i < 4; i++) {
            box(x + i * 7, 25, 4, 7, light);
          }
          canvas.drawArc(
            Rect.fromLTWH(x + 3, 42, 22, 45),
            math.pi,
            math.pi,
            false,
            paint
              ..color = light
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          paint.style = PaintingStyle.fill;
          line(x + 3, 64, x + 3, 114, light, 3);
          line(x + 25, 64, x + 25, 114, light, 3);
        }
        if (scene == PhotoScene.throne) {
          final arch = Path()
            ..moveTo(29, 93)
            ..lineTo(29, 43)
            ..quadraticBezierTo(29, 10, 50, 8)
            ..quadraticBezierTo(71, 10, 71, 43)
            ..lineTo(71, 93);
          for (final width in [5.0, 1.4]) {
            canvas.drawPath(arch, paint
              ..style = PaintingStyle.stroke
              ..color = width > 2 ? shadow : light
              ..strokeWidth = width);
          }
          paint.style = PaintingStyle.fill;
          poly([44, 85, 56, 85, 85, 140, 15, 140], const Color(0xff8b213a));
          line(44, 85, 15, 140, light.withAlpha(170), 1.3);
          line(56, 85, 85, 140, light.withAlpha(170), 1.3);
        } else {
          for (double y = 69; y < 119; y += 7) {
            for (final x in [0.0, 72.0]) {
              line(x, y, x + 28, y, shadow, .6);
            }
          }
        }
      case PhotoScene.lightning:
      case PhotoScene.stone:
        for (var k = 0; k < 5; k++) {
          double x = k.isEven ? 4 : 94, y = rng.nextDouble() * 24;
          for (var i = 0; i < 9; i++) {
            final u = x + rng.nextDouble() * 20 - 10,
                v = y + 7 + rng.nextDouble() * 9;
            line(x, y, u, v, light.withAlpha(65), 4);
            line(x, y, u, v, light, 1);
            line(u, v, u + 8, v - 3, light, .5);
            if (scene == PhotoScene.stone) {
              poly([x - 2, y, u - 2, v, u - 12, v - 4], shadow);
            }
            x = u;
            y = v;
          }
        }
      case PhotoScene.duel:
        beams();
        for (final x in [8.0, 92.0]) {
          final dx = x < 50 ? 1 : -1;
          for (var i = 0; i < 3; i++) {
            line(x + i * 2, 12, x + dx * 12 + i * 2, 59, light);
            line(x + dx * 12 + i * 2, 59, x + i * 2, 94, light);
          }
        }
        oval(14, 106, 72, 12, light);
        oval(18, 107, 64, 9, shadow);
      case PhotoScene.boxing:
        beams();
        poly([4, 91, 76, 82, 105, 98, 20, 116], base);
        for (final x in [6.0, 94.0]) {
          line(x, 60, x, 108, shadow, 3);
        }
        for (var i = 0; i < 3; i++) {
          line(
            5,
            65 + i * 9,
            94,
            72 + i * 9,
            i == 1 ? Colors.white70 : light,
            1.3,
          );
        }
      case PhotoScene.metal:
        for (double y = 2; y < 140; y += 8) {
          for (double x = -2; x < 100; x += 9) {
            line(x, y, x + 3, y - 3, light.withAlpha(90), 1.3);
          }
        }
        for (double y = 0; y < 140; y += 7) {
          oval(2, y, 5, 9, light);
          oval(3, y + 1, 3, 7, shadow);
        }
      case PhotoScene.sunset:
        oval(60, 28, 21, 21, light);
        skyline(false);
      case PhotoScene.city:
        skyline(true);
        for (var i = 0; i < 24; i++) {
          final x = rng.nextDouble() * 100;
          final y = 110 + rng.nextDouble() * 27;
          line(x, y, x + 2 + rng.nextDouble() * 14, y,
            (i.isEven ? light : const Color(0xff57d9f6)).withAlpha(70), .7);
        }
      case PhotoScene.studio:
        for (final x in [5.0, 17.0, 80.0, 92.0]) {
          box(x, 0, 4, 104, shadow);
          line(x + 3, 0, x + 3, 104, light, 1.4);
          line(x + 3, 104, x - 6, 140, light.withAlpha(100));
        }
      case PhotoScene.ice:
        for (var i = 0; i < 16; i++) {
          final x = rng.nextDouble() * 23;
          final y = 65 + rng.nextDouble() * 50;
          canvas.drawPath(
            Path()
              ..moveTo(x - 5, 140)
              ..quadraticBezierTo(x + 7, y + 14, x, y)
              ..quadraticBezierTo(x + 19, y + 23, x + 7, 140)
              ..close(),
            paint..color = light.withAlpha(100),
          );
          poly([100 - x, 140, 96 - x, y, 88 - x, 140], const Color(0x995bdbff));
        }
      case PhotoScene.racing:
        for (var i = 0; i < 14; i++) {
          oval(
            rng.nextDouble() * 100 - 10,
            rng.nextDouble() * 45,
            32,
            12,
            shadow.withAlpha(110),
          );
        }
        for (var y = 0; y < 5; y++) {
          for (var x = 0; x < 6; x++) {
            final t = math.sin(x * .7) * 3;
            box(
              x * 5,
              y * 5 + t + 16,
              5,
              5,
              (x + y).isEven ? Colors.white70 : shadow,
            );
          }
        }
      case PhotoScene.pakistan:
        oval(12, 15, 32, 32, Colors.white);
        oval(19, 10, 29, 29, base);
        final points = <double>[];
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 - math.pi / 2, r = i.isEven ? 6 : 2.5;
          points.addAll([41 + math.cos(a) * r, 22 + math.sin(a) * r]);
        }
        poly(points, Colors.white);
        for (var i = 0; i < 5; i++) {
          line(0, 100 + i * 4, 100, 76 + i * 3, light.withAlpha(45), 2);
        }
      case PhotoScene.victory:
        for (var i = 0; i < 10; i++) {
          poly([50, 99, i * 16 - 30, 0, i * 16 - 23, 0], light.withAlpha(65));
        }
        for (double x = 0; x < 100; x += 4) {
          final y = 109 + rng.nextDouble() * 10;
          oval(x, y, 4, 4, shadow);
          box(x, y + 4, 4, 30, shadow);
          line(x, y + 10, x - 4, y + 2, shadow, 1.3);
        }
        line(15, 117, 15, 89, shadow);
        poly([15, 89, 27, 91, 15, 96], light);
      case PhotoScene.alpine:
        for (var i = 0; i < 5; i++) {
          final x = i * 25.0 - 5, y = 39 + rng.nextDouble() * 22;
          poly([x - 38, 115, x, y, x + 37, 115], i.isEven ? base : shadow);
          poly([
            x - 9,
            y + 18,
            x,
            y,
            x + 11,
            y + 18,
            x + 3,
            y + 13,
            x - 1,
            y + 17,
          ], Colors.white70);
        }
        for (double x = 0; x < 100; x += 6) {
          final y = 105 + rng.nextDouble() * 13;
          poly([x - 5, 140, x, y, x + 6, 140], shadow);
        }
      case PhotoScene.tunnel:
        for (final x in [3, 25, 75, 97]) {
          line(50, 71, x, 140, light.withAlpha(60), 1.2);
        }
        for (var i = 0; i < 9; i++) {
          final inset = 44 * (1 - math.pow(.76, i)).toDouble();
          final r = Rect.fromLTRB(inset, 9 + inset, 100 - inset, 134 - inset);
          canvas.drawRect(
            r,
            paint
              ..color = light.withAlpha(60)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          canvas.drawRect(
            r,
            paint
              ..color = light
              ..strokeWidth = .8,
          );
          paint.style = PaintingStyle.fill;
        }
    }
    // A restrained edge vignette gives depth without covering the subject.
    canvas.drawRect(bounds, paint
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        radius: .85,
        colors: [Colors.transparent, Color(0x10000000), Color(0x65000000)],
        stops: [0, .65, 1],
      ).createShader(bounds));
    paint.shader = null;
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.scene != scene || old.sideA != sideA;
}
