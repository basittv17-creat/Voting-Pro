import 'dart:io';
import 'dart:typed_data';

/// A sidecar belongs to one immutable cutout. Publishing a new project image
/// therefore publishes its history as well, without changing any old snapshot.
class MaskHistory {
  static const maxBytes = 8 * 1024 * 1024;
  static int limit(int pixels) => (maxBytes ~/ pixels).clamp(1, 8);

  static File sidecar(File image) => File('${image.path}.history');

  static Future<void> save(
    File image,
    int width,
    int height,
    List<Uint8List> undo,
    List<Uint8List> redo,
  ) async {
    final header = ByteData(12)
      ..setUint16(0, 1)
      ..setUint32(2, width)
      ..setUint32(6, height)
      ..setUint8(10, undo.length)
      ..setUint8(11, redo.length);
    final handle = await sidecar(image).open(mode: FileMode.write);
    try {
      await handle.writeFrom(header.buffer.asUint8List());
      for (final mask in [...undo, ...redo]) {
        await handle.writeFrom(mask);
      }
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  static Future<(List<Uint8List>, List<Uint8List>)> read(
    File image,
    int width,
    int height,
  ) async {
    final empty = (<Uint8List>[], <Uint8List>[]);
    final file = sidecar(image);
    if (!await file.exists()) return empty;
    try {
      final handle = await file.open();
      try {
        final bytes = await handle.read(12);
        if (bytes.length != 12) return empty;
        final header = ByteData.sublistView(bytes);
        final count = header.getUint8(10) + header.getUint8(11);
        final pixels = width * height;
        if (header.getUint16(0) != 1 ||
            header.getUint32(2) != width ||
            header.getUint32(6) != height ||
            count > limit(pixels) ||
            await handle.length() != 12 + count * pixels)
          return empty;
        final masks = <Uint8List>[];
        for (var i = 0; i < count; i++) {
          final mask = await handle.read(pixels);
          if (mask.length != pixels) return empty;
          masks.add(mask);
        }
        return (
          masks.sublist(0, header.getUint8(10)),
          masks.sublist(header.getUint8(10)),
        );
      } finally {
        await handle.close();
      }
    } on FileSystemException {
      return empty;
    }
  }
}
