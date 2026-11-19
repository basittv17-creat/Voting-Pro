import 'dart:io';

/// Keep the temporary share directory from growing after repeated poster
/// exports. Only delete our own old PNGs; never touch other cached files.
class PosterShareCache {
  PosterShareCache._();

  static final RegExp _posterFile = RegExp(
    r'^voting_pro_poster_[0-9]+\.png$',
  );

  static Future<int> removeExpired(
    Directory directory, {
    DateTime? now,
    Duration maxAge = const Duration(hours: 24),
  }) async {
    if (!await directory.exists()) return 0;
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    var removed = 0;
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      if (!_posterFile.hasMatch(name)) continue;
      try {
        final modified = await entry.lastModified();
        if (modified.isBefore(cutoff)) {
          await entry.delete();
          removed++;
        }
      } on FileSystemException {
        // Cache cleanup must never prevent exporting a new poster.
      }
    }
    return removed;
  }
}
