import 'dart:io';
import 'package:flutter/material.dart';

/// Editable metallic VS battle template. Artwork coordinates: 1448 x 1086.
class MetallicVsBattleTemplate extends StatefulWidget {
  const MetallicVsBattleTemplate({
    super.key,
    this.photoA,
    this.photoB,
    required this.nameA,
    required this.nameB,
    required this.onPickPhoto,
    required this.onEditName,
    this.preview = false,
    this.isExporting = false,
    this.initialScaleA = 1,
    this.initialScaleB = 1,
    this.initialOffsetA = Offset.zero,
    this.initialOffsetB = Offset.zero,
    this.onPhotoTransform,
    this.onPhotoSelected,
  });

  final File? photoA;
  final File? photoB;
  final String nameA;
  final String nameB;
  final ValueChanged<bool> onPickPhoto;
  final ValueChanged<bool> onEditName;
  final bool preview;
  final bool isExporting;
  final double initialScaleA;
  final double initialScaleB;
  final Offset initialOffsetA;
  final Offset initialOffsetB;
  final void Function(bool sideA, double scale, Offset offset)? onPhotoTransform;
  final ValueChanged<bool>? onPhotoSelected;

  @override
  State<MetallicVsBattleTemplate> createState() => _MetallicVsBattleTemplateState();
}

class _MetallicVsBattleTemplateState extends State<MetallicVsBattleTemplate> {
  late double _scaleA, _scaleB;
  late Offset _offsetA, _offsetB;
  double _startScale = 1;

  @override
  void initState() {
    super.initState();
    _scaleA = widget.initialScaleA;
    _scaleB = widget.initialScaleB;
    _offsetA = widget.initialOffsetA;
    _offsetB = widget.initialOffsetB;
  }

  @override
  void didUpdateWidget(covariant MetallicVsBattleTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScaleA != widget.initialScaleA) _scaleA = widget.initialScaleA;
    if (oldWidget.initialScaleB != widget.initialScaleB) _scaleB = widget.initialScaleB;
    if (oldWidget.initialOffsetA != widget.initialOffsetA) _offsetA = widget.initialOffsetA;
    if (oldWidget.initialOffsetB != widget.initialOffsetB) _offsetB = widget.initialOffsetB;
  }

  void _notify(bool sideA) {
    widget.onPhotoTransform?.call(
      sideA, sideA ? _scaleA : _scaleB, sideA ? _offsetA : _offsetB);
  }

  Widget _photo(bool sideA) {
    final file = widget.preview ? null : (sideA ? widget.photoA : widget.photoB);
    final scale = sideA ? _scaleA : _scaleB;
    final offset = sideA ? _offsetA : _offsetB;
    return ClipRRect(
      borderRadius: BorderRadius.circular(84),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.preview || widget.isExporting
            ? null : () => widget.onPickPhoto(sideA),
        onScaleStart: widget.preview || widget.isExporting ? null : (_) {
          _startScale = scale;
          widget.onPhotoSelected?.call(sideA);
        },
        onScaleUpdate: widget.preview || widget.isExporting ? null : (details) {
          setState(() {
            final nextScale =
                (_startScale * details.scale).clamp(0.65, 7.0).toDouble();
            final nextOffset = (sideA ? _offsetA : _offsetB) + details.focalPointDelta;
            if (sideA) {
              _scaleA = nextScale;
              _offsetA = nextOffset;
            } else {
              _scaleB = nextScale;
              _offsetB = nextOffset;
            }
          });
          _notify(sideA);
        },
        child: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Color(0x00000000)),
          if (file != null)
            Transform.translate(
              offset: offset,
              child: Transform.scale(
                scale: scale,
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
            )
          else if (!widget.preview && !widget.isExporting)
            const Center(
              child: Icon(Icons.add_photo_alternate_outlined,
                color: Colors.white70, size: 68),
            ),
        ]),
      ),
    );
  }

  Widget _name(bool sideA) {
    final raw = sideA ? widget.nameA : widget.nameB;
    final isDefault = raw.trim().isEmpty || raw == 'A SIDE' || raw == 'B SIDE';
    final value = isDefault
        ? (sideA ? 'یہاں A والے بندے کا نام لکھیں' : 'یہاں B والے بندے کا نام لکھیں')
        : raw;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.preview || widget.isExporting
          ? null : () => widget.onEditName(sideA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: isDefault ? 33 : 72,
                height: 1,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFE95A),
                shadows: const [
                  Shadow(color: Color(0xFF3A0800), blurRadius: 3,
                    offset: Offset(2, 3)),
                  Shadow(color: Color(0xFFFFA900), blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF080808),
    child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1448,
          height: 1086,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFF080808)),
            // Photos are rendered beneath the transparent cut-outs.
            Positioned(left: 112, top: 112, width: 491, height: 612,
              child: _photo(true)),
            Positioned(left: 806, top: 112, width: 514, height: 612,
              child: _photo(false)),
            Image.asset(
              'assets/templates/Metallic_VS_Battle_Template.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
            if (!widget.preview) ...[
              Positioned(left: 82, top: 850, width: 535, height: 125,
                child: _name(true)),
              Positioned(left: 746, top: 850, width: 557, height: 125,
                child: _name(false)),
            ],
          ]),
        ),
      ),
    ),
  );
}
