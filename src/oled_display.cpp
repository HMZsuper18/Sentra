#include "oled_display.h"

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
bool oledReady = false;

static uint8_t _oledAddr = 0;
static unsigned long _lastReinit = 0;
static const unsigned long REINIT_INTERVAL = 2000;

static bool _probeOLED() {
    if (_oledAddr == 0) return false;
    Wire.beginTransmission(_oledAddr);
    return Wire.endTransmission() == 0;
}

void initOLED() {
    Wire.begin(21, 22);
    delay(10);

    uint8_t addrs[] = {0x3C, 0x3D};
    for (int i = 0; i < 2; i++) {
        Wire.beginTransmission(addrs[i]);
        if (Wire.endTransmission() == 0) {
            if (display.begin(SSD1306_SWITCHCAPVCC, addrs[i])) {
                _oledAddr = addrs[i];
                oledReady = true;
                Serial.print("OLED found at 0x");
                Serial.println(_oledAddr, HEX);
                break;
            }
        }
    }

    if (!oledReady) {
        Serial.println("OLED not found on 0x3C or 0x3D");
        return;
    }

    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Sentra Booting...");
    display.display();
    Serial.println("OLED ready");
}

void updateOLED(const String& line1, const String& line2, const String& line3, const String& line4) {
    if (!oledReady) {
        unsigned long now = millis();
        if (now - _lastReinit >= REINIT_INTERVAL) {
            _lastReinit = now;
            initOLED();
        }
        return;
    }

    if (!_probeOLED()) {
        oledReady = false;
        Serial.println("OLED lost connection");
        display.begin(SSD1306_SWITCHCAPVCC, _oledAddr);
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
