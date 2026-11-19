import 'package:flutter/material.dart';

import '../app_language.dart';

class EditorOptionsPanel extends StatelessWidget {
  const EditorOptionsPanel({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      AppLanguage.tr(title),
      textDirection: AppLanguage.direction,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xffFFDE85),
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
    final close = IconButton(
      tooltip: AppLanguage.tr('Close'),
      onPressed: onClose,
      icon: const Icon(Icons.close_rounded),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Material(
        color: const Color(0xff101b30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xff776136)),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight < 116 && constraints.maxWidth >= 480) {
              return Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: label),
                        close,
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 14, end: 3),
                  child: Row(
                    children: [
                      Expanded(child: label),
                      close,
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}
