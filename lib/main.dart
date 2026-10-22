import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

void main() => runApp(const PosterApp());
const mint = Color(0xFF79F0D6), gold = Color(0xFFFFD84D), dark = Color(0xFF080E19);

class PosterApp extends StatelessWidget {
  const PosterApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Voting Pro',
    theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: dark),
    home: const Editor(),
  );
}

class Editor extends StatefulWidget {
  const Editor({super.key});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final picker = ImagePicker();
  final shot = ScreenshotController();
  File? a, b;
  Color background = const Color(0xFF064B27), frameColor = gold;
  double frameWidth = 3, canvasRatio = .8;
  bool busy = false;
  final List<String> overlays = [];

  void msg(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> pick(bool sideA) async {
    try {
      final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      if (x != null && mounted) setState(() { if (sideA) { a = File(x.path); } else { b = File(x.path); } });
    } catch (e) { msg('تصویر منتخب نہیں ہو سکی: $e'); }
  }

  Future<void> save() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final bytes = await shot.capture(pixelRatio: 2.5);
      if (bytes == null) { msg('پوسٹر تیار نہیں ہو سکا۔'); return; }
      await Gal.putImageBytes(bytes, name: 'voting_pro_${DateTime.now().millisecondsSinceEpoch}');
      msg('پوسٹر گیلری میں محفوظ ہو گیا۔');
    } catch (e) { msg('محفوظ نہیں ہو سکا۔ گیلری کی اجازت چیک کریں۔'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> share() async {
    try {
      final bytes = await shot.capture(pixelRatio: 2.5);
      if (bytes == null) { msg('پوسٹر تیار نہیں ہو سکا۔'); return; }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/voting_pro_poster.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: 'Voting Pro Poster');
    } catch (e) { msg('شیئر نہیں ہو سکا: $e'); }
  }

  void backgrounds() {
    const colors = [Color(0xFF064B27), Color(0xFF102C67), Color(0xFF7F101B), Color(0xFF241044), Color(0xFF111827), Color(0xFF744210)];
    showModalBottomSheet<void>(context: context, builder: (c) => Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(spacing: 14, runSpacing: 14, children: colors.map((color) => InkWell(
        onTap: () { setState(() => background = color); Navigator.pop(c); },
        child: Container(width: 48, height: 48, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white))),
      )).toList()),
    ));
  }

  void frameTool() {
    showModalBottomSheet<void>(context: context, builder: (c) => StatefulBuilder(
      builder: (c, modalSet) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Frame Color'),
          Wrap(spacing: 12, children: [Colors.amber, Colors.white, Colors.pinkAccent, Colors.cyanAccent, Colors.redAccent, Colors.greenAccent].map((color) => InkWell(
            onTap: () { setState(() => frameColor = color); modalSet(() {}); },
            child: Container(width: 35, height: 35, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: frameColor == color ? Colors.black : Colors.transparent, width: 3))),
          )).toList()),
          const SizedBox(height: 12),
          const Text('Frame Thickness'),
          Slider(value: frameWidth, min: 1, max: 10, divisions: 9, onChanged: (v) { setState(() => frameWidth = v); modalSet(() {}); }),
          Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))),
        ]),
      ),
    ));
  }

  void canvasTool() {
    showModalBottomSheet<void>(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      for (final opt in <(String, double)>[('Poster 4:5', .8), ('Square 1:1', 1), ('Story 9:16', .5625), ('Landscape 16:9', 1.7778)])
        ListTile(title: Text(opt.$1), onTap: () { setState(() => canvasRatio = opt.$2); Navigator.pop(c); }),
    ]));
  }

  void emojiTool() {
    const emojis = ['⭐','🔥','👑','❤️','🏆','⚡','🎉','💥','👍','🌟','😊','💯'];
    showModalBottomSheet<void>(context: context, builder: (c) => Padding(
      padding: const EdgeInsets.all(18),
      child: Wrap(spacing: 12, runSpacing: 12, children: emojis.map((e) => InkWell(
        onTap: () { setState(() => overlays.add(e)); Navigator.pop(c); },
        child: Container(width: 52, height: 52, alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 28))),
      )).toList()),
    ));
  }

  Future<void> addText() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (c) => AlertDialog(
      title: const Text('متن شامل کریں'), content: TextField(controller: controller, maxLines: 3),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('Add'))],
    ));
    controller.dispose();
    if (value != null && value.isNotEmpty && mounted) setState(() => overlays.add(value));
  }

  Widget tool(String icon, String title, VoidCallback tap) {
    return Container(
      width: 128,
      height: 96,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Material(
        color: const Color(0xFF1B2638),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(color: mint, fontSize: 29, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget photoSlot(bool sideA) {
    final file = sideA ? a : b;
    return GestureDetector(onTap: () => pick(sideA), child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0xFF18202B), border: Border.all(color: gold, width: 3), borderRadius: BorderRadius.circular(8)),
      child: Stack(fit: StackFit.expand, children: [
        if (file != null) Image.file(file, fit: BoxFit.cover)
        else const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: mint, size: 34), SizedBox(height: 8), Text('تصویر شامل کریں', textAlign: TextAlign.center)])),
        Positioned(left: 0, right: 0, bottom: 0, child: Container(color: sideA ? const Color(0xCCB40E1B) : const Color(0xCC087B37), padding: const EdgeInsets.all(5), child: Text(sideA ? 'A SIDE' : 'B SIDE', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)))),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      const Row(children: [Icon(Icons.workspace_premium, color: gold, size: 34), SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Voting Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: gold)), Text('P O S T E R   M A K E R', style: TextStyle(fontSize: 10, letterSpacing: 2))]))]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.download_rounded), label: Text(busy ? 'ذرا انتظار کریں…' : 'Save Poster ↓'))),
        const SizedBox(width: 8), IconButton(onPressed: share, icon: const Icon(Icons.share)),
      ]),
    ])),
    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
      Screenshot(controller: shot, child: AspectRatio(aspectRatio: canvasRatio, child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: background, border: Border.all(color: frameColor, width: frameWidth)),
        child: Stack(children: [
          Column(children: [
            Expanded(flex: 7, child: Row(children: [Expanded(child: photoSlot(true)), const SizedBox(width: 6), Expanded(child: photoSlot(false))])),
            const SizedBox(height: 6),
            Expanded(flex: 3, child: Container(width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B0B08), Color(0xFF120B08), Color(0xFF6B0B08)]), border: Border.all(color: gold, width: 2), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('TAGDA\\nMUQABLA', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFFFFE35C)))))),
          ]),
          ...overlays.asMap().entries.map((entry) => Positioned(left: 10 + (entry.key % 4) * 35, top: 12 + (entry.key % 3) * 38, child: GestureDetector(onLongPress: () => setState(() => overlays.removeAt(entry.key)), child: Text(entry.value, style: const TextStyle(fontSize: 28, color: Colors.white))))),
        ]),
      ))),
      const SizedBox(height: 10), const Text('A یا B منتخب کریں، پھر گیلری سے تصویر لگائیں', style: TextStyle(color: Colors.white70, fontSize: 12)),
    ]))),
    Container(padding: const EdgeInsets.fromLTRB(8, 10, 8, 14), color: const Color(0xFF101827), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      tool('A', 'Add A Photo', () => pick(true)), tool('B', 'Add B Photo', () => pick(false)),
      tool('T', 'Text', addText), tool('✦', '3D Backgrounds', backgrounds),
      tool('☻', 'Stickers', emojiTool), tool('▣', 'Frame', frameTool),
      tool('😊', 'Emoji', emojiTool), tool('▱', 'Canvas', canvasTool),
      tool('▦', 'Background', backgrounds), tool('↗', 'Share Poster', share),
    ]))),
  ])));
}
