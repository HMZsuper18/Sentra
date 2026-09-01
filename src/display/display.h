#ifndef DISPLAY_H
#define DISPLAY_H

#include <Arduino.h>
#include <control/motor_driver.h>

void initDisplay();
void showBootScreen();
void pushStatus(const String& msg);
void refreshOLED();
void handleDisplayUpdate();

extern bool bleConnected;
extern String currentErrors;

#endif
