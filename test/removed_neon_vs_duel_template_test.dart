import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Only Neon VS Duel is excluded from ready-made templates', () {
    final editor = File('lib/main.dart').readAsStringSync();

    expect(editor, isNot(contains("key: 'neon_vs_duel'")));
    expect(editor, isNot(contains('Neon_VS_Duel_Template.png')));
    expect(editor, contains("key: 'royal_a_vs_b_battle'"));
    expect(editor, contains("key: 'tagra_muqabla'"));
    expect(editor, contains("key: 'neon_purple_showdown'"));
    expect(editor, contains("key: 'metallic_vs_battle'"));

    expect(
      File('assets/templates/Neon_VS_Duel_Template.png').existsSync(),
      isFalse,
    );
    expect(
      File('lib/widgets/neon_vs_duel_template.dart').existsSync(),
      isFalse,
    );
    expect(
      File('assets/templates/Neon_Purple_VS_Template.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/templates/Metallic_VS_Battle_Template.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/templates/Tagra_Muqabla_Template.png').existsSync(),
      isTrue,
    );
  });

  test('Unknown saved template selection falls back to classic canvas', () {
    final editor = File('lib/main.dart').readAsStringSync();

    expect(editor, contains('!_readyTemplateOptions.any('));
    expect(editor, contains('selectedReadyMadeTemplate = null;'));
    expect(editor, contains('canvasRatio = 4 / 3;'));
  });
}
