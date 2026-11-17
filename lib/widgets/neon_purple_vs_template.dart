import 'dart:io';
import 'package:flutter/material.dart';

/// Editable 4:3 Neon Purple VS template for VotingPro.
/// All geometry is authored in the source artwork's 1448 x 1086 coordinate space.
class NeonPurpleVsTemplate extends StatefulWidget {
  const NeonPurpleVsTemplate({
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
  State<NeonPurpleVsTemplate> createState() => _NeonPurpleVsTemplateState();
}

class _NeonPurpleVsTemplateState extends State<NeonPurpleVsTemplate> {
  late double _scaleA, _scaleB;
  late Offset _offsetA, _offsetB;
  double _startScale = 1;
  Offset _startOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scaleA = widget.initialScaleA;
    _scaleB = widget.initialScaleB;
    _offsetA = widget.initialOffsetA;
    _offsetB = widget.initialOffsetB;
  }

  @override
  void didUpdateWidget(covariant NeonPurpleVsTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScaleA != widget.initialScaleA) _scaleA = widget.initialScaleA;
    if (oldWidget.initialScaleB != widget.initialScaleB) _scaleB = widget.initialScaleB;
    if (oldWidget.initialOffsetA != widget.initialOffsetA) _offsetA = widget.initialOffsetA;
    if (oldWidget.initialOffsetB != widget.initialOffsetB) _offsetB = widget.initialOffsetB;
  }

  void _notify(bool sideA) {
    widget.onPhotoTransform?.call(
      sideA,
      sideA ? _scaleA : _scaleB,
      sideA ? _offsetA : _offsetB,
    );
  }

  Widget _photo(bool sideA) {
    final photo = widget.preview ? null : (sideA ? widget.photoA : widget.photoB);
    final scale = sideA ? _scaleA : _scaleB;
    final offset = sideA ? _offsetA : _offsetB;
    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.preview || widget.isExporting ? null : () => widget.onPickPhoto(sideA),
        onScaleStart: widget.preview || widget.isExporting ? null : (_) {
          _startScale = scale;
          _startOffset = offset;
          widget.onPhotoSelected?.call(sideA);
        },
        onScaleUpdate: widget.preview || widget.isExporting ? null : (details) {
          setState(() {
            final nextScale = (_startScale * details.scale).clamp(0.65, 7.0).toDouble();
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
          const ColoredBox(color: Color(0xFF171923)),
          if (photo != null)
            Transform.translate(
              offset: offset,
              child: Transform.scale(
                scale: scale,
                child: Image.file(photo, fit: BoxFit.contain,
                  width: double.infinity, height: double.infinity,
                  filterQuality: FilterQuality.high, gaplessPlayback: true),
              ),
            )
          else if (!widget.preview && !widget.isExporting)
            const Center(child: Icon(Icons.add_photo_alternate_outlined,
              color: Colors.white70, size: 72)),
        ]),
      ),
    );
  }

  Widget _name(String value, bool sideA) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.preview || widget.isExporting ? null : () => widget.onEditName(sideA),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
            maxLines: 1,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNastaliqUrdu',
              fontSize: 54,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFE500),
              shadows: [
                Shadow(color: sideA ? const Color(0xFF008CFF) : const Color(0xFFE000FF), blurRadius: 9),
                const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 2)),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF080E19),
    child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1448,
          height: 1086,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFF080E19)),
            // Photo windows are transparent in the PNG; photos are placed beneath it.
            const Positioned(left: 0, top: 0, width: 1448, height: 1086,
              child: SizedBox.expand()),
            Positioned(left: 92, top: 155, width: 535, height: 575, child: _photo(true)),
            Positioned(left: 780, top: 155, width: 555, height: 575, child: _photo(false)),
            Image.asset('assets/templates/Neon_Purple_VS_Template.png',
              fit: BoxFit.fill, filterQuality: FilterQuality.high, gaplessPlayback: true),
            if (!widget.preview)
              Positioned(left: 85, top: 837, width: 535, height: 92,
                child: _name(widget.nameA, true)),
            if (!widget.preview)
              Positioned(left: 775, top: 837, width: 585, height: 92,
                child: _name(widget.nameB, false)),
          ]),
        ),
      ),
    ),
  );
}
