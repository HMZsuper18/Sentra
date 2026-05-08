# Flutter App - Voice-Controlled Robot Interface

Voice-controlled robot interface app built with Flutter for Android/iOS.

## Structure

```
lib/
├── core/           # App constants, colors, keyword definitions
├── models/         # Data models (Particle, ErrorCodes)
├── services/       # Business logic (BLE, Firebase, Speech)
├── widgets/        # Reusable UI components
└── main.dart       # App entry point
```

## Features

- **Voice Recognition**: Arabic speech-to-text with keyword extraction
- **Bluetooth Control**: BLE connection to ESP32 robot
- **Firebase Integration**: Real-time command sync via SSE stream
- **Animated UI**: Glass-morphism design with particle effects

## Key Components

| Component | Description |
|-----------|-------------|
| `SpeechService` | Wraps speech_to_text package with restart logic |
| `BLEService` | Handles device scanning, connection, characteristic reads |
| `FirebaseService` | SSE stream listener + HTTP command writer |
| `MicWidget` | Animated microphone with ripple effects |
| `RobotMapWidget` | Visual representation of 4-motor robot |

## Dependencies

```yaml
speech_to_text: ^latest
flutter_blue_plus: ^latest
permission_handler: ^latest
http: ^latest
```

## Getting Started

```bash
cd app
flutter pub get
flutter run
```