import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/services/poster_share_cache.dart';

void main() {
  test('Share cache removes only old Voting Pro PNG files', () async {
    final dir = await Directory.systemTemp.createTemp('poster_share_cache_');
    addTearDown(() => dir.delete(recursive: true));

    final oldPoster = File('${dir.path}/voting_pro_poster_123.png');
    final freshPoster = File('${dir.path}/voting_pro_poster_456.png');
    final unrelated = File('${dir.path}/another_app.png');
    final misleading = File('${dir.path}/voting_pro_poster_bad.png');
    for (final file in [oldPoster, freshPoster, unrelated, misleading]) {
      await file.writeAsString('test');
    }
    final now = DateTime(2026, 11, 19, 12);
    for (final file in [oldPoster, unrelated, misleading]) {
      await file.setLastModified(now.subtract(const Duration(days: 3)));
    }
    await freshPoster.setLastModified(now);

    expect(await PosterShareCache.removeExpired(dir, now: now), 1);
    expect(await oldPoster.exists(), isFalse);
    expect(await freshPoster.exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
    expect(await misleading.exists(), isTrue);
  });

  test('Missing temporary directory is safe', () async {
    final dir = await Directory.systemTemp.createTemp('poster_share_missing_');
    await dir.delete(recursive: true);
    expect(await PosterShareCache.removeExpired(dir), 0);
  });
}
