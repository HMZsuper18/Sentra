#include "ble_handler.h"
#include "config.h"
#include <Preferences.h>

extern Preferences preferences;

static BLEServer* pServer = nullptr;
static BLEService* pService = nullptr;
static BLECharacteristic* pWifiNameChar = nullptr;
static BLECharacteristic* pWifiPassChar = nullptr;
static BLECharacteristic* pBoardNameChar = nullptr;
static BLECharacteristic* pErrorsChar = nullptr;
static BLECharacteristic* pDebugChar = nullptr;

extern String lastLcdMsg;
extern unsigned long lastBleUpdate;

class ServerCallbacks : public BLEServerCallbacks {
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

class WifiNameCallbacks : public BLECharacteristicCallbacks {
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

class WifiPassCallbacks : public BLECharacteristicCallbacks {
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

class BoardNameCallbacks : public BLECharacteristicCallbacks {
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

extern void connectToWifi();

void initBLE() {
    BLEDevice::init(boardName.c_str());
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    pService = pServer->createService(SERVICE_UUID);

    pWifiNameChar = pService->createCharacteristic(
        CHAR_WIFI_NAME,
        BLECharacteristic::PROPERTY_WRITE
    );
    pWifiNameChar->setCallbacks(new WifiNameCallbacks());
    pWifiNameChar->setValue("");

    pWifiPassChar = pService->createCharacteristic(
        CHAR_WIFI_PASS,
        BLECharacteristic::PROPERTY_WRITE
    );
    pWifiPassChar->setCallbacks(new WifiPassCallbacks());
    pWifiPassChar->setValue("");

    pBoardNameChar = pService->createCharacteristic(
        CHAR_BOARD_NAME,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ
    );
    pBoardNameChar->setCallbacks(new BoardNameCallbacks());
    pBoardNameChar->setValue(boardName.c_str());

    pErrorsChar = pService->createCharacteristic(
        CHAR_ERRORS,
        BLECharacteristic::PROPERTY_READ
    );
    pErrorsChar->setValue("OK");

    pDebugChar = pService->createCharacteristic(
        CHAR_DEBUG,
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