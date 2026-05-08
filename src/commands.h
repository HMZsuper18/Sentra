#ifndef COMMANDS_H
#define COMMANDS_H

#include <Arduino.h>

extern unsigned long motorStopTime;
extern bool motorRunning;
extern unsigned long lastCmdTime;

void executeCommand(const String& word);
void pushMotorStates();

#endif