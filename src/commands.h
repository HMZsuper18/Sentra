#ifndef COMMANDS_H
#define COMMANDS_H

#include <Arduino.h>

extern unsigned long motorStopTime;
extern bool motorRunning;
extern unsigned long lastCmdTime;

struct MoveStep {
    void (*action)();
    unsigned long duration;
};

#define MAX_QUEUE 10

extern MoveStep moveQueue[MAX_QUEUE];
extern int moveQueueLen;

void executeCommand(const String& word);
void pushMotorStates();
bool hasQueuedMoves();
void runNextMove();

#endif
