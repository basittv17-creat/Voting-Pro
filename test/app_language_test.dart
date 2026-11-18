import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/app_language.dart';

void main() {
  tearDown(() => AppLanguage.current = 'en');

  test('defaults to English with left-to-right UI', () {
    AppLanguage.current = 'en';
    expect(AppLanguage.tr('Save Poster'), 'Save Poster');
    expect(AppLanguage.tr('متن شامل کریں'), 'Add Text');
    expect(AppLanguage.direction.name, 'ltr');
  });

  test('Urdu interface translates core actions and sets RTL', () {
    AppLanguage.current = 'ur';
    expect(AppLanguage.tr('Save Poster ↓'), 'پوسٹر محفوظ کریں ↓');
    expect(AppLanguage.tr('Share App'), 'ایپ شیئر کریں');
    expect(AppLanguage.tr('Add Photo B'), 'تصویر B شامل کریں');
    expect(AppLanguage.direction.name, 'rtl');
  });

  test('user text and unknown asset labels are not altered', () {
    AppLanguage.current = 'ur';
    expect(AppLanguage.tr('My Custom Poster Name'), 'My Custom Poster Name');
    expect(AppLanguage.tr('A Style 01'), 'اے اسٹائل 01');
    expect(AppLanguage.tr('B Style 02'), 'بی اسٹائل 02');
  });
}
