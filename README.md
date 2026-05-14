# Sentra Robot 🤖

Sentra is an advanced, modular ESP32-based robotics platform. It features a hybrid control system (Firebase RTDB + BLE), a modern Flutter mobile application, and a high-performance power delivery system designed for stability and torque.

## 🛠 Hardware Specifications (Final Version)

### 1. Control & Logic (The Brain)
- **Microcontroller:** ESP32 DevKit V1 — A dual-core processor managing hybrid control logic (Firebase RTDB + BLE).
- **Display:** 0.96" OLED (SSD1306) — Real-time system monitoring (Status, Connection, and Command feedback) via I2C.

### 2. Power Management (High-Performance System) ⚡
- **Main Battery:** 11.1V 3-Cell (3S) LiPo Battery — Provides the high current and voltage needed for maximum motor performance.
- **Voltage Regulation:** DC-DC Buck Converter (LM2596) — Steps down the 11.1V battery voltage to a stable 5V to power the logic side (ESP32 & OLED).
- **Safety & Protection:** Total LiPo Alarm — External hardware buzzer to monitor cell health and prevent over-discharge.

### 3. Motion & Actuation (The Drivetrain)
- **Motor Driver:** L298N Dual H-Bridge Module — Interfaces the 11.1V power rail with the ESP32 logic to drive the motors.
- **Drive System:** 4-Wheel Drive (4WD) — Powered by four high-torque gear DC motors.
- **Chassis:** Custom 3D Printed Modular Body — Tailored for robust mounting and organized component housing.

### 4. Connectivity Stack
- **Cloud Link:** Google Firebase Realtime Database — For remote control and status synchronization over WiFi.
- **Local Bridge:** Bluetooth Low Energy (BLE) — Used for initial setup, WiFi provisioning, and low-latency debugging.

## 📡 Connectivity & Control

### Dual-Mode Operation

- **Cloud Control (Firebase):** Uses Google Firebase Realtime Database for long-range control and telemetry.
- **Local Control (BLE):** Custom Bluetooth Low Energy service for:
  - Initial WiFi Configuration (SSID/Password)
  - Real-time Error Reporting
  - Low-latency manual maneuvers

## 🚀 Features

- **Voice Command Processing:** Integrated NLP to translate Egyptian Arabic commands to robot actions.
- **Heartbeat Safety System:** Automatically stops motors if the connection is lost for more than 5 seconds.
- **Persistent Memory:** Saves WiFi credentials in ESP32 Preferences (NVS) to survive power cycles.
- **Live Debugging:** Streams system heap, RSSI, and uptime via BLE characteristics.

## Voice Commands

| Command | Arabic | Action |
|---------|--------|--------|
| Forward | قدام | Move forward |
| Backward | ورا | Move backward |
| Right | يمين | Turn right |
| Left | شمال | Turn left |
| Stop | وقف | Stop all motors |

## 📂 Project Structure

```
Sentra/
├── 📁 3D/            # STL and STEP files for the chassis
├── 📁 app/           # Flutter mobile application source code
├── 📁 src/           # ESP32 Firmware (C++)
│   ├── esp32_main.cpp
│   ├── motors.cpp / motors.h
│   ├── ble_handler.cpp / ble_handler.h
│   ├── wifi_handler.cpp / wifi_handler.h
│   ├── commands.cpp / commands.h
│   ├── oled_display.cpp / oled_display.h
│   ├── config.h
│   └── secrets.h     # (gitignored) WiFi/Firebase credentials
├── 📁 website/       # Firebase Web Dashboard
├── 📁 Sentra/        # Duplicate firmware (legacy)
├── platformio.ini    # PlatformIO project configuration
└── README.md
```

## Quick Start

**Firmware:**
```bash
cp src/secrets.h.example src/secrets.h
# edit src/secrets.h with your WiFi credentials and Firebase token
pio run && pio upload
```

**Mobile App:**
```bash
cd app && flutter run
```

**Website:**
```bash
cd website && firebase deploy
```

## 🔌 Pin Mapping

| Pin | Component |
|-----|-----------|
| GPIO14 | Motor IN1 |
| GPIO27 | Motor IN2 |
| GPIO26 | Motor IN3 |
| GPIO25 | Motor IN4 |
| GPIO21 | OLED SDA |
| GPIO22 | OLED SCL |
| GPIO2  | Status LED |

## License

See [LICENSE](LICENSE) for details.
