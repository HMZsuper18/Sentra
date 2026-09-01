#include "control/command_parser.h"
#include "display/display.h"
#include "config.h"

unsigned long motorStopTime = 0;
bool motorRunning = false;
unsigned long lastCmdTime = 0;
String lastMotorState = "";

MoveStep moveQueue[MAX_QUEUE];
int moveQueueLen = 0;

// ── Queue ────────────────────────────────────────────────────────────────────

void pushMove(void (*action)(), unsigned long duration) {
    if (moveQueueLen >= MAX_QUEUE) return;
    moveQueue[moveQueueLen].action = action;
    moveQueue[moveQueueLen].duration = duration;
    moveQueueLen++;
}

void runNextMove() {
    if (moveQueueLen == 0) return;
    moveQueue[0].action();
    motorStopTime = millis() + moveQueue[0].duration;
    motorRunning = true;
    for (int i = 1; i < moveQueueLen; i++) {
        moveQueue[i - 1] = moveQueue[i];
    }
    moveQueueLen--;
}

bool hasQueuedMoves() {
    return moveQueueLen > 0;
}

void pushMotorStates() {
    const char* states[] = {"idle", "forward", "backward"};
    String s1 = states[(int)motorStates[0]];
    String s2 = states[(int)motorStates[1]];
    String s3 = states[(int)motorStates[2]];
    String s4 = states[(int)motorStates[3]];
    String current = s1 + s2 + s3 + s4;
    if (current != lastMotorState) {
        lastMotorState = current;
        refreshOLED();
    }
}

void handleMotorTimeout() {
    unsigned long now = millis();

    if (motorRunning && now >= motorStopTime) {
        stopMotors();
        motorRunning = false;
        pushMotorStates();
        if (hasQueuedMoves()) {
            runNextMove();
            pushMotorStates();
        } else {
            pushStatus("Ready");
        }
    }

    if (motorRunning && (now - lastCmdTime >= HEARTBEAT_TIMEOUT)) {
        stopMotors();
        motorRunning = false;
        moveQueueLen = 0;
        pushStatus("Timeout");
        pushMotorStates();
        Serial.println("Heartbeat timeout - motors stopped");
    }
}
