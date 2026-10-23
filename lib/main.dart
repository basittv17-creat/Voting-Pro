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
    home: const SplashScreen(),
  );
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Editor(),
            transitionDuration: const Duration(milliseconds: 350),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E19),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Transform.rotate(
                    angle: _controller.value * 2 * 3.141592653589793,
                    child: child,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 100,
                    color: Color(0xFFFFD84D),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Voting Pro',
                  style: TextStyle(
                    color: Color(0xFFFFD84D),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'P O S T E R   M A K E R',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 8,
                          backgroundColor: Color(0xFF263142),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFD84D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading... ${(_controller.value * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFFFFD84D),
                          fontSize: 13,
                        ),
                      ),
                    ],
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

class Editor extends StatefulWidget {
  const Editor({super.key});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final picker = ImagePicker();
  final shot = ScreenshotController();
  File? a, b;
  Color background = const Color(0xFF000000), frameColor = gold;
  double frameWidth = 3, canvasRatio = 4 / 3;
  bool busy = false;
  final List<String> overlays = [];
  final Set<int> textOverlayIds = {};
  final Set<int> stickerOverlayIds = {};
  int? selectedStickerIndex;
  double stickerGestureStartScale = 1.0;
  double stickerScaleStartY = 0.0;
  bool showTextTools = false;
  bool showStickerTools = false;
  int? selectedTextIndex;
  final Map<int, Offset> textPositions = {};
  final Map<int, double> textScales = {};
  double textGestureStartScale = 1.0;
  Offset textGestureStartPosition = Offset.zero;
  Offset textGestureStartFocalPoint = Offset.zero;
  Offset textGestureLastFocalPoint = Offset.zero;
  String? selectedStylishFrame;
  String? selectedASideLabel;
  Offset aSideLabelPosition = Offset.zero;
  bool showASideLabelDelete = false;
  String? selectedBSideLabel;
  bool showBSideLabelDelete = false;
  bool showVs = true;
  bool isVsSelected = false;
  Offset vsOffset = Offset.zero;
  double vsScale = 1.0;
  double vsStartScale = 1.0;
  String vsStyle = 'Classic';

  static const stylishFrames = <(String, String)>[
    ('Royal Gold', 'assets/stylish_frames/01_royal_gold_frame.png'),
    ('Elegant Gold', 'assets/stylish_frames/02_elegant_gold_frame.png'),
    ('Luxury Gold', 'assets/stylish_frames/03_luxury_gold_frame.png'),
    ('Modern Gold', 'assets/stylish_frames/04_modern_gold_frame.png'),
    ('Red Glow', 'assets/stylish_frames/05_red_glow_frame.png'),
    ('Green Glow', 'assets/stylish_frames/06_green_glow_frame.png'),
    ('Golden Light', 'assets/stylish_frames/07_golden_light_frame.png'),
    ('Blue Light', 'assets/stylish_frames/08_blue_light_frame.png'),
    ('Multi Color', 'assets/stylish_frames/09_multi_color_frame.png'),
    ('Diamond', 'assets/stylish_frames/10_diamond_frame.png'),
    ('Shine', 'assets/stylish_frames/11_shine_frame.png'),
    ('Golden Border', 'assets/stylish_frames/12_golden_border_frame.png'),
  ];

  void vsStylesTool() {
    const styles = <(String, Color, List<Color>)>[
      ('Royal Gold', Color(0xFFFFD700), [Color(0xFFFFF1A8), Color(0xFFB8860B)]),
      ('Fire', Color(0xFFFF5722), [Color(0xFFFFC107), Color(0xFFD50000)]),
      ('Blue Neon', Color(0xFF00E5FF), [Color(0xFF2979FF), Color(0xFF00FFFF)]),
      ('Green Neon', Color(0xFF76FF03), [Color(0xFF00C853), Color(0xFFB2FF59)]),
      ('Electric', Color(0xFFE040FB), [Color(0xFF7C4DFF), Color(0xFF00E5FF)]),
      ('Diamond', Color(0xFFE1F5FE), [Color(0xFF80DEEA), Color(0xFFFFFFFF)]),
      ('Rainbow', Color(0xFFFF4081), [Color(0xFFFF1744), Color(0xFF651FFF)]),
      ('Luxury', Color(0xFFFFE082), [Color(0xFF8D6E63), Color(0xFFFFD54F)]),
      ('Golden Glow', Color(0xFFFFC107), [Color(0xFFFFF59D), Color(0xFFFF6F00)]),
      ('Black & Gold', Color(0xFFFFD700), [Color(0xFF212121), Color(0xFFFFD700)]),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.55,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: styles.length,
            itemBuilder: (c, index) {
              final style = styles[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    vsStyle = style.$1;
                    showVs = true;
                    isVsSelected = false;
                    vsOffset = Offset.zero;
                    vsScale = 1.0;
                    vsStartScale = 1.0;
                  });
                  Navigator.pop(c);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: style.$3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: style.$2, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'VS  •  ${style.$1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: style.$2,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 5),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void stylishFramesTool() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.65,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: stylishFrames.length,
            itemBuilder: (c, index) {
              final frame = stylishFrames[index];
              return InkWell(
                onTap: () {
                  setState(() => selectedStylishFrame = frame.$2);
                  Navigator.pop(c);
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        frame.$2,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(frame.$1, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

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
    const sizes = <(String, double)>[
      ('Poster 4:5', 4 / 5),
      ('Portrait 3:4', 3 / 4),
      ('Portrait 4:3', 4 / 3),
      ('Portrait 2:3', 2 / 3),
      ('Story 9:16', 9 / 16),
      ('Square 1:1', 1),
      ('Landscape 4:3', 4 / 3),
      ('Landscape 3:2', 3 / 2),
      ('Landscape 16:9', 16 / 9),
      ('Landscape 5:4', 5 / 4),
      ('Banner 2:1', 2),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.7,
          child: ListView(
            children: [
              const ListTile(
                title: Text('Canvas Size'),
                subtitle: Text('اپنے پوسٹر کا سائز منتخب کریں'),
              ),
              for (final opt in sizes)
                ListTile(
                  leading: const Icon(Icons.aspect_ratio),
                  title: Text(opt.$1),
                  trailing: canvasRatio == opt.$2
                      ? const Icon(Icons.check, color: gold)
                      : null,
                  onTap: () {
                    setState(() => canvasRatio = opt.$2);
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void aSideLabelTool() {
    const styles = [
      "assets/label_bars/a_side/A_Side_Style_1.png",
      "assets/label_bars/a_side/A_Side_Style_2.png",
      "assets/label_bars/a_side/A_Side_Style_3.png",
      "assets/label_bars/a_side/A_Side_Style_4.png",
      "assets/label_bars/a_side/A_Side_Style_5.png",
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.65,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: styles.length,
            itemBuilder: (c, i) => InkWell(
              onTap: () {
                setState(() {
                  selectedASideLabel = styles[i];
                  aSideLabelPosition = Offset.zero;
                  showASideLabelDelete = false;
                });
                Navigator.pop(c);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF251019),
                  border: Border.all(color: gold, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(styles[i], fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void bSideLabelTool() {
    const styles = [
      "assets/label_bars/b_side/B_Side_Style_1.png",
      "assets/label_bars/b_side/B_Side_Style_2.png",
      "assets/label_bars/b_side/B_Side_Style_3.png",
      "assets/label_bars/b_side/B_Side_Style_4.png",
      "assets/label_bars/b_side/B_Side_Style_5.png",
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.65,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: styles.length,
            itemBuilder: (c, i) => InkWell(
              onTap: () {
                setState(() {
                  selectedBSideLabel = styles[i];
                  showBSideLabelDelete = false;
                });
                Navigator.pop(c);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10251A),
                  border: Border.all(color: const Color(0xFF35D07F), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(styles[i], fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void emojiTool() {
    const emojis = ['⭐','🔥','👑','❤️','🏆','⚡','🎉','💥','👍','🌟','😊','💯'];
    showModalBottomSheet<void>(context: context, builder: (c) => Padding(
      padding: const EdgeInsets.all(18),
      child: Wrap(spacing: 12, runSpacing: 12, children: emojis.map((e) => InkWell(
        onTap: () { setState(() { overlays.add(e); final index = overlays.length - 1; stickerOverlayIds.add(index); selectedStickerIndex = index; selectedTextIndex = null; }); Navigator.pop(c); },
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
    if (value != null && value.isNotEmpty && mounted) {
      setState(() {
        overlays.add(value);
        textOverlayIds.add(overlays.length - 1);
        selectedTextIndex = overlays.length - 1;
      });
    }
  }

  void zoomSelectedText(double factor) {
    final index = selectedTextIndex;
    if (index == null || index < 0 || index >= overlays.length || !textOverlayIds.contains(index)) return;
    setState(() {
      textScales[index] = ((textScales[index] ?? 1.0) * factor)
          .clamp(0.4, 4.0).toDouble();
    });
  }

  void zoomSelectedSticker(double factor) {
    final index = selectedStickerIndex;
    if (index == null || index < 0 || index >= overlays.length || stickerOverlayIds.contains(index) == false) return;
    setState(() {
      textScales[index] = ((textScales[index] ?? 1.0) * factor).clamp(0.4, 4.0).toDouble();
    });
  }

  void deleteSelectedText() {
    final index = selectedTextIndex;
    if (index == null ||
        index < 0 ||
        index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      return;
    }

    setState(() {
      overlays.removeAt(index);

      final oldPositions = Map<int, Offset>.from(textPositions);
      final oldScales = Map<int, double>.from(textScales);

      textPositions.clear();
      textScales.clear();

      final oldTextIds = Set<int>.from(textOverlayIds);
      textOverlayIds.clear();

      for (var i = 0; i < overlays.length; i++) {
        final sourceIndex = i < index ? i : i + 1;

        if (oldPositions.containsKey(sourceIndex)) {
          textPositions[i] = oldPositions[sourceIndex]!;
        }
        if (oldScales.containsKey(sourceIndex)) {
          textScales[i] = oldScales[sourceIndex]!;
        }
        if (oldTextIds.contains(sourceIndex)) {
          textOverlayIds.add(i);
        }
      }

      selectedTextIndex = null;
    });
  }


  void deleteSelectedSticker() {
    final index = selectedStickerIndex;
    if (index == null ||
        index < 0 ||
        index >= overlays.length ||
        !stickerOverlayIds.contains(index)) {
      return;
    }

    setState(() {
      overlays.removeAt(index);

      final oldPositions = Map<int, Offset>.from(textPositions);
      final oldScales = Map<int, double>.from(textScales);
      final oldTextIds = Set<int>.from(textOverlayIds);
      final oldStickerIds = Set<int>.from(stickerOverlayIds);

      textPositions.clear();
      textScales.clear();
      textOverlayIds.clear();
      stickerOverlayIds.clear();

      for (var i = 0; i < overlays.length; i++) {
        final sourceIndex = i < index ? i : i + 1;
        if (oldPositions.containsKey(sourceIndex)) {
          textPositions[i] = oldPositions[sourceIndex]!;
        }
        if (oldScales.containsKey(sourceIndex)) {
          textScales[i] = oldScales[sourceIndex]!;
        }
        if (oldTextIds.contains(sourceIndex)) textOverlayIds.add(i);
        if (oldStickerIds.contains(sourceIndex)) stickerOverlayIds.add(i);
      }

      selectedStickerIndex = null;
    });
  }

  void openTextTools() {
    setState(() {
      showTextTools = !showTextTools;
      showStickerTools = false;
    });
  }

  void openStickerTools() {
    setState(() {
      showStickerTools = !showStickerTools;
      showTextTools = false;
    });
  }

  Widget tool(String icon, String title, VoidCallback tap) {
    return Container(
      width: 112,
      height: 80,
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
              Text(icon, style: const TextStyle(color: mint, fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget photoSlot(bool sideA) {
    final file = sideA ? a : b;
    final label = sideA ? selectedASideLabel : selectedBSideLabel;
    final showDelete = sideA ? showASideLabelDelete : showBSideLabelDelete;
    return GestureDetector(
      onTap: () => pick(sideA),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF18202B),
          border: Border.all(color: gold, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(fit: StackFit.expand, children: [
          if (file != null)
            Image.file(file, fit: BoxFit.cover)
          else
            const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: mint, size: 34),
                SizedBox(height: 8),
                Text("تصویر شامل کریں", textAlign: TextAlign.center),
              ],
            )),
          if (label != null)
            Positioned(
              left: 0, right: 0, bottom: 0, height: 42,
              child: GestureDetector(
                onDoubleTap: () => setState(() {
                  if (sideA) { showASideLabelDelete = true; }
                  else { showBSideLabelDelete = true; }
                }),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(label, fit: BoxFit.contain),
                  if (showDelete)
                    Positioned(
                      right: 0, top: 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          if (sideA) {
                            selectedASideLabel = null;
                            showASideLabelDelete = false;
                          } else {
                            selectedBSideLabel = null;
                            showBSideLabelDelete = false;
                          }
                        }),
                        icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                        style: IconButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                ]),
              ),
            )
          else
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                color: sideA ? const Color(0xCCB40E1B) : const Color(0xCC087B37),
                padding: const EdgeInsets.all(5),
                child: Text(
                  sideA ? "A SIDE" : "B SIDE",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ]),
      ),
    );
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
    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Column(children: [
      Screenshot(controller: shot, child: AspectRatio(aspectRatio: canvasRatio, child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: background, border: Border.all(color: frameColor, width: frameWidth)),
        child: Stack(children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: photoSlot(true)),
                    const SizedBox(width: 6),
                    Expanded(child: photoSlot(false)),
                  ],
                ),
              ),
            ],
          ),
          if (showVs)
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: vsOffset,
                child: Transform.scale(
                  scale: vsScale,
                  child: GestureDetector(
                    onTap: () => setState(() => isVsSelected = true),
                    onScaleStart: (_) {
                      setState(() {
                        isVsSelected = true;
                        vsStartScale = vsScale;
                      });
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        vsOffset += details.focalPointDelta;
                        vsScale =
                            (vsStartScale * details.scale).clamp(0.5, 3.0).toDouble();
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: isVsSelected
                                ? Border.all(color: Colors.cyanAccent, width: 1)
                                : null,
                          ),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: const <String, Color>{
                                'Royal Gold': Color(0xFFFFD700),
                                'Fire': Color(0xFFFF5722),
                                'Blue Neon': Color(0xFF00E5FF),
                                'Green Neon': Color(0xFF76FF03),
                                'Electric': Color(0xFFE040FB),
                                'Diamond': Color(0xFFE1F5FE),
                                'Rainbow': Color(0xFFFF4081),
                                'Luxury': Color(0xFFFFE082),
                                'Golden Glow': Color(0xFFFFC107),
                                'Black & Gold': Color(0xFFFFD700),
                              }[vsStyle] ?? gold,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                        if (isVsSelected)
                          Positioned(
                            right: -12,
                            top: -12,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() {
                                showVs = false;
                                isVsSelected = false;
                                vsOffset = Offset.zero;
                                vsScale = 1.0;
                                vsStartScale = 1.0;
                              }),
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ...overlays.asMap().entries.map((entry) {
            final index = entry.key;
            final isText = textOverlayIds.contains(index);
            final isSticker = stickerOverlayIds.contains(index);
            final isSelectedSticker = isSticker && selectedStickerIndex == index;
            final position = textPositions[index] ??
                Offset(10 + (index % 4) * 35.0, 12 + (index % 3) * 38.0);
            final scale = textScales[index] ?? 1.0;
            return Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() {
                  if (isText) {
                    selectedTextIndex = index;
                    selectedStickerIndex = null;
                  } else {
                    selectedStickerIndex = index;
                    selectedTextIndex = null;
                  }
                }),
                onPanStart: (_) {
                  setState(() {
                    if (isText) {
                      selectedTextIndex = index;
                      selectedStickerIndex = null;
                    } else {
                      selectedStickerIndex = index;
                      selectedTextIndex = null;
                    }
                    textGestureStartPosition = textPositions[index] ??
                        Offset(10 + (index % 4) * 35.0, 12 + (index % 3) * 38.0);
                  });
                },
                onPanUpdate: (details) => setState(() {
                  if (isText) {
                    selectedTextIndex = index;
                  } else {
                    selectedStickerIndex = index;
                  }
                  textPositions[index] =
                      (textPositions[index] ?? textGestureStartPosition) + details.delta;
                }),
                child: Transform.scale(
                  scale: (isText || isSticker) ? scale : 1.0,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(5),
                        decoration: (isText && selectedTextIndex == index) || isSelectedSticker
                            ? BoxDecoration(
                                border: Border.all(color: gold, width: 2),
                                borderRadius: BorderRadius.circular(isSticker ? 12 : 3),
                              )
                            : null,
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 28, color: Colors.white),
                        ),
                      ),
                      if (isSticker && isSelectedSticker)
                        Positioned(
                          right: -13,
                          top: -13,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: deleteSelectedSticker,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete, size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      if (isSticker && isSelectedSticker)
                        Positioned(
                          right: -13,
                          bottom: -13,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              setState(() {
                                selectedStickerIndex = index;
                                stickerGestureStartScale = textScales[index] ?? 1.0;
                                stickerScaleStartY = details.globalPosition.dy;
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                final deltaY = details.globalPosition.dy - stickerScaleStartY;
                                textScales[index] = (stickerGestureStartScale + deltaY * 0.01).clamp(0.4, 4.0).toDouble();
                              });
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: gold,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      if (isText && selectedTextIndex == index)
                        Positioned(
                          right: -15,
                          top: -15,
                          child: GestureDetector(
                            onTap: deleteSelectedText,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete, size: 17, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (selectedStylishFrame != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  selectedStylishFrame!,
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                ),
              ),
            ),
        ]),
      ))),

    ]))),
    Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
      color: const Color(0xFF101827),
      child: (showTextTools || showStickerTools)
          ? Row(
              children: [
                tool('←', 'Back', () => setState(() { showTextTools = false; showStickerTools = false; })),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: showStickerTools ? [
                      tool('+', 'Add Sticker', emojiTool),
                      tool('+', 'Zoom +', () => zoomSelectedSticker(1.2)),
                      tool('−', 'Zoom −', () => zoomSelectedSticker(0.8)),
                      tool('🗑', 'Delete', deleteSelectedSticker),
                    ] : [
                      tool('+', 'Add Text', addText),
                      tool('＋', 'Zoom +', () => zoomSelectedText(1.2)),
                      tool('−', 'Zoom −', () => zoomSelectedText(0.8)),
                      tool('🗑', 'Delete', deleteSelectedText),
                    ]),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                tool('A', 'Add A Photo', () => pick(true)),
                tool('B', 'Add B Photo', () => pick(false)),
                tool('T', 'Text', openTextTools),
                tool('🟥', 'A Side Label', aSideLabelTool),
                tool('🟩', 'B Side Label', bSideLabelTool),
                tool('✦', '3D Backgrounds', backgrounds),
                tool('☻', 'Stickers', openStickerTools),
                tool('▣', 'Frame', frameTool),
                tool('😊', 'Emoji', emojiTool),
                tool('▱', 'Canvas', canvasTool),
                tool('▦', 'Background', backgrounds),
                tool('↗', 'Share Poster', share),
                tool('✨', 'Stylish Frames', stylishFramesTool),
                tool('⚔️', 'VS Styles', vsStylesTool),
              ]),
            ),
    ),
  ])));
}
