import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      builder: (context, snapshot) => SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: snapshot.hasError
            ? const Text('Could not read the selected photo.')
            : !snapshot.hasData
            ? const LinearProgressIndicator()
            : Wrap(
                spacing: 8,
                children: [
                  if (snapshot.data == false)
                    Text(
                      AppLanguage.current == 'ur'
                          ? 'منتخب پس منظر دیکھنے کے لیے تصویر کا اصل پس منظر ہٹائیں۔'
                          : 'Use Remove Background first to reveal a photo background.',
                    ),
                  ChoiceChip(
                    label: Text(
                      AppLanguage.current == 'ur' ? 'کوئی نہیں' : 'None',
                    ),
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
                      label: Text(key),
                      selected: widget.selected == key,
                      onSelected: (_) => widget.onSelected(key),
                    ),
                  for (final scene in PhotoScene.values)
                    ChoiceChip(
                      avatar: SizedBox.square(
                        dimension: 28,
                        child: PhotoSceneArt(scene, sideA: widget.sideA),
                      ),
                      label: Text(
                        AppLanguage.current == 'ur' ? scene.ur : scene.en,
                      ),
                      selected: widget.selected == scene.id,
                      onSelected: (_) => widget.onSelected(scene.id),
                    ),
                ],
              ),
      ),
    ),
  );
}
