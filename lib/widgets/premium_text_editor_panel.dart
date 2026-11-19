import 'package:flutter/material.dart';

/// The same tools as the legacy toolbar, organized in a compact premium panel.
/// All values are supplied by the existing editor, never duplicated locally.
class TextPanelAction {
  const TextPanelAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

enum TextToolSection {
  none,
  color,
  style,
  layout,
  background,
  glow,
  shadow,
  outline,
  gradient,
  more,
}

class PremiumTextEditorPanel extends StatefulWidget {
  const PremiumTextEditorPanel({
    super.key,
    required this.selectedText,
    required this.section,
    required this.onAddText,
    required this.onEditText,
    required this.onDeleteText,
    required this.styleActions,
    required this.layoutActions,
    required this.moreActions,
    required this.textColor,
    required this.onTextColor,
    required this.onMoreColors,
    required this.textOpacity,
    required this.onOpacityStart,
    required this.onTextOpacity,
    required this.glowEnabled,
    required this.onGlowToggle,
    required this.glowStrength,
    required this.onGlowStart,
    required this.onGlowStrength,
    required this.glowColor,
    required this.onGlowColor,
    required this.shadowStrength,
    required this.onShadowToggle,
    required this.onShadowStart,
    required this.onShadowStrength,
    required this.gradientEnabled,
    required this.onGradientToggle,
    required this.outlineWidth,
    required this.onOutlineToggle,
    required this.outlineColor,
    required this.onOutlineStart,
    required this.onOutlineWidth,
    required this.onOutlineColor,
    required this.backgroundEnabled,
    required this.onBackgroundToggle,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.backgroundOpacity,
    required this.onBackgroundOpacityStart,
    required this.onBackgroundOpacity,
    required this.onBackgroundSettings,
  });

  final String? selectedText;
  final TextToolSection section;
  final VoidCallback onAddText, onEditText, onDeleteText;
  final List<TextPanelAction> styleActions, layoutActions, moreActions;
  final Color textColor;
  final ValueChanged<Color> onTextColor;
  final VoidCallback onMoreColors;
  final double textOpacity;
  final VoidCallback onOpacityStart;
  final ValueChanged<double> onTextOpacity;
  final bool glowEnabled;
  final VoidCallback onGlowToggle;
  final double glowStrength;
  final VoidCallback onGlowStart;
  final ValueChanged<double> onGlowStrength;
  final Color glowColor;
  final ValueChanged<Color> onGlowColor;
  final double shadowStrength;
  final VoidCallback onShadowToggle, onShadowStart;
  final ValueChanged<double> onShadowStrength;
  final bool gradientEnabled;
  final VoidCallback onGradientToggle;
  final double outlineWidth;
  final VoidCallback onOutlineToggle;
  final Color outlineColor;
  final VoidCallback onOutlineStart;
  final ValueChanged<double> onOutlineWidth;
  final ValueChanged<Color> onOutlineColor;
  final bool backgroundEnabled;
  final VoidCallback onBackgroundToggle;
  final Color backgroundColor;
  final ValueChanged<Color> onBackgroundColor;
  final double backgroundOpacity;
  final VoidCallback onBackgroundOpacityStart;
  final ValueChanged<double> onBackgroundOpacity;
  final VoidCallback onBackgroundSettings;

  @override
  State<PremiumTextEditorPanel> createState() => _PremiumTextEditorPanelState();
}

class _PremiumTextEditorPanelState extends State<PremiumTextEditorPanel> {
  static const _dark = Color(0xFF0B1527);
  static const _panel = Color(0xFF15283D);
  static const _gold = Color(0xFFFFD84D);
  static const _mint = Color(0xFF5EEDE4);
  static const _colors = <Color>[
    Color(0xFFFFD84D),
    Color(0xFFFFFFFF),
    Color(0xFF00E5FF),
    Color(0xFFFC2EC7),
    Color(0xFF00DB52),
    Color(0xFFFF243A),
    Color(0xFF0E56FA),
    Color(0xFF9A26E7),
    Colors.black,
    Color(0xFFFF7F20),
    Color(0xFFB8D4D6),
    Color(0xFF056F5E),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.section == TextToolSection.none) {
      return const SizedBox.shrink();
    }

    final Widget settings = switch (widget.section) {
      TextToolSection.none => const SizedBox.shrink(),
      TextToolSection.color => _color(),
      TextToolSection.style => _style(),
      TextToolSection.layout => _actionGrid(widget.layoutActions),
      TextToolSection.background => _background(),
      TextToolSection.glow => _glow(),
      TextToolSection.shadow => _shadow(),
      TextToolSection.outline => _outline(),
      TextToolSection.gradient => _gradient(),
      TextToolSection.more => _more(),
    };

    // Settings live in the scrollable gap BELOW the poster, not in a
    // modal bottom sheet. The one-row tool strip is rendered separately
    // in the original bottom toolbar position.
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: (MediaQuery.sizeOf(context).height * 0.32)
              .clamp(160.0, 285.0)
              .toDouble(),
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2D42), Color(0xFF1E1B38), _dark],
          ),
          border: Border.all(color: const Color(0xFF34DDE7), width: 1.3),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x3300DFE8), blurRadius: 14),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.selectedText == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Tap text on the poster to select',
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              settings,
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionGrid(List<TextPanelAction> actions) => LayoutBuilder(
    builder: (context, constraints) {
      // Avoid one giant column on narrow phones. Each row gets equal widths.
      final columns = constraints.maxWidth >= 470 ? 3 : 2;
      final tileWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions
            .map(
              (action) => SizedBox(
                width: tileWidth,
                height: 70,
                child: OutlinedButton(
                  onPressed: action.onPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _panel,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(6),
                    side: const BorderSide(color: Color(0xFF3D7284)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon, size: 22, color: _mint),
                      const SizedBox(height: 4),
                      Text(
                        action.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _style() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _actionGrid(widget.styleActions),
      const SizedBox(height: 12),
      _slider(
        'Text opacity',
        widget.textOpacity,
        0.1,
        1,
        widget.onOpacityStart,
        widget.onTextOpacity,
        percentage: true,
      ),
    ],
  );

  Widget _color() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Text color',
        style: TextStyle(color: _gold, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 9),
      _palette(widget.textColor, widget.onTextColor),
      const SizedBox(height: 12),
      _actionGrid([
        TextPanelAction('More colors', Icons.palette, widget.onMoreColors),
      ]),
      const SizedBox(height: 10),
      _slider(
        'Text opacity',
        widget.textOpacity,
        0.1,
        1,
        widget.onOpacityStart,
        widget.onTextOpacity,
        percentage: true,
      ),
    ],
  );

  // Each effect is its own destination. There is no nested Effects tab.
  Widget _glow() => _section(
    'Glow',
    Icons.auto_awesome,
    widget.glowEnabled,
    widget.onGlowToggle,
    child: Column(
      children: [
        _palette(widget.glowColor, widget.onGlowColor),
        _slider(
          'Glow intensity',
          widget.glowStrength,
          0,
          200,
          widget.onGlowStart,
          widget.onGlowStrength,
        ),
      ],
    ),
  );

  Widget _shadow() => _section(
    'Shadow',
    Icons.layers_outlined,
    widget.shadowStrength > 0,
    widget.onShadowToggle,
    child: _slider(
      'Shadow opacity',
      widget.shadowStrength,
      0,
      1,
      widget.onShadowStart,
      widget.onShadowStrength,
      percentage: true,
    ),
  );

  Widget _outline() => _section(
    'Outline (Stroke)',
    Icons.border_outer,
    widget.outlineWidth > 0,
    widget.onOutlineToggle,
    child: Column(
      children: [
        _palette(widget.outlineColor, widget.onOutlineColor),
        _slider(
          'Stroke width',
          widget.outlineWidth,
          0,
          8,
          widget.onOutlineStart,
          widget.onOutlineWidth,
        ),
      ],
    ),
  );

  Widget _gradient() => _section(
    'Gradient Fill',
    Icons.gradient,
    widget.gradientEnabled,
    widget.onGradientToggle,
  );

  Widget _background() => _section(
    'Text Background',
    Icons.format_color_fill,
    widget.backgroundEnabled,
    widget.onBackgroundToggle,
    child: Column(
      children: [
        _palette(widget.backgroundColor, widget.onBackgroundColor),
        _slider(
          'Background opacity',
          widget.backgroundOpacity,
          0,
          1,
          widget.onBackgroundOpacityStart,
          widget.onBackgroundOpacity,
          percentage: true,
        ),
        TextButton.icon(
          onPressed: widget.onBackgroundSettings,
          icon: const Icon(Icons.tune),
          label: const Text('Advanced background settings'),
        ),
      ],
    ),
  );

  Widget _more() => Column(
    children: [
      _actionGrid([
        TextPanelAction('Add Text', Icons.add, widget.onAddText),
        TextPanelAction('Edit Text', Icons.edit, widget.onEditText),
        ...widget.moreActions,
        TextPanelAction(
          'Delete Text',
          Icons.delete_outline,
          widget.onDeleteText,
        ),
      ]),
    ],
  );

  Widget _section(
    String name,
    IconData icon,
    bool enabled,
    VoidCallback toggle, {
    Widget? child,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _panel,
      border: Border.all(color: const Color(0xFF37566A)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _gold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Semantics(
              label: name,
              child: Switch.adaptive(
                value: enabled,
                onChanged: (_) => toggle(),
                activeTrackColor: _gold,
              ),
            ),
          ],
        ),
        if (child != null) child,
      ],
    ),
  );

  Widget _palette(Color selected, ValueChanged<Color> callback) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _colors.map((color) {
            final hex = color
                .toARGB32()
                .toRadixString(16)
                .substring(2)
                .toUpperCase();
            final isSelected = selected == color;
            return Semantics(
              selected: isSelected,
              child: Tooltip(
                message: 'Color #$hex',
                child: InkWell(
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => callback(color),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isSelected ? _gold : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    VoidCallback onStart,
    ValueChanged<double> onChanged, {
    bool percentage = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            percentage ? '${(value * 100).round()}%' : value.round().toString(),
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, color: _gold),
          ),
        ],
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        activeColor: _mint,
        onChangeStart: (_) => onStart(),
        onChanged: onChanged,
      ),
    ],
  );
}
