#include <Arduino.h>
#include <Preferences.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ArduinoJson.h>

#include "config.h"
#include "motors.h"
#include "ble_handler.h"
#include "wifi_handler.h"
#include "commands.h"

Preferences preferences;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

String lastCommand = "";
unsigned long motorStopTime = 0;
unsigned long lastCmdTime = 0;
bool motorRunning = false;

String lastLcdMsg = "";
String lastMotorState = "";
String boardName = "Sentra_Board";
String currentErrors = "";
unsigned long lastBleUpdate = 0;

bool bleConnected = false;

String lastLcdMsg_local = "";

void pushLCD(const String& msg) {
    lastLcdMsg_local = msg;
}

unsigned long lastPoll = 0;

void setup() {
    Serial.begin(115200);
    delay(500);
    initMotors();
    pinMode(2, OUTPUT);
    digitalWrite(2, LOW);

    preferences.begin("sentra", false);
    boardName = preferences.getString("boardname", "Sentra_Board");

    String storedSsid = preferences.getString("ssid", "");
    String storedPass = preferences.getString("password", "");

    if (storedSsid.length() > 0 && storedPass.length() > 0) {
        Serial.println("Found stored WiFi credentials, connecting...");
        pushLCD("Connecting...");
        connectToWifi();
    } else {
        Serial.println("No stored WiFi credentials, waiting for app...");
        pushLCD("No WiFi Config");
    }

    initBLE();

    pushMotorStates();
    lastCmdTime = millis();
    lastBleUpdate = millis();
}

void loop() {
    unsigned long now = millis();

    if (motorRunning && now >= motorStopTime) {
        stopMotors();
        motorRunning = false;
        pushLCD("Ready");
        pushMotorStates();
    }

    if (motorRunning && (now - lastCmdTime >= HEARTBEAT_TIMEOUT)) {
        stopMotors();
        motorRunning = false;
        pushLCD("Timeout");
        pushMotorStates();
        Serial.println("Heartbeat timeout - motors stopped");
    }

    if (now - lastBleUpdate >= BLE_UPDATE_INTERVAL) {
        lastBleUpdate = now;
        updateBLEInfo();
    }

    if (now - lastPoll < POLL_INTERVAL) return;
    lastPoll = now;

    if (!Firebase.ready()) return;

    if (Firebase.getString(fbdo, "/command/word")) {
        String raw = fbdo.stringData();
        if (raw == lastCommand) return;
        lastCommand = raw;

        StaticJsonDocument<128> doc;
        if (deserializeJson(doc, raw) == DeserializationError::Ok) {
            String word = doc["word"].as<String>();
            executeCommand(word);
        } else {
            pushLCD("Parse error");
            Serial.print("JSON parse error: ");
            Serial.println(raw);
        }
    } else {
        Serial.print("Firebase error: ");
        Serial.println(fbdo.errorReason());
    }
}