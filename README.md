# Now Bar - Smart Lock Screen Overlay

A Flutter application with Kotlin native services that simulates the "Now Bar" feature from Samsung's One UI 8.5. The app displays interactive capsules on the lock screen using an overlay window, featuring AI-powered prioritization of information.

## Features

### Interactive Capsules
- **Battery Capsule** - Real-time battery percentage with animated charging indicator and low battery warnings
- **Weather Capsule** - Current weather conditions with location-based data from Open-Meteo API
- **Music Capsule** - Media controls with play/pause, next/previous buttons and visualizer effect
- **Match Capsule** - Live sports scores with real-time match tracking

### AI-Powered Prioritization
- Rule-based AI engine ranks capsules based on contextual importance
- Battery emergencies get highest priority
- Active media playback is prioritized
- Live matches and extreme weather trigger elevated priority
- Extensible architecture for ML model integration

### Design
- Samsung One UI-inspired glass morphism design
- Animated wave effects at the bottom of each capsule
- Smooth swipe gestures for navigating between capsules
- Samsung color palette (Blue, Green, Orange, Pink)

## Architecture

```
nowbar/
├── android/
│   ├── app/
│   │   ├── build.gradle                    # App-level Gradle config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml         # App manifest with permissions
│   │       └── kotlin/com/example/nowbar/
│   │           ├── MainActivity.kt         # Flutter activity with overlay controls
│   │           ├── NowBarService.kt        # Foreground service for lock screen
│   │           ├── NowBarOverlayManager.kt # Overlay window management
│   │           ├── NowBarNotificationListener.kt # Media session listener
│   │           ├── BootReceiver.kt         # Auto-start on boot
│   │           └── ScreenStateReceiver.kt  # Screen on/off detection
│   ├── build.gradle                        # Project-level Gradle config
│   ├── settings.gradle                     # Settings with Flutter plugin
│   └── gradle.properties                   # Gradle properties
├── lib/
│   ├── main.dart                           # App entry point & UI
│   ├── capsule/
│   │   ├── capsule_manager.dart            # Capsule state management (Riverpod)
│   │   ├── capsule_widget.dart             # Glass capsule renderer with wave
│   │   ├── battery_capsule.dart            # Battery capsule UI
│   │   ├── weather_capsule.dart            # Weather capsule UI
│   │   ├── music_capsule.dart              # Music capsule UI
│   │   └── match_capsule.dart              # Sports match capsule UI
│   ├── ai/
│   │   ├── capsule_ai.dart                 # Rule-based AI prioritization
│   │   └── context_predictor.dart          # Context aggregation service
│   ├── services/
│   │   ├── overlay_channel.dart            # Flutter-Kotlin method channel
│   │   ├── battery_service.dart            # Battery monitoring service
│   │   ├── weather_service.dart            # Weather API service
│   │   ├── music_service.dart              # Media session service
│   │   └── match_service.dart              # Sports data service
│   └── theme/
│       └── nowbar_theme.dart               # Samsung One UI theme
├── assets/
│   └── animations/                         # Lottie/Rive animations
├── pubspec.yaml                            # Flutter dependencies
└── .github/workflows/
    └── build_apk.yml                       # CI/CD workflow
```

## Requirements

- **Platform**: Android 12+ (API 31+)
- **SDK**: `compileSdk 34`, `minSdk 31`
- **Kotlin**: 1.9.22
- **AGP**: 8.2.0
- **Flutter**: 3.16.0+

## Getting Started

### Prerequisites

1. Install Flutter SDK (>= 3.16.0)
2. Install Android Studio with Android SDK 34
3. Set up Android emulator or physical device (Android 12+)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd nowbar
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Create `android/local.properties`:
```properties
flutter.sdk=<path-to-flutter-sdk>
```

### Building

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

**App Bundle:**
```bash
flutter build appbundle --release
```

### Running

```bash
flutter run
```

## Permissions

The app requires the following permissions:

- `SYSTEM_ALERT_WINDOW` - Display overlay on lock screen
- `FOREGROUND_SERVICE` - Keep service running
- `FOREGROUND_SERVICE_SPECIAL_USE` - Android 14+ foreground service type
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - Weather location
- `POST_NOTIFICATIONS` - Service notification
- `BLUETOOTH` - Media control
- `RECEIVE_BOOT_COMPLETED` - Auto-start on boot

## Configuration

### Weather API
The app uses Open-Meteo free API (no API key required). To use a different weather provider, modify `lib/services/weather_service.dart`.

### Sports Data
The app includes demo match data by default. To integrate with a live sports API:
1. Obtain an API key from football-data.org or similar service
2. Update `lib/services/match_service.dart` with your API key

## CI/CD

GitHub Actions workflow is configured for:
- Automatic APK building on push to `main` or `develop`
- Static analysis and testing
- Signed release builds for tags
- Artifact uploads

### Required Secrets for Signed Builds

Add these secrets to your GitHub repository for signed release builds:
- `SIGNING_KEY` - Base64-encoded keystore file
- `KEY_ALIAS` - Key alias
- `KEY_STORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password

## How It Works

1. **Main App** - Normal Flutter app for configuring Now Bar and granting permissions
2. **Foreground Service** - Kotlin service that keeps the app alive in background
3. **Overlay Window** - System alert window shown on top of lock screen
4. **Method Channel** - Communication between Flutter UI and Kotlin services
5. **AI Engine** - Prioritizes capsules based on contextual signals

## Customization

### Adding New Capsules
1. Create a new capsule UI file in `lib/capsule/`
2. Add the capsule type to `CapsuleType` enum
3. Register in `CapsuleNotifier._initializeCapsules()`
4. Add AI scoring in `CapsuleAI`

### Changing Colors
Edit color constants in `lib/theme/nowbar_theme.dart`.

## Troubleshooting

**Overlay not showing:**
- Ensure "Display over other apps" permission is granted
- Check that battery optimization is disabled for the app
- Verify the service is running in the notification shade

**Media controls not working:**
- Grant notification listener permission
- Ensure a media app is actively playing

**Weather not loading:**
- Grant location permission
- Check internet connectivity

## License

This project is for educational purposes. Samsung One UI is a trademark of Samsung Electronics.

## Contributing

Contributions are welcome! Please ensure:
- Code follows Dart/KT style guidelines
- All tests pass
- Static analysis returns no issues
- Commit messages are descriptive