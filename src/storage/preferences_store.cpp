#include "storage/preferences_store.h"
#include <Preferences.h>

static Preferences preferences;

void initPreferences() {
    preferences.begin("sentra", false);
}

String getBoardName() {
    return preferences.getString("boardname", "Sentra_Board");
}

void setBoardName(const String& name) {
    preferences.putString("boardname", name);
}

String getStoredSsid() {
    return preferences.getString("ssid", "");
}

void setStoredSsid(const String& ssid) {
    preferences.putString("ssid", ssid);
}

String getStoredPassword() {
    return preferences.getString("password", "");
}

void setStoredPassword(const String& password) {
    preferences.putString("password", password);
}
