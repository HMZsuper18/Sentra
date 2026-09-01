#include "display/display.h"
#include <WiFi.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1

static Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
static bool oledReady = false;
static String lastMsg_local = "";
static unsigned long lastOledUpdate = 0;
static const unsigned long OLED_UPDATE_INTERVAL = 500;
static uint8_t oledAddr = 0;

String currentErrors = "";
static unsigned long lastReinit = 0;
static const unsigned long REINIT_INTERVAL = 2000;

// ── OLED Hardware ───────────────────────────────────────────────────────────

static bool probeOLED() {
    if (oledAddr == 0) return false;
    Wire.beginTransmission(oledAddr);
    return Wire.endTransmission() == 0;
}

void initDisplay() {
    Wire.begin(21, 22);
    delay(10);

    uint8_t addrs[] = {0x3C, 0x3D};
    for (int i = 0; i < 2; i++) {
        Wire.beginTransmission(addrs[i]);
        if (Wire.endTransmission() == 0) {
            if (display.begin(SSD1306_SWITCHCAPVCC, addrs[i])) {
                oledAddr = addrs[i];
                oledReady = true;
                Serial.print("OLED found at 0x");
                Serial.println(oledAddr, HEX);
                break;
            }
        }
    }

    if (!oledReady) {
        Serial.println("OLED not found on 0x3C or 0x3D");
        return;
    }

    showBootScreen();
    Serial.println("OLED ready");
}

void showBootScreen() {
    if (!oledReady) return;

    display.clearDisplay();
    display.setTextSize(3);
    display.setTextColor(SSD1306_WHITE);
    int16_t x1, y1;
    uint16_t w, h;
    display.getTextBounds("SENTRA", 0, 0, &x1, &y1, &w, &h);
    display.setCursor((SCREEN_WIDTH - w) / 2, (SCREEN_HEIGHT - h) / 2 - 6);
    display.println("SENTRA");

    display.setTextSize(1);
    display.setCursor(0, 56);
    display.setTextColor(SSD1306_WHITE);
    display.println("Booting...");

    display.display();
}

static void updateOLEDDisplay(const String& line1, const String& line2, const String& line3, const String& line4) {
    if (!oledReady) {
        unsigned long now = millis();
        if (now - lastReinit >= REINIT_INTERVAL) {
            lastReinit = now;
            initDisplay();
        }
        return;
    }

    if (!probeOLED()) {
        oledReady = false;
        Serial.println("OLED lost connection");
        display.begin(SSD1306_SWITCHCAPVCC, oledAddr);
        return;
    }

    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);

    display.setCursor(0, 0);
    display.println(line1.substring(0, 21));

    display.setCursor(0, 16);
    display.println(line2.substring(0, 21));

    display.setCursor(0, 32);
    display.println(line3.substring(0, 21));

    display.setCursor(0, 48);
    display.println(line4.substring(0, 21));

    display.display();
}

// ── Display Logic ───────────────────────────────────────────────────────────

static void buildOledLines(String& l1, String& l2, String& l3, String& l4) {
    if (WiFi.status() == WL_CONNECTED) {
        l1 = WiFi.SSID();
    } else {
        l1 = "No WiFi";
    }
    if (bleConnected) l1 += " [BLE]";

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
    updateOLEDDisplay(l1, l2, l3, l4);
}

void pushStatus(const String& msg) {
    lastMsg_local = msg;
    refreshOLED();
}

// ── Periodic Update ─────────────────────────────────────────────────────────

void handleDisplayUpdate() {
    unsigned long now = millis();
    if (now - lastOledUpdate >= OLED_UPDATE_INTERVAL) {
        lastOledUpdate = now;
        refreshOLED();
    }
}
