#include <Arduino.h>
#include <WiFi.h>
#include "esp_coexist.h"

#include "config.h"
#include "storage/preferences_store.h"
#include "display/display.h"
#include "control/motor_driver.h"
#include "control/command_parser.h"
#include "comm/ble_handler.h"
#include "comm/wifi_manager.h"

void setup() {
    Serial.begin(115200);
    delay(500);

    initPreferences();
    initMotors();
    pinMode(2, OUTPUT);
    digitalWrite(2, LOW);

    initDisplay();
    delay(200);

    String storedSsid = getStoredSsid();
    String storedPass = getStoredPassword();

    if (storedSsid.length() > 0 && storedPass.length() > 0) {
        Serial.println("Found stored WiFi credentials, connecting...");
        pushStatus("Connecting...");
        connectToWifi();
    } else {
        Serial.println("No stored WiFi credentials, waiting for app...");
        pushStatus("No WiFi Config");
    }

    esp_coex_preference_set(ESP_COEX_PREFER_WIFI);
    initBLE();

    pushMotorStates();
    refreshOLED();
}

void loop() {
    handleMotorTimeout();
    handleDisplayUpdate();
    handleWifiReconnect();

    static unsigned long lastBleUpdate = 0;
    unsigned long now = millis();
    if (now - lastBleUpdate >= BLE_UPDATE_INTERVAL) {
        lastBleUpdate = now;
        updateBLEInfo();
    }
}
