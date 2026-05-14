# Sentra — Agent Guide

## Quick Start

```bash
# Build & flash firmware
cp src/secrets.h
pio run && pio upload

# Flutter app
cd app && flutter run

# Website
cd website && firebase deploy
```

## Project Layout

```
src/                  ESP32 firmware (C++, PlatformIO/Arduino)
  esp32_main.cpp      setup() + loop() entry point
  motors.cpp/.h       L298N motor driver (IN1=14,IN2=27,IN3=26,IN4=25)
  ble_handler.cpp/.h  BLE GATT server (5 characteristics)
  wifi_handler.cpp/.h WiFi connect + Firebase init
  commands.cpp/.h     Arabic voice command dispatch
  oled_display.cpp/.h SSD1306 OLED (I2C: SDA=21, SCL=22)
  config.h            Constants, timing, UUIDs
  secrets.h           Gitignored — WiFi/Firebase credentials
app/                  Flutter mobile app (Dart)
website/              Firebase-hosted web dashboard
Sentra/               Duplicate of src/ (legacy)
```

## Coding Conventions

| Thing | Rule |
|-------|------|
| Functions | `camelCase` — `initMotors()`, `executeCommand()` |
| Globals | `camelCase` — `currentErrors`, `motorRunning`, `bootDone` |
| Macros/Constants | `UPPER_SNAKE_CASE` — `MOTOR_DURATION_TURN`, `DB_URL` |
| Enums | `UPPER_SNAKE_CASE` values, `PascalCase` type — `MOTOR_IDLE`, `MotorState` |
| Braces | Allman style (opening brace on its own line) except single-line `if`/`for` without braces |
| Indent | 4 spaces, no tabs |
| Includes | System `< >` first (sorted), then project `" "` (sorted) |
| Headers | `#ifndef` guards: `MODULE_NAME_H` |
| Section comments | `// ── Section Title ──` |

## When Making Changes

1. **Both copies**: `src/` and `Sentra/src/` contain identical firmware — always update both.
2. **Build check**: `pio run` must succeed before asking the user to test.
3. **Secrets**: Never hardcode passwords/tokens in tracked files. Use `secrets.h` (gitignored).
4. **Globals**: Use `extern` in headers, define in one `.cpp`. No function-local statics.
5. **New files**: Create `.h` + `.cpp` pair, add to `src/` and `Sentra/src/`.

## Firebase Data Flow

```
App/Website --HTTP PUT--> /command/word: '{"word":"Forward"}'
ESP32 ----poll every 200ms--> Firebase.getString /command/word
ESP32 --executeCommand()--> motors move
ESP32 --Firebase.setString--> /status/motor{1..4}: "forward"|"backward"|"idle"
ESP32 --Firebase.setString--> /command/word: ""  (clear after execute)
Website --poll every 2s--> /status/motor{1..4}, /status/lcd
```

## BLE Characteristics

| UUID suffix | Name | Props | Purpose |
|-------------|------|-------|---------|
| `...001` | WiFi SSID | WRITE | App sends SSID → ESP32 stores in NVS |
| `...002` | WiFi Password | WRITE | App sends password → ESP32 stores + connects |
| `...003` | Board Name | WRITE+READ | Custom BLE advertising name |
| `...004` | Errors | READ | `"OK"` or `"E006"` (WiFi fail) |
| `...005` | Debug | READ+NOTIFY | `IP:x|RSSI:x|Mem:x|Uptime:x` |

Service UUID: `12345678-1234-1234-1234-123456789abc`

## Voice Commands (Arabic → English)

| Arabic | Display | Action |
|--------|---------|--------|
| قدام / تقدم / امام / الأمام | Forward | Move 2s |
| ورا / للخلف / تراجع / الخلف | Backward | Move 2s |
| يمين / اتجه يمين / يميناً | Right | Turn 1s |
| شمال / اتجه شمال / يسار | Left | Turn 1s |
| وقف / توقف / استنى / قف | Stop | Halt |

## Pin Mapping

| GPIO | Component |
|------|-----------|
| 14 | Motor IN1 |
| 27 | Motor IN2 |
| 26 | Motor IN3 |
| 25 | Motor IN4 |
| 21 | OLED SDA |
| 22 | OLED SCL |
| 2  | Status LED |

## Known Quirks

- `Firebase.getString()` / `setString()` are **synchronous** — blocks loop while networking.
- Motors use **digitalWrite only** (no PWM) — full speed or stop.
- `bootDone` flag: first Firebase poll deletes `/command` node (discards stale commands).
- `toEnglish()` is display-only; command routing uses Arabic strings directly.
- Duplicate firmware in `Sentra/src/` — mirror all changes there too.
