import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/widgets/premium_text_editor_panel.dart';

void main() {
  Widget makeEditor({String? text = 'علی اور ولی'}) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: PremiumTextEditorPanel(
            selectedText: text,
            onClose: () {},
            onAddText: () {},
            onEditText: () {},
            onDeleteText: () {},
            styleActions: [
              TextPanelAction('Font', Icons.font_download_outlined, () {}),
              TextPanelAction('Zoom +', Icons.zoom_in, () {}),
            ],
            layoutActions: [
              TextPanelAction('Curve Up', Icons.arrow_upward, () {}),
              TextPanelAction('Curve Down', Icons.arrow_downward, () {}),
            ],
            moreActions: [
              TextPanelAction('Undo Text', Icons.undo, () {}),
            ],
            textColor: Colors.white,
            onTextColor: (_) {},
            onMoreColors: () {},
            textOpacity: 0.85,
            onOpacityStart: () {},
            onTextOpacity: (_) {},
            glowEnabled: true,
            onGlowToggle: () {},
            glowStrength: 70,
            onGlowStart: () {},
            onGlowStrength: (_) {},
            glowColor: Colors.cyan,
            onGlowColor: (_) {},
            gradientEnabled: true,
            onGradientToggle: () {},
            outlineWidth: 1.5,
            onOutlineToggle: () {},
            onOutlineIncrease: () {},
            onOutlineDecrease: () {},
            onOutlineColor: () {},
            backgroundEnabled: true,
            onBackgroundToggle: () {},
            backgroundColor: Colors.red,
            onBackgroundColor: (_) {},
            backgroundOpacity: 0.85,
            onBackgroundOpacityStart: () {},
            onBackgroundOpacity: (_) {},
            onBackgroundSettings: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('Text panel fits narrow portrait screen with Urdu selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(makeEditor());
    await tester.pumpAndSettle();
    final layoutError = tester.takeException();
    if (layoutError is FlutterError) {
      // Diagnose the exact constraint chain in CI on narrow devices.
      debugPrint(layoutError.toStringDeep());
    }
    expect(layoutError, isNull);
    expect(find.text('Text Editor'), findsOneWidget);
    expect(find.text('Selected: علی اور ولی'), findsOneWidget);
    expect(find.text('Effects'), findsOneWidget);
  });

  testWidgets('All tab categories remain accessible on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(makeEditor(text: 'Voting Pro'));
    await tester.tap(find.text('Layout'));
    await tester.pumpAndSettle();
    expect(find.text('Curve Up'), findsOneWidget);
    await tester.tap(find.text('Style'));
    await tester.pumpAndSettle();
    expect(find.text('Font'), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Text'), findsOneWidget);
    final layoutError = tester.takeException();
    if (layoutError is FlutterError) {
      // Diagnose the exact constraint chain in CI on narrow devices.
      debugPrint(layoutError.toStringDeep());
    }
    expect(layoutError, isNull);
  });
}
