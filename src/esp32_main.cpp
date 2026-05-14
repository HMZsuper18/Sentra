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
#include "oled_display.h"

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
bool bootDone = false;

String lastLcdMsg_local = "";
unsigned long lastOledUpdate = 0;
const unsigned long OLED_UPDATE_INTERVAL = 500;
unsigned long lastWifiCheck = 0;
const unsigned long WIFI_CHECK_INTERVAL = 5000;

extern bool oledReady;

String toEnglish(const String& word) {
    if (word == "يمين" || word == "اتجه يمين" || word == "يميناً") return "Right";
    if (word == "شمال" || word == "اتجه شمال" || word == "يسار")   return "Left";
    if (word == "قدام" || word == "تقدم" || word == "امام" || word == "الأمام") return "Forward";
    if (word == "ورا" || word == "للخلف" || word == "تراجع" || word == "الخلف") return "Backward";
    if (word == "وقف" || word == "توقف" || word == "استنى" || word == "قف") return "Stop";
    return word;
}

void buildOledLines(String& l1, String& l2, String& l3, String& l4) {
    if (WiFi.status() == WL_CONNECTED) {
        l1 = WiFi.SSID();
    } else {
        l1 = "No WiFi";
    }
    if (bleConnected) l1 += " [BLE]";

    l2 = toEnglish(lastLcdMsg_local);

    const char* labels[] = {"idle", "FWD", "BWD"};
    l3 = labels[(int)motorStates[0]];
    l3 += " ";
    l3 += labels[(int)motorStates[1]];
    l3 += " ";
    l3 += labels[(int)motorStates[2]];
    l3 += " ";
    l3 += labels[(int)motorStates[3]];

    if (!currentErrors.isEmpty()) {
        l4 = "ERR: " + currentErrors;
    } else if (WiFi.status() == WL_CONNECTED) {
        l4 = WiFi.localIP().toString();
    } else {
        l4 = "No WiFi";
    }
}

void refreshOLED() {
    String l1, l2, l3, l4;
    buildOledLines(l1, l2, l3, l4);
    updateOLED(l1, l2, l3, l4);
}

void pushLCD(const String& msg) {
    lastLcdMsg_local = msg;
    refreshOLED();
}

unsigned long lastPoll = 0;

void setup() {
    Serial.begin(115200);
    delay(500);
    initMotors();
    pinMode(2, OUTPUT);
    digitalWrite(2, LOW);

    initOLED();
    delay(200);

    preferences.begin("sentra", false);
    boardName = preferences.getString("boardname", "Sentra_Board");

    String storedSsid = preferences.getString("ssid", DEFAULT_SSID);
    String storedPass = preferences.getString("password", DEFAULT_PASS);

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
    refreshOLED();
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

    if (now - lastOledUpdate >= OLED_UPDATE_INTERVAL) {
        lastOledUpdate = now;
        refreshOLED();
    }

    if (now - lastWifiCheck >= WIFI_CHECK_INTERVAL) {
        lastWifiCheck = now;
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("WiFi lost, reconnecting...");
            pushLCD("WiFi Lost");
            digitalWrite(2, LOW);
            currentErrors = "E006";
            connectToWifi();
        } else if (currentErrors == "E006") {
            currentErrors = "";
        }
    }

    if (now - lastPoll < POLL_INTERVAL) return;
    lastPoll = now;

    if (!Firebase.ready()) return;

    if (Firebase.getString(fbdo, "/command/word")) {
        String raw = fbdo.stringData();
        if (raw.isEmpty()) { lastCommand = ""; return; }
        if (raw == lastCommand) return;

        if (!bootDone) {
            bootDone = true;
            Firebase.deleteNode(fbdo, "/command");
            lastCommand = "";
            return;
        }

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

        Firebase.setString(fbdo, "/command/word", "");
    }
}