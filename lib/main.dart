import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'widgets/neon_purple_vs_template.dart';
import 'widgets/metallic_vs_battle_template.dart';
import 'widgets/advanced_text_overlay.dart';
import 'widgets/premium_text_editor_panel.dart';
import 'widgets/bg_remover_page.dart';
import 'services/poster_share_cache.dart';
import 'app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    AppLanguage.current =
        prefs.getString(AppLanguage.preferenceKey) == 'ur' ? 'ur' : 'en';
  } catch (_) {
    AppLanguage.current = 'en';
  }
  runApp(const PosterApp());
}
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
  final GlobalKey<ScaffoldState> _editorScaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _autoSaveTimer;
  // Serialize disk writes so overlapping autosaves/lifecycle saves cannot race.
  Future<void> _saveQueue = Future<void>.value();
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

  bool showReadyMadeTemplateGallery = false;

  static const List<({
    String key,
    String name,
    Color base,
    Color accent,
    String frame,
    String aLabel,
    String bLabel,
    String vs,
  })> _readyTemplateOptions = [
    (
      key: 'royal_a_vs_b_battle',
      name: 'Royal Battle',
      base: Color(0xFF071B42),
      accent: Color(0xFFFFD84D),
      frame: '',
      aLabel: '',
      bLabel: '',
      vs: '',
    ),
    (
      key: 'tagra_muqabla',
      name: 'Tagra Muqabla',
      base: Color(0xFF08152B),
      accent: Color(0xFFFF4F9A),
      frame: '',
      aLabel: '',
      bLabel: '',
      vs: '',
    ),
    (
      key: 'neon_purple_showdown',
      name: 'Neon Purple VS',
      base: Color(0xFF080E19),
      accent: Color(0xFFB44CFF),
      frame: '',
      aLabel: '',
      bLabel: '',
      vs: '',
    ),
    (
      key: 'metallic_vs_battle',
      name: 'Metallic VS Battle',
      base: Color(0xFF080808),
      accent: Color(0xFFFF3025),
      frame: '',
      aLabel: '',
      bLabel: '',
      vs: '',
    ),
    (
      key: 'royal_blue_pink',
      name: 'Royal Blue',
      base: Color(0xFF102C67),
      accent: Color(0xFFFF4F9A),
      frame: 'assets/stylish_frames/01_royal_gold_frame.png',
      aLabel: 'assets/label_bars/a_side/A_Side_Style_1.png',
      bLabel: 'assets/label_bars/b_side/B_Side_Style_2.png',
      vs: 'Royal Gold',
    ),
    (
      key: 'classic_crown',
      name: 'Gold Crown',
      base: Color(0xFF111827),
      accent: Color(0xFFFFD700),
      frame: 'assets/stylish_frames/03_luxury_gold_frame.png',
      aLabel: 'assets/label_bars/a_side/A_Side_Style_2.png',
      bLabel: 'assets/label_bars/b_side/B_Side_Style_1.png',
      vs: 'Luxury',
    ),
    (
      key: 'neon_battle',
      name: 'Neon Battle',
      base: Color(0xFF090B2B),
      accent: Color(0xFFE040FB),
      frame: 'assets/stylish_frames/08_blue_light_frame.png',
      aLabel: 'assets/label_bars/a_side/A_Side_Style_4.png',
      bLabel: 'assets/label_bars/b_side/B_Side_Style_4.png',
      vs: 'Electric',
    ),
    (
      key: 'red_gold_arena',
      name: 'Red & Gold',
      base: Color(0xFF7F101B),
      accent: Color(0xFFFFD700),
      frame: 'assets/stylish_frames/05_red_glow_frame.png',
      aLabel: 'assets/label_bars/a_side/A_Side_Style_3.png',
      bLabel: 'assets/label_bars/b_side/B_Side_Style_5.png',
      vs: 'Fire',
    ),
    (
      key: 'blue_gold_classic',
      name: 'Blue & Gold',
      base: Color(0xFF102C67),
      accent: Color(0xFFFFD700),
      frame: 'assets/stylish_frames/02_elegant_gold_frame.png',
      aLabel: 'assets/label_bars/a_side/A_Side_Style_5.png',
      bLabel: 'assets/label_bars/b_side/B_Side_Style_3.png',
      vs: 'Golden Glow',
    ),
  ];

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
  final Map<int, Color> textBgColors = {};
  final Map<int, double> textBgOpacities = {};
  final Map<int, double> textBgPaddings = {};
  final Map<int, double> textBgRadii = {};
  final Map<int, double> textBgBorders = {};
  final Map<int, double> textBgShadows = {};
  final Set<int> textBgGradients = {};
  final Map<int, Color> textGlowColors = {};
  final Map<int, String> textAlignments = {};
  final Map<int, double> textLetterSpacings = {};
  final Set<int> boldTextOverlayIds = {};
  final Set<int> italicTextOverlayIds = {};
  final Set<int> underlineTextOverlayIds = {};
  final Set<int> strikeTextOverlayIds = {};
  final Map<int, double> textOpacities = {};
  final Map<int, double> textLineHeights = {};
  final Map<int, double> textOutlineWidths = {};
  final Map<int, Color> textOutlineColors = {};
  final Map<int, double> textCurves = {};
  final Set<int> gradientTextOverlayIds = {};
  final Map<int, String> customFontPaths = {};
  final Set<String> _loadedCustomFontFamilies = {};
  final List<Map<String, Object>> _textUndoHistory = [];
  final List<Map<String, Object>> _textRedoHistory = [];
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

  // Source photo files are immutable per gallery import / cutout, so avoid
  // copying multi-megabyte PNG/JPEG data on every text-slider autosave.
  final Map<String, String> _lastPersistedPhotoSources = {};

  Future<String?> _persistProjectImage(File? source, String filename) async {
    if (source == null || !await source.exists()) return null;
    final dir = await _projectDirectory();
    final target = File('${dir.path}/$filename');
    final sourcePath = source.absolute.path;
    if (sourcePath == target.absolute.path) {
      _lastPersistedPhotoSources[filename] = sourcePath;
      return target.path;
    }
    if (_lastPersistedPhotoSources[filename] == sourcePath &&
        await target.exists()) {
      return target.path;
    }
    await source.copy(target.path);
    _lastPersistedPhotoSources[filename] = sourcePath;
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

  Future<void> _saveProject() {
    if (_isRestoringProject || _isRestartingProject) {
      return Future<void>.value();
    }
    final save = _saveQueue.then((_) => _saveProjectSnapshot());
    _saveQueue = save.catchError((Object _) {});
    return save;
  }

  Future<void> _loadSavedCustomFonts(Map<String, dynamic> data) async {
    final storedFonts = data['textFonts'];
    final storedPaths = data['customFontPaths'];
    if (storedFonts is! Map || storedPaths is! Map) return;
    for (final entry in storedPaths.entries) {
      final family = storedFonts[entry.key];
      if (family is! String || !family.startsWith('VotingCustomFont') ||
          entry.value is! String || _loadedCustomFontFamilies.contains(family)) continue;
      try {
        final path = entry.value as String;
        final dir = await _projectDirectory();
        if (!path.startsWith('${dir.path}/custom_font_')) continue;
        final file = File(path);
        if (!await file.exists() || await file.length() > 5 * 1024 * 1024) continue;
        await ui.loadFontFromList(await file.readAsBytes(), fontFamily: family);
        _loadedCustomFontFamilies.add(family);
      } catch (_) {}
    }
  }

  Future<void> _saveProjectSnapshot() async {
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
        'textAlignments': _stringMapJson(textAlignments),
        'textLetterSpacings': _doubleMapJson(textLetterSpacings),
        'boldTextOverlayIds': boldTextOverlayIds.toList(),
        'italicTextOverlayIds': italicTextOverlayIds.toList(),
        'underlineTextOverlayIds': underlineTextOverlayIds.toList(),
        'strikeTextOverlayIds': strikeTextOverlayIds.toList(),
        'textOpacities': _doubleMapJson(textOpacities),
        'textLineHeights': _doubleMapJson(textLineHeights),
        'textOutlineWidths': _doubleMapJson(textOutlineWidths),
        'textOutlineColors': _colorMapJson(textOutlineColors),
        'textCurves': _doubleMapJson(textCurves),
        'gradientTextOverlayIds': gradientTextOverlayIds.toList(),
        'customFontPaths': _stringMapJson(customFontPaths),
        'textColors': _colorMapJson(textColors),
        'textBgColors': _colorMapJson(textBgColors),
        'textBgOpacities': _doubleMapJson(textBgOpacities),
        'textBgPaddings': _doubleMapJson(textBgPaddings),
        'textBgRadii': _doubleMapJson(textBgRadii),
        'textBgBorders': _doubleMapJson(textBgBorders),
        'textBgShadows': _doubleMapJson(textBgShadows),
        'textBgGradients': textBgGradients.toList(),
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

      await _loadSavedCustomFonts(data);
      if (!mounted) return;
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
        textAlignments.clear();
        final savedAlignments = data['textAlignments'];
        if (savedAlignments is Map) {
          for (final entry in savedAlignments.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && (entry.value == 'left' || entry.value == 'center' || entry.value == 'right')) {
              textAlignments[index] = entry.value as String;
            }
          }
        }
        textLetterSpacings.clear();
        final savedSpacings = data['textLetterSpacings'];
        if (savedSpacings is Map) {
          for (final entry in savedSpacings.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textLetterSpacings[index] = (entry.value as num).toDouble().clamp(-1.0, 8.0).toDouble();
            }
          }
        }
        boldTextOverlayIds
          ..clear()
          ..addAll((data['boldTextOverlayIds'] as List? ?? const []).whereType<num>().map((v) => v.toInt()));

        italicTextOverlayIds
          ..clear()
          ..addAll((data['italicTextOverlayIds'] as List? ?? const []).whereType<num>().map((v) => v.toInt()));
        underlineTextOverlayIds
          ..clear()
          ..addAll((data['underlineTextOverlayIds'] as List? ?? const []).whereType<num>().map((v) => v.toInt()));
        strikeTextOverlayIds
          ..clear()
          ..addAll((data['strikeTextOverlayIds'] as List? ?? const []).whereType<num>().map((v) => v.toInt()));
        textOpacities.clear();
        final storedOpacities = data['textOpacities'];
        if (storedOpacities is Map) {
          for (final entry in storedOpacities.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textOpacities[index] = (entry.value as num).toDouble().clamp(0.1, 1.0).toDouble();
            }
          }
        }
        textLineHeights.clear();
        final storedLineHeights = data['textLineHeights'];
        if (storedLineHeights is Map) {
          for (final entry in storedLineHeights.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textLineHeights[index] = (entry.value as num).toDouble().clamp(0.8, 2.5).toDouble();
            }
          }
        }

        textOutlineWidths.clear();
        final savedStrokeWidths = data['textOutlineWidths'];
        if (savedStrokeWidths is Map) {
          for (final entry in savedStrokeWidths.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textOutlineWidths[index] = (entry.value as num).toDouble().clamp(0.0, 8.0).toDouble();
            }
          }
        }
        textOutlineColors.clear();
        final savedStrokeColors = data['textOutlineColors'];
        if (savedStrokeColors is Map) {
          for (final entry in savedStrokeColors.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textOutlineColors[index] = Color((entry.value as num).toInt());
            }
          }
        }
        textCurves.clear();
        final savedCurves = data['textCurves'];
        if (savedCurves is Map) {
          for (final entry in savedCurves.entries) {
            final index = int.tryParse(entry.key.toString());
            if (index != null && entry.value is num) {
              textCurves[index] = (entry.value as num).toDouble().clamp(-1.0, 1.0).toDouble();
            }
          }
        }
        gradientTextOverlayIds
          ..clear()
          ..addAll((data['gradientTextOverlayIds'] as List? ?? const []).whereType<num>().map((v) => v.toInt()));
        customFontPaths.clear();
        final savedCustomFonts = data['customFontPaths'];
        if (savedCustomFonts is Map) {
          for (final entry in savedCustomFonts.entries) {
            final index = int.tryParse(entry.key.toString());
            final family = textFonts[index];
            if (index != null && entry.value is String &&
                family != null && _loadedCustomFontFamilies.contains(family)) {
              customFontPaths[index] = entry.value as String;
            }
          }
        }
        void readBgColors() {
          textBgColors.clear();
          final saved = data['textBgColors'];
          if (saved is Map) {
            for (final e in saved.entries) {
              final i = int.tryParse(e.key.toString());
              if (i != null && e.value is num) textBgColors[i] = Color((e.value as num).toInt());
            }
          }
        }
        void readBgValues(String key, Map<int, double> dest, double max) {
          dest.clear();
          final saved = data[key];
          if (saved is Map) {
            for (final e in saved.entries) {
              final i = int.tryParse(e.key.toString());
              if (i != null && e.value is num) {
                dest[i] = (e.value as num).toDouble().clamp(0.0, max).toDouble();
              }
            }
          }
        }
        readBgColors();
        readBgValues('textBgOpacities', textBgOpacities, 1);
        readBgValues('textBgPaddings', textBgPaddings, 24);
        readBgValues('textBgRadii', textBgRadii, 36);
        readBgValues('textBgBorders', textBgBorders, 6);
        readBgValues('textBgShadows', textBgShadows, 24);
        textBgGradients..clear()..addAll(
          (data['textBgGradients'] as List? ?? const []).whereType<num>().map((e) => e.toInt()));
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
                  (entry.value as num).toDouble().clamp(0.0, 200.0).toDouble();
            }
          }
        }
        tagraStickerOverlays
          ..clear()
          ..addAll((data['tagraStickerOverlays'] as List? ?? const []).whereType<Map<Object?, Object?>>().map((item) {
            final overlay = _TagraStickerOverlay(asset: item['asset'] as String);
            overlay.position = _offsetFromJson(item['position']);
            overlay.scale = (item['scale'] as num?)?.toDouble() ?? 1.0;
            return overlay;
          }));
        letterOverlays
          ..clear()
          ..addAll((data['letterOverlays'] as List? ?? const []).whereType<Map<Object?, Object?>>().map((item) {
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

        // Old saved projects may refer to templates no longer installed.
        // Return to the classic canvas without clearing either saved photo,
        // text, or any data for templates that still exist.
        if (selectedReadyMadeTemplate != null &&
            !_readyTemplateOptions.any(
              (template) => template.key == selectedReadyMadeTemplate)) {
          selectedReadyMadeTemplate = null;
          _templateANameEdited = false;
          _templateBNameEdited = false;
          canvasRatio = 4 / 3;
          background = dark;
          frameColor = gold;
          frameWidth = 3;
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
        title: Text(AppLanguage.tr('نیا پروجیکٹ شروع کریں؟')),
        content: Text(AppLanguage.tr('موجودہ محفوظ پروجیکٹ صاف ہو جائے گا۔ کیا آپ جاری رکھنا چاہتے ہیں؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppLanguage.tr('Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppLanguage.tr('Restart'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _isRestartingProject = true;
    _autoSaveTimer?.cancel();
    try {
      // Wait for pending autosaves before removing the old project.
      await _saveQueue;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_projectSaveKey);
      final dir = await _projectDirectory();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // The next editor still starts from its default in-memory state.
      // Do not restore the old project if clearing its files fails.
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const Editor()),
      (_) => false,
    );
  }

  Future<void> _changeAppLanguage(String language) async {
    if (language != 'en' && language != 'ur') return;
    if (AppLanguage.current != language && mounted) {
      setState(() => AppLanguage.current = language);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppLanguage.preferenceKey, language);
    } catch (_) {
      // The selected language remains active for the current session.
    }
  }

  static const String _votingProPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.awasigogera.votingpro';

  Future<void> _shareVotingProApp() async {
    try {
      await Share.share(
        'Voting Pro — Poster Maker\n'
        'Download Voting Pro from Google Play:\n'
        '$_votingProPlayStoreUrl',
        subject: 'Voting Pro',
      );
    } catch (error) {
      msg(AppLanguage.isUrdu
          ? 'ایپ شیئر نہیں ہو سکی: $error'
          : 'Could not share the app: $error');
    }
  }

  Widget _buildSettingsDrawer() {
    return Directionality(
      textDirection: AppLanguage.direction,
      child: Drawer(
        backgroundColor: const Color(0xFF101827),
        width: (MediaQuery.sizeOf(context).width * 0.82)
            .clamp(260.0, 340.0).toDouble(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: gold, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Voting Pro',
                      style: TextStyle(color: gold, fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    tooltip: AppLanguage.tr('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 21),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF303B50), height: 26),
              Text(AppLanguage.tr('App Language'),
                style: const TextStyle(color: gold,
                  fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _languageOption('ur', 'اردو'),
              const SizedBox(height: 6),
              _languageOption('en', 'English'),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF303B50)),
              const SizedBox(height: 10),
              Material(
                color: const Color(0xFF26374D),
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: const Icon(Icons.share_rounded, color: mint),
                  title: Text(AppLanguage.tr('Share App'),
                    textDirection: AppLanguage.direction,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white70),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareVotingProApp();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageOption(String code, String label) {
    final selected = AppLanguage.current == code;
    return Material(
      color: selected ? const Color(0xFF30334A) : const Color(0xFF1B2638),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(Icons.language_rounded,
          color: selected ? gold : Colors.white70),
        title: Text(label, textDirection: code == 'ur'
            ? TextDirection.rtl : TextDirection.ltr),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: mint)
            : const Icon(Icons.circle_outlined, color: Colors.white38),
        onTap: () async {
          Navigator.of(context).pop();
          await _changeAppLanguage(code);
        },
      ),
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLanguage.tr(s), textDirection: AppLanguage.direction)));
  }

  Future<void> pick(bool sideA) async {
    try {
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2400,
        maxHeight: 2400,
      );
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

          // A replacement photo starts with its own default crop/zoom.
          // Keep the opposite side's photo and transform untouched.
          _photoScales[sideA] = 1.0;
          _photoOffsets[sideA] = Offset.zero;
          _photoStartScales[sideA] = 1.0;
          _templatePhotoScales[sideA] = 1.0;
          _templatePhotoOffsets[sideA] = Offset.zero;
          _templatePhotoStartScales[sideA] = 1.0;
          // Explicitly choosing a photo overrides the sticky text lock.
          _clearCanvasSelection();
          _selectCanvasObject(photoSideA: sideA);
        });
      }
    } catch (e) {
      msg('تصویر منتخب نہیں ہو سکی: $e');
    }
  }

  Future<Uint8List?> capturePosterWithoutControls() async {
    if (!mounted) return null;
    // Hide handles for export without permanently discarding the selection.
    // Users can resume manipulating the same text after saving or sharing.
    final previousText = selectedTextIndex;
    final previousSticker = selectedStickerIndex;
    final previousTagra = selectedTagraStickerIndex;
    final previousLetter = selectedLetterOverlayIndex;
    final previousVs = isVsSelected;
    final previousPhoto = _selectedPhotoSideA;
    final previousTemplatePhoto = _selectedTemplatePhotoSideA;
    final previousADelete = showASideLabelDelete;
    final previousBDelete = showBSideLabelDelete;
    setState(() {
      _clearCanvasSelection();
      isExportingPoster = true;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      return await shot.capture(pixelRatio: 2.5);
    } finally {
      if (mounted) {
        setState(() {
          isExportingPoster = false;
          selectedTextIndex = previousText != null &&
                  previousText >= 0 &&
                  previousText < overlays.length &&
                  textOverlayIds.contains(previousText)
              ? previousText : null;
          selectedStickerIndex = previousSticker != null &&
                  previousSticker >= 0 &&
                  previousSticker < overlays.length &&
                  stickerOverlayIds.contains(previousSticker)
              ? previousSticker : null;
          selectedTagraStickerIndex = previousTagra != null &&
                  previousTagra >= 0 &&
                  previousTagra < tagraStickerOverlays.length
              ? previousTagra : null;
          selectedLetterOverlayIndex = previousLetter != null &&
                  previousLetter >= 0 &&
                  previousLetter < letterOverlays.length
              ? previousLetter : null;
          isVsSelected = previousVs;
          _selectedPhotoSideA = previousPhoto;
          _selectedTemplatePhotoSideA = previousTemplatePhoto;
          showASideLabelDelete = previousADelete;
          showBSideLabelDelete = previousBDelete;
        });
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
    _selectedTemplatePhotoSideA = null;
    showASideLabelDelete = false;
    showBSideLabelDelete = false;
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
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
    if (busy) return;
    setState(() {
      busy = true;
    });
    try {
      final bytes = await capturePosterWithoutControls();
      if (bytes == null) {
        msg('پوسٹر تیار نہیں ہو سکا۔');
        return;
      }
      final dir = await getTemporaryDirectory();
      // Share receivers may read the image after the share sheet closes.
      // Remove only expired files from previous shares, never the current PNG.
      try {
        await PosterShareCache.removeExpired(dir);
      } on FileSystemException {
        // Cache cleanup must not interrupt sharing.
      }
      final file = File(
        '${dir.path}/voting_pro_poster_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Made with Voting Pro — Poster Maker\n'
            'Download the app from Google Play:\n'
            '$_votingProPlayStoreUrl',
      );
    } catch (e) {
      msg('شیئر نہیں ہو سکا: $e');
    } finally {
      if (mounted) setState(() => busy = false);
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
    if (selectedReadyMadeTemplate == 'royal_a_vs_b_battle') {
      return _buildRoyalBattleArtwork(preview: preview);
    }
    if (selectedReadyMadeTemplate == 'metallic_vs_battle') {
      return MetallicVsBattleTemplate(
        photoA: a,
        photoB: b,
        nameA: aSideLabelText,
        nameB: bSideLabelText,
        preview: preview,
        isExporting: isExportingPoster,
        initialScaleA: _templatePhotoScales[true] ?? 1.0,
        initialScaleB: _templatePhotoScales[false] ?? 1.0,
        initialOffsetA: _templatePhotoOffsets[true] ?? Offset.zero,
        initialOffsetB: _templatePhotoOffsets[false] ?? Offset.zero,
        onPickPhoto: (sideA) => pick(sideA),
        onEditName: (sideA) => editSideLabelText(sideA),
        onPhotoSelected: (sideA) =>
            _selectCanvasObject(templatePhotoSideA: sideA),
        onPhotoTransform: (sideA, scale, offset) {
          setState(() {
            _templatePhotoScales[sideA] = scale;
            _templatePhotoOffsets[sideA] = offset;
          });
        },
      );
    }
    if (selectedReadyMadeTemplate == 'neon_purple_showdown') {
      return NeonPurpleVsTemplate(
        photoA: a,
        photoB: b,
        nameA: aSideLabelText,
        nameB: bSideLabelText,
        preview: preview,
        isExporting: isExportingPoster,
        initialScaleA: _templatePhotoScales[true] ?? 1.0,
        initialScaleB: _templatePhotoScales[false] ?? 1.0,
        initialOffsetA: _templatePhotoOffsets[true] ?? Offset.zero,
        initialOffsetB: _templatePhotoOffsets[false] ?? Offset.zero,
        onPickPhoto: (sideA) => pick(sideA),
        onEditName: (sideA) => editSideLabelText(sideA),
        onPhotoSelected: (sideA) =>
            _selectCanvasObject(templatePhotoSideA: sideA),
        onPhotoTransform: (sideA, scale, offset) {
          setState(() {
            _templatePhotoScales[sideA] = scale;
            _templatePhotoOffsets[sideA] = offset;
          });
        },
      );
    }
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
                        fit: BoxFit.contain,
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
                    onTap: () { pick(true); },
                    onScaleStart: (_) {
                      _selectCanvasObject(templatePhotoSideA: true);
                      _templatePhotoStartScales[true] =
                          _templatePhotoScales[true] ?? 1.0;
                    },
                    onScaleUpdate: (details) {
                      if (_selectedTemplatePhotoSideA != true) return;
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
                    onTap: () { pick(false); },
                    onScaleStart: (_) {
                      _selectCanvasObject(templatePhotoSideA: false);
                      _templatePhotoStartScales[false] =
                          _templatePhotoScales[false] ?? 1.0;
                    },
                    onScaleUpdate: (details) {
                      if (_selectedTemplatePhotoSideA != false) return;
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


  Widget _royalTemplateName(String value, {required double availableWidth}) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: availableWidth * 0.25,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFD51B),
            shadows: const [
              Shadow(color: Color(0xFF17100A), blurRadius: 2, offset: Offset(2, 3)),
              Shadow(color: Color(0xFFFF9800), blurRadius: 7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoyalBattleArtwork({bool preview = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        Widget photoLayer(bool sideA) {
          final File? photo = preview ? null : (sideA ? a : b);
          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF050505)),
              if (photo != null)
                ClipRect(
                  child: Transform.translate(
                    offset: _templatePhotoOffsets[sideA] ?? Offset.zero,
                    child: Transform.scale(
                      scale: _templatePhotoScales[sideA] ?? 1.0,
                      child: Image.file(
                        photo,
                        fit: BoxFit.contain,
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
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: Colors.white70, size: w * 0.045),
                ),
            ],
          );
        }

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF050505)),
              // Exact transparent photo-window bounds measured from the 1448x1086 PNG.
              Positioned(
                left: w * (66 / 1448), top: h * (74 / 1086),
                width: w * (548 / 1448), height: h * (774 / 1086),
                child: photoLayer(true),
              ),
              Positioned(
                left: w * (838 / 1448), top: h * (75 / 1086),
                width: w * (545 / 1448), height: h * (772 / 1086),
                child: photoLayer(false),
              ),
              Image.asset(
                'assets/templates/Royal_A_vs_B_Battle_Template.png',
                fit: BoxFit.fill, gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              ),
              // Removes only the printed instruction text inside the two original name strips.
              Image.asset(
                'assets/templates/Royal_Battle_NameStrip_CleanOverlay.png',
                fit: BoxFit.fill, gaplessPlayback: true,
              ),
              if (!preview)
                Positioned(
                  left: w * 0.075, top: h * 0.805,
                  width: w * 0.345, height: h * 0.105,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => editSideLabelText(true),
                    child: _templateANameEdited
                        ? _royalTemplateName(aSideLabelText, availableWidth: w * 0.345)
                        : const SizedBox.expand(),
                  ),
                ),
              if (!preview)
                Positioned(
                  left: w * 0.600, top: h * 0.805,
                  width: w * 0.345, height: h * 0.105,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => editSideLabelText(false),
                    child: _templateBNameEdited
                        ? _royalTemplateName(bSideLabelText, availableWidth: w * 0.345)
                        : const SizedBox.expand(),
                  ),
                ),
              if (!preview)
                Positioned(
                  left: w * (66 / 1448), top: h * (74 / 1086),
                  width: w * (548 / 1448), height: h * (774 / 1086),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pick(true),
                    onScaleStart: (_) {
                      _selectCanvasObject(templatePhotoSideA: true);
                      _templatePhotoStartScales[true] = _templatePhotoScales[true] ?? 1.0;
                    },
                    onScaleUpdate: (details) {
                      if (_selectedTemplatePhotoSideA != true) return;
                      setState(() {
                        _templatePhotoScales[true] =
                            ((_templatePhotoStartScales[true] ?? 1.0) * details.scale)
                                .clamp(0.8, 8.0).toDouble();
                        _templatePhotoOffsets[true] =
                            (_templatePhotoOffsets[true] ?? Offset.zero) + details.focalPointDelta;
                      });
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              if (!preview)
                Positioned(
                  left: w * (838 / 1448), top: h * (75 / 1086),
                  width: w * (545 / 1448), height: h * (772 / 1086),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pick(false),
                    onScaleStart: (_) {
                      _selectCanvasObject(templatePhotoSideA: false);
                      _templatePhotoStartScales[false] = _templatePhotoScales[false] ?? 1.0;
                    },
                    onScaleUpdate: (details) {
                      if (_selectedTemplatePhotoSideA != false) return;
                      setState(() {
                        _templatePhotoScales[false] =
                            ((_templatePhotoStartScales[false] ?? 1.0) * details.scale)
                                .clamp(0.8, 8.0).toDouble();
                        _templatePhotoOffsets[false] =
                            (_templatePhotoOffsets[false] ?? Offset.zero) + details.focalPointDelta;
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
    setState(() {
      showReadyMadeTemplateGallery = !showReadyMadeTemplateGallery;
    });
  }

  void _selectReadyMadeTemplate(String templateKey) {
    final template = _readyTemplateOptions.firstWhere(
      (item) => item.key == templateKey,
    );

    setState(() {
      showReadyMadeTemplateGallery = false;
      _templateANameEdited = false;
      _templateBNameEdited = false;
      _templatePhotoScales[true] = 1.0;
      _templatePhotoScales[false] = 1.0;
      _templatePhotoOffsets[true] = Offset.zero;
      _templatePhotoOffsets[false] = Offset.zero;
      _selectedTemplatePhotoSideA = null;
      _clearCanvasSelection();
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

      if (templateKey == 'royal_a_vs_b_battle' ||
          templateKey == 'tagra_muqabla' ||
          templateKey == 'neon_purple_showdown' ||
          templateKey == 'metallic_vs_battle') {
        selectedReadyMadeTemplate = templateKey;
        canvasRatio = templateKey == 'tagra_muqabla' ? 1447 / 1087 : 4 / 3;
        background = dark;
        frameWidth = 0;
        selectedStylishFrame = null;
        selectedASideLabel = null;
        selectedBSideLabel = null;
        aSideLabelText = templateKey == 'neon_purple_showdown' ? 'رائے اویس' : 'اسد';
        bSideLabelText = templateKey == 'neon_purple_showdown' ? 'شہزاد بھٹی برانڈ' : 'رقیہ';
        selectedTextIndex = null;
        selectedStickerIndex = null;
        selectedTagraStickerIndex = null;
        selectedLetterOverlayIndex = null;
      } else {
        selectedReadyMadeTemplate = null;
        canvasRatio = 4 / 3;
        background = template.base;
        frameColor = template.accent;
        frameWidth = 4;
        selectedStylishFrame = template.frame;
        selectedASideLabel = template.aLabel;
        selectedBSideLabel = template.bLabel;
        vsStyle = template.vs;
        showVs = true;
        vsOffset = Offset.zero;
        vsScale = 1.0;
        vsStartScale = 1.0;
      }
    });

    msg('${template.name} ٹیمپلیٹ منتخب ہوگیا۔');
  }

  Widget _buildReadyTemplateThumbnail(
    ({String key, String name, Color base, Color accent, String frame,
      String aLabel, String bLabel, String vs}) template,
  ) {
    final isRoyal = template.key == 'royal_a_vs_b_battle';
    final isTagra = template.key == 'tagra_muqabla';
    final isNeonPurple = template.key == 'neon_purple_showdown';
    final isMetallic = template.key == 'metallic_vs_battle';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [template.base, template.accent.withOpacity(0.72)],
              ),
            ),
          ),
          if (isMetallic)
            Image.asset('assets/templates/Metallic_VS_Battle_Template.png',
              fit: BoxFit.contain, filterQuality: FilterQuality.medium)
          else if (isNeonPurple)
            Image.asset('assets/templates/Neon_Purple_VS_Template.png',
              fit: BoxFit.contain, filterQuality: FilterQuality.medium)
          else if (isRoyal)
            Image.asset(
              'assets/templates/Royal_A_vs_B_Battle_Template.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            )
          else if (isTagra)
            Image.asset(
              'assets/templates/Tagra_Muqabla_Template.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            )
          else ...[
            Positioned(
              left: 5, top: 12, width: 38, height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.34),
                  border: Border.all(color: template.accent, width: 1.2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.person, color: Colors.white70, size: 24),
              ),
            ),
            Positioned(
              right: 5, top: 12, width: 38, height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.34),
                  border: Border.all(color: template.accent, width: 1.2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.person, color: Colors.white70, size: 24),
              ),
            ),
            Center(
              child: Text(
                'VS',
                style: TextStyle(
                  color: template.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
                ),
              ),
            ),
            Positioned(
              left: 2, right: 2, bottom: 7, height: 22,
              child: Row(
                children: [
                  Expanded(child: Image.asset(template.aLabel, fit: BoxFit.contain)),
                  const SizedBox(width: 4),
                  Expanded(child: Image.asset(template.bLabel, fit: BoxFit.contain)),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(template.frame, fit: BoxFit.fill),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadyMadeTemplatePicker() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111A2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD84D), width: 1.4),
          boxShadow: const [
            BoxShadow(color: Color(0x55FFD84D), blurRadius: 16, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, color: Color(0xFFFFD84D), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLanguage.tr('Ready-made Templates'),
                    style: TextStyle(
                      color: Color(0xFFFFD84D),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  AppLanguage.tr('ٹیمپلیٹس منتخب کریں'),
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                IconButton(
                  tooltip: AppLanguage.tr('Close'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => showReadyMadeTemplateGallery = false),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _readyTemplateOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final template = _readyTemplateOptions[index];
                  final isSelected =
                      (selectedReadyMadeTemplate ?? '') == template.key ||
                      (selectedReadyMadeTemplate == null &&
                          template.key == 'blue_gold_classic' &&
                          selectedStylishFrame == template.frame);
                  return SizedBox(
                    width: 104,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectReadyMadeTemplate(template.key),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFD84D)
                                      : Colors.white38,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? const [BoxShadow(color: Color(0xAAFFD84D), blurRadius: 10)]
                                    : null,
                              ),
                              child: _buildReadyTemplateThumbnail(template),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            template.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFFFD84D) : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
          Text(AppLanguage.tr('Frame Color')),
          Wrap(spacing: 12, children: [Colors.amber, Colors.white, Colors.pinkAccent, Colors.cyanAccent, Colors.redAccent, Colors.greenAccent].map((color) => InkWell(
            onTap: () { setState(() => frameColor = color); modalSet(() {}); },
            child: Container(width: 35, height: 35, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: frameColor == color ? Colors.black : Colors.transparent, width: 3))),
          )).toList()),
          const SizedBox(height: 12),
          Text(AppLanguage.tr('Frame Thickness')),
          Slider(value: frameWidth, min: 1, max: 10, divisions: 9, onChanged: (v) { setState(() => frameWidth = v); modalSet(() {}); }),
          Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.pop(c), child: Text(AppLanguage.tr('Done')))),
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
        onTap: () { _textUndoHistory.clear(); _textRedoHistory.clear(); setState(() { _clearCanvasSelection(); overlays.add(e); final index = overlays.length - 1; stickerOverlayIds.add(index); _selectCanvasObject(stickerIndex: index); }); Navigator.pop(c); },
        child: Container(width: 52, height: 52, alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 28))),
      )).toList()),
    ));
  }

  bool _hasArabicScript(String value) => RegExp(r'[\u0600-\u06FF]').hasMatch(value);

  TextAlign _overlayTextAlign(int index) {
    switch (textAlignments[index]) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  void cycleSelectedTextAlignment() {
    final index = selectedTextIndex;
    if (index == null || !textOverlayIds.contains(index)) {
      msg('پہلے ٹیکسٹ منتخب کریں');
      return;
    }
    _rememberTextEdit();
    setState(() {
      textAlignments[index] = switch (textAlignments[index]) {
        'left' => 'center',
        'center' => 'right',
        _ => 'left',
      };
    });
  }

  void toggleSelectedTextBold() {
    final index = selectedTextIndex;
    if (index == null || !textOverlayIds.contains(index)) {
      msg('پہلے ٹیکسٹ منتخب کریں');
      return;
    }
    _rememberTextEdit();
    setState(() {
      if (!boldTextOverlayIds.add(index)) boldTextOverlayIds.remove(index);
    });
  }

  void adjustSelectedTextSpacing(double delta) {
    final index = selectedTextIndex;
    if (index == null || !textOverlayIds.contains(index)) {
      msg('پہلے ٹیکسٹ منتخب کریں');
      return;
    }
    _rememberTextEdit();
    setState(() {
      textLetterSpacings[index] =
          ((textLetterSpacings[index] ?? 0.0) + delta).clamp(-1.0, 8.0).toDouble();
    });
  }

  int? get _activeTextIndex {
    final index = selectedTextIndex;
    if (index == null || index < 0 || index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      msg('پہلے ٹیکسٹ منتخب کریں');
      return null;
    }
    return index;
  }

  void toggleTextItalic() {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      if (!italicTextOverlayIds.add(index)) italicTextOverlayIds.remove(index);
    });
  }

  void toggleTextUnderline() {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      if (!underlineTextOverlayIds.add(index)) underlineTextOverlayIds.remove(index);
    });
  }

  void toggleTextStrikethrough() {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      if (!strikeTextOverlayIds.add(index)) strikeTextOverlayIds.remove(index);
    });
  }

  void adjustTextOpacity(double delta) {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      textOpacities[index] =
          ((textOpacities[index] ?? 1.0) + delta).clamp(0.1, 1.0).toDouble();
    });
  }

  void adjustTextLineHeight(double delta) {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      textLineHeights[index] =
          ((textLineHeights[index] ?? 1.2) + delta).clamp(0.8, 2.5).toDouble();
    });
  }


  Future<void> editTextBackground() async {
    final index = _activeTextIndex;
    if (index == null) return;
    bool enabled = textBgColors.containsKey(index);
    Color color = textBgColors[index] ?? const Color(0xFF151A30);
    double opacity = textBgOpacities[index] ?? 0.8;
    double padding = textBgPaddings[index] ?? 0;
    double radius = textBgRadii[index] ?? 8;
    double border = textBgBorders[index] ?? 0;
    double shadow = textBgShadows[index] ?? 0;
    bool gradient = textBgGradients.contains(index);
    const palette = <Color>[
      Color(0xFF151A30), Colors.black, Colors.white,
      Color(0xFF263238), Color(0xFF004D40), Color(0xFF0D47A1),
      Color(0xFF4A148C), Color(0xFF880E4F), Color(0xFFB71C1C),
      Color(0xFFF57F17), Color(0xFF00ACC1), Color(0xFF2E7D32),
    ];
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) {
          Widget control(String label, double value, double max,
              ValueChanged<double> change) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$label: ${value.toStringAsFixed(label == "Opacity" ? 2 : 0)}'),
              Slider(
                value: value.clamp(0.0, max).toDouble(),
                min: 0, max: max,
                onChanged: (v) => update(() => change(v)),
              ),
            ],
          );
          return AlertDialog(
            title: const Text('Text Background'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable tight-fit background'),
                      value: enabled,
                      onChanged: (v) => update(() => enabled = v),
                    ),
                    const Text('Background color'),
                    Wrap(spacing: 7, runSpacing: 7, children: [
                      for (final swatch in palette)
                        InkWell(
                          onTap: () => update(() { color = swatch; enabled = true; }),
                          child: Container(
                            width: 31, height: 31,
                            decoration: BoxDecoration(
                              color: swatch,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color == swatch ? Colors.amber : Colors.grey,
                                width: color == swatch ? 3 : 1),
                            ),
                          ),
                        ),
                    ]),
                    control('Opacity', opacity, 1, (v) => opacity = v),
                    control('Glyph edge thickness', padding, 24, (v) => padding = v),
                    control('Corners', radius, 36, (v) => radius = v),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gradient background'),
                      value: gradient,
                      onChanged: (v) => update(() => gradient = v),
                    ),
                    control('Border width', border, 6, (v) => border = v),
                    control('Shadow blur', shadow, 24, (v) => shadow = v),
                    const Text('Background follows only the shapes of letters, not the line box.'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Apply')),
            ],
          );
        },
      ),
    );
    if (apply != true || !mounted || index >= overlays.length ||
        !textOverlayIds.contains(index)) return;
    _rememberTextEdit();
    setState(() {
      if (enabled) {
        textBgColors[index] = color;
        textBgOpacities[index] = opacity;
        textBgPaddings[index] = padding;
        textBgRadii[index] = radius;
        textBgBorders[index] = border;
        textBgShadows[index] = shadow;
        if (gradient) { textBgGradients.add(index); }
        else { textBgGradients.remove(index); }
      } else {
        textBgColors.remove(index);
        textBgOpacities.remove(index);
        textBgPaddings.remove(index);
        textBgRadii.remove(index);
        textBgBorders.remove(index);
        textBgShadows.remove(index);
        textBgGradients.remove(index);
      }
    });
  }

  void resetSelectedTextStyle() {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      textFonts.remove(index);
      textColors.remove(index);
      textBgColors.remove(index);
      textBgOpacities.remove(index);
      textBgPaddings.remove(index);
      textBgRadii.remove(index);
      textBgBorders.remove(index);
      textBgShadows.remove(index);
      textBgGradients.remove(index);
      textGlowColors.remove(index);
      textGlowStrengths.remove(index);
      textAlignments.remove(index);
      textLetterSpacings.remove(index);
      textOpacities.remove(index);
      textLineHeights.remove(index);
      textOutlineWidths.remove(index);
      textOutlineColors.remove(index);
      textCurves.remove(index);
      gradientTextOverlayIds.remove(index);
      customFontPaths.remove(index);
      boldTextOverlayIds.remove(index);
      italicTextOverlayIds.remove(index);
      underlineTextOverlayIds.remove(index);
      strikeTextOverlayIds.remove(index);
      textScales[index] = 1.0;
    });
  }

  void duplicateSelectedText() {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      final next = overlays.length;
      overlays.add(overlays[index]);
      textOverlayIds.add(next);
      textPositions[next] = (textPositions[index] ??
          Offset(10 + (index % 4) * 35.0, 12 + (index % 3) * 38.0)) +
          const Offset(24, 24);
      textScales[next] = textScales[index] ?? 1.0;
      if (textFonts.containsKey(index)) textFonts[next] = textFonts[index]!;
      if (textColors.containsKey(index)) textColors[next] = textColors[index]!;
      if (textBgColors.containsKey(index)) textBgColors[next] = textBgColors[index]!;
      if (textBgOpacities.containsKey(index)) textBgOpacities[next] = textBgOpacities[index]!;
      if (textBgPaddings.containsKey(index)) textBgPaddings[next] = textBgPaddings[index]!;
      if (textBgRadii.containsKey(index)) textBgRadii[next] = textBgRadii[index]!;
      if (textBgBorders.containsKey(index)) textBgBorders[next] = textBgBorders[index]!;
      if (textBgShadows.containsKey(index)) textBgShadows[next] = textBgShadows[index]!;
      if (textBgGradients.contains(index)) textBgGradients.add(next);
      if (textGlowColors.containsKey(index)) textGlowColors[next] = textGlowColors[index]!;
      if (textGlowStrengths.containsKey(index)) textGlowStrengths[next] = textGlowStrengths[index]!;
      if (textAlignments.containsKey(index)) textAlignments[next] = textAlignments[index]!;
      if (textLetterSpacings.containsKey(index)) textLetterSpacings[next] = textLetterSpacings[index]!;
      if (textOpacities.containsKey(index)) textOpacities[next] = textOpacities[index]!;
      if (textLineHeights.containsKey(index)) textLineHeights[next] = textLineHeights[index]!;
      if (textOutlineWidths.containsKey(index)) textOutlineWidths[next] = textOutlineWidths[index]!;
      if (textOutlineColors.containsKey(index)) textOutlineColors[next] = textOutlineColors[index]!;
      if (textCurves.containsKey(index)) textCurves[next] = textCurves[index]!;
      if (gradientTextOverlayIds.contains(index)) gradientTextOverlayIds.add(next);
      if (customFontPaths.containsKey(index)) customFontPaths[next] = customFontPaths[index]!;
      if (boldTextOverlayIds.contains(index)) boldTextOverlayIds.add(next);
      if (italicTextOverlayIds.contains(index)) italicTextOverlayIds.add(next);
      if (underlineTextOverlayIds.contains(index)) underlineTextOverlayIds.add(next);
      if (strikeTextOverlayIds.contains(index)) strikeTextOverlayIds.add(next);
      _selectCanvasObject(textIndex: next);
    });
  }

  void chooseTextPreset() {
    final index = _activeTextIndex;
    if (index == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101827),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 10,
            spacing: 10,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(AppLanguage.tr('Typography Presets'),
                  style: TextStyle(fontSize: 20, color: Colors.white,
                    fontWeight: FontWeight.bold)),
              ),
              for (final preset in const <String>['Headline', 'Caption', 'Neon', 'Elegant'])
                ActionChip(
                  label: Text(AppLanguage.tr(preset), style: const TextStyle(color: Colors.white)),
                  backgroundColor: const Color(0xFF263247),
                  onPressed: () {
                    _rememberTextEdit();
                    setState(() {
                      if (preset == 'Headline') {
                        boldTextOverlayIds.add(index);
                        textScales[index] = 1.5;
                        textLetterSpacings[index] = 1.2;
                        textGlowStrengths[index] = 0;
                      } else if (preset == 'Caption') {
                        boldTextOverlayIds.remove(index);
                        textScales[index] = 0.75;
                        textLetterSpacings[index] = 0;
                        textGlowStrengths[index] = 0;
                      } else if (preset == 'Neon') {
                        boldTextOverlayIds.add(index);
                        textColors[index] = const Color(0xFF00E5FF);
                        textGlowColors[index] = const Color(0xFF00E5FF);
                        textGlowStrengths[index] = 110;
                      } else {
                        boldTextOverlayIds.remove(index);
                        italicTextOverlayIds.add(index);
                        textColors[index] = const Color(0xFFFFD700);
                        textGlowStrengths[index] = 0;
                        if (!_hasArabicScript(overlays[index])) {
                          customFontPaths.remove(index);
                          textFonts[index] = 'PlayfairDisplayLocal';
                        }
                      }
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Object> _captureTextSnapshot() => <String, Object>{
    'overlays': List<String>.from(overlays),
    'textOverlayIds': Set<int>.from(textOverlayIds),
    'stickerOverlayIds': Set<int>.from(stickerOverlayIds),
    'textPositions': Map<int, Offset>.from(textPositions),
    'textScales': Map<int, double>.from(textScales),
    'textGlowStrengths': Map<int, double>.from(textGlowStrengths),
    'textLetterSpacings': Map<int, double>.from(textLetterSpacings),
    'textOpacities': Map<int, double>.from(textOpacities),
    'textLineHeights': Map<int, double>.from(textLineHeights),
    'textOutlineWidths': Map<int, double>.from(textOutlineWidths),
    'textCurves': Map<int, double>.from(textCurves),
    'textFonts': Map<int, String>.from(textFonts),
    'textAlignments': Map<int, String>.from(textAlignments),
    'customFontPaths': Map<int, String>.from(customFontPaths),
    'textColors': Map<int, Color>.from(textColors),
    'textBgColors': Map<int, Color>.from(textBgColors),
    'textBgOpacities': Map<int, double>.from(textBgOpacities),
    'textBgPaddings': Map<int, double>.from(textBgPaddings),
    'textBgRadii': Map<int, double>.from(textBgRadii),
    'textBgBorders': Map<int, double>.from(textBgBorders),
    'textBgShadows': Map<int, double>.from(textBgShadows),
    'textBgGradients': Set<int>.from(textBgGradients),
    'textGlowColors': Map<int, Color>.from(textGlowColors),
    'textOutlineColors': Map<int, Color>.from(textOutlineColors),
    'boldTextOverlayIds': Set<int>.from(boldTextOverlayIds),
    'italicTextOverlayIds': Set<int>.from(italicTextOverlayIds),
    'underlineTextOverlayIds': Set<int>.from(underlineTextOverlayIds),
    'strikeTextOverlayIds': Set<int>.from(strikeTextOverlayIds),
    'gradientTextOverlayIds': Set<int>.from(gradientTextOverlayIds),
  };

  void _restoreTextSnapshot(Map<String, Object> snapshot) {
    // Undo/Redo must not accidentally deselect a text that still exists.
    final previousSelectedText = selectedTextIndex;
    overlays..clear()..addAll(snapshot['overlays'] as List<String>);
    textOverlayIds..clear()..addAll(snapshot['textOverlayIds'] as Set<int>);
    stickerOverlayIds..clear()..addAll(snapshot['stickerOverlayIds'] as Set<int>);
    textPositions..clear()..addAll(snapshot['textPositions'] as Map<int, Offset>);
    textScales..clear()..addAll(snapshot['textScales'] as Map<int, double>);
    textGlowStrengths..clear()..addAll(snapshot['textGlowStrengths'] as Map<int, double>);
    textLetterSpacings..clear()..addAll(snapshot['textLetterSpacings'] as Map<int, double>);
    textOpacities..clear()..addAll(snapshot['textOpacities'] as Map<int, double>);
    textLineHeights..clear()..addAll(snapshot['textLineHeights'] as Map<int, double>);
    textOutlineWidths..clear()..addAll(snapshot['textOutlineWidths'] as Map<int, double>);
    textCurves..clear()..addAll(snapshot['textCurves'] as Map<int, double>);
    textFonts..clear()..addAll(snapshot['textFonts'] as Map<int, String>);
    textAlignments..clear()..addAll(snapshot['textAlignments'] as Map<int, String>);
    customFontPaths..clear()..addAll(snapshot['customFontPaths'] as Map<int, String>);
    textColors..clear()..addAll(snapshot['textColors'] as Map<int, Color>);
    textBgColors..clear()..addAll(snapshot['textBgColors'] as Map<int, Color>);
    textBgOpacities..clear()..addAll(snapshot['textBgOpacities'] as Map<int, double>);
    textBgPaddings..clear()..addAll(snapshot['textBgPaddings'] as Map<int, double>);
    textBgRadii..clear()..addAll(snapshot['textBgRadii'] as Map<int, double>);
    textBgBorders..clear()..addAll(snapshot['textBgBorders'] as Map<int, double>);
    textBgShadows..clear()..addAll(snapshot['textBgShadows'] as Map<int, double>);
    textBgGradients..clear()..addAll(snapshot['textBgGradients'] as Set<int>);
    textGlowColors..clear()..addAll(snapshot['textGlowColors'] as Map<int, Color>);
    textOutlineColors..clear()..addAll(snapshot['textOutlineColors'] as Map<int, Color>);
    boldTextOverlayIds..clear()..addAll(snapshot['boldTextOverlayIds'] as Set<int>);
    italicTextOverlayIds..clear()..addAll(snapshot['italicTextOverlayIds'] as Set<int>);
    underlineTextOverlayIds..clear()..addAll(snapshot['underlineTextOverlayIds'] as Set<int>);
    strikeTextOverlayIds..clear()..addAll(snapshot['strikeTextOverlayIds'] as Set<int>);
    gradientTextOverlayIds..clear()..addAll(snapshot['gradientTextOverlayIds'] as Set<int>);
    _clearCanvasSelection();
    if (previousSelectedText != null &&
        previousSelectedText >= 0 &&
        previousSelectedText < overlays.length &&
        textOverlayIds.contains(previousSelectedText)) {
      selectedTextIndex = previousSelectedText;
    }
  }

  void _rememberTextEdit() {
    _textUndoHistory.add(_captureTextSnapshot());
    if (_textUndoHistory.length > 25) _textUndoHistory.removeAt(0);
    _textRedoHistory.clear();
  }

  void undoTextEdit() {
    if (_textUndoHistory.isEmpty) { msg('Undo history خالی ہے'); return; }
    final previous = _textUndoHistory.removeLast();
    _textRedoHistory.add(_captureTextSnapshot());
    setState(() => _restoreTextSnapshot(previous));
  }

  void redoTextEdit() {
    if (_textRedoHistory.isEmpty) { msg('Redo history خالی ہے'); return; }
    final next = _textRedoHistory.removeLast();
    _textUndoHistory.add(_captureTextSnapshot());
    setState(() => _restoreTextSnapshot(next));
  }

  void adjustSelectedTextCurve(double delta) {
    final index = _activeTextIndex;
    if (index == null) return;
    if (overlays[index].contains('\n')) {
      msg('Curved Text کے لیے ایک سطر منتخب کریں (Urdu / English)');
      return;
    }
    _rememberTextEdit();
    setState(() => textCurves[index] =
      ((textCurves[index] ?? 0.0) + delta).clamp(-1.0, 1.0).toDouble());
  }

  void toggleSelectedTextGradient() {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() {
      if (!gradientTextOverlayIds.add(index)) gradientTextOverlayIds.remove(index);
    });
  }

  void adjustSelectedTextOutline(double delta) {
    final index = _activeTextIndex;
    if (index == null) return;
    _rememberTextEdit();
    setState(() => textOutlineWidths[index] =
      ((textOutlineWidths[index] ?? 0.0) + delta).clamp(0.0, 8.0).toDouble());
  }

  void cycleTextOutlineColor() {
    final index = _activeTextIndex;
    if (index == null) return;
    const colors = [Colors.black, Colors.white, Color(0xFFFFD700),
      Color(0xFF00E5FF), Color(0xFFFF1744)];
    _rememberTextEdit();
    setState(() {
      final current = textOutlineColors[index] ?? colors.first;
      final i = colors.indexOf(current);
      textOutlineColors[index] = colors[(i + 1) % colors.length];
    });
  }

  // Choose the target in the import flow instead of showing
  // "Select text first" when selection was cleared (e.g. after Save).
  Future<int?> _chooseFontImportTarget() async {
    final active = selectedTextIndex;
    if (active != null && active >= 0 && active < overlays.length &&
        textOverlayIds.contains(active)) {
      return active;
    }
    final candidates = textOverlayIds.toList()
      ..removeWhere((i) => i < 0 || i >= overlays.length)
      ..sort();
    if (candidates.isEmpty) {
      final create = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import Font'),
          content: const Text(
            'پہلے پوسٹر پر ٹیکسٹ شامل کریں۔ کیا آپ نیا ٹیکسٹ بنانا چاہتے ہیں؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add Text'),
            ),
          ],
        ),
      );
      if (create != true || !mounted) return null;
      await addText();
      if (!mounted) return null;
      final newIndex = selectedTextIndex;
      return newIndex != null && textOverlayIds.contains(newIndex)
          ? newIndex : null;
    }

    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Text for Font'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final i in candidates)
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: Text(
                    overlays[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Text ${i + 1}'),
                  onTap: () => Navigator.pop(dialogContext, i),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add New Text'),
                onTap: () => Navigator.pop(dialogContext, -1),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (!mounted || picked == null) return null;
    if (picked == -1) {
      await addText();
      if (!mounted) return null;
      final newIndex = selectedTextIndex;
      return newIndex != null && textOverlayIds.contains(newIndex)
          ? newIndex : null;
    }
    if (!textOverlayIds.contains(picked) || picked >= overlays.length) {
      return null;
    }
    setState(() => _selectCanvasObject(textIndex: picked));
    return picked;
  }

  Future<void> importSelectedTextFont() async {
    final index = await _chooseFontImportTarget();
    if (index == null || !mounted) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
        withData: true,
      );
      if (result == null || !mounted) return;
      final chosen = result.files.single;
      final bytes = chosen.bytes;
      if (bytes == null || bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        msg('صرف 5MB تک TTF/OTF font منتخب کریں');
        return;
      }
      if (bytes.length < 4) { msg('غلط فونٹ فائل'); return; }
      final signature = bytes.sublist(0, 4);
      final isTrueType = signature[0] == 0 && signature[1] == 1 &&
          signature[2] == 0 && signature[3] == 0;
      final isOpenType = String.fromCharCodes(signature) == 'OTTO';
      if (!isTrueType && !isOpenType) {
        msg('یہ درست TTF/OTF font فائل نہیں ہے');
        return;
      }
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final family = 'VotingCustomFont$stamp';
      final dir = await _projectDirectory();
      final extension = isOpenType ? 'otf' : 'ttf';
      final path = '${dir.path}/custom_font_$stamp.$extension';
      await File(path).writeAsBytes(bytes, flush: true);
      await ui.loadFontFromList(bytes, fontFamily: family);
      if (!mounted || index >= overlays.length || !textOverlayIds.contains(index)) return;
      _rememberTextEdit();
      setState(() {
        _loadedCustomFontFamilies.add(family);
        customFontPaths[index] = path;
        textFonts[index] = family;
      });
      msg('Custom font منتخب ٹیکسٹ پر لاگو ہوگیا');
    } catch (e) {
      msg('Font import ناکام: $e');
    }
  }

  Future<void> addText() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (c) => AlertDialog(
      title: Text(AppLanguage.tr('متن شامل کریں')),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        minLines: 2,
        maxLines: 6,
        textDirection: AppLanguage.direction,
        decoration: InputDecoration(
          hintText: AppLanguage.tr('اردو یا English میں ٹیکسٹ لکھیں'),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(AppLanguage.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: Text(AppLanguage.tr('Add')))],
    ));
    controller.dispose();
    if (value != null && value.isNotEmpty && mounted) {
      _rememberTextEdit();
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
        title: Text(AppLanguage.tr('Edit Text')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 6,
          textDirection: _hasArabicScript(controller.text)
              ? TextDirection.rtl : AppLanguage.direction,
          decoration: InputDecoration(
            hintText: AppLanguage.tr('اپنا ٹیکسٹ یہاں تبدیل کریں'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLanguage.tr('Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            icon: const Icon(Icons.check),
            label: Text(AppLanguage.tr('Save')),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null && value.isNotEmpty && mounted) {
      _rememberTextEdit();
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

      _rememberTextEdit();
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
              title: Text(
                AppLanguage.tr('Custom Color'),
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
                  child: Text(AppLanguage.tr('Done')),
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
                    Expanded(
                      child: Text(
                        AppLanguage.tr('Text Color Studio'),
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
                      label: Text(
                        AppLanguage.tr('Custom'),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Text(
                  AppLanguage.tr('Premium • Gold • Neon • Pastel • 300+ Colors'),
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(AppLanguage.tr('Preview: '),
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
                      tooltip: AppLanguage.tr('Reset to white'),
                      onPressed: () {
                        _rememberTextEdit();
                        setState(() => textColors[index] = Colors.white);
                      },
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
                          onTap: () {
                            _rememberTextEdit();
                            setState(() => textColors[index] = color);
                          },
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
                    child: Text(AppLanguage.tr('Apply Color')),
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
          ]
        : <(String, String)>[
            ('RobotoLocal', 'Modern'),
            ('OswaldLocal', 'Bold'),
            ('PlayfairDisplayLocal', 'Elegant'),
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
                AppLanguage.tr(isUrdu ? 'اردو فونٹس منتخب کریں' : 'Choose English Font'),
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
                    AppLanguage.tr(font.$2),
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
                    _rememberTextEdit();
                    setState(() {
                      customFontPaths.remove(index);
                      textFonts[index] = font.$1;
                    });
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
    _rememberTextEdit();
    setState(() {
      textScales[index] = ((textScales[index] ?? 1.0) * factor)
          .clamp(0.4, 4.0).toDouble();
    });
  }

  void zoomSelectedSticker(double factor) {
    final index = selectedStickerIndex;
    if (index == null || index < 0 || index >= overlays.length || stickerOverlayIds.contains(index) == false) return;
    // Text snapshots also contain shared overlay indices/scales. A sticker edit
    // must not later be rolled back by an unrelated text Undo.
    _textUndoHistory.clear();
    _textRedoHistory.clear();
    setState(() {
      textScales[index] = ((textScales[index] ?? 1.0) * factor).clamp(0.4, 4.0).toDouble();
    });
  }

  void deleteSelectedText({int? targetIndex}) {
    final index = targetIndex ?? selectedTextIndex;
    if (index == null ||
        index < 0 ||
        index >= overlays.length ||
        !textOverlayIds.contains(index)) {
      return;
    }

    _rememberTextEdit();
    setState(() {
      overlays.removeAt(index);

      final oldPositions = Map<int, Offset>.from(textPositions);
      final oldScales = Map<int, double>.from(textScales);
      final oldFonts = Map<int, String>.from(textFonts);
      final oldColors = Map<int, Color>.from(textColors);
      final oldBgColors = Map<int, Color>.from(textBgColors);
      final oldBgOpacities = Map<int, double>.from(textBgOpacities);
      final oldBgPaddings = Map<int, double>.from(textBgPaddings);
      final oldBgRadii = Map<int, double>.from(textBgRadii);
      final oldBgBorders = Map<int, double>.from(textBgBorders);
      final oldBgShadows = Map<int, double>.from(textBgShadows);
      final oldBgGradients = Set<int>.from(textBgGradients);
      final oldGlowColors = Map<int, Color>.from(textGlowColors);
      final oldGlowStrengths = Map<int, double>.from(textGlowStrengths);
      final oldAlignments = Map<int, String>.from(textAlignments);
      final oldSpacings = Map<int, double>.from(textLetterSpacings);
      final oldBoldIds = Set<int>.from(boldTextOverlayIds);
      final oldItalicIds = Set<int>.from(italicTextOverlayIds);
      final oldUnderlineIds = Set<int>.from(underlineTextOverlayIds);
      final oldStrikeIds = Set<int>.from(strikeTextOverlayIds);
      final oldOpacities = Map<int, double>.from(textOpacities);
      final oldLineHeights = Map<int, double>.from(textLineHeights);
      final oldOutlineWidths = Map<int, double>.from(textOutlineWidths);
      final oldOutlineColors = Map<int, Color>.from(textOutlineColors);
      final oldCurves = Map<int, double>.from(textCurves);
      final oldGradients = Set<int>.from(gradientTextOverlayIds);
      final oldCustomPaths = Map<int, String>.from(customFontPaths);

      textPositions.clear();
      textScales.clear();
      textFonts.clear();
      textColors.clear();
      textBgColors.clear();
      textBgOpacities.clear();
      textBgPaddings.clear();
      textBgRadii.clear();
      textBgBorders.clear();
      textBgShadows.clear();
      textBgGradients.clear();
      textGlowColors.clear();
      textGlowStrengths.clear();
      textAlignments.clear();
      textLetterSpacings.clear();
      boldTextOverlayIds.clear();
      italicTextOverlayIds.clear();
      underlineTextOverlayIds.clear();
      strikeTextOverlayIds.clear();
      textOpacities.clear();
      textLineHeights.clear();
      textOutlineWidths.clear();
      textOutlineColors.clear();
      textCurves.clear();
      gradientTextOverlayIds.clear();
      customFontPaths.clear();

      final oldTextIds = Set<int>.from(textOverlayIds);
      final oldStickerIds = Set<int>.from(stickerOverlayIds);
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
        if (oldBgColors.containsKey(sourceIndex)) textBgColors[i] = oldBgColors[sourceIndex]!;
        if (oldBgOpacities.containsKey(sourceIndex)) textBgOpacities[i] = oldBgOpacities[sourceIndex]!;
        if (oldBgPaddings.containsKey(sourceIndex)) textBgPaddings[i] = oldBgPaddings[sourceIndex]!;
        if (oldBgRadii.containsKey(sourceIndex)) textBgRadii[i] = oldBgRadii[sourceIndex]!;
        if (oldBgBorders.containsKey(sourceIndex)) textBgBorders[i] = oldBgBorders[sourceIndex]!;
        if (oldBgShadows.containsKey(sourceIndex)) textBgShadows[i] = oldBgShadows[sourceIndex]!;
        if (oldBgGradients.contains(sourceIndex)) textBgGradients.add(i);
        if (oldGlowColors.containsKey(sourceIndex)) {
          textGlowColors[i] = oldGlowColors[sourceIndex]!;
        }
        if (oldGlowStrengths.containsKey(sourceIndex)) {
          textGlowStrengths[i] = oldGlowStrengths[sourceIndex]!;
        }
        if (oldAlignments.containsKey(sourceIndex)) textAlignments[i] = oldAlignments[sourceIndex]!;
        if (oldSpacings.containsKey(sourceIndex)) textLetterSpacings[i] = oldSpacings[sourceIndex]!;
        if (oldBoldIds.contains(sourceIndex)) boldTextOverlayIds.add(i);
        if (oldItalicIds.contains(sourceIndex)) italicTextOverlayIds.add(i);
        if (oldUnderlineIds.contains(sourceIndex)) underlineTextOverlayIds.add(i);
        if (oldStrikeIds.contains(sourceIndex)) strikeTextOverlayIds.add(i);
        if (oldOpacities.containsKey(sourceIndex)) textOpacities[i] = oldOpacities[sourceIndex]!;
        if (oldLineHeights.containsKey(sourceIndex)) textLineHeights[i] = oldLineHeights[sourceIndex]!;
        if (oldOutlineWidths.containsKey(sourceIndex)) textOutlineWidths[i] = oldOutlineWidths[sourceIndex]!;
        if (oldOutlineColors.containsKey(sourceIndex)) textOutlineColors[i] = oldOutlineColors[sourceIndex]!;
        if (oldCurves.containsKey(sourceIndex)) textCurves[i] = oldCurves[sourceIndex]!;
        if (oldGradients.contains(sourceIndex)) gradientTextOverlayIds.add(i);
        if (oldCustomPaths.containsKey(sourceIndex)) customFontPaths[i] = oldCustomPaths[sourceIndex]!;
        if (oldTextIds.contains(sourceIndex)) {
          textOverlayIds.add(i);
        }
        if (oldStickerIds.contains(sourceIndex)) {
          stickerOverlayIds.add(i);
        }
      }

      if (selectedStickerIndex != null) {
        if (selectedStickerIndex == index) {
          selectedStickerIndex = null;
        } else if (selectedStickerIndex! > index) {
          selectedStickerIndex = selectedStickerIndex! - 1;
        }
      }
      if (selectedTextIndex != null) {
        if (selectedTextIndex == index) {
          selectedTextIndex = null;
        } else if (selectedTextIndex! > index) {
          selectedTextIndex = selectedTextIndex! - 1;
        }
      }
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

    _textUndoHistory.clear();
    _textRedoHistory.clear();
    setState(() {
      overlays.removeAt(index);

      final oldPositions = Map<int, Offset>.from(textPositions);
      final oldScales = Map<int, double>.from(textScales);
      final oldFonts = Map<int, String>.from(textFonts);
      final oldColors = Map<int, Color>.from(textColors);
      final oldBgColors = Map<int, Color>.from(textBgColors);
      final oldBgOpacities = Map<int, double>.from(textBgOpacities);
      final oldBgPaddings = Map<int, double>.from(textBgPaddings);
      final oldBgRadii = Map<int, double>.from(textBgRadii);
      final oldBgBorders = Map<int, double>.from(textBgBorders);
      final oldBgShadows = Map<int, double>.from(textBgShadows);
      final oldBgGradients = Set<int>.from(textBgGradients);
      final oldGlowColors = Map<int, Color>.from(textGlowColors);
      final oldGlowStrengths = Map<int, double>.from(textGlowStrengths);
      final oldAlignments = Map<int, String>.from(textAlignments);
      final oldSpacings = Map<int, double>.from(textLetterSpacings);
      final oldBoldIds = Set<int>.from(boldTextOverlayIds);
      final oldItalicIds = Set<int>.from(italicTextOverlayIds);
      final oldUnderlineIds = Set<int>.from(underlineTextOverlayIds);
      final oldStrikeIds = Set<int>.from(strikeTextOverlayIds);
      final oldOpacities = Map<int, double>.from(textOpacities);
      final oldLineHeights = Map<int, double>.from(textLineHeights);
      final oldOutlineWidths = Map<int, double>.from(textOutlineWidths);
      final oldOutlineColors = Map<int, Color>.from(textOutlineColors);
      final oldCurves = Map<int, double>.from(textCurves);
      final oldGradients = Set<int>.from(gradientTextOverlayIds);
      final oldCustomPaths = Map<int, String>.from(customFontPaths);
      final oldTextIds = Set<int>.from(textOverlayIds);
      final oldStickerIds = Set<int>.from(stickerOverlayIds);

      textPositions.clear();
      textScales.clear();
      textFonts.clear();
      textColors.clear();
      textBgColors.clear();
      textBgOpacities.clear();
      textBgPaddings.clear();
      textBgRadii.clear();
      textBgBorders.clear();
      textBgShadows.clear();
      textBgGradients.clear();
      textGlowColors.clear();
      textGlowStrengths.clear();
      textAlignments.clear();
      textLetterSpacings.clear();
      boldTextOverlayIds.clear();
      italicTextOverlayIds.clear();
      underlineTextOverlayIds.clear();
      strikeTextOverlayIds.clear();
      textOpacities.clear();
      textLineHeights.clear();
      textOutlineWidths.clear();
      textOutlineColors.clear();
      textCurves.clear();
      gradientTextOverlayIds.clear();
      customFontPaths.clear();
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
        if (oldBgColors.containsKey(sourceIndex)) textBgColors[i] = oldBgColors[sourceIndex]!;
        if (oldBgOpacities.containsKey(sourceIndex)) textBgOpacities[i] = oldBgOpacities[sourceIndex]!;
        if (oldBgPaddings.containsKey(sourceIndex)) textBgPaddings[i] = oldBgPaddings[sourceIndex]!;
        if (oldBgRadii.containsKey(sourceIndex)) textBgRadii[i] = oldBgRadii[sourceIndex]!;
        if (oldBgBorders.containsKey(sourceIndex)) textBgBorders[i] = oldBgBorders[sourceIndex]!;
        if (oldBgShadows.containsKey(sourceIndex)) textBgShadows[i] = oldBgShadows[sourceIndex]!;
        if (oldBgGradients.contains(sourceIndex)) textBgGradients.add(i);
        if (oldGlowColors.containsKey(sourceIndex)) {
          textGlowColors[i] = oldGlowColors[sourceIndex]!;
        }
        if (oldGlowStrengths.containsKey(sourceIndex)) {
          textGlowStrengths[i] = oldGlowStrengths[sourceIndex]!;
        }
        if (oldAlignments.containsKey(sourceIndex)) textAlignments[i] = oldAlignments[sourceIndex]!;
        if (oldSpacings.containsKey(sourceIndex)) textLetterSpacings[i] = oldSpacings[sourceIndex]!;
        if (oldBoldIds.contains(sourceIndex)) boldTextOverlayIds.add(i);
        if (oldItalicIds.contains(sourceIndex)) italicTextOverlayIds.add(i);
        if (oldUnderlineIds.contains(sourceIndex)) underlineTextOverlayIds.add(i);
        if (oldStrikeIds.contains(sourceIndex)) strikeTextOverlayIds.add(i);
        if (oldOpacities.containsKey(sourceIndex)) textOpacities[i] = oldOpacities[sourceIndex]!;
        if (oldLineHeights.containsKey(sourceIndex)) textLineHeights[i] = oldLineHeights[sourceIndex]!;
        if (oldOutlineWidths.containsKey(sourceIndex)) textOutlineWidths[i] = oldOutlineWidths[sourceIndex]!;
        if (oldOutlineColors.containsKey(sourceIndex)) textOutlineColors[i] = oldOutlineColors[sourceIndex]!;
        if (oldCurves.containsKey(sourceIndex)) textCurves[i] = oldCurves[sourceIndex]!;
        if (oldGradients.contains(sourceIndex)) gradientTextOverlayIds.add(i);
        if (oldCustomPaths.containsKey(sourceIndex)) customFontPaths[i] = oldCustomPaths[sourceIndex]!;
        if (oldTextIds.contains(sourceIndex)) textOverlayIds.add(i);
        if (oldStickerIds.contains(sourceIndex)) stickerOverlayIds.add(i);
      }

      if (selectedStickerIndex != null) {
        if (selectedStickerIndex == index) {
          selectedStickerIndex = null;
        } else if (selectedStickerIndex! > index) {
          selectedStickerIndex = selectedStickerIndex! - 1;
        }
      }
      if (selectedTextIndex != null) {
        if (selectedTextIndex == index) {
          selectedTextIndex = null;
        } else if (selectedTextIndex! > index) {
          selectedTextIndex = selectedTextIndex! - 1;
        }
      }
    });
  }

  void openBackgroundRemover() {
    if (busy) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackgroundRemoverPage(
          initialPhotoA: a,
          initialPhotoB: b,
          initialSideA: _selectedPhotoSideA ?? _selectedTemplatePhotoSideA ?? true,
          onApply: (sideA, cutout) async {
            if (!mounted) return;
            setState(() {
              // Replace only the requested picture. Keep text, stickers,
              // poster layout, other photo and selection state unchanged.
              if (sideA) {
                a = cutout;
              } else {
                b = cutout;
              }
              _photoScales[sideA] = 1.0;
              _photoOffsets[sideA] = Offset.zero;
              _photoStartScales[sideA] = 1.0;
              _templatePhotoScales[sideA] = 1.0;
              _templatePhotoOffsets[sideA] = Offset.zero;
              _templatePhotoStartScales[sideA] = 1.0;
              // Applying a photo cutout explicitly changes editing target.
              _clearCanvasSelection();
              _selectCanvasObject(photoSideA: sideA);
            });
          },
        ),
      ),
    );
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
      if (showStickerTools) _clearCanvasSelection();
      showTextTools = false;
      showCanvasTools = false;
    });
  }


  void openTagraStickerGallery() {
    setState(() {
      final previousTagraIndex = selectedTagraStickerIndex;
      _clearCanvasSelection();
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
      _clearCanvasSelection();
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
      _selectCanvasObject();
    });
  }

  void openLetterStyleGallery(bool sideA) {
    setState(() {
      _clearCanvasSelection();
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

      _clearCanvasSelection();
      _selectCanvasObject(letterIndex: index);
    });
  }

  void deleteSelectedLetterOverlay() {
    final index = selectedLetterOverlayIndex;
    if (index == null || index < 0 || index >= letterOverlays.length) return;
    setState(() {
      letterOverlays.removeAt(index);
      _selectCanvasObject();
    });
  }

  bool get _hasSelectedAStyle {
    final index = selectedLetterOverlayIndex;
    return index != null &&
        index >= 0 &&
        index < letterOverlays.length &&
        letterOverlays[index].sideA;
  }

  void _setSelectedAStyleScale(double nextScale) {
    final index = selectedLetterOverlayIndex;
    if (index == null || index < 0 || index >= letterOverlays.length) return;
    final item = letterOverlays[index];
    if (!item.sideA) return;

    final clampedScale = nextScale.clamp(0.2, 5.0).toDouble();
    if ((clampedScale - item.scale).abs() < 0.0001) return;

    setState(() {
      // Keep the visual centre fixed while the top-left anchored Transform scales.
      final sizeDelta = 110.0 * (item.scale - clampedScale) / 2;
      item.position += Offset(sizeDelta, sizeDelta);
      item.scale = clampedScale;
    });
  }

  void _moveSelectedAStyle(Offset delta) {
    final index = selectedLetterOverlayIndex;
    if (index == null || index < 0 || index >= letterOverlays.length) return;
    final item = letterOverlays[index];
    if (!item.sideA) return;
    setState(() => item.position += delta);
  }

  Widget _buildCompactLetterStylePanel(bool sideA) {
    final index = selectedLetterOverlayIndex;
    if (index == null || index < 0 || index >= letterOverlays.length ||
        letterOverlays[index].sideA != sideA) {
      return const SizedBox.shrink();
    }
    final item = letterOverlays[index];
    final accent = sideA ? gold : const Color(0xFFD6B5FF);
    void setScale(double value) {
      if (sideA) { _setSelectedAStyleScale(value); }
      else { _setSelectedBStyleScale(value); }
    }
    void move(Offset delta) {
      if (sideA) { _moveSelectedAStyle(delta); }
      else { _moveSelectedBStyle(delta); }
    }
    Widget button(IconData icon, String tooltip, VoidCallback action,
        {bool danger = false}) {
      return SizedBox(
        width: 42, height: 42,
        child: Tooltip(
          message: AppLanguage.tr(tooltip),
          child: Material(
            color: danger ? const Color(0xFFCF393B) : const Color(0xFF263047),
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: action,
              child: Icon(icon, size: 21,
                  color: danger ? Colors.white : accent),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Center(
        child: Container(
          width: (MediaQuery.sizeOf(context).width - 28)
              .clamp(240.0, 370.0).toDouble(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF141D2D),
            border: Border.all(color: accent.withValues(alpha: 0.8),
                width: 1.3),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(color: Color(0x50000000), blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 35,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(AppLanguage.tr(sideA ? 'A STYLE' : 'B STYLE'),
                        textDirection: AppLanguage.direction,
                        style: TextStyle(color: accent, fontSize: 11,
                            fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(AppLanguage.tr('Drag • Pinch • Adjust'), maxLines: 1,
                          textDirection: AppLanguage.direction,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.white60)),
                    ),
                    SizedBox(
                      width: 36, height: 34,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: AppLanguage.tr('Deselect style'),
                        onPressed: () => setState(_clearCanvasSelection),
                        icon: const Icon(Icons.close_rounded,
                            size: 19, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 41,
                child: Row(
                  children: [
                    button(Icons.remove_rounded, 'Zoom out',
                        () => setScale(item.scale - 0.1)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accent,
                          inactiveTrackColor: const Color(0xFF364054),
                          thumbColor: Colors.white,
                          trackHeight: 3,
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          min: 0.2, max: 5.0,
                          value: item.scale.clamp(0.2, 5.0).toDouble(),
                          onChanged: setScale,
                        ),
                      ),
                    ),
                    button(Icons.add_rounded, 'Zoom in',
                        () => setScale(item.scale + 0.1)),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  button(Icons.keyboard_arrow_up_rounded, 'Move up',
                      () => move(const Offset(0, -8))),
                  button(Icons.keyboard_arrow_left_rounded, 'Move left',
                      () => move(const Offset(-8, 0))),
                  button(Icons.keyboard_arrow_down_rounded, 'Move down',
                      () => move(const Offset(0, 8))),
                  button(Icons.keyboard_arrow_right_rounded, 'Move right',
                      () => move(const Offset(8, 0))),
                  button(Icons.delete_outline_rounded, 'Delete style',
                      deleteSelectedLetterOverlay, danger: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAStyleControlPanel() => _buildCompactLetterStylePanel(true);

  bool get _hasSelectedBStyle {
    final index = selectedLetterOverlayIndex;
    return index != null &&
        index >= 0 &&
        index < letterOverlays.length &&
        !letterOverlays[index].sideA;
  }

  void _setSelectedBStyleScale(double nextScale) {
    final index = selectedLetterOverlayIndex;
    if (index == null || index < 0 || index >= letterOverlays.length) return;
    final item = letterOverlays[index];
    if (item.sideA) return;

    final clampedScale = nextScale.clamp(0.2, 5.0).toDouble();
    if ((clampedScale - item.scale).abs() < 0.0001) return;

    setState(() {
      // Keep the visual centre fixed while the top-left anchored Transform scales.
      final sizeDelta = 110.0 * (item.scale - clampedScale) / 2;
      item.position += Offset(sizeDelta, sizeDelta);
      item.scale = clampedScale;
    });
  }

  void _moveSelectedBStyle(Offset delta) {
    final index = selectedLetterOverlayIndex;
    if (index == null || index < 0 || index >= letterOverlays.length) return;
    final item = letterOverlays[index];
    if (item.sideA) return;
    setState(() => item.position += delta);
  }

  Widget _buildBStyleControlPanel() => _buildCompactLetterStylePanel(false);

  Widget letterStyleTool(String asset, String title, VoidCallback tap) {
    return Container(
      width: 94,
      height: 68,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: const Color(0xFF1B2638),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 35,
                width: 58,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 3),
              Text(
                AppLanguage.tr(title),
                textDirection: AppLanguage.direction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPremiumTextPanel() {
    final index = selectedTextIndex;
    final valid = index != null &&
        index >= 0 &&
        index < overlays.length &&
        textOverlayIds.contains(index);
    final active = valid ? index : null;

    void updateSelected(VoidCallback mutation) {
      if (active == null) {
        msg('پہلے ٹیکسٹ منتخب کریں');
        return;
      }
      _rememberTextEdit();
      setState(mutation);
    }

    return PremiumTextEditorPanel(
      selectedText: active == null ? null : overlays[active],
      onClose: () => setState(() {
        showTextTools = false;
        showGlowPanel = false;
      }),
      onAddText: addText,
      onEditText: editSelectedText,
      onDeleteText: deleteSelectedText,
      styleActions: [
        TextPanelAction('Font', Icons.font_download_outlined, chooseTextFont),
        TextPanelAction('Import TTF/OTF', Icons.upload_file, importSelectedTextFont),
        TextPanelAction('Zoom +', Icons.zoom_in, () => zoomSelectedText(1.2)),
        TextPanelAction('Zoom −', Icons.zoom_out, () => zoomSelectedText(0.8)),
        TextPanelAction('Bold', Icons.format_bold, toggleSelectedTextBold),
        TextPanelAction('Italic', Icons.format_italic, toggleTextItalic),
        TextPanelAction('Underline', Icons.format_underline, toggleTextUnderline),
        TextPanelAction('Strike', Icons.strikethrough_s, toggleTextStrikethrough),
        TextPanelAction('Presets', Icons.style_outlined, chooseTextPreset),
        TextPanelAction('Reset Style', Icons.restart_alt, resetSelectedTextStyle),
      ],
      layoutActions: [
        TextPanelAction('Alignment', Icons.format_align_center,
          cycleSelectedTextAlignment),
        TextPanelAction('Line Height +', Icons.height,
          () => adjustTextLineHeight(0.1)),
        TextPanelAction('Line Height −', Icons.compress,
          () => adjustTextLineHeight(-0.1)),
        TextPanelAction('Letter Space +', Icons.space_bar,
          () => adjustSelectedTextSpacing(0.5)),
        TextPanelAction('Letter Space −', Icons.space_bar,
          () => adjustSelectedTextSpacing(-0.5)),
        TextPanelAction('Curve Up', Icons.keyboard_arrow_up,
          () => adjustSelectedTextCurve(0.2)),
        TextPanelAction('Curve Down', Icons.keyboard_arrow_down,
          () => adjustSelectedTextCurve(-0.2)),
        TextPanelAction('Duplicate', Icons.copy, duplicateSelectedText),
      ],
      moreActions: [
        TextPanelAction('Undo Text', Icons.undo, undoTextEdit),
        TextPanelAction('Redo Text', Icons.redo, redoTextEdit),
        TextPanelAction('BG Remover', Icons.content_cut, openBackgroundRemover),
        TextPanelAction('Color Palette', Icons.palette, chooseTextColor),
        TextPanelAction('Text Background', Icons.format_color_fill,
          editTextBackground),
        TextPanelAction('Reset Style', Icons.restart_alt,
          resetSelectedTextStyle),
      ],
      textColor: active == null ? Colors.white :
          (textColors[active] ?? Colors.white),
      onTextColor: (color) => updateSelected(
        () => textColors[active!] = color),
      onMoreColors: chooseTextColor,
      textOpacity: active == null ? 1 : (textOpacities[active] ?? 1),
      onOpacityStart: () { if (active != null) _rememberTextEdit(); },
      onTextOpacity: (value) {
        if (active == null) return;
        setState(() => textOpacities[active] = value);
      },
      glowEnabled: active != null && (textGlowStrengths[active] ?? 0) > 0,
      onGlowToggle: () => updateSelected(() {
        textGlowStrengths[active!] =
            (textGlowStrengths[active] ?? 0) > 0 ? 0 : 100;
      }),
      glowStrength: active == null ? 0 :
          (textGlowStrengths[active] ?? 0),
      onGlowStart: () { if (active != null) _rememberTextEdit(); },
      onGlowStrength: (value) {
        if (active == null) return;
        setState(() => textGlowStrengths[active] = value);
      },
      glowColor: active == null ? const Color(0xFFFF1744) :
          (textGlowColors[active] ?? const Color(0xFFFF1744)),
      onGlowColor: (color) => updateSelected(() {
        textGlowColors[active!] = color;
        if ((textGlowStrengths[active] ?? 0) <= 0) {
          textGlowStrengths[active] = 100;
        }
      }),
      gradientEnabled: active != null &&
          gradientTextOverlayIds.contains(active),
      onGradientToggle: toggleSelectedTextGradient,
      outlineWidth: active == null ? 0 :
          (textOutlineWidths[active] ?? 0),
      onOutlineToggle: () => updateSelected(() {
        if ((textOutlineWidths[active] ?? 0) > 0) {
          textOutlineWidths.remove(active);
        } else {
          textOutlineWidths[active!] = 1.5;
        }
      }),
      onOutlineIncrease: () => adjustSelectedTextOutline(0.5),
      onOutlineDecrease: () => adjustSelectedTextOutline(-0.5),
      onOutlineColor: cycleTextOutlineColor,
      backgroundEnabled: active != null &&
          textBgColors.containsKey(active),
      onBackgroundToggle: () => updateSelected(() {
        if (textBgColors.containsKey(active)) {
          textBgColors.remove(active);
        } else {
          textBgColors[active!] = const Color(0xFF0C1430);
          textBgOpacities[active] = 0.85;
        }
      }),
      backgroundColor: active == null ? const Color(0xFF0C1430) :
          (textBgColors[active] ?? const Color(0xFF0C1430)),
      onBackgroundColor: (color) => updateSelected(() {
        textBgColors[active!] = color;
        textBgOpacities.putIfAbsent(active, () => 0.85);
      }),
      backgroundOpacity: active == null ? 0.85 :
          (textBgOpacities[active] ?? 0.85),
      onBackgroundOpacityStart: () {
        if (active != null) _rememberTextEdit();
      },
      onBackgroundOpacity: (value) {
        if (active == null) return;
        setState(() {
          textBgColors.putIfAbsent(
            active, () => const Color(0xFF0C1430));
          textBgOpacities[active] = value;
        });
      },
      onBackgroundSettings: editTextBackground,
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
      width: 94,
      height: 68,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
                    fontSize: isGlowTool ? 24 : 21,
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
                const SizedBox(height: 3),
                Text(
                  AppLanguage.tr(title),
                  textDirection: AppLanguage.direction,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isGlowTool
                        ? const Color(0xFF00E5FF)
                        : Colors.white,
                    fontSize: 10,
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
  bool? _selectedTemplatePhotoSideA;

  // While a text layer is selected, do not send gestures to the photo below.
  bool get _textOwnsCanvasGestures =>
      !isExportingPoster &&
      selectedTextIndex != null &&
      textOverlayIds.contains(selectedTextIndex);

  void _selectCanvasObject({
    int? tagraIndex,
    int? letterIndex,
    int? textIndex,
    int? stickerIndex,
    bool isVs = false,
    bool? photoSideA,
    bool? templatePhotoSideA,
  }) {
    // Selected text is the editing target until another text is tapped or deleted.
    if (_textOwnsCanvasGestures && textIndex == null) return;
    // Centralized exclusive selection: passing one target clears every other
    // movable object's selection. Label asset paths are content, not selection.
    selectedTagraStickerIndex = tagraIndex;
    selectedLetterOverlayIndex = letterIndex;
    selectedTextIndex = textIndex;
    selectedStickerIndex = stickerIndex;
    isVsSelected = isVs;
    _selectedPhotoSideA = photoSideA;
    _selectedTemplatePhotoSideA = templatePhotoSideA;

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
        title: Text(AppLanguage.tr(sideA ? 'Edit A Side Name' : 'Edit B Side Name')),
        content: StatefulBuilder(
          builder: (context, setDialogState) => TextField(
            controller: controller,
            autofocus: true,
            maxLength: 28,
            textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(controller.text)
                ? TextDirection.rtl
                : TextDirection.ltr,
            textAlign: RegExp(r'[\u0600-\u06FF]').hasMatch(controller.text)
                ? TextAlign.right
                : TextAlign.left,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: AppLanguage.tr(sideA ? 'Enter A Side name' : 'Enter B Side name'),
              hintText: AppLanguage.tr(sideA ? 'Type A Side name' : 'Type B Side name'),
            ),
            onChanged: (_) => setDialogState(() {}),
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLanguage.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: Text(AppLanguage.tr('Save')),
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
    final isUrduLabelText = RegExp(r'[\u0600-\u06FF]').hasMatch(labelText);
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
              onTap: () {
                if (_textOwnsCanvasGestures) return;
                setState(() => _selectCanvasObject(photoSideA: sideA));
              },
              onScaleStart: (_) {
                if (_textOwnsCanvasGestures) return;
                setState(() {
                  _selectCanvasObject(photoSideA: sideA);
                  _photoStartScales[sideA] = _photoScales[sideA] ?? 1.0;
                });
              },
              onScaleUpdate: (details) {
                if (_textOwnsCanvasGestures ||
                    _selectedPhotoSideA != sideA) return;
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
                      fit: BoxFit.contain,
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
                  // Keep the selected label artwork unchanged while only its name text updates.
                  Image.asset(
                    label,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      // Give long names a wider safe area, then scale them down
                      // as needed so they remain inside the original label artwork.
                      child: FractionallySizedBox(
                        widthFactor: 0.78,
                        heightFactor: 0.90,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            labelText,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            textDirection: isUrduLabelText
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: TextStyle(
                              fontFamily: isUrduLabelText
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
  Widget build(BuildContext context) => Scaffold(
    key: _editorScaffoldKey,
    endDrawer: _buildSettingsDrawer(),
    body: SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        const Icon(Icons.workspace_premium, color: gold, size: 34),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voting Pro', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: gold)),
            Text(AppLanguage.isUrdu ? 'پوسٹر میکر' : 'P O S T E R   M A K E R',
              textDirection: AppLanguage.direction,
              style: const TextStyle(fontSize: 10, letterSpacing: 2)),
          ])),
        SizedBox(
          width: 40, height: 40,
          child: IconButton(
            tooltip: AppLanguage.tr('Settings'),
            padding: EdgeInsets.zero,
            iconSize: 21,
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            onPressed: () => _editorScaffoldKey.currentState?.openEndDrawer(),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.download_rounded), label: Text(AppLanguage.tr(busy ? 'ذرا انتظار کریں…' : 'Save Poster ↓'), textDirection: AppLanguage.direction))),
        const SizedBox(width: 8), IconButton(onPressed: busy ? null : share, tooltip: AppLanguage.tr('Share Poster'), icon: const Icon(Icons.share)),
      ]),
    ])),
    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Column(children: [
      // Empty canvas touches must not deselect an active text overlay.
      // Only another text selection or Delete changes the active text.
      GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          if (selectedTextIndex == null &&
              selectedLetterOverlayIndex != null) {
            setState(_clearCanvasSelection);
          }
        },
        child: Screenshot(controller: shot, child: AspectRatio(aspectRatio: canvasRatio, child: Container(
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
                    Expanded(child: IgnorePointer(
                      ignoring: _textOwnsCanvasGestures,
                      child: photoSlot(true),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: IgnorePointer(
                      ignoring: _textOwnsCanvasGestures,
                      child: photoSlot(false),
                    )),
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
                        if (!isExportingPoster && isVsSelected)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() {
                                showVs = false;
                                vsOffset = Offset.zero;
                                vsScale = 1.0;
                                vsStartScale = 1.0;
                                _selectCanvasObject();
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
            final selected = !isExportingPoster && selectedLetterOverlayIndex == index;
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
                    final oldScale = item.scale;
                    final nextScale = details.pointerCount >= 2
                        ? (letterGestureStartScale * details.scale)
                            .clamp(0.2, 5.0)
                            .toDouble()
                        : oldScale;
                    item.position += details.focalPointDelta;
                    final centerAdjustment = 55.0 * (oldScale - nextScale);
                    item.position += Offset(centerAdjustment, centerAdjustment);
                    item.scale = nextScale;
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
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (index < 0 || index >= letterOverlays.length) {
                                return;
                              }
                              setState(() {
                                letterOverlays.removeAt(index);
                                _selectCanvasObject();
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
                          right: 0,
                          bottom: 0,
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
                                final oldScale = item.scale;
                                final nextScale = (letterResizeStartScale + dy * 0.01)
                                    .clamp(0.2, 5.0)
                                    .toDouble();
                                final centerAdjustment = 55.0 * (oldScale - nextScale);
                                item.position += Offset(centerAdjustment, centerAdjustment);
                                item.scale = nextScale;
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
                    final oldScale = item.scale;
                    final nextScale = details.pointerCount >= 2
                        ? (tagraGestureStartScale * details.scale)
                            .clamp(0.2, 5.0).toDouble()
                        : oldScale;
                    item.position += details.focalPointDelta +
                        Offset(70.0 * (oldScale - nextScale),
                            70.0 * (oldScale - nextScale));
                    item.scale = nextScale;
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
                          right: 0,
                          top: 0,
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
                          right: 0,
                          bottom: 0,
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
                                final nextScale =
                                    (tagraGestureStartScale + delta * 0.01)
                                        .clamp(0.2, 5.0).toDouble();
                                final centerDelta = 70.0 * (item.scale - nextScale);
                                item.position += Offset(centerDelta, centerDelta);
                                item.scale = nextScale;
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

          if (selectedReadyMadeTemplate == null)
            ...([...overlays.asMap().entries]..sort((left, right) {
              // Keep the active text on top for hit testing, while preserving
              // the original poster stacking order when saving/exporting.
              if (_textOwnsCanvasGestures) {
                if (left.key == selectedTextIndex) return 1;
                if (right.key == selectedTextIndex) return -1;
              }
              return left.key.compareTo(right.key);
            })).map((entry) {
            final index = entry.key;
            final isText = textOverlayIds.contains(index);
            final isSticker = stickerOverlayIds.contains(index);
            final isSelectedSticker = !isExportingPoster && isSticker && selectedStickerIndex == index;
            final position = textPositions[index] ??
                Offset(10 + (index % 4) * 35.0, 12 + (index % 3) * 38.0);
            final scale = textScales[index] ?? 1.0;
            // Enlarge the hit target without changing the painted text position.
            final textTouchInset = isText && !isExportingPoster ? 12.0 : 0.0;
            return Positioned(
              left: position.dx - textTouchInset,
              top: position.dy - textTouchInset,
              child: GestureDetector(
                key: ValueKey(index),
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {
                  // Do not wait for the double-tap recognizer before selecting.
                  if (isText && selectedTextIndex != index) {
                    setState(() => _selectCanvasObject(textIndex: index));
                  } else if (isSticker && selectedStickerIndex != index) {
                    setState(() => _selectCanvasObject(stickerIndex: index));
                  }
                },
                onTap: () {
                  if (isText && selectedTextIndex != index) {
                    setState(() => _selectCanvasObject(textIndex: index));
                  } else if (isSticker && selectedStickerIndex != index) {
                    setState(() => _selectCanvasObject(stickerIndex: index));
                  }
                },
                onDoubleTap: () {
                  if (isText) {
                    setState(() => _selectCanvasObject(textIndex: index));
                    editSelectedText();
                  }
                },
                onScaleStart: (details) {
                  // Gesture start cannot steal selection from another text.
                  if (_textOwnsCanvasGestures && selectedTextIndex != index) return;
                  if (isText) {
                    _rememberTextEdit();
                  } else {
                    _textUndoHistory.clear();
                    _textRedoHistory.clear();
                  }
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
                  if (_textOwnsCanvasGestures && selectedTextIndex != index) return;
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
                child: Padding(
                  padding: EdgeInsets.all(textTouchInset),
                  child: Transform.scale(
                  scale: (isText || isSticker) ? scale : 1.0,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(5),
                        decoration: (!isExportingPoster && isText && selectedTextIndex == index) || isSelectedSticker
                            ? BoxDecoration(
                                border: Border.all(color: gold, width: 2),
                                borderRadius: BorderRadius.circular(isSticker ? 12 : 3),
                              )
                            : null,
                        child: AdvancedTextOverlay(
                          text: entry.value,
                          backgroundColor: isText ? textBgColors[index] : null,
                          backgroundOpacity: textBgOpacities[index] ?? 0.8,
                          backgroundExpansion: textBgPaddings[index] ?? 0,
                          backgroundGradient: textBgGradients.contains(index),
                          backgroundShadowBlur: textBgShadows[index] ?? 0,
                          backgroundBorderWidth: textBgBorders[index] ?? 0,
                          alignment: _overlayTextAlign(index),
                          direction: _hasArabicScript(entry.value) ? TextDirection.rtl : TextDirection.ltr,
                          gradient: gradientTextOverlayIds.contains(index),
                          outlineWidth: textOutlineWidths[index] ?? 0.0,
                          outlineColor: textOutlineColors[index] ?? Colors.black,
                          curve: textCurves[index] ?? 0.0,
                          style: TextStyle(
                            fontFamily: textFonts[index] ??
                                (RegExp(r'[\u0600-\u06FF]').hasMatch(entry.value)
                                    ? 'NotoNastaliqUrdu'
                                    : 'RobotoLocal'),
                            fontSize: 28,
                            fontWeight: boldTextOverlayIds.contains(index) ? FontWeight.w900 : FontWeight.normal,
                            fontStyle: italicTextOverlayIds.contains(index) ? FontStyle.italic : FontStyle.normal,
                            decoration: TextDecoration.combine([
                              if (underlineTextOverlayIds.contains(index)) TextDecoration.underline,
                              if (strikeTextOverlayIds.contains(index)) TextDecoration.lineThrough,
                            ]),
                            decorationColor: textColors[index] ?? Colors.white,
                            height: textLineHeights[index] ?? 1.2,
                            letterSpacing: textLetterSpacings[index] ?? 0.0,
                            color: (textColors[index] ?? Colors.white)
                                .withOpacity(textOpacities[index] ?? 1.0),
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
                              _textUndoHistory.clear();
                              _textRedoHistory.clear();
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
                      if (!isExportingPoster && isText && selectedTextIndex == index)
                        Positioned(
                          right: -15,
                          top: -15,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => deleteSelectedText(targetIndex: index),
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
                      if (!isExportingPoster && isText && selectedTextIndex == index)
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
                      if (!isExportingPoster && isText && selectedTextIndex == index)
                        Positioned(
                          right: -13,
                          bottom: -13,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              _rememberTextEdit();
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
      )))),
      if (!isExportingPoster && _hasSelectedAStyle)
        _buildAStyleControlPanel(),
      if (!isExportingPoster && _hasSelectedBStyle)
        _buildBStyleControlPanel(),

    ]))),
    if (showReadyMadeTemplateGallery) _buildReadyMadeTemplatePicker(),
    if (showTextTools && selectedReadyMadeTemplate == null)
      _buildPremiumTextPanel(),
    if (!showTextTools || selectedReadyMadeTemplate != null) Container(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 9),
      color: const Color(0xFF101827),
      child: selectedReadyMadeTemplate != null
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                tool('A', 'Change Photo A', () => pick(true)),
                tool('B', 'Change Photo B', () => pick(false)),
                tool('🎨', 'Templates', readyMadeTemplatesTool),
                tool('✂', 'BG Remover', openBackgroundRemover),
                tool('↩', 'Classic Editor', () => setState(() {
                  _clearCanvasSelection();
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
                      tool('⇧', 'Import TTF/OTF Font', importSelectedTextFont),
                      tool('✂', 'BG Remover', openBackgroundRemover),
                      tool('↶', 'Undo Text', undoTextEdit),
                      tool('↷', 'Redo Text', redoTextEdit),
                      tool('◠', 'Curve Up (Urdu / English)', () => adjustSelectedTextCurve(0.2)),
                      tool('◡', 'Curve Down (Urdu / English)', () => adjustSelectedTextCurve(-0.2)),
                      tool('🌈', 'Gradient Fill', toggleSelectedTextGradient),
                      tool('▣+', 'Outline Width +', () => adjustSelectedTextOutline(0.5)),
                      tool('▣−', 'Outline Width −', () => adjustSelectedTextOutline(-0.5)),
                      tool('▣', 'Outline Color', cycleTextOutlineColor),
                      tool('B', 'Bold On/Off', toggleSelectedTextBold),
                      tool('I', 'Italic On/Off', toggleTextItalic),
                      tool('U̲', 'Underline On/Off', toggleTextUnderline),
                      tool('S̶', 'Strikethrough On/Off', toggleTextStrikethrough),
                      tool('▤', 'Text Presets', chooseTextPreset),
                      tool('⧉', 'Duplicate Text', duplicateSelectedText),
                      tool('≡', 'Align Left / Center / Right', cycleSelectedTextAlignment),
                      tool('↔+', 'Letter Spacing +', () => adjustSelectedTextSpacing(0.5)),
                      tool('↔−', 'Letter Spacing −', () => adjustSelectedTextSpacing(-0.5)),
                      tool('↕+', 'Line Height +', () => adjustTextLineHeight(0.1)),
                      tool('↕−', 'Line Height −', () => adjustTextLineHeight(-0.1)),
                      tool('◉+', 'Opacity +', () => adjustTextOpacity(0.1)),
                      tool('◉−', 'Opacity −', () => adjustTextOpacity(-0.1)),
                      tool('↺', 'Reset Text Style', resetSelectedTextStyle),
                      tool('🎨', 'Color', chooseTextColor),
                      tool('▰', 'Text Background', editTextBackground),
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
                tool('✂', 'BG Remover', openBackgroundRemover),
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
