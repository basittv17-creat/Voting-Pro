import 'package:flutter/material.dart';

import '../app_language.dart';
import 'text_background_plate.dart';

enum TextBackgroundTab { overview, advanced, gradient, border, shadow, opacity }

/// Inline, live settings for a single text overlay. The editor owns all state.
class TextBackgroundDock extends StatelessWidget {
  const TextBackgroundDock({
    super.key,
    required this.tab,
    required this.hasSelection,
    required this.enabled,
    required this.color,
    required this.design,
    required this.glyphMode,
    required this.opacity,
    required this.thickness,
    required this.corners,
    required this.border,
    required this.shadow,
    required this.gradient,
    required this.onClose,
    required this.onToggle,
    required this.onColor,
    required this.onPreset,
    required this.onGlyphBackground,
    required this.onSliderStart,
    required this.onOpacity,
    required this.onThickness,
    required this.onCorners,
    required this.onBorder,
    required this.onShadow,
    required this.onGradient,
    required this.onWhiteText,
    required this.onChooseFont,
    required this.onUndo,
    required this.onRedo,
  });

  final TextBackgroundTab tab;
  final bool hasSelection, enabled, gradient, glyphMode;
  final Color color;
  final String? design;
  final double opacity, thickness, corners, border, shadow;
  final VoidCallback onClose, onToggle, onSliderStart, onWhiteText;
  final VoidCallback onChooseFont, onUndo, onRedo;
  final ValueChanged<Color> onColor;
  final ValueChanged<String?> onPreset;
  final VoidCallback onGlyphBackground;
  final ValueChanged<double> onOpacity, onThickness, onCorners;
  final ValueChanged<double> onBorder, onShadow;
  final ValueChanged<bool> onGradient;

  static const gold = Color(0xFFFFD84D);
  static const mint = Color(0xFF34DDE7);
  static const palette = <Color>[
    gold, Colors.white, Color(0xFF00E5FF), Color(0xFFFC2EC7),
    Color(0xFF00DB52), Color(0xFFFF243A), Color(0xFF0E56FA),
    Color(0xFF9A26E7), Colors.black, Color(0xFF151A30),
    Color(0xFF263238), Color(0xFF004D40), Color(0xFF0D47A1),
    Color(0xFF4A148C), Color(0xFF880E4F), Color(0xFFB71C1C),
    Color(0xFFF57F17), Color(0xFF00ACC1), Color(0xFF2E7D32),
  ];

  String get _thicknessLabel => glyphMode
      ? 'Glyph edge thickness'
      : 'Plate padding';

  String get title => switch (tab) {
    TextBackgroundTab.overview => 'Text Background',
    TextBackgroundTab.advanced => 'Advanced Backgrounds',
    TextBackgroundTab.gradient => 'Gradient background',
    TextBackgroundTab.border => 'Border width',
    TextBackgroundTab.shadow => 'Shadow blur',
    TextBackgroundTab.opacity => 'Background opacity',
  };

  @override
  Widget build(BuildContext context) {
    final full = tab == TextBackgroundTab.overview ||
        tab == TextBackgroundTab.advanced;
    return Container(
      key: const ValueKey('text-background-dock'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102B43), Color(0xFF0B1527)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: mint, width: 1.5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x3300DFE8), blurRadius: 9),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined, color: gold, size: 21),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppLanguage.tr(title),
                  textDirection: AppLanguage.direction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeTrackColor: gold,
                onChanged: hasSelection ? (_) => onToggle() : null,
              ),
              IconButton(
                tooltip: AppLanguage.tr('Close'),
                onPressed: onClose,
                icon: const Icon(Icons.keyboard_arrow_down, color: mint),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey('background-controls-${tab.name}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasSelection)
                    Text(
                      AppLanguage.tr('Tap text on the poster to select'),
                      style: const TextStyle(color: gold, fontSize: 12),
                    ),
                  if (full) ...[
                    _presets(),
                    const SizedBox(height: 4),
                    Text(AppLanguage.tr('Background color')),
                    _swatches(),
                    _grid(),
                    if (tab == TextBackgroundTab.advanced)
                      Wrap(
                        spacing: 6,
                        children: [
                          ActionChip(
                            label: Text(AppLanguage.tr('None / Reset')),
                            onPressed: hasSelection ? () => onPreset(null) : null,
                          ),
                          ActionChip(
                            label: Text(AppLanguage.tr('Glyph-only background')),
                            onPressed: hasSelection ? onGlyphBackground : null,
                          ),
                          ActionChip(
                            label: Text(AppLanguage.tr('Use white text')),
                            onPressed: hasSelection ? onWhiteText : null,
                          ),
                          ActionChip(
                            label: Text(AppLanguage.tr('Choose a matching font')),
                            onPressed: hasSelection ? onChooseFont : null,
                          ),
                        ],
                      ),
                  ] else ...[
                    if (tab == TextBackgroundTab.gradient) ...[
                      _gradient(),
                      _swatches(),
                    ],
                    if (tab == TextBackgroundTab.border) ...[
                      _slider('Border width', border, 6, onBorder),
                      _slider('Corners', corners, 36, onCorners),
                      _slider(_thicknessLabel, thickness, 24, onThickness),
                    ],
                    if (tab == TextBackgroundTab.shadow)
                      _slider('Shadow blur', shadow, 24, onShadow),
                    if (tab == TextBackgroundTab.opacity)
                      _slider('Background opacity', opacity, 1, onOpacity, percent: true),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: AppLanguage.tr('Undo Text'),
                        onPressed: hasSelection ? onUndo : null,
                        icon: const Icon(Icons.undo, color: gold),
                      ),
                      IconButton(
                        tooltip: AppLanguage.tr('Redo Text'),
                        onPressed: hasSelection ? onRedo : null,
                        icon: const Icon(Icons.redo, color: gold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presets() => SizedBox(
    height: 49,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final entry in premiumTextBackgrounds.entries)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message: AppLanguage.tr(entry.key),
              child: Semantics(
                selected: design == entry.key && enabled,
                button: true,
                child: InkWell(
                  onTap: hasSelection ? () => onPreset(entry.key) : null,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 83,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: design == entry.key && enabled
                            ? gold
                            : const Color(0xFF39566D),
                      ),
                    ),
                    child: TextBackgroundPlate(
                      color: Color(entry.value.$1),
                      design: entry.key,
                      gradient: true,
                      radius: entry.value.$4,
                      borderWidth: 1.5,
                      padding: 2,
                      child: Center(
                        child: Text(
                          AppLanguage.tr(entry.key),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _swatches() => SizedBox(
    height: 43,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final swatch in palette)
          Tooltip(
            message: '${AppLanguage.tr('Color')} #${swatch.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            child: Semantics(
              selected: enabled && color == swatch,
              button: true,
              child: InkWell(
                onTap: hasSelection ? () => onColor(swatch) : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 43,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: swatch,
                        border: Border.all(
                          color: enabled && color == swatch ? gold : Colors.white70,
                          width: enabled && color == swatch ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _grid() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 280 &&
          MediaQuery.textScalerOf(context).scale(12) <= 16 ? 2 : 1;
      final tile = (width - (columns - 1) * 6) / columns;
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final item in [
            _slider('Background opacity', opacity, 1, onOpacity, percent: true),
            _slider('Border width', border, 6, onBorder),
            _slider(_thicknessLabel, thickness, 24, onThickness),
            _slider('Shadow blur', shadow, 24, onShadow),
            _slider('Corners', corners, 36, onCorners),
            _gradient(),
          ])
            SizedBox(width: tile, child: item),
        ],
      );
    },
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF39566D)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );

  Widget _slider(
    String label,
    double value,
    double maximum,
    ValueChanged<double> onChange, {
    bool percent = false,
  }) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          children: [
            Text(AppLanguage.tr(label), style: const TextStyle(fontSize: 11)),
            Text(
              percent ? '${(value * 100).round()}%' : value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 11, color: gold),
            ),
          ],
        ),
        SliderTheme(
          data: const SliderThemeData(trackHeight: 4),
          child: Slider(
            key: ValueKey('background-slider-$label'),
            value: value.clamp(0.0, maximum).toDouble(),
            max: maximum,
            activeColor: gold,
            onChangeStart: hasSelection ? (_) => onSliderStart() : null,
            onChanged: hasSelection ? onChange : null,
            semanticFormatterCallback: (v) =>
                '${AppLanguage.tr(label)} ${v.toStringAsFixed(1)}',
          ),
        ),
      ],
    ),
  );

  Widget _gradient() => _card(
    Row(
      children: [
        Expanded(
          child: Text(
            AppLanguage.tr('Gradient background'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Switch.adaptive(
          value: gradient,
          activeTrackColor: gold,
          onChanged: hasSelection ? onGradient : null,
        ),
      ],
    ),
  );
}
