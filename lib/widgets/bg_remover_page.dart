import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/offline_bg_remover.dart';

/// Full-screen editor following the three approved Voting Pro mockups.
/// The AI model, manual brush and PNG export run on the device without an API.
class BackgroundRemoverPage extends StatefulWidget {
  const BackgroundRemoverPage({
    super.key,
    required this.initialPhotoA,
    required this.initialPhotoB,
    required this.onApply,
    this.initialSideA = true,
  });

  final File? initialPhotoA;
  final File? initialPhotoB;
  final bool initialSideA;
  final Future<void> Function(bool sideA, File result) onApply;

  @override
  State<BackgroundRemoverPage> createState() => _BackgroundRemoverPageState();
}

class _BackgroundRemoverPageState extends State<BackgroundRemoverPage> {
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
        if (mounted) _loadFile(initial);
      });
    }
  }

  @override
  void dispose() {
    _brushCursor.dispose();
    super.dispose();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _loadFile(File file) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Preparing image locally…';
    });
    try {
      final prepared = await OfflineBgRemover.prepare(await file.readAsBytes());
      final decoded = img.decodeImage(prepared);
      if (decoded == null) throw const FormatException('Unsupported image');
      if (!mounted) return;
      setState(() {
        _sourcePng = prepared;
        _previewPng = prepared;
        _imageWidth = decoded.width;
        _imageHeight = decoded.height;
        _mask = Uint8List.fromList(
          List<int>.filled(decoded.width * decoded.height, 255),
        );
        _manual = false;
        _compare = false;
        _undo.clear();
        _redo.clear();
        _hasUnsavedEdits = false;
        _status = 'Image ready • Auto or Manual editing';
      });
    } catch (error) {
      _notice('Image could not be loaded: $error');
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
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      await _loadFile(File(picked.path));
    } catch (error) {
      _notice('Could not open gallery: $error');
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
    if (_undo.length > 8) _undo.removeAt(0);
    _redo.clear();
  }

  Future<void> _updatePreview() async {
    if (_sourcePng == null || _mask == null) return;
    final bytes = await OfflineBgRemover.compose(
      _sourcePng!, Uint8List.fromList(_mask!),
    );
    if (!mounted) return;
    final hasUnsavedEdits = _mask!.any((pixel) => pixel != 255);
    setState(() {
      _previewPng = bytes;
      _brushCursor.value = null;
      _hasUnsavedEdits = hasUnsavedEdits;
      // Always show the updated result after editing, not stale Compare view.
      _compare = false;
    });
  }

  Future<void> _autoRemove() async {
    if (_busy || _sourcePng == null || _mask == null) {
      if (_sourcePng == null) _notice('Upload Your Picture first');
      return;
    }
    final originalMask = Uint8List.fromList(_mask!);
    final wasManual = _manual;
    final previousStatus = _status;
    setState(() {
      _busy = true;
      _manual = false;
      _status = 'Removing background offline…';
    });
    try {
      final result = await OfflineBgRemover.autoMask(
        _sourcePng!, _imageWidth, _imageHeight,
      );
      if (!mounted) return;
      _mask = result;
      await _updatePreview();
      // Commit Undo only after inference AND preview composition succeed.
      // A failed Auto attempt must never erase the user's existing Redo stack.
      _undo.add(originalMask);
      if (_undo.length > 8) _undo.removeAt(0);
      _redo.clear();
      setState(() => _status = 'Auto cutout ready • Use Manual to refine edges');
    } catch (error) {
      _mask = originalMask;
      _hasUnsavedEdits = originalMask.any((pixel) => pixel != 255);
      if (mounted) {
        setState(() {
          _manual = wasManual;
          _status = previousStatus;
        });
      }
      _notice('Offline auto removal unavailable: $error');
      if (_sourcePng != null && mounted) {
        try {
          await _updatePreview();
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
    if (_busy || _mask == null || _sourcePng == null) return;
    setState(() => _busy = true);
    try {
      edit();
      await _updatePreview();
    } catch (error) {
      _notice('Could not update cutout preview: $error');
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
    });
  }

  Future<void> _redoChange() async {
    if (_redo.isEmpty) return;
    await _runMaskEdit(() {
      _undo.add(Uint8List.fromList(_mask!));
      _mask = _redo.removeLast();
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

  void _paintAt(Offset local) {
    if (!_manual || _busy || _mask == null || _sourcePng == null) return;
    final point = _toImagePoint(local);
    if (point == null) {
      _lastPoint = null;
      return;
    }
    final rect = _previewRect!;
    final radius = _brushSize * _imageWidth / rect.width / 2;
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
    _brushCursor.value = local;
  }

  void _beginStroke(Offset local) {
    if (_busy || !_manual || _mask == null ||
        _toImagePoint(local) == null) return;
    _recordUndo();
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
    if (!_manual || _busy || _mask == null) return;
    setState(() => _busy = true);
    try {
      await _updatePreview();
    } catch (error) {
      _notice('Brush preview failed: $error');
    } finally {
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
      await widget.onApply(_sideA, file);
      if (mounted) {
        setState(() => _allowExit = true);
        Navigator.of(context).pop();
      }
    } catch (error) {
      _notice('Could not apply cutout: $error');
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
        label: Text(label, maxLines: 2, textAlign: TextAlign.center),
      );

  @override
  Widget build(BuildContext context) {
    final imageAvailable = _previewPng != null && _sourcePng != null;
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
                          Text(_status,
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
                            child: imageAvailable
                                ? LayoutBuilder(builder: (ctx, constraints) {
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
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: _manual
                                          ? (d) => _beginStroke(d.localPosition)
                                          : null,
                                      onPanUpdate: _manual
                                          ? (d) => _paintAt(d.localPosition)
                                          : null,
                                      onPanEnd: _manual
                                          ? (_) => _endStroke()
                                          : null,
                                      onPanCancel: _manual
                                          ? () => _endStroke()
                                          : null,
                                      onTapUp: _manual
                                          ? (d) => _tapBrush(d.localPosition)
                                          : null,
                                      child: Stack(children: [
                                        Positioned(
                                          left: left, top: top,
                                          width: w, height: h,
                                          child: CustomPaint(
                                            painter: _CheckerboardPainter(),
                                            child: Image.memory(
                                              _compare ? _sourcePng! : _previewPng!,
                                              gaplessPlayback: true,
                                              fit: BoxFit.fill,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: ValueListenableBuilder<Offset?>(
                                              valueListenable: _brushCursor,
                                              builder: (context, cursor, child) {
                                                if (!_manual || cursor == null) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Positioned(
                                                      left: cursor.dx - _brushSize / 2,
                                                      top: cursor.dy - _brushSize / 2,
                                                      child: Container(
                                                        width: _brushSize,
                                                        height: _brushSize,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: gold, width: 2,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 6, top: 6,
                                          child: _action(
                                            _compare ? 'After' : 'Compare',
                                            Icons.compare,
                                            () => setState(
                                              () => _compare = !_compare,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    );
                                  })
                                : const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.image_outlined,
                                          color: mint, size: 62),
                                        SizedBox(height: 10),
                                        Text('Upload Your Picture',
                                          style: TextStyle(
                                            color: Colors.white70)),
                                        Text('Preview appears here',
                                          style: TextStyle(
                                            color: Colors.white38)),
                                      ],
                                    ),
                                  ),
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
