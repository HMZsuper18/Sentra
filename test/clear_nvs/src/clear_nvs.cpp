#include <Arduino.h>
#include <Preferences.h>

void setup() {
    Serial.begin(115200);
    delay(500);

    Preferences preferences;
    preferences.begin("sentra", false);

    String ssid = preferences.getString("ssid", "");
    String pass = preferences.getString("password", "");

    preferences.clear();
    preferences.end();

    Serial.println("NVS 'sentra' namespace cleared!");
    Serial.print("Removed SSID: ");
    Serial.println(ssid.isEmpty() ? "(none)" : ssid.c_str());
    Serial.println("Reboot to apply.");
}

void loop() {}
