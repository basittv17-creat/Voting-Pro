import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import '../app_language.dart';
import 'editor_options_panel.dart';
import 'photo_scene.dart';

bool _hasPhotoTransparency(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  return image != null && image.any((pixel) => pixel.a < pixel.maxChannelValue);
}

class PhotoBackgroundSettings extends StatefulWidget {
  const PhotoBackgroundSettings({
    super.key,
    required this.file,
    required this.sideA,
    required this.title,
    required this.palettes,
    required this.selected,
    required this.onClose,
    required this.onSelected,
  });

  final File file;
  final bool sideA;
  final String title;
  final Map<String, List<Color>> palettes;
  final String? selected;
  final VoidCallback onClose;
  final ValueChanged<String?> onSelected;

  @override
  State<PhotoBackgroundSettings> createState() =>
      PhotoBackgroundSettingsState();
}

class PhotoBackgroundSettingsState extends State<PhotoBackgroundSettings> {
  late final Future<bool> _transparent = _checkTransparency();

  Future<bool> _checkTransparency() async =>
      compute(_hasPhotoTransparency, await widget.file.readAsBytes());

  @override
  Widget build(BuildContext context) => EditorOptionsPanel(
    title: widget.title,
    onClose: widget.onClose,
    child: FutureBuilder<bool>(
      future: _transparent,
      builder: (context, snapshot) => CustomScrollView(
        key: const PageStorageKey('photo-background-scroll'),
        scrollCacheExtent: const ScrollCacheExtent.pixels(150),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (snapshot.hasError)
                    Text(AppLanguage.tr('Could not read the selected photo.'))
                  else if (!snapshot.hasData)
                    const LinearProgressIndicator()
                  else if (snapshot.data == false)
                    Text(AppLanguage.tr(
                      'Use Remove Background first to reveal a photo background.',
                    ))
                  else ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 3,
                      children: [
                        ChoiceChip(
                          label: Text(AppLanguage.tr('None')),
                          selected: widget.selected == null,
                          onSelected: (_) => widget.onSelected(null),
                        ),
                        for (final MapEntry(:key, :value) in widget.palettes.entries)
                          ChoiceChip(
                            avatar: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: value),
                              ),
                              child: const SizedBox.square(dimension: 20),
                            ),
                            label: Text(AppLanguage.tr(key)),
                            selected: widget.selected == key,
                            onSelected: (_) => widget.onSelected(key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLanguage.tr('Premium photo backgrounds'),
                      textDirection: AppLanguage.direction,
                      style: const TextStyle(
                        color: Color(0xffffd84d),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (snapshot.data == true)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 132,
                  mainAxisExtent: 124,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final scene = PhotoScene.values[index];
                    return PhotoSceneCard(
                      key: ValueKey(scene.id),
                      scene: scene,
                      sideA: widget.sideA,
                      selected: widget.selected == scene.id,
                      onTap: () => widget.onSelected(scene.id),
                    );
                  },
                  childCount: PhotoScene.values.length,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Draw only visible portrait previews, with the very same renderer used
/// behind the actual photo. No decoded thumbnail assets or network requests.
class PhotoSceneCard extends StatelessWidget {
  const PhotoSceneCard({
    super.key,
    required this.scene,
    required this.sideA,
    required this.selected,
    required this.onTap,
  });

  final PhotoScene scene;
  final bool sideA;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppLanguage.isUrdu ? scene.ur : AppLanguage.tr(scene.en);
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: const Color(0xff17253b),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? const Color(0xffffd84d) : const Color(0xff40516c),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoSceneArt(scene, sideA: sideA),
                        if (selected)
                          const Positioned(
                            right: 3,
                            top: 3,
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xffffd84d),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 30,
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      textDirection: AppLanguage.direction,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
