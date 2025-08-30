
SoloMission - Ready-to-build Flutter project (prototype)
=======================================================

What is included
- Minimal Flutter project skeleton with prototype logic in lib/main.dart
- pubspec.yaml listing required packages
- README with build and Play Store steps

Important notes BEFORE building
1) This project is a prototype demonstrating the app flow and core logic.
   For the daily alarm/notification at 05:00 that reliably wakes Android devices,
   you must follow the extra steps in the README below (timezone setup and android_alarm_manager_plus).

2) Test on a real Android device. Emulators may not show exact alarm behavior.

Setup & build (local machine)
-----------------------------
1. Install Flutter SDK and set up Android toolchain: https://flutter.dev/docs/get-started/install
2. Clone or extract this project folder.
3. From project root, get packages:
   flutter pub get

4. (Recommended) Add timezone support for accurate scheduled notifications:
   - Add dependency: timezone: ^0.9.0
   - Initialize tz in main() (see flutter_local_notifications docs)

5. If you want alarms that fire in background (wake device), consider adding:
   android_alarm_manager_plus: ^2.0.0
   and follow its setup instructions (AndroidManifest and initialization).

6. Build APK:
   flutter build apk --release

7. The generated APK will be in build/app/outputs/flutter-apk/app-release.apk

AndroidManifest notes (add inside <application>):
------------------------------------------------
<!-- Add permission to receive BOOT_COMPLETED if you schedule repeating alarms -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- For Android 12+ if using exact alarms: request SCHEDULE_EXACT_ALARM -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />

Play Store & release checklist
------------------------------
- Test thoroughly on multiple Android versions (API 21+ recommended)
- Prepare app icon and feature graphics
- Add privacy policy if you collect user data (we store only nickname and tasks locally)
- Sign your app with a release keystore (docs: https://developer.android.com/studio/publish/app-signing)
- Provide screenshots, description, content rating, and target countries
- Upload APK / AAB to Google Play Console and follow publishing steps

Need help adding:
- timezone setup with flutter_local_notifications (zonedSchedule)
- android_alarm_manager_plus integration
- Keystore signing steps
Tell me which of these you want me to add and I will produce the exact code snippets and config changes.
