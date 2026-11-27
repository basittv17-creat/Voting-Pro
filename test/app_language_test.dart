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

  test('remover actions and recoverable errors are bilingual', () {
    AppLanguage.current = 'ur';
    expect(AppLanguage.tr('Auto Remove'), 'خودکار صفائی');
    expect(AppLanguage.tr('Restore'), 'بحال کریں');
    expect(
      AppLanguage.tr('Offline auto removal unavailable'),
      isNot('Offline auto removal unavailable'),
    );
    AppLanguage.current = 'en';
    expect(AppLanguage.tr('Auto Remove'), 'Auto Remove');
  });

  test('Hindi selection and invalid locale fallback', () {
    expect(AppLanguage.normalize(null), 'en');
    expect(AppLanguage.normalize('invalid'), 'en');
    AppLanguage.current = 'hi';
    expect(AppLanguage.tr('Save Poster'), 'पोस्टर सहेजें');
    expect(AppLanguage.tr('Auto Remove'), 'अपने आप हटाएँ');
    expect(AppLanguage.tr('متن شامل کریں'), 'टेक्स्ट जोड़ें');
    expect(AppLanguage.tr('Neon arena'), 'नीऑन अखाड़ा');
    expect(AppLanguage.direction.name, 'ltr');
    expect(AppLanguage.tr('My Custom Poster Name'), 'My Custom Poster Name');
  });

  test('user text and unknown asset labels are not altered', () {
    AppLanguage.current = 'ur';
    expect(AppLanguage.tr('My Custom Poster Name'), 'My Custom Poster Name');
    expect(AppLanguage.tr('A Style 01'), 'اے اسٹائل 01');
    expect(AppLanguage.tr('B Style 02'), 'بی اسٹائل 02');
  });
}
