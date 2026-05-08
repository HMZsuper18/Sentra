# ESP32 Firmware - Robot Motor Control

Embedded C++ firmware for ESP32-based robot with 4-motor control.

## Structure

```
src/
├── config.h        # Constants, BLE UUIDs, timing values
├── motors.h/cpp    # Motor driver & pin definitions
├── ble_handler.h/cpp  # BLE server & characteristic callbacks
├── wifi_handler.h/cpp # WiFi connection & Firebase init
├── commands.h/cpp  # Command execution & state updates
├── esp32_main.cpp  # Main entry point (setup/loop)
└── platformio.ini  # PlatformIO configuration
```

## Hardware

- **Board**: ESP32 (WiFi + BLE)
- **Motors**: 4 DC motors (2 left, 2 right)
- **Pins**: IN1=14, IN2=27, IN3=26, IN4=25

## Commands

| Command | Action |
|---------|--------|
| `قدام` (forward) | All motors forward |
| `ورا` (backward) | All motors backward |
| `يمين` (right) | Left forward, right backward |
| `شمال` (left) | Right forward, left backward |
| `وقف` (stop) | All motors stop |

## BLE Characteristics

| UUID | Property | Description |
|------|----------|-------------|
| ...001 | Write | WiFi SSID |
| ...002 | Write | WiFi Password |
| ...003 | Read/Write | Board Name |
| ...004 | Read | Error Codes |
| ...005 | Read/Notify | Debug Info (IP, RSSI, Memory, Uptime) |

## Building

```bash
pio run
pio upload
```