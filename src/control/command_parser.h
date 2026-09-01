#ifndef COMMAND_PARSER_H
#define COMMAND_PARSER_H

#include <Arduino.h>
#include <control/motor_driver.h>

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

void pushMotorStates();
bool hasQueuedMoves();
void runNextMove();
void handleMotorTimeout();
void pushMove(void (*action)(), unsigned long duration);

#endif
