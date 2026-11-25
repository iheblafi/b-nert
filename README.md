# Zeiterfassung Bamsenet: mobile app

Flutter app for Android and iOS. Plan and spec live one folder up (`../PLAN.md`, `../docs/spec/`).

## Run

```
cp config/example.json config/stage.json   # fill in URL and anon key, never commit
flutter run --dart-define-from-file=config/stage.json
```

## Check

```
dart format lib test
flutter analyze
flutter test
```

CI: `.github/workflows/ci.yml` (format, analyze, test, Android debug build) and `codemagic.yaml` (unsigned iOS build).

## Structure

- `lib/app/`: app widget, router, shell
- `lib/core/`: config, backend client, session, errors, design system, localisation
- `lib/features/<feature>/`: model, repository, state, screen. Screens never call the backend directly.
