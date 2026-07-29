# Track Me — Flutter App

> AI-Powered Productivity Application — Mobile Client

## 🚀 Tech Stack

- **Flutter** 3.x / Dart
- **Riverpod** — State management
- **GoRouter** — Navigation
- **Dio** — HTTP client with JWT interceptor
- **Isar** — Local database (offline-ready)
- **Material Design 3** — Purple & White theme
- **Google Fonts (Inter)** — Typography
- **Firebase** — Push notifications (FCM)
- **Google Sign-In** — Social authentication

---

## 📁 Project Structure

```
lib/
├── app/
│   └── app.dart                    # Root MaterialApp
├── core/
│   ├── config/
│   │   └── app_env.dart            # --dart-define env vars
│   ├── constants/
│   │   └── app_constants.dart      # App-wide constants
│   ├── local/
│   │   └── isar_service.dart       # Isar DB singleton
│   ├── models/
│   │   └── app_settings_model.dart # App settings (Isar)
│   ├── network/
│   │   └── dio_client.dart         # HTTP client + interceptors
│   ├── notifications/
│   │   └── notification_service.dart
│   ├── router/
│   │   └── app_router.dart         # GoRouter config
│   ├── services/
│   │   └── firebase_service.dart
│   ├── shell/
│   │   └── main_shell.dart         # Bottom nav shell
│   ├── theme/
│   │   ├── app_colors.dart         # Color palette
│   │   └── app_theme.dart          # Material 3 theme
│   └── widgets/
│       ├── app_button.dart
│       ├── app_card.dart
│       ├── app_text_field.dart
│       └── shared_widgets.dart
├── features/
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   ├── dashboard/
│   ├── habits/
│   ├── goals/
│   ├── ai/
│   ├── profile/
│   └── notifications/
└── main.dart
```

---

## ⚙️ Setup

### 1. Prerequisites

- Flutter SDK 3.x ([Install guide](https://docs.flutter.dev/get-started/install))
- Dart SDK (included with Flutter)
- Android Studio / VS Code
- Firebase project (for FCM)

### 2. Clone and Install

```bash
# Install Flutter dependencies
cd track_me
flutter pub get
```

### 3. Configure Environment

Copy and fill in your values:

```bash
cp .env.example .env.dev.json
```

Edit `.env.dev.json`:
```json
{
  "BASE_URL": "http://10.0.2.2:3000/api",
  "GEMINI_API_KEY": "your_gemini_api_key",
  "GOOGLE_CLIENT_ID": "your_google_client_id"
}
```

### 4. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app with package name `com.trackme.app`
3. Download `google-services.json` → place in `android/app/`
4. Add iOS app with bundle ID `com.trackme.app`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### 5. Google Sign-In Setup

1. Get your OAuth 2.0 Client ID from Google Cloud Console
2. Add it to your `.env.dev.json`
3. For Android: add SHA-1 fingerprint to Firebase Console

### 6. Run the App

```bash
# Development (with env vars)
flutter run --dart-define-from-file=.env.dev.json

# With specific device
flutter run --dart-define-from-file=.env.dev.json -d android

# Release build
flutter build apk --dart-define-from-file=.env.prod.json
flutter build ipa --dart-define-from-file=.env.prod.json
```

### 7. Code Generation

After modifying Isar models or Riverpod providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🏗 Architecture

The app follows **Clean Feature-Based Architecture**:

```
Feature/
├── data/
│   ├── models/         # Domain + Local (Isar) models
│   ├── repositories/   # Data access layer
│   └── datasources/    # API + Local datasources
├── providers/          # Riverpod state management
└── presentation/
    ├── screens/        # Full-page screens
    └── widgets/        # Feature-specific widgets
```

### Key Patterns:
- **Repository Pattern** — Abstracts data sources
- **Optimistic Updates** — UI updates immediately, sync in background
- **Offline-First** — Isar caches data locally
- **Provider + Notifier** — Unidirectional state flow

---

## 📱 App Screens

| Screen | Description |
|--------|-------------|
| Splash | Animated logo, onboarding check |
| Onboarding | 4 animated screens (shown once) |
| Login | Email/Google/Apple auth |
| Register | New account creation |
| Dashboard | Home with progress, habits, goals, AI |
| Habits | Weekly grid tracker |
| Goals | Category-grouped goal list |
| AI Insights | Productivity score, weekly report |
| Profile | Stats, achievements, settings |

---

## 🎨 Design System

- **Primary**: `#7C3AED` (Purple)
- **Background**: `#F8F7FF`
- **Surface**: `#FFFFFF`
- **Font**: Inter (Google Fonts)
- **Border Radius**: 16dp (cards), 12dp (inputs), 24dp (sheets)

---

## 🧪 Testing

```bash
flutter test
flutter analyze
```

---

## 📦 Build & Deploy

### Android

```bash
# Update version in pubspec.yaml
flutter build appbundle --release --dart-define-from-file=.env.prod.json
# Upload to Google Play Console
```

### iOS

```bash
flutter build ipa --release --dart-define-from-file=.env.prod.json
# Upload to App Store Connect via Transporter
```
