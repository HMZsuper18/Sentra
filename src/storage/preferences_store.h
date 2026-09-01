#ifndef PREFERENCES_STORE_H
#define PREFERENCES_STORE_H

#include <Arduino.h>

void initPreferences();

String getBoardName();
void setBoardName(const String& name);

String getStoredSsid();
void setStoredSsid(const String& ssid);

String getStoredPassword();
void setStoredPassword(const String& password);

#endif
