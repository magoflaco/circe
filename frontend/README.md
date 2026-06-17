# Circe Mobile Application

This directory contains the Flutter mobile application for the Circe intelligent monitoring system. It serves as the primary interface for caregivers to monitor vital signs, receive alerts, and manage device configurations.

## Requirements
- Flutter SDK (stable channel, version >= 3.22.x)
- Dart SDK >= 3.4.0

## Setup
1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Run the application on an emulator or physical device:
   ```bash
   flutter run
   ```

## Build Release
To build an APK for Android deployment:
```bash
flutter build apk --release
```

## Structure
- `lib/screens`: User interface components and views.
- `lib/services`: API clients, real-time WebSockets, and local storage management.
- `lib/models.dart`: Data structures and JSON serialization.
