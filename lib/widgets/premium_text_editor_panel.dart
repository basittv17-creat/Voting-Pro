import 'package:flutter/material.dart';

/// The same tools as the legacy toolbar, organized in a compact premium panel.
/// All values are supplied by the existing editor, never duplicated locally.
class TextPanelAction {
  const TextPanelAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

enum TextPanelTab { style, color, effects, layout, more }

class PremiumTextEditorPanel extends StatefulWidget {
  const PremiumTextEditorPanel({
    super.key,
    required this.selectedText,
    required this.onClose,
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
    required this.gradientEnabled,
    required this.onGradientToggle,
    required this.outlineWidth,
    required this.onOutlineToggle,
    required this.onOutlineIncrease,
    required this.onOutlineDecrease,
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
  final VoidCallback onClose, onAddText, onEditText, onDeleteText;
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
  final bool gradientEnabled;
  final VoidCallback onGradientToggle;
  final double outlineWidth;
  final VoidCallback onOutlineToggle;
  final VoidCallback onOutlineIncrease, onOutlineDecrease, onOutlineColor;
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
  TextPanelTab _tab = TextPanelTab.effects;
  static const _dark = Color(0xFF0B1527);
  static const _panel = Color(0xFF15283D);
  static const _gold = Color(0xFFFFD84D);
  static const _mint = Color(0xFF5EEDE4);
  static const _colors = <Color>[
    Color(0xFFFFD84D), Color(0xFFFFFFFF), Color(0xFF00E5FF),
    Color(0xFFFC2EC7), Color(0xFF00DB52), Color(0xFFFF243A),
    Color(0xFF0E56FA), Color(0xFF9A26E7), Color(0xFF101018),
    Color(0xFFFF7F20), Color(0xFFB8D4D6), Color(0xFF056F5E),
  ];

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.48;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight.clamp(185.0, 450.0)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0F2D42), Color(0xFF1E1B38), _dark],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF477C94), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x5500DFE8), blurRadius: 22),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 52, height: 5, decoration: BoxDecoration(
          color: const Color(0xFF90DCF2),
          borderRadius: BorderRadius.circular(10),
        )),
        const SizedBox(height: 9),
        Row(children: [
          IconButton(
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
            tooltip: 'Close text editor',
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Icon(Icons.text_fields, color: _gold, size: 24),
          const SizedBox(width: 6),
          const Expanded(child: Text(
            'Text Editor', maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
            ),
          )),
          IconButton(
            tooltip: 'Add text',
            onPressed: widget.onAddText,
            icon: const Icon(Icons.add_circle_outline, color: _mint),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 7),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF192736),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold),
              ),
              child: Text(
                widget.selectedText == null
                    ? 'Tap text on the poster to select'
                    : 'Selected: ${widget.selectedText}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: widget.selectedText != null &&
                    RegExp(r'[\u0600-\u06FF]').hasMatch(widget.selectedText!)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: const TextStyle(
                  color: _gold, fontSize: 12, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(children: [
          _tabButton(TextPanelTab.style, 'Style', Icons.brush_outlined),
          _tabButton(TextPanelTab.color, 'Color', Icons.palette_outlined),
          _tabButton(TextPanelTab.effects, 'Effects', Icons.auto_awesome),
          _tabButton(TextPanelTab.layout, 'Layout', Icons.dashboard_outlined),
          _tabButton(TextPanelTab.more, 'More', Icons.more_horiz),
        ]),
        const SizedBox(height: 9),
        Flexible(child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1B2F),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFF2D6276)),
            ),
            child: SingleChildScrollView(
              child: switch (_tab) {
                TextPanelTab.style => _style(),
                TextPanelTab.color => _color(),
                TextPanelTab.effects => _effects(),
                TextPanelTab.layout => _actionGrid(widget.layoutActions),
                TextPanelTab.more => _more(),
              },
            ),
          ),
        )),
      ]),
    );
  }

  Widget _tabButton(TextPanelTab tab, String name, IconData icon) {
    final active = tab == _tab;
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF4B4215) : _panel,
            border: Border.all(
              color: active ? _gold : const Color(0xFF3A5268),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: active ? _gold : Colors.white),
            const SizedBox(height: 3),
            FittedBox(child: Text(name, style: TextStyle(
              color: active ? _gold : Colors.white,
              fontSize: 11, fontWeight: FontWeight.w700,
            ))),
          ]),
        ),
      ),
    ));
  }

  Widget _actionGrid(List<TextPanelAction> actions) => LayoutBuilder(
    builder: (context, constraints) {
      // Avoid one giant column on narrow phones. Each row gets equal widths.
      final columns = constraints.maxWidth >= 470 ? 3 : 2;
      final tileWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
      return Wrap(
        spacing: 8, runSpacing: 8,
        children: actions.map((action) => SizedBox(
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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(action.icon, size: 22, color: _mint),
              const SizedBox(height: 4),
              Text(action.label, maxLines: 2, textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11)),
            ]),
          ),
        )).toList(),
      );
    },
  );

  Widget _style() => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _actionGrid(widget.styleActions),
      const SizedBox(height: 12),
      _slider('Text opacity', widget.textOpacity, 0.1, 1,
        widget.onOpacityStart, widget.onTextOpacity, percentage: true),
    ]);

  Widget _color() => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Text color', style: TextStyle(color: _gold,
        fontWeight: FontWeight.bold)),
      const SizedBox(height: 9),
      _palette(widget.textColor, widget.onTextColor),
      const SizedBox(height: 12),
      _actionGrid([TextPanelAction('More colors', Icons.palette,
        widget.onMoreColors)]),
      const SizedBox(height: 10),
      _slider('Text opacity', widget.textOpacity, 0.1, 1,
        widget.onOpacityStart, widget.onTextOpacity, percentage: true),
    ]);

  Widget _effects() => Column(children: [
    _section(
      'Glow', Icons.auto_awesome, widget.glowEnabled,
      widget.onGlowToggle,
      child: Column(children: [
        _palette(widget.glowColor, widget.onGlowColor),
        _slider('Glow intensity', widget.glowStrength, 0, 200,
          widget.onGlowStart, widget.onGlowStrength),
      ]),
    ),
    _section(
      'Outline (Stroke)', Icons.border_outer, widget.outlineWidth > 0,
      widget.onOutlineToggle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Stroke width',
            style: TextStyle(color: Colors.white70)),
          const Spacer(),
          IconButton(onPressed: widget.onOutlineDecrease,
            tooltip: 'Decrease outline',
            icon: const Icon(Icons.remove, color: _mint)),
          Text(widget.outlineWidth.toStringAsFixed(1)),
          IconButton(onPressed: widget.onOutlineIncrease,
            tooltip: 'Increase outline',
            icon: const Icon(Icons.add, color: _mint)),
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onOutlineColor,
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Outline color'),
          ),
        ),
      ]),
    ),
    _section('Gradient Fill', Icons.gradient, widget.gradientEnabled,
      widget.onGradientToggle),
    _section('Text Background', Icons.format_color_fill,
      widget.backgroundEnabled, widget.onBackgroundToggle,
      child: Column(children: [
        _palette(widget.backgroundColor, widget.onBackgroundColor),
        _slider('Background opacity', widget.backgroundOpacity, 0, 1,
          widget.onBackgroundOpacityStart, widget.onBackgroundOpacity,
          percentage: true),
        TextButton.icon(
          onPressed: widget.onBackgroundSettings,
          icon: const Icon(Icons.tune),
          label: const Text('Advanced background settings'),
        ),
      ]),
    ),
  ]);

  Widget _more() => Column(children: [
    _actionGrid([
      TextPanelAction('Add Text', Icons.add, widget.onAddText),
      TextPanelAction('Edit Text', Icons.edit, widget.onEditText),
      ...widget.moreActions,
      TextPanelAction('Delete Text', Icons.delete_outline, widget.onDeleteText),
    ]),
  ]);

  Widget _section(String name, IconData icon, bool enabled,
      VoidCallback toggle, {Widget? child}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _panel,
      border: Border.all(color: const Color(0xFF37566A)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _gold, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 14,
        ))),
        Switch.adaptive(value: enabled, onChanged: (_) => toggle(),
          activeTrackColor: _gold),
      ]),
      if (child != null) child,
    ]),
  );

  Widget _palette(Color selected, ValueChanged<Color> callback) => Wrap(
    spacing: 8, runSpacing: 8,
    children: _colors.map((color) => InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: () => callback(color),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected == color ? _gold : Colors.white24,
            width: selected == color ? 3 : 1),
          boxShadow: selected == color ? [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
          ] : null,
        ),
      ),
    )).toList(),
  );

  Widget _slider(String label, double value, double min, double max,
      VoidCallback onStart, ValueChanged<double> onChanged,
      {bool percentage = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(children: [
        Expanded(child: Text(label, maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.white70))),
        const SizedBox(width: 6),
        Text(
          percentage ? '${(value * 100).round()}%' : value.round().toString(),
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 12, color: _gold),
        ),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min, max: max,
        activeColor: _mint,
        onChangeStart: (_) => onStart(),
        onChanged: onChanged,
      ),
    ],
  );
}
