import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/widgets/premium_vs.dart';

void main() {
  testWidgets('All ten VS designs retain their original artwork', (
    tester,
  ) async {
    const gallery = ValueKey('vs-artwork-gallery');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: gallery,
            child: ColoredBox(
              color: const Color(0xff091323),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var row = 0; row < 5; row++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var column = 0; column < 2; column++)
                          PremiumVsRenderer(
                            width: 128,
                            style: VsStyleDefinition.styles[row * 2 + column],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(gallery),
      matchesGoldenFile('goldens/premium_vs_artwork.png'),
    );
  });
}
