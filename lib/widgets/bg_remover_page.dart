import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/offline_bg_remover.dart';
import '../services/mask_history.dart';
import '../app_language.dart';

/// Full-screen editor following the three approved Voting Pro mockups.
/// The AI model, manual brush and PNG export run on the device without an API.
class BackgroundRemoverPage extends StatefulWidget {
  const BackgroundRemoverPage({
    super.key,
    required this.initialPhotoA,
    required this.initialPhotoB,
    required this.onApply,
    this.initialSideA = true,
    this.onClose,
    this.initialOriginal,
    this.autoMask,
    this.onCanvasChanged,
    this.onSelectSide,
    this.onUpload,
  });

  final VoidCallback? onCanvasChanged;
  final File? initialPhotoA;
  final File? initialPhotoB;
  final bool initialSideA;
  final VoidCallback? onClose;
  // Inline editor retains the original independently of the applied cutout.
  final File? initialOriginal;
  final ValueChanged<bool>? onSelectSide;
  final VoidCallback? onUpload;
  final Future<Uint8List> Function(Uint8List, int, int)? autoMask;
  final Future<void> Function(bool sideA, File result) onApply;

  @override
  State<BackgroundRemoverPage> createState() => BackgroundRemoverPageState();
}

class BackgroundRemoverPageState extends State<BackgroundRemoverPage> {
  static const mint = Color(0xFF79F0D6);
  static const gold = Color(0xFFFFD84D);
  static const dark = Color(0xFF080E19);
  final _picker = ImagePicker();
  bool _sideA = true;
  bool _busy = false;
  bool _manual = false;
  bool _erase = true;
  bool _compare = false;
  bool _hasUnsavedEdits = false;
  bool _allowExit = false;
  double _brushSize = 28;
  Uint8List? _sourcePng;
  Uint8List? _previewPng;
  Uint8List? _mask;
  int _imageWidth = 0, _imageHeight = 0;
  final List<Uint8List> _undo = [];
  final List<Uint8List> _redo = [];
  Offset? _lastPoint;
  // Brush cursor repaints independently; pan events must not rebuild the
  // entire full-screen editor and decode/recreate the preview on each move.
  final ValueNotifier<Offset?> _brushCursor = ValueNotifier<Offset?>(null);
  Rect? _previewRect;
  String _status = 'Upload a picture or use the current A/B photo';

  @override
  void initState() {
    super.initState();
    _sideA = widget.initialSideA;
    final initial = _sideA ? widget.initialPhotoA : widget.initialPhotoB;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFile(widget.initialOriginal ?? initial,
            applied: widget.initialOriginal == null ? null : initial);
      });
    }
  }

  @override
  void dispose() {
    _releaseLivePixels();
    _brushCursor.dispose();
    super.dispose();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLanguage.tr(message), textDirection: AppLanguage.direction), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _loadFile(File file, {File? applied}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Preparing image locally…';
    });
    try {
      final prepared = await OfflineBgRemover.open(
        await file.readAsBytes(),
        applied != null && applied.path != file.path ? await applied.readAsBytes() : null,
      );
      final history = applied == null ? (<Uint8List>[], <Uint8List>[]) :
          await MaskHistory.read(applied, prepared.width, prepared.height);
      if (!mounted) return;
      setState(() {
        _sourcePng = prepared.source;
        _previewPng = prepared.preview;
        _imageWidth = prepared.width;
        _imageHeight = prepared.height;
        _mask = prepared.mask;
        _manual = false;
        _compare = false;
        _undo..clear()..addAll(history.$1);
        _redo..clear()..addAll(history.$2);
        _hasUnsavedEdits = false;
        _lastPoint = null;
        _brushCursor.value = null;
        _status = 'Image ready • Auto or Manual editing';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = _sourcePng == null
              ? 'Image unavailable • please choose another picture'
              : 'Previous image kept • choose another picture';
        });
      }
      _notice('Image could not be loaded');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Prevent accidentally losing a manual cutout when switching slots or
  // replacing the source image. Undo history changes only after editing.
  Future<bool> _confirmDiscardEdits() async {
    if (!_hasUnsavedEdits) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard background edits?'),
        content: const Text(
          'Leaving or switching pictures will discard the current cutout and its Undo history. '
          'Use Apply Cutout to save your work first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );
    return discard == true && mounted;
  }

  Future<void> _uploadPicture() async {
    if (_busy || !await _confirmDiscardEdits()) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      await _loadFile(File(picked.path));
    } catch (_) {
      _notice('Could not open gallery');
    }
  }

  Future<void> _changeSide(bool sideA) async {
    if (_busy || _sideA == sideA || !await _confirmDiscardEdits()) return;
    setState(() {
      _sideA = sideA;
      _sourcePng = null;
      _previewPng = null;
      _mask = null;
      _undo.clear();
      _redo.clear();
      _hasUnsavedEdits = false;
      _lastPoint = null;
      _brushCursor.value = null;
      _previewRect = null;
    });
    final photo = sideA ? widget.initialPhotoA : widget.initialPhotoB;
    if (photo != null) {
      await _loadFile(photo);
    } else {
      setState(() => _status = 'Upload picture for side ${sideA ? "A" : "B"}');
    }
  }

  void _recordUndo() {
    final current = _mask;
    if (current == null) return;
    _hasUnsavedEdits = true;
    _undo.add(Uint8List.fromList(current));
    if (_undo.length > MaskHistory.limit(_mask!.length)) _undo.removeAt(0);
    _redo.clear();
  }

  Future<void> _updatePreview({bool commit = true}) async {
    if (_sourcePng == null || _mask == null) return;
    final bytes = await OfflineBgRemover.compose(
      _sourcePng!, Uint8List.fromList(_mask!),
    );
    if (!mounted) return;
    if (commit && widget.onClose != null) {
      await _commitInline(bytes);
      if (!mounted) return;
    }
    final hasUnsavedEdits = widget.onClose == null && _mask!.any((pixel) => pixel != 255);
    setState(() {
      _previewPng = bytes;
      _brushCursor.value = null;
      _hasUnsavedEdits = hasUnsavedEdits;
      // Always show the updated result after editing, not stale Compare view.
      _compare = false;
    });
  }

  Future<void> _commitInline(Uint8List bytes) async {
    final apply = widget.onApply;
    final side = _sideA;
    final folder = await getApplicationDocumentsDirectory();
    final file = File('${folder.path}/voting_pro_cutout_${DateTime.now().microsecondsSinceEpoch}.png');
    try {
      await file.writeAsBytes(bytes, flush: true);
      await MaskHistory.save(file, _imageWidth, _imageHeight, _undo, _redo);
      if (!mounted) throw StateError('The editor was closed.');
      await apply(side, file);
    } catch (_) {
      final history = MaskHistory.sidecar(file);
      if (await history.exists()) await history.delete();
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<void> _autoRemove() async {
    if (_busy || _strokeActive || _sourcePng == null || _mask == null) {
      if (_sourcePng == null) _notice('Upload Your Picture first');
      return;
    }
    final originalMask = Uint8List.fromList(_mask!);
    final previousUndo = _undo.toList();
    final previousRedo = _redo.toList();
    final wasManual = _manual;
    final previousStatus = _status;
    setState(() {
      _busy = true;
      _manual = false;
      _status = 'Removing background offline…';
    });
    try {
      final result = await (widget.autoMask ?? OfflineBgRemover.autoMask)(
        _sourcePng!, _imageWidth, _imageHeight,
      );
      if (!mounted) return;
      _mask = result;
      _undo.add(originalMask);
      if (_undo.length > MaskHistory.limit(result.length)) _undo.removeAt(0);
      _redo.clear();
      await _updatePreview();
      if (!mounted) return;
      setState(() => _status = widget.onClose == null
          ? 'Auto cutout ready • Use Manual to refine edges'
          : 'Background removed • Saved');
    } catch (_) {
      _undo..clear()..addAll(previousUndo);
      _redo..clear()..addAll(previousRedo);
      _mask = originalMask;
      _hasUnsavedEdits = originalMask.any((pixel) => pixel != 255);
      if (mounted) {
        setState(() {
          _manual = wasManual;
          _status = previousStatus;
        });
      }
      _notice('Offline auto removal unavailable');
      if (_sourcePng != null && mounted) {
        try {
          await _updatePreview(commit: false);
        } catch (_) {
          // Keep the last valid preview if composing the original also fails.
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Serialize preview recomposition so quick Undo/Redo taps cannot show
  // an older PNG after a newer mask change finishes.
  Future<void> _runMaskEdit(VoidCallback edit) async {
    if (_busy || _strokeActive || _mask == null || _sourcePng == null) return;
    final previous = Uint8List.fromList(_mask!);
    final previousStatus = _status;
    final previousDirty = _hasUnsavedEdits;
    final undo = List<Uint8List>.of(_undo);
    final redo = List<Uint8List>.of(_redo);
    setState(() => _busy = true);
    try {
      edit();
      await _updatePreview();
    } catch (_) {
      _mask = previous;
      _status = previousStatus;
      _hasUnsavedEdits = previousDirty;
      _undo..clear()..addAll(undo);
      _redo..clear()..addAll(redo);
      _notice('Could not update cutout preview');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    await _runMaskEdit(() {
      _recordUndo();
      _mask!.fillRange(0, _mask!.length, 255);
      _status = 'Reset to original image';
    });
  }

  Future<void> _undoChange() async {
    if (_undo.isEmpty) return;
    await _runMaskEdit(() {
      _redo.add(Uint8List.fromList(_mask!));
      _mask = _undo.removeLast();
      _status = 'Previous edit restored';
    });
  }

  Future<void> _redoChange() async {
    if (_redo.isEmpty) return;
    await _runMaskEdit(() {
      _undo.add(Uint8List.fromList(_mask!));
      _mask = _redo.removeLast();
      _status = 'Edit reapplied';
    });
  }

  Offset? _toImagePoint(Offset local) {
    final rect = _previewRect;
    if (rect == null || !rect.contains(local)) return null;
    return Offset(
      (local.dx - rect.left) * _imageWidth / rect.width,
      (local.dy - rect.top) * _imageHeight / rect.height,
    );
  }

  bool get manualBrush => _manual && _mask != null;
  bool get editing => _busy || _strokeActive;
  // Keep the last live frame visible until its final cutout is committed.
  Uint8List? get livePixels => _livePixels;
  bool _strokeActive = false;
  List<Uint8List>? _undoBeforeStroke;
  List<Uint8List>? _redoBeforeStroke;
  Uint8List? _maskBeforeStroke;
  bool _dirtyBeforeStroke = false;

  void _startStrokeHistory() {
    if (_strokeActive) return;
    _undoBeforeStroke = _undo.toList();
    _redoBeforeStroke = _redo.toList();
    _dirtyBeforeStroke = _hasUnsavedEdits;
    _recordUndo();
    _maskBeforeStroke = _undo.last;
    _strokeActive = true;
  }

  void _clearStrokeHistory() {
    _undoBeforeStroke = null;
    _redoBeforeStroke = null;
    _maskBeforeStroke = null;
  }
  Uint8List? _livePixels;

  // Each composed frame has a new MemoryImage key. Evict superseded
  // previews rather than allowing a long brush stroke to fill ImageCache.
  void _releaseLivePixels() {
    final previous = _livePixels;
    _livePixels = null;
    if (previous != null) {
      PaintingBinding.instance.imageCache.evict(MemoryImage(previous));
    }
  }

  int _strokeRevision = 0;
  int _strokeSession = 0;
  bool _renderingStroke = false;
  final Stopwatch _previewClock = Stopwatch()..start();
  int _lastPreviewStart = -45;

  void _notifyCanvas() => widget.onCanvasChanged?.call();

  Future<void> _renderStroke() async {
    final now = _previewClock.elapsedMilliseconds;
    if (_renderingStroke || !_strokeActive || now - _lastPreviewStart < 45) return;
    // Bound preview frequency without delayed jobs surviving a closed panel.
    // The final stroke always composes the complete mask.
    _lastPreviewStart = now;
    _renderingStroke = true;
    final revision = _strokeRevision;
    final session = _strokeSession;
    try {
      final pixels = await OfflineBgRemover.compose(_sourcePng!, Uint8List.fromList(_mask!));
      if (mounted && _strokeActive && session == _strokeSession) {
        setState(() {
          _releaseLivePixels();
          _livePixels = pixels;
        });
        _notifyCanvas();
      }
    } catch (_) {
      // Stroke-end composition handles errors and restores the previous mask.
    } finally {
      _renderingStroke = false;
      if (mounted && _strokeActive && revision != _strokeRevision) unawaited(_renderStroke());
    }
  }

  // The photo widget already converts pointers through its pan/zoom transforms.
  // Fit the original pixels inside that local viewport just as Image.file does.
  void canvasStroke(Offset local, Size bounds, {required bool start, required double zoom}) {
    if (!manualBrush || _busy) return;
    final fitted = applyBoxFit(BoxFit.contain, Size(_imageWidth.toDouble(), _imageHeight.toDouble()), bounds);
    final rect = Alignment.center.inscribe(fitted.destination, Offset.zero & bounds);
    if (!rect.contains(local)) { _lastPoint = null; return; }
    if (start || !_strokeActive) {
      _startStrokeHistory();
      _lastPoint = null;
    }
    _drawStroke(Offset((local.dx-rect.left)*_imageWidth/rect.width,
        (local.dy-rect.top)*_imageHeight/rect.height), _brushSize*_imageWidth/(2*rect.width*zoom));
  }

  Future<void> finishCanvasStroke() => _endStroke();

  void _paintAt(Offset local) {
    if (!_manual || _busy || _mask == null || _sourcePng == null) return;
    final point = _toImagePoint(local);
    if (point == null) {
      _lastPoint = null;
      return;
    }
    final rect = _previewRect!;
    final radius = _brushSize * _imageWidth / rect.width / 2;
    _drawStroke(point, radius);
    _brushCursor.value = local;
  }

  void _drawStroke(Offset point, double radius) {
    final last = _lastPoint ?? point;
    final distance = (point - last).distance;
    final steps = math.max(1, (distance / math.max(1, radius / 3)).ceil());
    for (var step = 0; step <= steps; step++) {
      final at = Offset.lerp(last, point, step / steps)!;
      OfflineBgRemover.brush(
        _mask!, _imageWidth, _imageHeight,
        at.dx, at.dy, radius, erase: _erase,
      );
    }
    _lastPoint = point;
    _strokeRevision++;
    unawaited(_renderStroke());
  }

  void _beginStroke(Offset local) {
    if (_busy || !_manual || _mask == null ||
        _toImagePoint(local) == null) return;
    _startStrokeHistory();
    _lastPoint = null;
    _paintAt(local);
  }

  Future<void> _tapBrush(Offset local) async {
    if (_busy || !_manual || _mask == null ||
        _toImagePoint(local) == null) return;
    _beginStroke(local);
    await _endStroke();
  }

  Future<void> _endStroke() async {
    _lastPoint = null;
    if (!_manual || _busy || _mask == null || !_strokeActive) return;
    _strokeActive = false;
    _strokeSession++;
    _strokeRevision++;
    setState(() => _busy = true);
    try {
      await _updatePreview();
    } catch (_) {
      if (_maskBeforeStroke != null) _mask = _maskBeforeStroke;
      if (_undoBeforeStroke != null) _undo..clear()..addAll(_undoBeforeStroke!);
      if (_redoBeforeStroke != null) _redo..clear()..addAll(_redoBeforeStroke!);
      _hasUnsavedEdits = _dirtyBeforeStroke;
      _notice('Brush preview failed');
    } finally {
      _clearStrokeHistory();
      _releaseLivePixels();
      if (mounted) _notifyCanvas();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyCutout() async {
    if (_busy || _sourcePng == null || _mask == null) {
      if (_sourcePng == null) _notice('Upload Your Picture first');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Saving transparent PNG locally…';
    });
    try {
      final png = await OfflineBgRemover.compose(
        _sourcePng!, Uint8List.fromList(_mask!),
      );
      final folder = await getApplicationDocumentsDirectory();
      final file = File(
        '${folder.path}/voting_pro_cutout_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png, flush: true);
      if (!mounted) return;
      await widget.onApply(_sideA, file);
      if (mounted && widget.onClose == null) {
        setState(() => _allowExit = true);
        Navigator.of(context).pop();
      }
    } catch (_) {
      _notice('Could not apply cutout');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _action(
    String label, IconData icon, VoidCallback? action, {
    bool primary = false,
  }) =>
      OutlinedButton.icon(
        onPressed: _busy ? null : action,
        style: OutlinedButton.styleFrom(
          foregroundColor: primary ? dark : mint,
          backgroundColor: primary ? gold : const Color(0xFF19283C),
          side: BorderSide(color: primary ? gold : mint.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 19),
        label: Text(AppLanguage.tr(label), maxLines: 2, textAlign: TextAlign.center),
      );

  Widget _preview(bool imageAvailable) => imageAvailable
      ? LayoutBuilder(
          builder: (ctx, constraints) {
            final scale = math.min(
              constraints.maxWidth / _imageWidth,
              constraints.maxHeight / _imageHeight,
            );
            final w = _imageWidth * scale;
            final h = _imageHeight * scale;
            final left = (constraints.maxWidth - w) / 2;
            final top = (constraints.maxHeight - h) / 2;
            _previewRect = Rect.fromLTWH(left, top, w, h);
            return GestureDetector(
              key: widget.onClose == null ? null : const ValueKey('inline-cutout-brush'),
              behavior: HitTestBehavior.opaque,
              onPanStart: _manual ? (d) => _beginStroke(d.localPosition) : null,
              onPanUpdate: _manual ? (d) => _paintAt(d.localPosition) : null,
              onPanEnd: _manual ? (_) => _endStroke() : null,
              onPanCancel: _manual ? () => _endStroke() : null,
              onTapUp: _manual ? (d) => _tapBrush(d.localPosition) : null,
              child: Stack(
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    width: w,
                    height: h,
                    child: CustomPaint(
                      painter: _CheckerboardPainter(),
                      child: Image.memory(
                        _compare ? _sourcePng! : (_livePixels ?? _previewPng!),
                        gaplessPlayback: true,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  BackgroundBrushCursor(
                    cursor: _brushCursor,
                    enabled: _manual,
                    size: _brushSize,
                  ),
                  if (widget.onClose == null)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: _action(
                        _compare ? 'After' : 'Compare',
                        Icons.compare,
                        () => setState(() => _compare = !_compare),
                      ),
                    ),
                ],
              ),
            );
          },
        )
      : Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_outlined, color: mint, size: 48),
                const SizedBox(height: 6),
                Text(
                  AppLanguage.current == 'ur' ? 'اپنی تصویر منتخب کریں' : 'Upload Your Picture',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  AppLanguage.current == 'ur' ? 'تصویر یہاں دکھائی دے گی' : 'Preview appears here',
                  style: const TextStyle(color: Colors.white38),
                ),
              ],
            ),
          ),
        );

  Widget _mainDock(bool imageAvailable) {
    String label(String en, String ur) => AppLanguage.current == 'ur' ? ur : en;
    Widget control(String title, IconData icon, VoidCallback? action, {bool active = false}) =>
        Expanded(child: SizedBox(height: 50, child: OutlinedButton(
          onPressed: _busy ? null : action,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            foregroundColor: active ? gold : Colors.white,
            backgroundColor: active ? const Color(0xFF45345C) : const Color(0xFF172B43),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: active ? gold : const Color(0xFF45617A)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Flexible(child: Text(title, maxLines: 2, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, height: 1.05, fontWeight: FontWeight.w700))),
          ]),
        )));
    return Container(
      key: const ValueKey('main-remover-dock'),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF18263E), Color(0xFF101827)]),
        border: Border.all(color: const Color(0xFF7862A4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(builder: (context, bounds) => Padding(
        padding: const EdgeInsets.all(7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(textDirection: TextDirection.ltr, children: [
            SizedBox(width: 62, height: 52, child: OutlinedButton(
              key: const ValueKey('main-remover-back'),
              onPressed: widget.onClose,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero, foregroundColor: gold,
                backgroundColor: const Color(0xFF493715),
                side: const BorderSide(color: gold, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.arrow_back_rounded, size: 22),
                Text(label('Back', 'واپس'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            )),
            const SizedBox(width: 5),
            control(label('Auto Remove Background', 'خودکار پس منظر ہٹائیں'), Icons.auto_awesome,
              imageAvailable ? _autoRemove : null, active: !_manual),
            const SizedBox(width: 5),
            control(label('Custom Remove', 'دستی پس منظر ہٹائیں'), Icons.brush_outlined,
              imageAvailable ? () => setState(() { _manual = true; _erase = true; _notifyCanvas(); }) : null, active: _manual),
          ]),
          Expanded(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_busy) const Padding(padding: EdgeInsets.only(top: 4), child: LinearProgressIndicator(color: mint, minHeight: 2)),
          if (_busy) Text(AppLanguage.tr(_status), maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: mint, fontSize: 11)),
          const SizedBox(height: 5),
          Row(children: [
            for (final side in [true, false]) ...[
              Expanded(child: ChoiceChip(
                label: Center(child: Text(label(side ? 'Photo A' : 'Photo B', side ? 'تصویر A' : 'تصویر B'))),
                selected: _sideA == side,
                selectedColor: const Color(0xFF493715),
                onSelected: _busy ? null : (_) => widget.onSelectSide!(side),
              )),
              if (side) const SizedBox(width: 5),
            ],
            const SizedBox(width: 5),
            IconButton(tooltip: label('Upload Your Picture', 'تصویر منتخب کریں'),
              onPressed: _busy ? null : widget.onUpload,
              icon: const Icon(Icons.add_photo_alternate_outlined, color: gold)),
          ]),
          if (!imageAvailable && !_busy)
            Text(label('Choose or upload a photo', 'تصویر منتخب کریں'), textAlign: TextAlign.center,
              style: const TextStyle(color: mint, fontSize: 12)),
          if (imageAvailable && !_manual) ...[
            Row(children: [
              Expanded(child: Text(AppLanguage.tr(_status),
                style: const TextStyle(color: mint, fontSize: 12))),
              TextButton.icon(onPressed: _busy ? null : _reset, icon: const Icon(Icons.refresh, size: 16),
                label: Text(label('Reset', 'ری سیٹ'))),
            ]),
            if (_undo.isNotEmpty || _redo.isNotEmpty)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(tooltip: label('Undo', 'واپس'), onPressed: _busy || _undo.isEmpty ? null : _undoChange, icon: const Icon(Icons.undo)),
                IconButton(tooltip: label('Redo', 'دوبارہ'), onPressed: _busy || _redo.isEmpty ? null : _redoChange, icon: const Icon(Icons.redo)),
              ]),
          ],
          if (imageAvailable && _manual) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: SizedBox(height: (bounds.maxHeight - 100).clamp(95.0, 130.0).toDouble(), child: _preview(true))),
              const SizedBox(width: 6),
              Expanded(flex: 2, child: Column(children: [
                Row(children: [
                  control(label('Erase', 'مٹائیں'), Icons.auto_fix_off,
                    () => setState(() => _erase = true), active: _erase),
                  const SizedBox(width: 4),
                  control(label('Restore', 'بحال کریں'), Icons.brush_outlined,
                    () => setState(() => _erase = false), active: !_erase),
                ]),
                SizedBox(height: 30, child: Slider(value: _brushSize, min: 5, max: 90,
                  label: label('Brush size', 'برش کا سائز'), onChanged: _busy ? null : (v) => setState(() => _brushSize = v))),
                Wrap(children: [
                  IconButton(tooltip: label('Undo', 'واپس'), onPressed: _busy || _undo.isEmpty ? null : _undoChange, icon: const Icon(Icons.undo)),
                  IconButton(tooltip: label('Redo', 'دوبارہ'), onPressed: _busy || _redo.isEmpty ? null : _redoChange, icon: const Icon(Icons.redo)),
                  IconButton(tooltip: label('Reset', 'ری سیٹ'), onPressed: _busy ? null : _reset, icon: const Icon(Icons.refresh)),
                ]),
              ])),
            ]),
          ],
            ],
          ))),
        ]),
      )),
    );
  }

  Widget _inline(bool imageAvailable) {
    String label(String en, String ur) => AppLanguage.current == 'ur' ? ur : en;
    void brush(bool erase) => setState(() {
      _manual = true;
      _erase = erase;
      _notifyCanvas();
    });
    Widget tile(String title, IconData icon, VoidCallback? action,
        {bool selected = false}) => Expanded(
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: _busy ? null : action,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            minimumSize: const Size(0, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: selected ? const Color(0xFF42305F) : const Color(0xFF182A40),
            foregroundColor: selected ? gold : Colors.white,
            side: BorderSide(color: selected ? gold : const Color(0xFF435777)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17),
              const SizedBox(height: 2),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown,
                child: Text(title, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))),
            ],
          ),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF18243A), Color(0xFF101827)],
        ),
        border: Border.all(color: const Color(0xFF7862A4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(builder: (context, bounds) {
        final previewHeight = (bounds.maxHeight - 48).clamp(106.0, 145.0).toDouble();
        final headerHeight = bounds.maxHeight.clamp(0.0, 44.0).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    const Icon(Icons.auto_fix_high, color: gold, size: 17),
                    const SizedBox(width: 5),
                    Expanded(child: Text(
                      label('Remove Background — ${_sideA ? "A" : "B"} Side',
                        'پس منظر ہٹائیں — ${_sideA ? "A" : "B"} سائیڈ'),
                      textDirection: AppLanguage.direction,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.w700),
                    )),
                    IconButton(
                      key: const ValueKey('inline-remover-close'),
                      tooltip: label('Close', 'بند کریں'),
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      padding: EdgeInsets.zero,
                      onPressed: widget.onClose,
                      icon: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFF26334B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF7862A4)),
                        ),
                        child: const Icon(Icons.close_rounded, color: gold, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_busy && bounds.maxHeight > headerHeight + 2)
              const LinearProgressIndicator(color: mint, minHeight: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColoredBox(
                      color: const Color(0xFF0C1322),
                      child: SizedBox(height: previewHeight, child: _preview(imageAvailable)),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(flex: 2, child: Column(children: [
                  Row(children: [
                    tile(label('Auto Remove', 'خودکار صفائی'), Icons.auto_awesome,
                      imageAvailable ? _autoRemove : null, selected: !_manual),
                    const SizedBox(width: 5),
                    tile(label('Erase', 'مٹائیں'), Icons.auto_fix_off,
                      imageAvailable ? () => brush(true) : null, selected: _manual && _erase),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    tile(label('Restore', 'بحال کریں'), Icons.brush_outlined,
                      imageAvailable ? () => brush(false) : null, selected: _manual && !_erase),
                    const SizedBox(width: 5),
                    tile(label('Reset', 'ری سیٹ'), Icons.refresh, imageAvailable ? _reset : null),
                  ]),
                  if (_manual)
                    SizedBox(height: 32, child: Slider(
                      label: label('Brush size', 'برش کا سائز'),
                      value: _brushSize, min: 5, max: 90,
                      onChanged: _busy ? null : (value) => setState(() => _brushSize = value),
                    )),
                  if (imageAvailable && (_manual || _undo.isNotEmpty || _redo.isNotEmpty))
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(tooltip: label('Undo', 'واپس'), icon: const Icon(Icons.undo, size: 17),
                        onPressed: _busy || _undo.isEmpty ? null : _undoChange,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40), padding: EdgeInsets.zero),
                      IconButton(tooltip: label('Redo', 'دوبارہ'), icon: const Icon(Icons.redo, size: 17),
                        onPressed: _busy || _redo.isEmpty ? null : _redoChange,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40), padding: EdgeInsets.zero),
                      IconButton(tooltip: label('Compare', 'موازنہ'), icon: Icon(_compare ? Icons.visibility : Icons.compare, size: 17),
                        onPressed: _busy ? null : () => setState(() => _compare = !_compare),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40), padding: EdgeInsets.zero),
                    ]),
                ])),
              ]),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageAvailable = _previewPng != null && _sourcePng != null;
    if (widget.onSelectSide != null) return _mainDock(imageAvailable);
    if (widget.onClose != null) return _inline(imageAvailable);
    return PopScope(
      canPop: _allowExit || (!_busy && !_hasUnsavedEdits),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !mounted || _busy) return;
        if (await _confirmDiscardEdits() && mounted) {
          setState(() => _allowExit = true);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voting Pro', style: TextStyle(
              fontWeight: FontWeight.w800, color: gold,
            )),
            Text('BG REMOVER', style: TextStyle(
              color: Colors.white70, fontSize: 11, letterSpacing: 3,
            )),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: Text('Offline • Free',
              style: TextStyle(color: mint, fontSize: 12))),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(color: mint),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111C2E),
                        border: Border.all(color: gold, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(children: [
                            Icon(Icons.auto_fix_high, color: gold),
                            SizedBox(width: 8),
                            Expanded(child: Text('Picture Background Remover',
                              style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.bold, color: gold))),
                          ]),
                          const SizedBox(height: 10),
                          const Text('Choose the target photo slot',
                            style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('Photo A')),
                              ButtonSegment(value: false, label: Text('Photo B')),
                            ],
                            selected: {_sideA},
                            onSelectionChanged: _busy
                                ? null
                                : (selected) => _changeSide(selected.first),
                          ),
                          const SizedBox(height: 12),
                          _action('Upload Your Picture',
                            Icons.add_photo_alternate_outlined,
                            _uploadPicture, primary: true),
                          const SizedBox(height: 12),
                          Text(AppLanguage.tr(_status),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: mint, fontSize: 12)),
                          const SizedBox(height: 10),
                          Container(
                            height: 340,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFF222A35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: mint.withOpacity(0.55)),
                            ),
                            child: _preview(imageAvailable),
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: _action(
                              'Auto Remove', Icons.auto_awesome,
                              _autoRemove,
                              primary: imageAvailable && !_manual,
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _action(
                              'Manual', Icons.brush,
                              imageAvailable
                                  ? () => setState(() => _manual = true)
                                  : null,
                              primary: imageAvailable && _manual,
                            )),
                          ]),
                          if (_manual && imageAvailable) ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              const Text('Brush Size',
                                style: TextStyle(color: Colors.white70)),
                              Expanded(
                                child: Slider(
                                  value: _brushSize,
                                  min: 5, max: 90,
                                  activeColor: mint,
                                  onChanged: _busy ? null
                                      : (v) => setState(() => _brushSize = v),
                                ),
                              ),
                              Text('${_brushSize.round()} px',
                                style: const TextStyle(color: mint)),
                            ]),
                            Row(children: [
                              Expanded(child: _action(
                                'Erase', Icons.auto_fix_off,
                                () => setState(() => _erase = true),
                                primary: _erase,
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _action(
                                'Restore', Icons.brush_outlined,
                                () => setState(() => _erase = false),
                                primary: !_erase,
                              )),
                            ]),
                            const SizedBox(height: 7),
                            const Text(
                              'Draw directly on the image to erase or restore.',
                              style: TextStyle(
                                color: Colors.white60, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _action('Undo', Icons.undo,
                              _undo.isEmpty ? null : _undoChange)),
                            const SizedBox(width: 7),
                            Expanded(child: _action('Redo', Icons.redo,
                              _redo.isEmpty ? null : _redoChange)),
                            const SizedBox(width: 7),
                            Expanded(child: _action('Reset', Icons.refresh,
                              imageAvailable ? _reset : null)),
                          ]),
                          const SizedBox(height: 12),
                          _action('Apply Cutout to Photo ${_sideA ? "A" : "B"}',
                            Icons.check_circle_outline,
                            imageAvailable ? _applyCutout : null,
                            primary: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AI removes person backgrounds. Manual tools also work '
                      'on objects. Processing stays on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Testable isolated cursor. A Positioned must be an effective direct
/// child of Stack; returning Positioned *inside* ValueListenableBuilder causes
/// a ParentDataWidget runtime exception during manual erase gestures.
class BackgroundBrushCursor extends StatelessWidget {
  const BackgroundBrushCursor({
    super.key,
    required this.cursor,
    required this.enabled,
    required this.size,
  });

  final ValueListenable<Offset?> cursor;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ValueListenableBuilder<Offset?>(
        valueListenable: cursor,
        builder: (context, position, child) {
          if (!enabled || position == null) {
            return const SizedBox.shrink();
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: position.dx - size / 2,
                top: position.dy - size / 2,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD84D), width: 2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tile = 14.0;
    final light = Paint()..color = const Color(0xFF555963);
    final dark = Paint()..color = const Color(0xFF313640);
    for (var y = 0; y * tile < size.height; y++) {
      for (var x = 0; x * tile < size.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * tile, y * tile, tile, tile),
          (x + y).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
