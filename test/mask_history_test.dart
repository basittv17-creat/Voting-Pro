import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/services/mask_history.dart';

void main() {
  test(
    'Cutout histories are independent, bounded and safe after truncation',
    () async {
      final directory = await Directory.systemTemp.createTemp();
      addTearDown(() => directory.delete(recursive: true));
      final a = File('${directory.path}/a.png'),
          b = File('${directory.path}/b.png');
      final mask = Uint8List.fromList([0, 64, 128, 255]);
      await MaskHistory.save(a, 2, 2, [mask], []);
      await MaskHistory.save(b, 2, 2, [], [mask]);
      expect((await MaskHistory.read(a, 2, 2)).$1.single, mask);
      expect((await MaskHistory.read(b, 2, 2)).$2.single, mask);
      expect((await MaskHistory.read(a, 1, 4)).$1, isEmpty);
      await MaskHistory.sidecar(b).writeAsBytes([1, 2]);
      expect((await MaskHistory.read(b, 2, 2)).$2, isEmpty);
      expect(
        MaskHistory.limit(1600 * 1600) * 1600 * 1600,
        lessThanOrEqualTo(MaskHistory.maxBytes),
      );
    },
  );
}
