import 'package:flutter/material.dart';
import '../app_language.dart';

import 'editor_options_panel.dart';
import 'premium_vs.dart';

class VsStylesPanel extends StatelessWidget {
  const VsStylesPanel({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  final VsStyleDefinition? selected;
  final ValueChanged<VsStyleDefinition> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => EditorOptionsPanel(
        title: 'VS Styles',
        onClose: onClose,
        child: LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            primary: false,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 600 ? 4 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 89,
            ),
            itemCount: VsStyleDefinition.styles.length,
            itemBuilder: (context, index) {
              final style = VsStyleDefinition.styles[index];
              final active = style == selected;
              return Semantics(
                selected: active,
                button: true,
                child: Material(
                  color: const Color(0xff091323),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: active ? style.light : const Color(0xff34445f),
                      width: active ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('vs-style-${style.name}'),
                    onTap: () => onSelect(style),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PremiumVsRenderer(style: style),
                              Text(
                                AppLanguage.tr(style.name),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (active)
                          PositionedDirectional(
                            end: 5,
                            top: 5,
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: style.light,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}
