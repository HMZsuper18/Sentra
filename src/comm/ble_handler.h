#ifndef BLE_HANDLER_H
#define BLE_HANDLER_H

#include <Arduino.h>

extern bool bleConnected;
extern String currentErrors;

void initBLE();
void updateBLEInfo();
void handleVoiceCommand(const String& cmd);

#endif
