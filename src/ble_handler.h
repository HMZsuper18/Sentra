#ifndef BLE_HANDLER_H
#define BLE_HANDLER_H

class BLECharacteristic;

extern bool bleConnected;
extern String boardName;
extern String currentErrors;

void initBLE();
void updateBLEInfo();
void pushLCD(const String& msg);

#endif