# Voting Pro Android APKs: which one to install

Use the **signed release APK** from the **Build Flutter APK and Web** GitHub Actions run on `main`. Download the artifact named `voting-pro-apk`, unzip it, and install `app-release.apk`. This is the normal release application with the Voting Pro launcher icon.

The **Android UI Smoke** workflow runs Flutter integration tests. **Never install the intermediate APK produced by `flutter drive`**: it contains a test-runner entrypoint and may close immediately after its tests finish. The CI workflow now rebuilds from `lib/main.dart`, generates the proper launcher icon, installs that normal debug app on an emulator, checks it remains running after splash, and only then uploads `voting-pro-normal-app-debug-apk` for optional development use.

Prefer the signed release APK. A debug APK may have a different signing certificate and cannot always be installed as an update over a release APK. **Back up saved poster projects before changing installations**; uninstalling can erase local app data.

The app ID is `com.awasigogera.votingpro`. The app display name should be **Voting Pro**. Check the `text-09-normal-app-launch.png` Android screenshot in the UI workflow artifacts.

If even the signed release APK opens then closes on your device, collect a device `adb logcat` crash trace; the CI emulator smoke check alone cannot rule out device-specific problems.
