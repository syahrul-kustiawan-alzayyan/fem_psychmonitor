# AGENTS.md - Fem-Psych Monitor

## Project Overview
- **Flutter** (v3.11+, Dart 3.11.1) monoplatform app
- **Provider** for state management (not Riverpod/BLoC)
- **SQLite** (sqflite) + SharedPreferences for persistence

## Developer Commands

```bash
# Install deps
flutter pub get

# Run app (ensure assets exist first)
flutter run

# Analyze/lint
flutter analyze

# Generate launcher icons (after modifying pubspec.yaml assets)
flutter pub run flutter_launcher_icons
```

## Required Assets
Must exist in `assets/` before running:
- `model_female.tflite` - TensorFlow Lite emotion model
- `logo.png` - App icon
- `MBTI.json`, `psych.json`, `saran.json` - Assessment data

## Architecture

### Entry Flow
`main.dart` → `AppRouter` checks `StorageService.isFirstLaunch()`:
1. First launch → `OnboardingScreen` → `AuthScreen`
2. Returning user → `AuthScreen` (if not logged in) → `MainNavigation`
3. Logged-in user with DB record → `MainNavigation` (bottom nav)

### Main Screens
| Screen | File | Purpose |
|--------|------|---------|
| Auth | `auth_screen.dart` | Login/register |
| Onboarding | `onboarding_screen.dart` | MBTI + mental health assessment |
| Home | `home_screen.dart` | Dashboard with emotion stats |
| Live Detection | `live_detection_screen.dart` | Voice emotion recording |
| History | `history_screen.dart` | Past emotion records chart |
| Profile | `profile_screen.dart` | User MBTI results |
| Settings | `settings_screen.dart` | Language/theme toggle |

### Services
- `database_service.dart` - SQLite operations (CRUD for users, emotion records)
- `storage_service.dart` - SharedPreferences (first launch, login state)
- `tflite_emotion_service.dart` - TensorFlow Lite model loading/inference
- `audio_recorder_detection.dart` - Audio recording via `record` package

### Providers
- `LocaleProvider` - Language (en/id) switching
- `ThemeProvider` - Light/dark mode
- `AuthProvider` - Login state and username

## Quirks

### Portrait-Only
```dart
// main.dart:22-25
SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
]);
```

### Required Model Path
Emotion model loaded from `assets/model_female.tflite` - verify file exists or inference will fail.

### No Tests
No `test/` directory exists. Run `flutter test` returns empty.

### Locale Files
Both English (`*_en.json`) and Indonesian (`*.json`) versions exist in `assets/`. App defaults to Indonesian via `AppLocalizations`.

## i18n
`lib/l10n/app_localizations.dart` - uses `AppLocalizations.tr('key')` for translations.