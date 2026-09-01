#include "comm/wifi_manager.h"
#include "storage/preferences_store.h"
#include "display/display.h"
#include "config.h"
#include <WiFi.h>

static unsigned long lastWifiCheck = 0;
static const unsigned long WIFI_CHECK_INTERVAL = 5000;

void connectToWifi() {
    String ssid = getStoredSsid();
    String password = getStoredPassword();

    if (ssid.length() == 0) {
        Serial.println("No WiFi credentials stored");
        pushStatus("No WiFi Config");
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
        pushStatus("WiFi OK");
        digitalWrite(2, HIGH);
    } else {
        Serial.println("WiFi connection failed");
        pushStatus("WiFi Failed");
        currentErrors = "E006";
    }
}

void handleWifiReconnect() {
    unsigned long now = millis();
    if (now - lastWifiCheck < WIFI_CHECK_INTERVAL) return;
    lastWifiCheck = now;

    if (WiFi.status() != WL_CONNECTED) {
        String checkSsid = getStoredSsid();
        if (checkSsid.length() > 0) {
            Serial.println("WiFi lost, reconnecting...");
            pushStatus("WiFi Lost");
            digitalWrite(2, LOW);
            currentErrors = "E006";
            connectToWifi();
        }
    } else if (currentErrors == "E006") {
        currentErrors = "";
    }
}
