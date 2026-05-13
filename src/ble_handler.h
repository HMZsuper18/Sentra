#ifndef BLE_HANDLER_H
#define BLE_HANDLER_H

#include <Arduino.h>

class BLECharacteristic;

extern bool bleConnected;
extern String boardName;
extern String currentErrors;

void initBLE();
void updateBLEInfo();
void pushLCD(const String& msg);

#endif