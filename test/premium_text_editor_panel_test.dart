import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/widgets/premium_text_editor_panel.dart';

void main() {
  Widget makeEditor({
    String? text = 'علی اور ولی',
    TextToolSection section = TextToolSection.glow,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: PremiumTextEditorPanel(
            selectedText: text,
            section: section,
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

  testWidgets('Glow controls fit a narrow screen without nested tab bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(makeEditor());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Glow'), findsOneWidget);
    expect(find.text('Glow intensity'), findsOneWidget);
    expect(find.text('Effects'), findsNothing);
    expect(find.text('Text Editor'), findsNothing);
  });

  testWidgets('Background and outline controls are independent sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      makeEditor(section: TextToolSection.background),
    );
    await tester.pumpAndSettle();
    expect(find.text('Text Background'), findsOneWidget);
    expect(find.text('Background opacity'), findsOneWidget);
    expect(find.text('Glow'), findsNothing);

    await tester.pumpWidget(
      makeEditor(section: TextToolSection.outline),
    );
    await tester.pumpAndSettle();
    expect(find.text('Outline (Stroke)'), findsOneWidget);
    expect(find.text('Stroke width'), findsOneWidget);
    expect(find.text('Text Background'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Style Layout and More still expose the legacy actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(makeEditor(
      text: 'Voting Pro',
      section: TextToolSection.layout,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Curve Up'), findsOneWidget);

    await tester.pumpWidget(makeEditor(section: TextToolSection.style));
    await tester.pumpAndSettle();
    expect(find.text('Font'), findsOneWidget);

    await tester.pumpWidget(makeEditor(section: TextToolSection.more));
    await tester.pumpAndSettle();
    expect(find.text('Delete Text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No compact controls panel before a text tool is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      makeEditor(section: TextToolSection.none),
    );
    expect(find.text('Glow'), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
