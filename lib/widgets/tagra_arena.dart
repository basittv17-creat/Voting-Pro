import 'dart:io';

import 'package:flutter/material.dart';

enum TagraArena {
  thunder('tagra_royal_thunder', 'رائل تھنڈر'),
  emerald('tagra_emerald_fire', 'ایمرلڈ فائر');

  const TagraArena(this.id, this.urdu);
  final String id;
  final String urdu;
  String get asset => 'assets/templates/$id.png';

  static TagraArena? fromId(String? id) {
    for (final arena in values) {
      if (arena.id == id) return arena;
    }
    return null;
  }
}

/// Geometry is in artwork pixels so a saved crop survives viewport changes.
class TagraArenaPoster extends StatelessWidget {
  const TagraArenaPoster({
    super.key,
    required this.arena,
    required this.urdu,
    this.photoA,
    this.photoB,
    this.nameA = '',
    this.nameB = '',
    this.scales = const {},
    this.offsets = const {},
    this.onPick,
    this.onSelect,
    this.onName,
    this.onTransform,
    this.exporting = false,
  });

  final TagraArena arena;
  final bool urdu, exporting;
  final File? photoA, photoB;
  final String nameA, nameB;
  final Map<bool, double> scales;
  final Map<bool, Offset> offsets;
  final ValueChanged<bool>? onPick, onSelect, onName;
  final void Function(bool, double, Offset)? onTransform;

  @override
  Widget build(BuildContext context) {
    final round = arena == TagraArena.emerald;
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 1200,
        height: 900,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xff172735))),
            for (final side in [true, false])
              Positioned(
                left: (side ? 300.0 : 900.0) - (round ? 218 : 220),
                top: round ? 251 : 258,
                width: round ? 436 : 440,
                height: round ? 436 : 420,
                child: _Portrait(
                  key: ValueKey('arena-photo-${side ? "A" : "B"}'),
                  file: side ? photoA : photoB,
                  scale: scales[side] ?? 1,
                  offset: offsets[side] ?? Offset.zero,
                  label: urdu
                      ? (side ? 'تصویر اے' : 'تصویر بی')
                      : 'Photo ${side ? "A" : "B"}',
                  onTap: exporting || onPick == null
                      ? null
                      : () {
                          onSelect?.call(side);
                          if ((side ? photoA : photoB) == null) onPick!(side);
                        },
                  onStart: () => onSelect?.call(side),
                  onTransform: exporting || onTransform == null
                      ? null
                      : (scale, offset) => onTransform!(side, scale, offset),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(arena.asset, fit: BoxFit.fill),
              ),
            ),
            for (final side in [true, false])
              Positioned(
                left: side ? 90 : 690,
                top: 713,
                width: 420,
                height: 110,
                child: GestureDetector(
                  key: ValueKey('arena-name-${side ? "A" : "B"}'),
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      exporting || onName == null ? null : () => onName!(side),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          (side ? nameA : nameB).trim().isNotEmpty
                              ? (side ? nameA : nameB)
                              : (exporting || onName == null
                                  ? ''
                                  : (urdu ? 'نام لکھیں' : 'Add name')),
                          textDirection: RegExp(r'[\u0600-\u06FF]')
                                      .hasMatch(side ? nameA : nameB) ||
                                  (urdu && (side ? nameA : nameB).isEmpty)
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontFamilyFallback: ['RobotoLocal'],
                            fontSize: 48,
                            color: Color(0xffffedbc),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Portrait extends StatefulWidget {
  const _Portrait({
    super.key,
    required this.file,
    required this.scale,
    required this.offset,
    required this.label,
    required this.onTap,
    required this.onStart,
    required this.onTransform,
  });
  final File? file;
  final double scale;
  final Offset offset;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback onStart;
  final void Function(double, Offset)? onTransform;
  @override
  State<_Portrait> createState() => _PortraitState();
}

class _PortraitState extends State<_Portrait> {
  double startScale = 1;
  Offset origin = Offset.zero, anchor = Offset.zero;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, bounds) {
          final interactive = widget.file != null && widget.onTransform != null;
          return Semantics(
            label: widget.label,
            button: widget.onTap != null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onScaleStart: !interactive
                  ? null
                  : (d) {
                      widget.onStart();
                      startScale = widget.scale;
                      origin = widget.offset;
                      anchor = d.localFocalPoint -
                          bounds.biggest.center(Offset.zero);
                    },
              onScaleUpdate: !interactive
                  ? null
                  : (d) {
                      final scale =
                          (startScale * d.scale).clamp(1.0, 7.0).toDouble();
                      final point = d.localFocalPoint -
                          bounds.biggest.center(Offset.zero);
                      final delta =
                          point - (anchor - origin) * (scale / startScale);
                      final limit =
                          bounds.biggest.center(Offset.zero) * (scale - 1);
                      widget.onTransform!(
                        scale,
                        Offset(
                          delta.dx.clamp(-limit.dx, limit.dx).toDouble(),
                          delta.dy.clamp(-limit.dy, limit.dy).toDouble(),
                        ),
                      );
                    },
              child: ClipRect(
                child: widget.file == null
                    ? (widget.onTap == null
                        ? const SizedBox.expand()
                        : const Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white70,
                              size: 68,
                            ),
                          ))
                    : Transform.translate(
                        offset: widget.offset,
                        child: Transform.scale(
                          scale: widget.scale,
                          child: Image.file(
                            widget.file!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.expand(),
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      );
}
