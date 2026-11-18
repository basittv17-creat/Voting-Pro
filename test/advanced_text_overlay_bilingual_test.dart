import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/widgets/advanced_text_overlay.dart';

void main() {
  Future<void> checkCurve(WidgetTester tester, String value,
      TextDirection direction) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AdvancedTextOverlay(
            text: value,
            style: const TextStyle(fontSize: 28, color: Colors.white),
            alignment: TextAlign.center,
            direction: direction,
            curve: 0.6,
            gradient: true,
            outlineWidth: 1.5,
            outlineColor: Colors.black,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.descendant(
      of: find.byType(AdvancedTextOverlay),
      matching: find.byType(CustomPaint),
    ), findsWidgets);
  }

  testWidgets('English curved text renders with gradient and outline',
      (tester) async {
    await checkCurve(tester, 'Voting Pro', TextDirection.ltr);
  });

  testWidgets('Urdu curved text keeps words shaped and renders effects',
      (tester) async {
    await checkCurve(tester, 'ووٹنگ پرو مقابلہ', TextDirection.rtl);
  });

  testWidgets('Multiline Urdu uses normal shaped text renderer',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AdvancedTextOverlay(
          text: 'ووٹنگ پرو\nمقابلہ',
          style: TextStyle(fontSize: 26),
          alignment: TextAlign.center,
          direction: TextDirection.rtl,
          curve: 0.6,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('ووٹنگ پرو\nمقابلہ'), findsOneWidget);
  });
}
