import 'dart:io';
import 'package:flutter/material.dart';

/// Responsive, interactive artwork layer for the Neon VS Duel ready-made template.
/// Wire [onPickPhoto] and [onEditName] to VotingPro's existing picker and name editor.
class NeonVsDuelTemplate extends StatefulWidget {
  const NeonVsDuelTemplate({
    super.key,
    required this.imageA,
    required this.imageB,
    this.nameA = 'علی',
    this.nameB = 'ولی',
    required this.onPickPhoto,
    required this.onEditName,
    this.preview = false,
  });

  final File? imageA;
  final File? imageB;
  final String nameA;
  final String nameB;
  final ValueChanged<bool> onPickPhoto;
  final ValueChanged<bool> onEditName;
  final bool preview;

  @override
  State<NeonVsDuelTemplate> createState() => _NeonVsDuelTemplateState();
}

class _NeonVsDuelTemplateState extends State<NeonVsDuelTemplate> {
  final Map<bool, double> _scale = {true: 1, false: 1};
  final Map<bool, double> _startScale = {true: 1, false: 1};
  final Map<bool, Offset> _offset = {true: Offset.zero, false: Offset.zero};

  Widget _photo(bool sideA, double width, double height) {
    final file = sideA ? widget.imageA : widget.imageB;
    return ClipRRect(
      borderRadius: BorderRadius.circular(width * .12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.preview ? null : () => widget.onPickPhoto(sideA),
        onScaleStart: widget.preview ? null : (_) {
          _startScale[sideA] = _scale[sideA] ?? 1;
        },
        onScaleUpdate: widget.preview ? null : (details) {
          setState(() {
            _scale[sideA] = ((_startScale[sideA] ?? 1) * details.scale)
                .clamp(.8, 8.0).toDouble();
            _offset[sideA] = (_offset[sideA] ?? Offset.zero) +
                details.focalPointDelta;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF17191F)),
            if (file != null)
              ClipRect(
                child: Transform.translate(
                  offset: _offset[sideA] ?? Offset.zero,
                  child: Transform.scale(
                    scale: _scale[sideA] ?? 1,
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              )
            else if (!widget.preview)
              Center(
                child: Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.white70, size: width * .075),
              ),
          ],
        ),
      ),
    );
  }

  Widget _name(String value, bool sideA, double width) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.preview ? null : () => widget.onEditName(sideA),
      child: Center(
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
              fontSize: width * .205,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: sideA
                  ? const [
                      Shadow(color: Color(0xFF061A3B), blurRadius: 3,
                          offset: Offset(2, 3)),
                      Shadow(color: Color(0xFF69DFFF), blurRadius: 7),
                    ]
                  : const [
                      Shadow(color: Color(0xFF390027), blurRadius: 3,
                          offset: Offset(2, 3)),
                      Shadow(color: Color(0xFFFF3BCB), blurRadius: 7),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // All measurements are normalized to the original 1448 x 1086 artwork.
        // This lets the same template follow every canvas ratio without fixed pixels.
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: w * (64 / 1448),
                top: h * (105 / 1086),
                width: w * (591 / 1448),
                height: h * (639 / 1086),
                child: _photo(true, w * (591 / 1448), h * (639 / 1086)),
              ),
              Positioned(
                left: w * (752 / 1448),
                top: h * (105 / 1086),
                width: w * (590 / 1448),
                height: h * (639 / 1086),
                child: _photo(false, w * (590 / 1448), h * (639 / 1086)),
              ),
              // Rebuild the small cleared name-text areas with the original blue/pink plates.
              Positioned(
                left: w * (250 / 1448),
                top: h * (770 / 1086),
                width: w * (188 / 1448),
                height: h * (132 / 1086),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF07356E), Color(0xFF041B3D)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * (1000 / 1448),
                top: h * (770 / 1086),
                width: w * (188 / 1448),
                height: h * (132 / 1086),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF710B45), Color(0xFF350024)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/templates/Neon_VS_Duel_Template.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              if (!widget.preview) ...[
                Positioned(
                  left: w * (245 / 1448),
                  top: h * (765 / 1086),
                  width: w * (190 / 1448),
                  height: h * (135 / 1086),
                  child: _name(widget.nameA, true, w * (190 / 1448)),
                ),
                Positioned(
                  left: w * (990 / 1448),
                  top: h * (765 / 1086),
                  width: w * (190 / 1448),
                  height: h * (135 / 1086),
                  child: _name(widget.nameB, false, w * (190 / 1448)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
