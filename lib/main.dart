import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          PageRouteBuilder<void>(
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

class _LetterStyleOverlay {
  _LetterStyleOverlay({required this.asset, required this.sideA});

  final String asset;
  final bool sideA;
  Offset position = const Offset(30, 30);
  double scale = 1.0;
}

class _TagraStickerOverlay {
  _TagraStickerOverlay({required this.asset});

  final String asset;
  Offset position = const Offset(70, 100);
  double scale = 1.0;
}

class Editor extends StatefulWidget {
  const Editor({super.key});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> with WidgetsBindingObserver {
  static const String _projectSaveKey = 'voting_pro_project_v1';
  Timer? _autoSaveTimer;
  bool _isRestoringProject = true;
  bool _isRestartingProject = false;

  final picker = ImagePicker();
  final shot = ScreenshotController();
  File? a, b;
  Color background = const Color(0xFF000000), frameColor = gold;
  double frameWidth = 3, canvasRatio = 4 / 3;
  bool busy = false;
  bool isExportingPoster = false;
  final List<String> overlays = [];
  final Set<int> textOverlayIds = {};
  final Set<int> stickerOverlayIds = {};
  int? selectedStickerIndex;
  double stickerGestureStartScale = 1.0;
  double stickerScaleStartY = 0.0;
  bool showTextTools = false;
  bool showGlowPanel = false;
  bool showStickerTools = false;
  bool showCanvasTools = false;
  bool showVotingStickerTools = false;

  bool showAStyleGallery = false;
  bool showBStyleGallery = false;
  bool showTagraStickerGallery = false;

  final List<_TagraStickerOverlay> tagraStickerOverlays = [];
  int? selectedTagraStickerIndex;
  Offset tagraGestureStartPosition = Offset.zero;
  double tagraGestureStartScale = 1.0;
  double tagraResizeStartY = 0.0;

  static const List<String> tagraStickerAssets = [
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_01_Royal_Gold.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_02_Comic_Burst.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_03_Green_Crown.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_04_Fire.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_05_Blue_Megaphone.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_06_Red_Brush.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_07_Gold_Trophy.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_08_Pakistan_Flag.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_09_Purple_Neon.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_10_Ice_Blue.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_11_Royal_Ribbon.png",
    "assets/tagra_muqabla_stickers/Tagra_Muqabla_12_Pink_Neon.png",
  ];

  final List<_LetterStyleOverlay> letterOverlays = [];
  int? selectedLetterOverlayIndex;
  Offset letterGestureStartPosition = Offset.zero;
  double letterGestureStartScale = 1.0;
  double letterResizeStartY = 0.0;
  double letterResizeStartScale = 1.0;

  static const List<String> aStyleAssets = [
    "assets/a_letter_styles/A_Style_01.png",
    "assets/a_letter_styles/A_Style_02.png",
    "assets/a_letter_styles/A_Style_03.png",
    "assets/a_letter_styles/A_Style_04.png",
    "assets/a_letter_styles/A_Style_05.png",
    "assets/a_letter_styles/A_Style_06.png",
    "assets/a_letter_styles/A_Style_07.png",
    "assets/a_letter_styles/A_Style_08.png",
    "assets/a_letter_styles/A_Style_09.png",
    "assets/a_letter_styles/A_Style_10.png",
  ];
  static const List<String> bStyleAssets = [
    "assets/b_letter_styles/B_Style_01.png",
    "assets/b_letter_styles/B_Style_02.png",
    "assets/b_letter_styles/B_Style_03.png",
    "assets/b_letter_styles/B_Style_04.png",
    "assets/b_letter_styles/B_Style_05.png",
    "assets/b_letter_styles/B_Style_06.png",
    "assets/b_letter_styles/B_Style_07.png",
    "assets/b_letter_styles/B_Style_08.png",
    "assets/b_letter_styles/B_Style_09.png",
    "assets/b_letter_styles/B_Style_10.png",
  ];

  String? leftVotingSticker;
  String? rightVotingSticker;
  static const List<String> votingStickerAssets = [
    "assets/voting_stickers/01_lion.png",
    "assets/voting_stickers/02_cheetah.png",
    "assets/voting_stickers/03_tiger.png",
    "assets/voting_stickers/04_elephant.png",
    "assets/voting_stickers/05_eagle.png",
    "assets/voting_stickers/06_wolf.png",
    "assets/voting_stickers/07_panther.png",
    "assets/voting_stickers/08_bear.png",
    "assets/voting_stickers/09_cobra.png",
    "assets/voting_stickers/10_crossed_swords.png",
  ];
  int? selectedTextIndex;
  final Map<int, Offset> textPositions = {};
  final Map<int, double> textScales = {};
  final Map<int, String> textFonts = {};
  final Map<int, Color> textColors = {};
  final Map<int, Color> textGlowColors = {};
  final Map<int, double> textGlowStrengths = {};
  double textGestureStartScale = 1.0;
  Offset textGestureStartPosition = Offset.zero;
  Offset textGestureStartFocalPoint = Offset.zero;
  Offset textGestureLastFocalPoint = Offset.zero;
  String? selectedStylishFrame;
  String? selectedReadyMadeTemplate;
  bool _templateANameEdited = false;
  bool _templateBNameEdited = false;
  String? selectedASideLabel;
  String aSideLabelText = 'A SIDE';
  String bSideLabelText = 'B SIDE';
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


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreProject();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _scheduleProjectSave();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _autoSaveTimer?.cancel();
      unawaited(_saveProject());
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleProjectSave() {
    if (!mounted || _isRestoringProject || _isRestartingProject) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 650), () {
      unawaited(_saveProject());
    });
  }

  Future<Directory> _projectDirectory() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/voting_pro_project');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> _persistProjectImage(File? source, String filename) async {
    if (source == null || !await source.exists()) return null;
    final dir = await _projectDirectory();
    final target = File('${dir.path}/$filename');
    if (source.absolute.path != target.absolute.path) {
      await source.copy(target.path);
    }
    return target.path;
  }

  List<double> _offsetJson(Offset value) => <double>[value.dx, value.dy];

  Offset _offsetFromJson(dynamic value, [Offset fallback = Offset.zero]) {
    if (value is List && value.length >= 2 &&
        value[0] is num && value[1] is num) {
      return Offset((value[0] as num).toDouble(), (value[1] as num).toDouble());
    }
    return fallback;
  }

  Map<String, dynamic> _offsetMapJson(Map<int, Offset> map) => {
    for (final entry in map.entries)
      entry.key.toString(): _offsetJson(entry.value),
  };

  Map<String, dynamic> _doubleMapJson(Map<int, double> map) => {
    for (final entry in map.entries)
      entry.key.toString(): entry.value,
  };

  Map<String, dynamic> _stringMapJson(Map<int, String> map) => {
    for (final entry in map.entries)
      entry.key.toString(): entry.value,
  };

  Map<String, dynamic> _colorMapJson(Map<int, Color> map) => {
    for (final entry in map.entries)
      entry.key.toString(): entry.value.value,
  };

  Future<void> _saveProject() async {
    if (_isRestoringProject || _isRestartingProject) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final imageA = await _persistProjectImage(a, 'side_a.img');
      final imageB = await _persistProjectImage(b, 'side_b.img');
      final data = <String, dynamic>{
        'version': 1,
        'imageA': imageA,
        'imageB': imageB,
        'background': background.value,
        'frameColor': frameColor.value,
        'frameWidth': frameWidth,
        'canvasRatio': canvasRatio,
        'overlays': overlays,
        'textOverlayIds': textOverlayIds.toList(),
        'stickerOverlayIds': stickerOverlayIds.toList(),
        'textPositions': _offsetMapJson(textPositions),
        'textScales': _doubleMapJson(textScales),
        'textFonts': _stringMapJson(textFonts),
        'textColors': _colorMapJson(textColors),
        'textGlowColors': _colorMapJson(textGlowColors),
        'textGlowStrengths': _doubleMapJson(textGlowStrengths),
        'tagraStickerOverlays': [
          for (final item in tagraStickerOverlays)
            {'asset': item.asset, 'position': _offsetJson(item.position), 'scale': item.scale},
        ],
        'letterOverlays': [
          for (final item in letterOverlays)
            {'asset': item.asset, 'sideA': item.sideA, 'position': _offsetJson(item.position), 'scale': item.scale},
        ],
        'leftVotingSticker': leftVotingSticker,
        'rightVotingSticker': rightVotingSticker,
        'selectedStylishFrame': selectedStylishFrame,
        'selectedReadyMadeTemplate': selectedReadyMadeTemplate,
        'templateANameEdited': _templateANameEdited,
        'templateBNameEdited': _templateBNameEdited,
        'aSideLabelText': aSideLabelText,
        'bSideLabelText': bSideLabelText,
        'aSideLabelPosition': _offsetJson(aSideLabelPosition),
        'selectedASideLabel': selectedASideLabel,
        'selectedBSideLabel': selectedBSideLabel,
        'showVs': showVs,
        'vsOffset': _offsetJson(vsOffset),
        'vsScale': vsScale,
        'vsStyle': vsStyle,
        'photoScales': {'a': _photoScales[true] ?? 1.0, 'b': _photoScales[false] ?? 1.0},
        'photoOffsets': {'a': _offsetJson(_photoOffsets[true] ?? Offset.zero), 'b': _offsetJson(_photoOffsets[false] ?? Offset.zero)},
        'templatePhotoScales': {
          'a': _templatePhotoScales[true] ?? 1.0,
          'b': _templatePhotoScales[false] ?? 1.0,
        },
        'templatePhotoOffsets': {
          'a': _offsetJson(_templatePhotoOffsets[true] ?? Offset.zero),
          'b': _offsetJson(_templatePhotoOffsets[false] ?? Offset.zero),
        },
      };
      await prefs.setString(_projectSaveKey, jsonEncode(data));
    } catch (_) {
      // Autosave is best-effort; keep editing even if storage is temporarily unavailable.
    }
  }

  Future<void> _restoreProject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_projectSaveKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);
      final imageAPath = data['imageA'] as String?;
      final imageBPath = data['imageB'] as String?;
      final imageA = imageAPath == null ? null : File(imageAPath);
      final imageB = imageBPath == null ? null : File(imageBPath);

      setState(() {
        a = imageA != null && imageA.existsSync() ? imageA : null;
        b = imageB != null && imageB.existsSync() ? imageB : null;
        background = Color((data['background'] as num?)?.toInt() ?? const Color(0xFF000000).value);
        frameColor = Color((data['frameColor'] as num?)?.toInt() ?? gold.value);
        frameWidth = (data['frameWidth'] as num?)?.toDouble() ?? 3;
        canvasRatio = (data['canvasRatio'] as num?)?.toDouble() ?? 4 / 3;
        overlays
          ..clear()
          ..addAll((data['overlays'] as List? ?? const []).whereType<String>());
        textOverlayIds
          ..clear()
          ..addAll((data['textOverlayIds'] as List? ?? const []).whereType<num>().map((v) => v.toInt()));
        stickerOverlayIds
          ..clear()
          ..addAll((data['stickerOverlayIds'] as List? ?? const []).whereType<num>().map((v) => v.toInt()));
        textPositions.clear();
        final positions = data['textPositions'];
        if (positions is Map) {
          for (final entry in positions.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null) textPositions[index] = _offsetFromJson(entry.value);
          }
        }
        textScales.clear();
        final scales = data['textScales'];
        if (scales is Map) {
          for (final entry in scales.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) textScales[index] = (entry.value as num).toDouble();
          }
        }
        textFonts.clear();
        final fonts = data['textFonts'];
        if (fonts is Map) {
          for (final entry in fonts.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is String) textFonts[index] = entry.value as String;
          }
        }
        textColors.clear();
        final colors = data['textColors'];
        if (colors is Map) {
          for (final entry in colors.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textColors[index] = Color((entry.value as num).toInt());
            }
          }
        }

        textGlowColors.clear();
        final savedGlowColors = data['textGlowColors'];
        if (savedGlowColors is Map) {
          for (final entry in savedGlowColors.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textGlowColors[index] = Color((entry.value as num).toInt());
            }
          }
        }

        textGlowStrengths.clear();
        final savedGlowStrengths = data['textGlowStrengths'];
        if (savedGlowStrengths is Map) {
          for (final entry in savedGlowStrengths.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textGlowStrengths[index] =
                  (entry.value as num).toDouble().clamp(0.0, 100.0).toDouble();
            }
          }
        }
        tagraStickerOverlays
          ..clear()
          ..addAll((data['tagraStickerOverlays'] as List? ?? const []).whereType<Map<dynamic, dynamic>>().map((item) {
            final overlay = _TagraStickerOverlay(asset: item['asset'] as String);
            overlay.position = _offsetFromJson(item['position']);
            overlay.scale = (item['scale'] as num?)?.toDouble() ?? 1.0;
            return overlay;
          }));
        letterOverlays
          ..clear()
          ..addAll((data['letterOverlays'] as List? ?? const []).whereType<Map<dynamic, dynamic>>().map((item) {
            final overlay = _LetterStyleOverlay(asset: item['asset'] as String, sideA: item['sideA'] as bool? ?? true);
            overlay.position = _offsetFromJson(item['position'], const Offset(30, 30));
            overlay.scale = (item['scale'] as num?)?.toDouble() ?? 1.0;
            return overlay;
          }));
        leftVotingSticker = data['leftVotingSticker'] as String?;
        rightVotingSticker = data['rightVotingSticker'] as String?;
        selectedStylishFrame = data['selectedStylishFrame'] as String?;
        selectedReadyMadeTemplate = data['selectedReadyMadeTemplate'] as String?;
        _templateANameEdited = data['templateANameEdited'] as bool? ?? false;
        _templateBNameEdited = data['templateBNameEdited'] as bool? ?? false;
        aSideLabelText = data['aSideLabelText'] as String? ?? 'A SIDE';
        bSideLabelText = data['bSideLabelText'] as String? ?? 'B SIDE';
        aSideLabelPosition = _offsetFromJson(data['aSideLabelPosition']);
        selectedASideLabel = data['selectedASideLabel'] as String?;
        selectedBSideLabel = data['selectedBSideLabel'] as String?;
        showVs = data['showVs'] as bool? ?? true;
        vsOffset = _offsetFromJson(data['vsOffset']);
        vsScale = (data['vsScale'] as num?)?.toDouble() ?? 1.0;
        vsStyle = data['vsStyle'] as String? ?? 'Classic';
        final photoScales = data['photoScales'];
        if (photoScales is Map) {
          _photoScales[true] = (photoScales['a'] as num?)?.toDouble() ?? 1.0;
          _photoScales[false] = (photoScales['b'] as num?)?.toDouble() ?? 1.0;
        }
        final photoOffsets = data['photoOffsets'];
        if (photoOffsets is Map) {
          _photoOffsets[true] = _offsetFromJson(photoOffsets['a']);
          _photoOffsets[false] = _offsetFromJson(photoOffsets['b']);
        }

        final templatePhotoScales = data['templatePhotoScales'];
        if (templatePhotoScales is Map) {
          _templatePhotoScales[true] =
              (templatePhotoScales['a'] as num?)?.toDouble() ?? 1.0;
          _templatePhotoScales[false] =
              (templatePhotoScales['b'] as num?)?.toDouble() ?? 1.0;
        }
        final templatePhotoOffsets = data['templatePhotoOffsets'];
        if (templatePhotoOffsets is Map) {
          _templatePhotoOffsets[true] =
              _offsetFromJson(templatePhotoOffsets['a']);
          _templatePhotoOffsets[false] =
              _offsetFromJson(templatePhotoOffsets['b']);
        }

        showTextTools = false;
        showStickerTools = false;
        showCanvasTools = false;
        showVotingStickerTools = false;
        showAStyleGallery = false;
        showBStyleGallery = false;
        showTagraStickerGallery = false;
      });
    } catch (_) {
      // Ignore an invalid old save and open a clean editor.
    } finally {
      _isRestoringProject = false;
    }
  }

  Future<void> restartProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نیا پروجیکٹ شروع کریں؟'),
        content: const Text('موجودہ محفوظ پروجیکٹ صاف ہو جائے گا۔ کیا آپ جاری رکھنا چاہتے ہیں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('منسوخ')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restart')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _isRestartingProject = true;
    _autoSaveTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_projectSaveKey);
      final dir = await _projectDirectory();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const Editor()),
      (_) => false,
    );
  }

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
      if (x != null && mounted) {
        final sourceFile = File(x.path);
        final projectDir = await _projectDirectory();
        final extension = x.path.contains('.')
            ? x.path.split('.').last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')
            : 'jpg';
        final uniqueName =
            '${sideA ? 'side_a' : 'side_b'}_${DateTime.now().microsecondsSinceEpoch}.${extension.isEmpty ? 'jpg' : extension}';
        final newImageFile = await sourceFile.copy('${projectDir.path}/$uniqueName');
        if (!mounted) return;
        await FileImage(newImageFile).evict();
        if (!mounted) return;
        setState(() {
          if (sideA) {
            a = newImageFile;
          } else {
            b = newImageFile;
          }
        });
      }
    } catch (e) {
      msg('تصویر منتخب نہیں ہو سکی: $e');
    }
  }

  Future<Uint8List?> capturePosterWithoutControls() async {
    if (!mounted) return null;
    setState(() => isExportingPoster = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      return await shot.capture(pixelRatio: 2.5);
    } finally {
      if (mounted) {
        setState(() => isExportingPoster = false);
      }
    }
  }

  // Clear selection state only; keep poster objects and their content intact.
  // This prevents selection borders and edit/delete/resize handles from being
  // included in the saved image.
  void _clearCanvasSelection() {
    selectedTextIndex = null;
    selectedStickerIndex = null;
    selectedTagraStickerIndex = null;
    selectedLetterOverlayIndex = null;
    isVsSelected = false;
    _selectedPhotoSideA = null;
    showASideLabelDelete = false;
    showBSideLabelDelete = false;
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      _clearCanvasSelection();
      busy = true;
    });
    try {
      final bytes = await capturePosterWithoutControls();
      if (bytes == null) {
        msg('پوسٹر تیار نہیں ہو سکا۔');
        return;
      }
      await Gal.putImageBytes(
        bytes,
        name: 'voting_pro_${DateTime.now().millisecondsSinceEpoch}',
      );
      msg('پوسٹر گیلری میں محفوظ ہو گیا۔');
    } catch (e) {
      msg('محفوظ نہیں ہو سکا۔ گیلری کی اجازت چیک کریں۔');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> share() async {
    try {
      final bytes = await capturePosterWithoutControls();
      if (bytes == null) {
        msg('پوسٹر تیار نہیں ہو سکا۔');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/voting_pro_poster.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Voting Pro Poster',
      );
    } catch (e) {
      msg('شیئر نہیں ہو سکا: $e');
    }
  }


  Widget _readyTemplateName(String text, {required bool sideA, required double availableWidth}) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: availableWidth * 0.26,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: sideA ? const Color(0xFFFFD51B) : const Color(0xFFFFF5FC),
            shadows: sideA
                ? const [
                    Shadow(color: Color(0xFF10102A), blurRadius: 2, offset: Offset(2, 3)),
                    Shadow(color: Color(0xFFFF9800), blurRadius: 8),
                  ]
                : const [
                    Shadow(color: Color(0xFF260014), blurRadius: 2, offset: Offset(2, 3)),
                    Shadow(color: Color(0xFFE60062), blurRadius: 8),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyMadeTemplateArtwork({bool preview = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        Widget photoLayer(bool sideA) {
          final File? photo = preview ? null : (sideA ? a : b);
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: sideA
                        ? const [Color(0xFF0B3A7A), Color(0xFF09162C)]
                        : const [Color(0xFF7E123D), Color(0xFF170C19)],
                  ),
                ),
              ),
              if (photo != null)
                ClipRect(
                  child: Transform.translate(
                    offset: _templatePhotoOffsets[sideA] ?? Offset.zero,
                    child: Transform.scale(
                      scale: _templatePhotoScales[sideA] ?? 1.0,
                      child: Image.file(
                        photo,
                        key: ValueKey<String>(
                          'template-photo-${sideA ? "A" : "B"}-${photo.path}',
                        ),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                )
              else if (!isExportingPoster)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.white.withOpacity(0.82), size: w * 0.045),
                      const SizedBox(height: 4),
                      Text(
                        sideA ? 'A کی تصویر' : 'B کی تصویر',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: w * 0.025,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF080E19)),
              Positioned(
                left: w * 0.010,
                top: h * 0.215,
                width: w * 0.345,
                height: h * 0.545,
                child: photoLayer(true),
              ),
              Positioned(
                left: w * 0.650,
                top: h * 0.215,
                width: w * 0.345,
                height: h * 0.545,
                child: photoLayer(false),
              ),
              Image.asset(
                'assets/templates/Tagra_Muqabla_Template.png',
                fit: BoxFit.fill,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              ),

              if (!preview && _templateANameEdited)
                Positioned.fill(
                  child: Image.asset(
                    'assets/templates/Tagra_Muqabla_A_NamePlate.png',
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              if (!preview && _templateBNameEdited)
                Positioned.fill(
                  child: Image.asset(
                    'assets/templates/Tagra_Muqabla_B_NamePlate.png',
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),

              if (!preview)
                Positioned(
                  left: w * 0.055,
                  top: h * 0.765,
                  width: w * 0.315,
                  height: h * 0.145,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => editSideLabelText(true),
                    child: _templateANameEdited
                        ? _readyTemplateName(aSideLabelText, sideA: true, availableWidth: w * 0.315)
                        : const SizedBox.expand(),
                  ),
                ),
              if (!preview)
                Positioned(
                  left: w * 0.630,
                  top: h * 0.765,
                  width: w * 0.315,
                  height: h * 0.145,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => editSideLabelText(false),
                    child: _templateBNameEdited
                        ? _readyTemplateName(bSideLabelText, sideA: false, availableWidth: w * 0.315)
                        : const SizedBox.expand(),
                  ),
                ),

              // Separate photo hit areas sit above the artwork, so transparent PNG pixels never block taps.
              if (!preview)
                Positioned(
                  left: w * 0.018,
                  top: h * 0.220,
                  width: w * 0.320,
                  height: h * 0.530,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pick(true),
                    onScaleStart: (_) {
                      _templatePhotoStartScales[true] =
                          _templatePhotoScales[true] ?? 1.0;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        _templatePhotoScales[true] =
                            ((_templatePhotoStartScales[true] ?? 1.0) *
                                    details.scale)
                                .clamp(0.8, 8.0)
                                .toDouble();
                        _templatePhotoOffsets[true] =
                            (_templatePhotoOffsets[true] ?? Offset.zero) +
                                details.focalPointDelta;
                      });
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              if (!preview)
                Positioned(
                  left: w * 0.655,
                  top: h * 0.220,
                  width: w * 0.330,
                  height: h * 0.530,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pick(false),
                    onScaleStart: (_) {
                      _templatePhotoStartScales[false] =
                          _templatePhotoScales[false] ?? 1.0;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        _templatePhotoScales[false] =
                            ((_templatePhotoStartScales[false] ?? 1.0) *
                                    details.scale)
                                .clamp(0.8, 8.0)
                                .toDouble();
                        _templatePhotoOffsets[false] =
                            (_templatePhotoOffsets[false] ?? Offset.zero) +
                                details.focalPointDelta;
                      });
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }


  void readyMadeTemplatesTool() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF080E19),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.88,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ready-made Voting Templates',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('پرانے Templates'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _legacyReadyMadeTemplatesTool();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'تگڑا مقابلہ — اصل پوسٹر کا ڈیزائن برقرار رہے گا۔',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AspectRatio(
                        aspectRatio: 1447 / 1087,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildReadyMadeTemplateArtwork(preview: true),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'صرف A/B کی تصاویر اور نیچے کے نام تبدیل کیے جا سکتے ہیں۔',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('یہ ٹیمپلیٹ استعمال کریں'),
                    onPressed: () {
                      setState(() {
                        selectedReadyMadeTemplate = 'tagra_muqabla';
                        _templateANameEdited = false;
                        _templateBNameEdited = false;
                        canvasRatio = 1447 / 1087;
                        background = dark;
                        frameWidth = 0;
                        selectedStylishFrame = null;
                        selectedASideLabel = null;
                        selectedBSideLabel = null;
                        aSideLabelText = 'اسد';
                        bSideLabelText = 'رقیہ';
                        showASideLabelDelete = false;
                        showBSideLabelDelete = false;
                        isVsSelected = false;
                        showTextTools = false;
                        showStickerTools = false;
                        showCanvasTools = false;
                        showVotingStickerTools = false;
                        showAStyleGallery = false;
                        showBStyleGallery = false;
                        showTagraStickerGallery = false;
                        selectedTextIndex = null;
                        selectedStickerIndex = null;
                        selectedTagraStickerIndex = null;
                        selectedLetterOverlayIndex = null;
                      });
                      Navigator.pop(sheetContext);
                      msg('تگڑا مقابلہ ٹیمپلیٹ منتخب ہوگیا۔ تصویر بدلنے کے لیے A/B حصے پر، اور نام بدلنے کے لیے نام پر ٹیپ کریں۔');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _legacyReadyMadeTemplatesTool() {
    const templates = <({
      String name,
      String subtitle,
      Color base,
      Color accent,
      String frame,
      String aLabel,
      String bLabel,
      String vs,
    })>[
      (
        name: 'Royal Blue & Pink',
        subtitle: 'آپ کے نمونے سے متاثر',
        base: Color(0xFF102C67),
        accent: Color(0xFFFF4F9A),
        frame: 'assets/stylish_frames/01_royal_gold_frame.png',
        aLabel: 'assets/label_bars/a_side/A_Side_Style_1.png',
        bLabel: 'assets/label_bars/b_side/B_Side_Style_2.png',
        vs: 'Royal Gold',
      ),
      (
        name: 'Classic Crown Battle',
        subtitle: 'گولڈن کراؤن اسٹائل',
        base: Color(0xFF111827),
        accent: Color(0xFFFFD700),
        frame: 'assets/stylish_frames/03_luxury_gold_frame.png',
        aLabel: 'assets/label_bars/a_side/A_Side_Style_2.png',
        bLabel: 'assets/label_bars/b_side/B_Side_Style_1.png',
        vs: 'Luxury',
      ),
      (
        name: 'Neon Battle',
        subtitle: 'نیون بلیو اور پنک',
        base: Color(0xFF090B2B),
        accent: Color(0xFFE040FB),
        frame: 'assets/stylish_frames/08_blue_light_frame.png',
        aLabel: 'assets/label_bars/a_side/A_Side_Style_4.png',
        bLabel: 'assets/label_bars/b_side/B_Side_Style_4.png',
        vs: 'Electric',
      ),
      (
        name: 'Red & Gold Arena',
        subtitle: 'ریڈ گلو اور گولڈ',
        base: Color(0xFF7F101B),
        accent: Color(0xFFFFD700),
        frame: 'assets/stylish_frames/05_red_glow_frame.png',
        aLabel: 'assets/label_bars/a_side/A_Side_Style_3.png',
        bLabel: 'assets/label_bars/b_side/B_Side_Style_5.png',
        vs: 'Fire',
      ),
      (
        name: 'Blue & Gold Classic',
        subtitle: 'شاہانہ بلیو اور گولڈ',
        base: Color(0xFF102C67),
        accent: Color(0xFFFFD700),
        frame: 'assets/stylish_frames/02_elegant_gold_frame.png',
        aLabel: 'assets/label_bars/a_side/A_Side_Style_5.png',
        bLabel: 'assets/label_bars/b_side/B_Side_Style_3.png',
        vs: 'Golden Glow',
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text(
                  'Ready-made Templates',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'ٹیمپلیٹ منتخب کریں، پھر A/B تصاویر اور نام اپنی مرضی سے تبدیل کریں۔',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          canvasRatio = 4 / 3;
                          background = template.base;
                          frameColor = template.accent;
                          frameWidth = 4;
                          selectedStylishFrame = template.frame;
                          selectedASideLabel = template.aLabel;
                          selectedBSideLabel = template.bLabel;
                          vsStyle = template.vs;
                          showVs = true;
                          isVsSelected = false;
                          vsOffset = Offset.zero;
                          vsScale = 1.0;
                          vsStartScale = 1.0;
                        });
                        Navigator.pop(sheetContext);
                        msg('${template.name} ٹیمپلیٹ منتخب ہوگیا۔');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [template.base, template.accent.withOpacity(0.72)],
                          ),
                          border: Border.all(color: template.accent, width: 2),
                          boxShadow: [
                            BoxShadow(color: template.accent.withOpacity(0.2), blurRadius: 8),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events, size: 32, color: template.accent),
                              const SizedBox(height: 8),
                              Text(
                                template.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                template.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.28),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('4:3  •  منتخب کریں', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    setState(() {
      showCanvasTools = true;
      showTextTools = false;
      showStickerTools = false;
    });
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
        onTap: () { setState(() { overlays.add(e); final index = overlays.length - 1; stickerOverlayIds.add(index); _selectCanvasObject(stickerIndex: index); }); Navigator.pop(c); },
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
        final index = overlays.length - 1;
        textOverlayIds.add(index);
        textFonts[index] = RegExp(r'[\u0600-\u06FF]').hasMatch(value)
            ? 'NotoNastaliqUrdu'
            : 'RobotoLocal';
        _selectCanvasObject(textIndex: index);
      });
    }
  }




  Future<void> editSelectedText() async {
    final index = selectedTextIndex;

    if (index == null ||
        index < 0 ||
        index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      msg('پہلے وہ ٹیکسٹ منتخب کریں جسے تبدیل کرنا ہے۔');
      return;
    }

    final controller = TextEditingController(
      text: overlays[index],
    );

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'اپنا ٹیکسٹ یہاں تبدیل کریں',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null && value.isNotEmpty && mounted) {
      setState(() {
        overlays[index] = value;
        selectedTextIndex = index;
      });
    }
  }

  List<Shadow> _textGlowShadows(int index) {
    final intensity =
        (textGlowStrengths[index] ?? 0.0).clamp(0.0, 200.0).toDouble();

    if (intensity <= 0) return const <Shadow>[];

    final color =
        textGlowColors[index] ?? const Color(0xFFFF1744);
    final level = intensity / 200.0;
    final power = intensity / 100.0;

    return <Shadow>[
      Shadow(
        color: color.withOpacity((0.35 + 0.35 * level).clamp(0.0, 1.0)),
        blurRadius: 3.0 + 8.0 * power,
      ),
      Shadow(
        color: color.withOpacity((0.30 + 0.50 * level).clamp(0.0, 1.0)),
        blurRadius: 6.0 + 18.0 * power,
      ),
      Shadow(
        color: color.withOpacity((0.25 + 0.60 * level).clamp(0.0, 1.0)),
        blurRadius: 10.0 + 30.0 * power,
      ),
    ];
  }

  void textGlowTool() {
    final index = selectedTextIndex;

    if (index == null ||
        index < 0 ||
        index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      msg('پہلے ٹیکسٹ منتخب کریں، پھر Glow کھولیں۔');
      return;
    }

    setState(() {
      showGlowPanel = !showGlowPanel;
    });
  }

  Widget _buildInlineGlowPanel() {
    final index = selectedTextIndex;

    if (index == null ||
        index < 0 ||
        index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      return const SizedBox.shrink();
    }

    const palette = <Color>[
      Color(0xFFFF1744),
      Color(0xFFFF4081),
      Color(0xFFFF6D00),
      Color(0xFFFFD600),
      Color(0xFF76FF03),
      Color(0xFF00E5FF),
      Color(0xFF2979FF),
      Color(0xFFD500F9),
      Color(0xFFFFFFFF),
    ];

    final strength =
        (textGlowStrengths[index] ?? 0.0).clamp(0.0, 200.0).toDouble();
    final selectedColor =
        textGlowColors[index] ?? const Color(0xFFFF1744);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111F),
        border: const Border(
          top: BorderSide(color: Color(0xFF00E5FF), width: 1.2),
          bottom: BorderSide(color: Color(0xFF17364A), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4400E5FF),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF00E5FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NEON GLOW STUDIO',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${strength.round()}%',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Close Glow',
                onPressed: () => setState(() => showGlowPanel = false),
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Glow Color',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final color in palette)
                GestureDetector(
                  onTap: () {
                    setState(() => textGlowColors[index] = color);
                  },
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color
                            ? Colors.white
                            : Colors.white24,
                        width: selectedColor == color ? 3 : 1,
                      ),
                      boxShadow: [
                        if (selectedColor == color)
                          BoxShadow(
                            color: color.withValues(alpha: 0.65),
                            blurRadius: 9,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: selectedColor == color
                        ? const Icon(Icons.check, size: 16, color: Colors.black)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.blur_on,
                color: Color(0xFF00E5FF),
                size: 19,
              ),
              const SizedBox(width: 7),
              const Text(
                'Intensity',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: strength,
                  min: 0,
                  max: 200,
                  divisions: 200,
                  activeColor: const Color(0xFF00E5FF),
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() => textGlowStrengths[index] = value);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Reset Glow',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() => textGlowStrengths[index] = 0.0);
                },
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF00E5FF),
                  size: 21,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void chooseTextColor() {
    final index = selectedTextIndex;
    if (index == null ||
        index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      msg('پہلے ٹیکسٹ منتخب کریں');
      return;
    }

    final premium = <Color>[
      const Color(0xFFFFD700), const Color(0xFFFFC857),
      const Color(0xFFB8860B), const Color(0xFFFFE5A3),
      const Color(0xFFE5C07B), const Color(0xFFB76E79),
      const Color(0xFFE8A0A8), const Color(0xFFAD6A6A),
      const Color(0xFFC0C0C0), const Color(0xFFE8E8E8),
      const Color(0xFF8A8A8A), const Color(0xFFFFFFFF),
      const Color(0xFF39FF14), const Color(0xFFFF00FF),
      const Color(0xFF00FFFF), const Color(0xFFFF3131),
      const Color(0xFF7DF9FF), const Color(0xFFFF6EC7),
      const Color(0xFFB026FF), const Color(0xFFFE4EDA),
      const Color(0xFF00FF9C), const Color(0xFFFF7A00),
      const Color(0xFF001F3F), const Color(0xFF4B0082),
      const Color(0xFF004D40), const Color(0xFF800020),
      const Color(0xFF4169E1), const Color(0xFFDC143C),
      const Color(0xFF228B22), const Color(0xFFFFDAB9),
      const Color(0xFFFFB6C1), const Color(0xFFB0E0E6),
      const Color(0xFFD8BFD8), const Color(0xFFF5F5DC),
    ];

    final palette = <Color>[...premium];
    for (var h = 0; h < 360; h += 12) {
      for (final sat in <double>[0.45, 0.70, 0.90, 1.0]) {
        for (final val in <double>[0.55, 0.75, 0.95]) {
          palette.add(HSVColor.fromAHSV(1, h.toDouble(), sat, val).toColor());
        }
      }
    }
    for (var i = 0; i <= 10; i++) {
      final v = i / 10;
      palette.add(HSVColor.fromAHSV(1, 0, 0, v).toColor());
    }

    Future<void> openCustomPicker(BuildContext sheetContext) async {
      final initial = textColors[index] ?? Colors.white;
      final hsv = HSVColor.fromColor(initial);
      var hue = hsv.hue;
      var saturation = hsv.saturation;
      var value = hsv.value;

      await showDialog<void>(
        context: sheetContext,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            final color = HSVColor.fromAHSV(1, hue, saturation, value).toColor();
            void updateColor() {
              final next = HSVColor.fromAHSV(1, hue, saturation, value).toColor();
              setState(() => textColors[index] = next);
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF101827),
              title: const Text(
                'Custom Color',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Hue: ${hue.round()}°',
                        style: const TextStyle(color: Colors.white)),
                    Slider(
                      value: hue,
                      min: 0,
                      max: 360,
                      activeColor: color,
                      onChanged: (v) {
                        dialogSetState(() => hue = v);
                        updateColor();
                      },
                    ),
                    Text('Saturation: ${(saturation * 100).round()}%',
                        style: const TextStyle(color: Colors.white)),
                    Slider(
                      value: saturation,
                      min: 0,
                      max: 1,
                      activeColor: color,
                      onChanged: (v) {
                        dialogSetState(() => saturation = v);
                        updateColor();
                      },
                    ),
                    Text('Brightness: ${(value * 100).round()}%',
                        style: const TextStyle(color: Colors.white)),
                    Slider(
                      value: value,
                      min: 0,
                      max: 1,
                      activeColor: color,
                      onChanged: (v) {
                        dialogSetState(() => value = v);
                        updateColor();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101827),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Text Color Studio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => openCustomPicker(sheetContext),
                      icon: const Icon(Icons.colorize, color: Colors.white),
                      label: const Text(
                        'Custom',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Premium • Gold • Neon • Pastel • 300+ Colors',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Preview: ',
                        style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        overlays[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColors[index] ?? Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reset to white',
                      onPressed: () => setState(
                          () => textColors[index] = Colors.white),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 9,
                      runSpacing: 11,
                      children: palette.map((color) {
                        final selected = (textColors[index] ?? Colors.white) == color;
                        return GestureDetector(
                          onTap: () => setState(() => textColors[index] = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? Colors.white : Colors.white24,
                                width: selected ? 3 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      const BoxShadow(
                                        color: Colors.white30,
                                        blurRadius: 7,
                                      )
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    size: 19, color: Colors.black)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Apply Color'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void chooseTextFont() {
    final index = selectedTextIndex;
    if (index == null ||
        index < 0 ||
        index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      msg('پہلے ٹیکسٹ منتخب کریں');
      return;
    }

    final isUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(overlays[index]);
    final fonts = isUrdu
        ? <(String, String)>[
            ('NotoNastaliqUrdu', 'اردو نستعلیق'),
            ('NotoNastaliqUrdu', 'عربی خطاطی'),
            ('NotoNastaliqUrdu', 'ماڈرن اردو'),
          ]
        : <(String, String)>[
            ('RobotoLocal', 'Modern'),
            ('OswaldLocal', 'Bold'),
            ('PlayfairDisplayLocal', 'Elegant'),
            ('RobotoLocal', 'Clean'),
            ('PacificoLocal', 'Handwriting'),
          ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101827),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUrdu ? 'اردو فونٹس منتخب کریں' : 'Choose English Font',
                style: const TextStyle(
                  color: gold, fontSize: 20, fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fonts.map((font) => ActionChip(
                  label: Text(
                    font.$2,
                    style: TextStyle(
                      fontFamily: font.$1,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  backgroundColor: textFonts[index] == font.$1
                      ? const Color(0xFF087B65)
                      : const Color(0xFF263247),
                  onPressed: () {
                    setState(() => textFonts[index] = font.$1);
                    Navigator.pop(sheetContext);
                  },
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
      final oldFonts = Map<int, String>.from(textFonts);
      final oldColors = Map<int, Color>.from(textColors);
      final oldGlowColors = Map<int, Color>.from(textGlowColors);
      final oldGlowStrengths = Map<int, double>.from(textGlowStrengths);

      textPositions.clear();
      textScales.clear();
      textFonts.clear();
      textColors.clear();
      textGlowColors.clear();
      textGlowStrengths.clear();

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
        if (oldFonts.containsKey(sourceIndex)) textFonts[i] = oldFonts[sourceIndex]!;
        if (oldColors.containsKey(sourceIndex)) textColors[i] = oldColors[sourceIndex]!;
        if (oldGlowColors.containsKey(sourceIndex)) {
          textGlowColors[i] = oldGlowColors[sourceIndex]!;
        }
        if (oldGlowStrengths.containsKey(sourceIndex)) {
          textGlowStrengths[i] = oldGlowStrengths[sourceIndex]!;
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
      final oldFonts = Map<int, String>.from(textFonts);
      final oldColors = Map<int, Color>.from(textColors);
      final oldGlowColors = Map<int, Color>.from(textGlowColors);
      final oldGlowStrengths = Map<int, double>.from(textGlowStrengths);
      final oldTextIds = Set<int>.from(textOverlayIds);
      final oldStickerIds = Set<int>.from(stickerOverlayIds);

      textPositions.clear();
      textScales.clear();
      textFonts.clear();
      textColors.clear();
      textGlowColors.clear();
      textGlowStrengths.clear();
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
        if (oldFonts.containsKey(sourceIndex)) textFonts[i] = oldFonts[sourceIndex]!;
        if (oldColors.containsKey(sourceIndex)) textColors[i] = oldColors[sourceIndex]!;
        if (oldGlowColors.containsKey(sourceIndex)) {
          textGlowColors[i] = oldGlowColors[sourceIndex]!;
        }
        if (oldGlowStrengths.containsKey(sourceIndex)) {
          textGlowStrengths[i] = oldGlowStrengths[sourceIndex]!;
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
      showCanvasTools = false;
    });
  }

  void openStickerTools() {
    setState(() {
      showStickerTools = !showStickerTools;
      showTextTools = false;
      showCanvasTools = false;
    });
  }


  void openTagraStickerGallery() {
    setState(() {
      final previousTagraIndex = selectedTagraStickerIndex;
      showTagraStickerGallery = true;
      showAStyleGallery = false;
      showBStyleGallery = false;
      showTextTools = false;
      showStickerTools = false;
      showCanvasTools = false;
      showVotingStickerTools = false;

      // Keep the current Tagra sticker active while browsing alternative designs.
      // If none is selected, target the most recently added sticker instead.
      if (tagraStickerOverlays.isEmpty) {
        _selectCanvasObject();
      } else {
        final targetIndex = previousTagraIndex != null &&
                previousTagraIndex >= 0 &&
                previousTagraIndex < tagraStickerOverlays.length
            ? previousTagraIndex
            : tagraStickerOverlays.length - 1;
        _selectCanvasObject(tagraIndex: targetIndex);
      }
    });
  }

  void addTagraStickerOverlay(String asset) {
    setState(() {
      // The Tagra gallery is a design chooser, not an "add another layer" action.
      // Replace the existing sticker, preserving its position and size, and clean
      // up duplicates left by older versions of the app.
      final selectedIndex = selectedTagraStickerIndex;
      _TagraStickerOverlay? previous;
      if (selectedIndex != null &&
          selectedIndex >= 0 &&
          selectedIndex < tagraStickerOverlays.length) {
        previous = tagraStickerOverlays[selectedIndex];
      } else if (tagraStickerOverlays.isNotEmpty) {
        previous = tagraStickerOverlays.last;
      }

      final replacement = _TagraStickerOverlay(asset: asset);
      if (previous != null) {
        replacement.position = previous.position;
        replacement.scale = previous.scale;
      }

      tagraStickerOverlays
        ..clear()
        ..add(replacement);
      _selectCanvasObject(tagraIndex: 0);
    });
  }

  void deleteSelectedTagraSticker() {
    final index = selectedTagraStickerIndex;
    if (index == null ||
        index < 0 ||
        index >= tagraStickerOverlays.length) {
      return;
    }

    setState(() {
      tagraStickerOverlays.removeAt(index);
      selectedTagraStickerIndex = null;
    });
  }

  void openLetterStyleGallery(bool sideA) {
    setState(() {
      showAStyleGallery = sideA;
      showBStyleGallery = !sideA;
      showTextTools = false;
      showStickerTools = false;
      showCanvasTools = false;
      showVotingStickerTools = false;
    });
  }

  void addLetterStyleOverlay(String asset, bool sideA) {
    setState(() {
      final matchingIndices = <int>[];

      for (var i = 0; i < letterOverlays.length; i++) {
        if (letterOverlays[i].sideA == sideA) {
          matchingIndices.add(i);
        }
      }

      late final int index;

      if (matchingIndices.isNotEmpty) {
        index = matchingIndices.first;
        final old = letterOverlays[index];

        final replacement = _LetterStyleOverlay(
          asset: asset,
          sideA: sideA,
        )
          ..position = old.position
          ..scale = old.scale;

        letterOverlays[index] = replacement;

        for (final duplicateIndex
            in matchingIndices.skip(1).toList().reversed) {
          letterOverlays.removeAt(duplicateIndex);
        }
      } else {
        letterOverlays.add(
          _LetterStyleOverlay(asset: asset, sideA: sideA),
        );
        index = letterOverlays.length - 1;
      }

      _selectCanvasObject(letterIndex: index);
    });
  }

  void deleteSelectedLetterOverlay() {
    final index = selectedLetterOverlayIndex;
    if (index == null || index < 0 || index >= letterOverlays.length) return;
    setState(() {
      letterOverlays.removeAt(index);
      selectedLetterOverlayIndex = null;
    });
  }

  Widget letterStyleTool(String asset, String title, VoidCallback tap) {
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
              SizedBox(
                height: 43,
                width: 64,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tool(String icon, String title, VoidCallback tap) {
    final isGlowTool = title == 'Glow';
    final originalTap = tap;
    tap = () {
      if (isVsSelected && mounted) {
        setState(() => isVsSelected = false);
      }
      originalTap();
    };
    return Container(
      width: 112,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isGlowTool
            ? const [
                BoxShadow(
                  color: Color(0x6600E5FF),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: isGlowTool
            ? const Color(0xFF063747)
            : const Color(0xFF1B2638),
        elevation: isGlowTool ? 8 : 0,
        shadowColor: const Color(0xFF00E5FF),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isGlowTool
                  ? Border.all(
                      color: const Color(0xFF00E5FF),
                      width: 1.8,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: TextStyle(
                    color: isGlowTool
                        ? const Color(0xFF00E5FF)
                        : mint,
                    fontSize: isGlowTool ? 27 : 23,
                    fontWeight: FontWeight.bold,
                    shadows: isGlowTool
                        ? const [
                            Shadow(
                              color: Color(0xFF00E5FF),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isGlowTool
                        ? const Color(0xFF00E5FF)
                        : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final Map<bool, double> _photoScales = {true: 1.0, false: 1.0};
  final Map<bool, Offset> _photoOffsets = {true: Offset.zero, false: Offset.zero};
  final Map<bool, double> _photoStartScales = {true: 1.0, false: 1.0};

  // Independent zoom and pan for Ready-made template photos.
  final Map<bool, double> _templatePhotoScales = {true: 1.0, false: 1.0};
  final Map<bool, Offset> _templatePhotoOffsets = {
    true: Offset.zero,
    false: Offset.zero,
  };
  final Map<bool, double> _templatePhotoStartScales = {
    true: 1.0,
    false: 1.0,
  };

  // Exactly one canvas object is active at a time. This prevents overlapping
  // GestureDetectors from leaving multiple objects selected or moving together.
  bool? _selectedPhotoSideA;

  void _selectCanvasObject({
    int? tagraIndex,
    int? letterIndex,
    int? textIndex,
    int? stickerIndex,
    bool isVs = false,
    bool? photoSideA,
  }) {
    // Centralized exclusive selection: passing one target clears every other
    // movable object's selection. Label asset paths are content, not selection.
    selectedTagraStickerIndex = tagraIndex;
    selectedLetterOverlayIndex = letterIndex;
    selectedTextIndex = textIndex;
    selectedStickerIndex = stickerIndex;
    isVsSelected = isVs;
    _selectedPhotoSideA = photoSideA;

    // Close stale label-delete handles when the user selects another object.
    showASideLabelDelete = false;
    showBSideLabelDelete = false;
  }

  Future<void> editSideLabelText(bool sideA) async {
    final controller = TextEditingController(
      text: sideA ? aSideLabelText : bSideLabelText,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(sideA ? 'Edit A Side Name' : 'Edit B Side Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 28,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Enter your text',
            hintText: 'Type name here',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (sideA) {
          aSideLabelText = result;
          if (selectedReadyMadeTemplate != null) _templateANameEdited = true;
        } else {
          bSideLabelText = result;
          if (selectedReadyMadeTemplate != null) _templateBNameEdited = true;
        }
      });
    }
  }

  Widget photoSlot(bool sideA) {
    final file = sideA ? a : b;
    final label = sideA ? selectedASideLabel : selectedBSideLabel;
    final showDelete = sideA ? showASideLabelDelete : showBSideLabelDelete;
    final labelText = sideA ? aSideLabelText : bSideLabelText;
    return GestureDetector(
      onTap: () {
        if (file == null) {
          pick(sideA);
          return;
        }
        setState(() => _selectCanvasObject(photoSideA: sideA));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF18202B),
          border: Border.all(color: gold, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(fit: StackFit.expand, children: [
          if (file != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectCanvasObject(photoSideA: sideA)),
              onScaleStart: (_) {
                setState(() {
                  _selectCanvasObject(photoSideA: sideA);
                  _photoStartScales[sideA] = _photoScales[sideA] ?? 1.0;
                });
              },
              onScaleUpdate: (details) {
                if (_selectedPhotoSideA != sideA) return;
                setState(() {
                  _photoScales[sideA] = ((_photoStartScales[sideA] ?? 1.0) *
                      details.scale).clamp(1.0, 5.0).toDouble();
                  _photoOffsets[sideA] =
                      (_photoOffsets[sideA] ?? Offset.zero) + details.focalPointDelta;
                });
              },
              child: ClipRect(
                child: Transform.translate(
                  offset: _photoOffsets[sideA] ?? Offset.zero,
                  child: Transform.scale(
                    scale: _photoScales[sideA] ?? 1.0,
                    child: Image.file(
                      file,
                      key: ValueKey<String>(
                        'editor-photo-${sideA ? "A" : "B"}-${file.path}',
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            )
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
                onTap: () => editSideLabelText(sideA),
                onDoubleTap: () => setState(() {
                  if (sideA) { showASideLabelDelete = true; }
                  else { showBSideLabelDelete = true; }
                }),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(label, fit: BoxFit.contain),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        widthFactor: 0.68,
                        heightFactor: 0.86,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            labelText,
                            maxLines: 1,
                            textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(labelText)
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: TextStyle(
                              fontFamily: RegExp(r'[\u0600-\u06FF]').hasMatch(labelText)
                                  ? 'NotoNastaliqUrdu'
                                  : 'OswaldLocal',
                              color: label.contains('Style_4')
                                  ? const Color(0xFFFFD45C)
                                  : Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 3,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                child: GestureDetector(
                  onTap: () => editSideLabelText(sideA),
                  child: Text(
                    labelText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
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
        padding: selectedReadyMadeTemplate == null ? const EdgeInsets.all(7) : EdgeInsets.zero,
        decoration: selectedReadyMadeTemplate == null
            ? BoxDecoration(color: background, border: Border.all(color: frameColor, width: frameWidth))
            : const BoxDecoration(color: dark),
        child: Stack(children: [
          if (selectedReadyMadeTemplate == null)
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
          if (selectedReadyMadeTemplate == null && leftVotingSticker != null)
            Positioned(
              left: 2,
              top: 2,
              width: 42,
              height: 42,
              child: Image.asset(leftVotingSticker!, fit: BoxFit.contain),
            ),
          if (selectedReadyMadeTemplate == null && rightVotingSticker != null)
            Positioned(
              right: 2,
              top: 2,
              width: 42,
              height: 42,
              child: Image.asset(rightVotingSticker!, fit: BoxFit.contain),
            ),
          if (selectedReadyMadeTemplate == null && showVs)
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: vsOffset,
                child: Transform.scale(
                  scale: vsScale,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectCanvasObject(isVs: true)),
                    onScaleStart: (_) {
                      setState(() {
                        _selectCanvasObject(isVs: true);
                        vsStartScale = vsScale;
                      });
                    },
                    onScaleUpdate: (details) {
                      if (!isVsSelected) return;
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
                            right: 0,
                            top: 0,
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


          if (selectedReadyMadeTemplate == null) ...letterOverlays.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final selected = selectedLetterOverlayIndex == index;
            return Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() {
                  _selectCanvasObject(letterIndex: index);
                }),
                onScaleStart: (details) {
                  setState(() {
                    _selectCanvasObject(letterIndex: index);
                    letterGestureStartPosition = item.position;
                    letterGestureStartScale = item.scale;
                  });
                },
                onScaleUpdate: (details) {
                  if (selectedLetterOverlayIndex != index) return;
                  setState(() {
                    item.position += details.focalPointDelta;
                    if (details.pointerCount >= 2) {
                      item.scale =
                          (letterGestureStartScale * details.scale).clamp(0.2, 5.0).toDouble();
                    }
                  });
                },
                child: Transform.scale(
                  scale: item.scale,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: selected
                            ? BoxDecoration(
                                border: Border.all(color: gold, width: 1.5),
                              )
                            : null,
                        child: Image.asset(
                          item.asset,
                          width: 110,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: -12,
                          top: -12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (index < 0 || index >= letterOverlays.length) {
                                return;
                              }
                              setState(() {
                                letterOverlays.removeAt(index);
                                selectedLetterOverlayIndex = null;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (selected)
                        Positioned(
                          right: -12,
                          bottom: -12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              setState(() {
                                _selectCanvasObject(letterIndex: index);
                                letterResizeStartY = details.globalPosition.dy;
                                letterResizeStartScale = item.scale;
                              });
                            },
                            onPanUpdate: (details) {
                              if (selectedLetterOverlayIndex != index) return;
                              setState(() {
                                final dy = details.globalPosition.dy - letterResizeStartY;
                                item.scale =
                                    (letterResizeStartScale + dy * 0.01).clamp(0.2, 5.0).toDouble();
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
                    ],
                  ),
                ),
              ),
            );
          }),
          if (selectedReadyMadeTemplate == null) ...tagraStickerOverlays.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final selected = !isExportingPoster && selectedTagraStickerIndex == index;

            return Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() {
                  _selectCanvasObject(tagraIndex: index);
                }),
                onScaleStart: (details) {
                  setState(() {
                    _selectCanvasObject(tagraIndex: index);
                    tagraGestureStartPosition = item.position;
                    tagraGestureStartScale = item.scale;
                  });
                },
                onScaleUpdate: (details) {
                  if (selectedTagraStickerIndex != index) return;
                  setState(() {
                    item.position += details.focalPointDelta;
                    if (details.pointerCount >= 2) {
                      item.scale = (tagraGestureStartScale * details.scale)
                          .clamp(0.2, 5.0)
                          .toDouble();
                    }
                  });
                },
                child: Transform.scale(
                  scale: item.scale,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: selected
                            ? BoxDecoration(
                                border: Border.all(
                                  color: gold,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Image.asset(
                          item.asset,
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.broken_image,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: -12,
                          top: -12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: deleteSelectedTagraSticker,
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      if (selected)
                        Positioned(
                          right: -12,
                          bottom: -12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              setState(() {
                                _selectCanvasObject(tagraIndex: index);
                                tagraGestureStartScale = item.scale;
                                tagraResizeStartY = details.globalPosition.dy;
                              });
                            },
                            onPanUpdate: (details) {
                              if (selectedTagraStickerIndex != index) return;
                              setState(() {
                                final delta =
                                    details.globalPosition.dy -
                                    tagraResizeStartY;
                                item.scale =
                                    (tagraGestureStartScale + delta * 0.01)
                                        .clamp(0.2, 5.0)
                                        .toDouble();
                              });
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: gold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.open_in_full,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (selectedReadyMadeTemplate == null) ...overlays.asMap().entries.map((entry) {
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
                    _selectCanvasObject(textIndex: index);
                  } else {
                    _selectCanvasObject(stickerIndex: index);
                  }
                }),
                onDoubleTap: () {
                  if (isText) {
                    deleteSelectedText();
                  }
                },
                onScaleStart: (details) {
                  setState(() {
                    if (isText) {
                      _selectCanvasObject(textIndex: index);
                    } else {
                      _selectCanvasObject(stickerIndex: index);
                    }
                    textGestureStartPosition = textPositions[index] ??
                        Offset(10 + (index % 4) * 35.0, 12 + (index % 3) * 38.0);
                    textGestureStartScale = textScales[index] ?? 1.0;
                  });
                },
                onScaleUpdate: (details) {
                  if (isText ? selectedTextIndex != index : selectedStickerIndex != index) return;
                  setState(() {
                    if (isText) {
                      if (details.pointerCount >= 2) {
                        textScales[index] =
                            (textGestureStartScale * details.scale).clamp(0.4, 4.0).toDouble();
                      } else {
                        textPositions[index] =
                            (textPositions[index] ?? textGestureStartPosition) +
                            details.focalPointDelta;
                      }
                    } else {
                      textPositions[index] =
                          (textPositions[index] ?? textGestureStartPosition) +
                          details.focalPointDelta;
                    }
                  });
                },
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
                          style: TextStyle(
                            fontFamily: textFonts[index] ??
                                (RegExp(r'[\u0600-\u06FF]').hasMatch(entry.value)
                                    ? 'NotoNastaliqUrdu'
                                    : 'RobotoLocal'),
                            fontSize: 28,
                            color: textColors[index] ?? Colors.white,
                            shadows: _textGlowShadows(index),
                          ),
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
                                _selectCanvasObject(stickerIndex: index);
                                stickerGestureStartScale = textScales[index] ?? 1.0;
                                stickerScaleStartY = details.globalPosition.dy;
                              });
                            },
                            onPanUpdate: (details) {
                              if (selectedStickerIndex != index) return;
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
                            behavior: HitTestBehavior.opaque,
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
                      if (isText && selectedTextIndex == index)
                        Positioned(
                          left: -15,
                          top: -15,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: editSelectedText,
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A6A6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (isText && selectedTextIndex == index)
                        Positioned(
                          right: -13,
                          bottom: -13,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              setState(() {
                                _selectCanvasObject(textIndex: index);
                                textGestureStartScale = textScales[index] ?? 1.0;
                                textGestureStartFocalPoint = details.globalPosition;
                              });
                            },
                            onPanUpdate: (details) {
                              if (selectedTextIndex != index) return;
                              setState(() {
                                final deltaY = details.globalPosition.dy -
                                    textGestureStartFocalPoint.dy;
                                textScales[index] = (textGestureStartScale +
                                    deltaY * 0.015)
                                    .clamp(0.4, 4.0).toDouble();
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
                              child: const Icon(
                                Icons.open_in_full,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (selectedReadyMadeTemplate == null && selectedStylishFrame != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.10,
                    child: Image.asset(
                      selectedStylishFrame!,
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
          if (selectedReadyMadeTemplate != null)
            Positioned.fill(child: _buildReadyMadeTemplateArtwork()),
        ]),
      ))),

    ]))),
    if (showGlowPanel && showTextTools && selectedTextIndex != null)
      _buildInlineGlowPanel(),
    Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
      color: const Color(0xFF101827),
      child: selectedReadyMadeTemplate != null
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                tool('A', 'Change Photo A', () => pick(true)),
                tool('B', 'Change Photo B', () => pick(false)),
                tool('🎨', 'Templates', readyMadeTemplatesTool),
                tool('↩', 'Classic Editor', () => setState(() {
                  selectedReadyMadeTemplate = null;
                  _templateANameEdited = false;
                  _templateBNameEdited = false;
                  canvasRatio = 4 / 3;
                  frameWidth = 3;
                  frameColor = gold;
                  background = dark;
                })),
              ]),
            )
          : (showTextTools || showStickerTools || showCanvasTools || showVotingStickerTools || showAStyleGallery || showBStyleGallery || showTagraStickerGallery)
          ? Row(
              children: [
                tool('←', 'Back', () => setState(() { showTextTools = false; showStickerTools = false; showCanvasTools = false; showVotingStickerTools = false; showAStyleGallery = false; showBStyleGallery = false; showTagraStickerGallery = false; selectedLetterOverlayIndex = null; selectedTagraStickerIndex = null; })),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: showTagraStickerGallery ? [
                      for (final asset in tagraStickerAssets)
                        letterStyleTool(
                          asset,
                          asset.split("/").last
                              .replaceAll(".png", "")
                              .replaceAll("Tagra_Muqabla_", "")
                              .replaceAll("_", " "),
                          () => addTagraStickerOverlay(asset),
                        ),
                    ] : (showAStyleGallery || showBStyleGallery) ? [
                      for (final asset in (showAStyleGallery ? aStyleAssets : bStyleAssets))
                        letterStyleTool(
                          asset,
                          asset.split("/").last.replaceAll(".png", "").replaceAll("_", " "),
                          () => addLetterStyleOverlay(asset, showAStyleGallery),
                        ),
                    ] : showVotingStickerTools ? [
                      for (final asset in votingStickerAssets)
                        tool(
                          "👑",
                          asset.split("/").last.replaceAll(".png", "").replaceAll(RegExp(r"^\d+_"), "").replaceAll("_", " "),
                          () => setState(() {
                            if (leftVotingSticker == null) {
                              leftVotingSticker = asset;
                            } else if (rightVotingSticker == null) {
                              rightVotingSticker = asset;
                            } else {
                              rightVotingSticker = asset;
                            }
                          }),
                        ),
                    ] : showCanvasTools ? [
                      for (final opt in const <(String, double)>[
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
                      ])
                        tool(canvasRatio == opt.$2 ? '✓' : '▱', opt.$1, () => setState(() => canvasRatio = opt.$2)),
                    ] : showStickerTools ? [
                      tool('+', 'Add Sticker', emojiTool),
                      tool('+', 'Zoom +', () => zoomSelectedSticker(1.2)),
                      tool('−', 'Zoom −', () => zoomSelectedSticker(0.8)),
                      tool('🗑', 'Delete', deleteSelectedSticker),
                    ] : [
                      tool('+', 'Add Text', addText),
                      tool('✎', 'Edit Text', editSelectedText),
                      tool('Aa', 'Font', chooseTextFont),
                      tool('🎨', 'Color', chooseTextColor),
                      tool(
                        '✨',
                        'Glow',
                        textGlowTool,
                      ),
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
                tool('A', 'Add Photo A', () => pick(true)),
                tool('B', 'Add Photo B', () => pick(false)),
                tool('🎨', 'Ready-made Templates', readyMadeTemplatesTool),
                letterStyleTool('assets/a_letter_styles/A_Style_01.png', 'A Style', () => openLetterStyleGallery(true)),
                letterStyleTool('assets/b_letter_styles/B_Style_01.png', 'B Style', () => openLetterStyleGallery(false)),
                tool('T', 'Text', openTextTools),
                tool('🟥', 'A Side Label', aSideLabelTool),
                tool('🟩', 'B Side Label', bSideLabelTool),
                tool('✦', '3D Backgrounds', backgrounds),
                tool('☻', 'Stickers', openStickerTools),
                tool('▣', 'Frame', frameTool),
                tool('😊', 'Emoji', emojiTool),
                tool('▱', 'Canvas', canvasTool),
                tool('👑', 'Voting Sticker', () => setState(() { showVotingStickerTools = true; showTextTools = false; showStickerTools = false; showCanvasTools = false; })),
                tool('▦', 'Background', backgrounds),
                tool('↗', 'Share Poster', share),
                tool('✨', 'Stylish Frames', stylishFramesTool),
                tool('⚔️', 'VS Styles', vsStylesTool),
                tool('🏆', 'تگڑا مقابلہ اسٹیکرز', openTagraStickerGallery),
                tool('↻', 'Restart Project', restartProject),
              ]),
            ),
    ),
  ])));
}
