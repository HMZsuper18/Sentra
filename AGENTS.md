# Sentra Robot — Build & Development Guide

## Project Structure

```
Sentra/
├── src/                    # ESP32 firmware (Arduino/PlatformIO)
│   ├── esp32_main.cpp      # Entry point
│   ├── config.h            # Timing, BLE UUIDs
│   ├── secrets.h           # WiFi creds, OpenRouter API key
│   ├── comm/               # BLE & WiFi handlers
│   ├── control/            # Motor driver & command parser
│   ├── display/            # OLED display
│   └── storage/            # ESP32 Preferences (NVS)
└── app/                    # Flutter mobile app
    └── lib/
        ├── main.dart       # App entry, providers, theme
        ├── models/         # AppState (ChangeNotifier)
        ├── services/       # BLE, STT, TTS services
        └── ui/             # HomeScreen widget
```

## ESP32 Firmware

```bash
# Build
pio run

# Upload (connect ESP32 via USB)
pio run -t upload

# Serial monitor
pio device monitor

# Clean build
pio run --target clean
```

**Dependencies** (managed by PlatformIO):
- ArduinoJson
- Adafruit SSD1306
- Adafruit GFX Library

## Flutter App

```bash
# Navigate to app directory
cd app

# Install dependencies
flutter pub get

# Run analyzer (check for warnings/errors)
flutter analyze

# Run on connected device
flutter run

# Build release APK
flutter build apk
```

**Dependencies**:
- flutter_blue_plus (BLE)
- speech_to_text (STT)
- flutter_tts (TTS)
- provider (state management)

## Code Style

- Use `debugPrint()` instead of `print()` for Dart logging
- ESP32 firmware uses `Serial.println()` for debug output
- Follow existing naming conventions (camelCase Dart, snake_case C++ files)
- ESP32 C++ files use `.cpp` extension, headers use `.h`
