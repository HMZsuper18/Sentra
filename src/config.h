#ifndef CONFIG_H
#define CONFIG_H

// ── Firebase ─────────────────────────────────────────────────────────────────
#define DB_URL   "https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/"
#define DB_TOKEN "zuUhC4VNiO0quwQ3JlmtH6hLf2Lx8YvODFCCuZVC"

// ── Timing ────────────────────────────────────────────────────────────────────
#define POLL_INTERVAL        200UL
#define MOTOR_DURATION_TURN  1000UL
#define MOTOR_DURATION_MOVE  2000UL
#define HEARTBEAT_TIMEOUT    5000UL
#define BLE_UPDATE_INTERVAL  10000UL

// ── BLE Service UUID ──────────────────────────────────────────────────────────
#define SERVICE_UUID     "12345678-1234-1234-1234-123456789abc"
#define CHAR_WIFI_NAME   "12345678-1234-1234-1234-123456789001"
#define CHAR_WIFI_PASS   "12345678-1234-1234-1234-123456789002"
#define CHAR_BOARD_NAME  "12345678-1234-1234-1234-123456789003"
#define CHAR_ERRORS      "12345678-1234-1234-1234-123456789004"
#define CHAR_DEBUG       "12345678-1234-1234-1234-123456789005"

#endif