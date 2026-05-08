#define FIREBASE_USE_PSRAM
#define ENABLE_RTDB
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <ArduinoJson.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include "motors.h"

Preferences preferences;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

const char* DB_URL   = "https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/";
const char* DB_TOKEN = "zuUhC4VNiO0quwQ3JlmtH6hLf2Lx8YvODFCCuZVC";

const unsigned long POLL_INTERVAL       = 200;
const unsigned long MOTOR_DURATION_TURN = 1000;
const unsigned long MOTOR_DURATION_MOVE = 2000;
const unsigned long HEARTBEAT_TIMEOUT   = 5000;
const unsigned long BLE_UPDATE_INTERVAL = 10000;

String lastCommand    = "";
unsigned long motorStopTime  = 0;
unsigned long lastCmdTime    = 0;
bool          motorRunning   = false;

String lastLcdMsg      = "";
String lastMotorState  = "";
String boardName       = "Sentra_Board";
String currentErrors   = "";
unsigned long lastBleUpdate = 0;

bool bleConnected = false;

BLEServer* pServer = nullptr;
BLEService* pService = nullptr;
BLECharacteristic* pWifiNameChar = nullptr;
BLECharacteristic* pWifiPassChar = nullptr;
BLECharacteristic* pBoardNameChar = nullptr;
BLECharacteristic* pErrorsChar = nullptr;
BLECharacteristic* pDebugChar = nullptr;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        bleConnected = true;
        Serial.println("App connected via BLE");
        pushLCD("App Connected");
    }
    void onDisconnect(BLEServer* pServer) {
        bleConnected = false;
        Serial.println("App disconnected via BLE");
        pushLCD("Ready");
    }
};

class WifiNameCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
        String newSsid = pChar->getValue().c_str();
        if (newSsid.length() > 0) {
            preferences.putString("ssid", newSsid);
            Serial.print("WiFi SSID updated: ");
            Serial.println(newSsid);
            pushLCD("WiFi Updated");
        }
    }
};

class WifiPassCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
        String newPass = pChar->getValue().c_str();
        if (newPass.length() > 0) {
            preferences.putString("password", newPass);
            Serial.print("WiFi Password updated: ");
            Serial.println(newPass);
            pushLCD("WiFi Updated");
            connectToWifi();
        }
    }
};

class BoardNameCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
        String newName = pChar->getValue().c_str();
        if (newName.length() > 0) {
            preferences.putString("boardname", newName);
            boardName = newName;
            Serial.print("Board Name updated: ");
            Serial.println(newName);
        }
    }
};

void initBLE() {
    BLEDevice::init(boardName.c_str());
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    pService = pServer->createService("12345678-1234-1234-1234-123456789abc");

    pWifiNameChar = pService->createCharacteristic(
        "12345678-1234-1234-1234-123456789001",
        BLECharacteristic::PROPERTY_WRITE
    );
    pWifiNameChar->setCallbacks(new WifiNameCallbacks());
    pWifiNameChar->setValue("");

    pWifiPassChar = pService->createCharacteristic(
        "12345678-1234-1234-1234-123456789002",
        BLECharacteristic::PROPERTY_WRITE
    );
    pWifiPassChar->setCallbacks(new WifiPassCallbacks());
    pWifiPassChar->setValue("");

    pBoardNameChar = pService->createCharacteristic(
        "12345678-1234-1234-1234-123456789003",
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ
    );
    pBoardNameChar->setCallbacks(new BoardNameCallbacks());
    pBoardNameChar->setValue(boardName.c_str());

    pErrorsChar = pService->createCharacteristic(
        "12345678-1234-1234-1234-123456789004",
        BLECharacteristic::PROPERTY_READ
    );
    pErrorsChar->setValue("OK");

    pDebugChar = pService->createCharacteristic(
        "12345678-1234-1234-1234-123456789005",
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pDebugChar->setValue("");
    pDebugChar->addDescriptor(new BLE2902());

    pService->start();

    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(pService->getUUID());
    pAdvertising->setScanResponse(true);
    pAdvertising->start();

    Serial.println("BLE started, waiting for app connection...");
    pushLCD("BLE Ready");
}

void updateBLEInfo() {
    if (!bleConnected) return;

    pBoardNameChar->setValue(boardName.c_str());
    pErrorsChar->setValue(currentErrors.isEmpty() ? "OK" : currentErrors.c_str());

    String debugInfo = "IP:" + WiFi.localIP().toString();
    debugInfo += "|RSSI:" + String(WiFi.RSSI());
    debugInfo += "|Mem:" + String(ESP.getFreeHeap());
    debugInfo += "|Uptime:" + String(millis() / 1000);
    pDebugChar->setValue(debugInfo.c_str());
    pDebugChar->notify();
}

void connectToWifi() {
    String ssid = preferences.getString("ssid", "");
    String password = preferences.getString("password", "");

    if (ssid.length() == 0) {
        Serial.println("No WiFi credentials stored");
        pushLCD("No WiFi Config");
        return;
    }

    WiFi.disconnect();
    delay(100);
    WiFi.begin(ssid.c_str(), password.c_str());

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts++ < 40) {
        delay(500);
        Serial.print(".");
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("WiFi connected!");
        Serial.println(WiFi.localIP());
        pushLCD("WiFi OK");
        digitalWrite(2, HIGH);

        initFirebase();
    } else {
        Serial.println("WiFi connection failed");
        pushLCD("WiFi Failed");
        currentErrors = "E006";
    }
}

void initFirebase() {
    config.database_url = DB_URL;
    config.signer.tokens.legacy_token = DB_TOKEN;
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
}

void pushLCD(const String& msg) {
    lastLcdMsg = msg;
}

void pushMotorStates() {
    const char* states[] = {"idle", "forward", "backward"};
    String s1 = states[(int)motorStates[0]];
    String s2 = states[(int)motorStates[1]];
    String s3 = states[(int)motorStates[2]];
    String s4 = states[(int)motorStates[3]];
    String current = s1 + s2 + s3 + s4;
    if (current != lastMotorState) {
        lastMotorState = current;
        if (Firebase.ready()) {
            Firebase.setString(fbdo, "/status/motor1", s1);
            Firebase.setString(fbdo, "/status/motor2", s2);
            Firebase.setString(fbdo, "/status/motor3", s3);
            Firebase.setString(fbdo, "/status/motor4", s4);
        }
    }
}

void executeCommand(const String& word) {
    pushLCD(word);
    lastCmdTime = millis();
    pushMotorStates();

    if (word == "يمين" || word == "اتجه يمين" || word == "يميناً") {
        turnRight();
        motorStopTime = millis() + MOTOR_DURATION_TURN;
        motorRunning  = true;
    } else if (word == "شمال" || word == "اتجه شمال" || word == "يسار") {
        turnLeft();
        motorStopTime = millis() + MOTOR_DURATION_TURN;
        motorRunning  = true;
    } else if (word == "قدام" || word == "تقدم" || word == "امام" || word == "الأمام") {
        moveForward();
        motorStopTime = millis() + MOTOR_DURATION_MOVE;
        motorRunning  = true;
    } else if (word == "ورا" || word == "للخلف" || word == "تراجع" || word == "الخلف") {
        moveBackward();
        motorStopTime = millis() + MOTOR_DURATION_MOVE;
        motorRunning  = true;
    } else if (word == "وقف" || word == "توقف" || word == "استنى" || word == "قف") {
        stopMotors();
        motorRunning = false;
        pushLCD("Stopped");
    } else {
        pushLCD(word);
    }
    pushMotorStates();
}

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

unsigned long lastPoll = 0;

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
        Serial.println("Heartbeat timeout — motors stopped");
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