#include "wifi_handler.h"
#include "config.h"
#include "ble_handler.h"
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <Preferences.h>

extern Preferences preferences;
extern FirebaseData fbdo;
extern FirebaseAuth auth;
extern FirebaseConfig config;
extern String currentErrors;

void connectToWifi() {
    String ssid = preferences.getString("ssid", DEFAULT_SSID);
    String password = preferences.getString("password", DEFAULT_PASS);

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