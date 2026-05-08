# Sentra - Voice-Controlled Robot

Voice-controlled robot system with Flutter mobile app, ESP32 firmware, and web dashboard.

## Project Overview

Sentra is a smart robot controlled via Arabic voice commands. The system consists of three main components:

| Component | Technology | Description |
|-----------|------------|-------------|
| [Mobile App](app/) | Flutter | Voice interface with BLE control |
| [Firmware](src/) | C++ / ESP32 | Motor control and wireless communication |
| [Dashboard](website/) | Firebase | Web-based monitoring interface |

## System Architecture

```
┌─────────────┐     BLE/WiFi      ┌─────────────┐
│  Flutter    │ ◄──────────────► │    ESP32    │
│  Mobile App │                  │   Robot     │
└─────────────┘                  └─────────────┘
       │
       │ Firebase SSE
       ▼
┌─────────────┐
│   Website   │
│  Dashboard  │
└─────────────┘
```

## Components

### Mobile App (`app/`)
Voice-controlled interface with:
- Arabic speech-to-text recognition
- Bluetooth Low Energy device connection
- Real-time command sync via Firebase
- Animated glass-morphism UI
- Robot visualization with motor status

See [app/lib/README.md](app/lib/README.md) for details.

### ESP32 Firmware (`src/`)
Embedded C++ code for robot control:
- 4-motor differential drive
- BLE + WiFi connectivity
- Error monitoring system
- Debug telemetry via BLE characteristics

See [src/README.md](src/README.md) for details.

### Web Dashboard (`website/`)
Firebase-hosted web interface:
- Real-time command display
- Responsive dark theme
- Mobile-friendly design

See [website/README.md](website/README.md) for details.

## Voice Commands

| Command | Arabic | Action |
|---------|--------|--------|
| Forward | قدام | Move forward |
| Backward | ورا | Move backward |
| Right | يمين | Turn right |
| Left | شمال | Turn left |
| Stop | وقف | Stop all motors |

## Quick Start

**Mobile App:**
```bash
cd app && flutter run
```

**Firmware:**
```bash
pio run && pio upload
```

**Website:**
```bash
cd website && firebase deploy
```

## License

See [LICENSE](LICENSE) for details.