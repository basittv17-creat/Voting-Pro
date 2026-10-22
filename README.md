# Voting Pro — Flutter Project

پروجیکٹ کا نام: **Voting Pro**
Flutter/Dart package identifier: `voting_pro`  
Android application ID namespace: `com.votingpro` (project scaffold generated with this organization)

## موجودہ فائلیں
- `lib/main.dart` — Flutter/Dart source
- `pubspec.yaml` — package metadata اور dependencies
- `.github/workflows/flutter-build.yml` — GitHub Actions سے Android APK اور Flutter Web build کرنے کی کوشش
- `android/` اور `web/` — Flutter CLI کے ذریعے CI میں platform scaffolding generate ہوگا

## GitHub پر
Repository کا نام `voting-pro` رکھیں (یا اپنا پسندیدہ repository نام)۔
ZIP extract کرکے اس کے اندر کی تمام فائلیں اپ لوڈ کریں، خاص طور پر hidden `.github` فولڈر۔

## Build
Flutter SDK environment میں:
```bash
flutter pub get
flutter build apk --release
flutter build web --release
```

## نوٹ
- `voting_pro` Dart package/project identifier ہے؛ package names میں space استعمال نہیں ہوتی۔ Android namespace/org `com.votingpro` ہے، جبکہ موبائل پر نظر آنے والا نام `Voting Pro` رکھا جائے گا۔
- اس سورس کو اس ماحول میں Flutter SDK سے compile نہیں کیا گیا۔ GitHub Actions کا پہلا run compile check ہوگا۔
- یہ ابھی ابتدائی پروٹوٹائپ ہے، مکمل production-ready ایپ نہیں۔
