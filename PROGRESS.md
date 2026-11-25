# Sprint 1 progress (complete 2026-11-21)

Status per ticket lives in ../task.html (b1 to b7 done).
Check: `dart format --set-exit-if-changed lib test && flutter analyze && flutter test` passes.

## b1, Android build: done
Installed Android SDK Platform 36 and NDK 28.2.13676358 with the SDK CLI, one package per call:

    C:/Users/ihebl/AppData/Local/Android/Sdk/cmdline-tools/latest/bin/android.exe sdk install <package>

Gradle installed Platform 35 and CMake 3.22.1 itself during the first build.
`flutter build apk --debug` builds build/app/outputs/flutter-apk/app-debug.apk (about 8.5 minutes the first time).

Not verified: CI has never run (no git remote), APK not installed on a device yet.
Sprint 1 is finished; sprint 2 has not been started.

## Extra (2026-11-24): German and English
Asked for outside the sprint plan. App follows the device language (German if it is neither German nor English); the user can override it on the sign-in screen and under More. Choice kept in shared preferences (`bamsenet.language`), not cleared on sign-out. Code: lib/core/l10n/language.dart, language_picker.dart, lib/l10n/app_en.arb. Tests: test/app/language_test.dart.
First install on the real phone (Xiaomi 25098RA98G, Android 15) succeeded.
