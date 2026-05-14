#include "commands.h"
#include "motors.h"
#include "ble_handler.h"
#include "config.h"
#include <FirebaseESP32.h>
#include <ArduinoJson.h>

extern FirebaseData fbdo;
extern String lastMotorState;

void pushLCD(const String& msg);
void refreshOLED();

MoveStep moveQueue[MAX_QUEUE];
int moveQueueLen = 0;

static void _pushMove(void (*action)(), unsigned long duration) {
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

static int _parseDuration(const String& s) {
    int num = 0;
    for (unsigned int i = 0; i < s.length(); i++) {
        if (s[i] >= '0' && s[i] <= '9') {
            num = num * 10 + (s[i] - '0');
        }
    }
    if (num > 0) return num * 1000;
    return 0;
}

static String _trim(const String& s) {
    int start = 0, end = s.length() - 1;
    while (start <= end && s[start] == ' ') start++;
    while (end >= start && s[end] == ' ') end--;
    if (start > end) return "";
    return s.substring(start, end + 1);
}

static void _parseAndQueue(const String& part) {
    String p = _trim(part);
    if (p.isEmpty()) return;

    unsigned long dur = _parseDuration(p);
    if (dur == 0) dur = MOTOR_DURATION_MOVE;

    if (p.indexOf("يمين") >= 0 || p.indexOf("يميناً") >= 0) {
        _pushMove(turnRight, dur == MOTOR_DURATION_MOVE ? MOTOR_DURATION_TURN : dur);
    } else if (p.indexOf("شمال") >= 0 || p.indexOf("يسار") >= 0) {
        _pushMove(turnLeft, dur == MOTOR_DURATION_MOVE ? MOTOR_DURATION_TURN : dur);
    } else if (p.indexOf("قدام") >= 0 || p.indexOf("تقدم") >= 0 || p.indexOf("امام") >= 0) {
        _pushMove(moveForward, dur);
    } else if (p.indexOf("ورا") >= 0 || p.indexOf("للخلف") >= 0 || p.indexOf("تراجع") >= 0 || p.indexOf("الخلف") >= 0) {
        _pushMove(moveBackward, dur);
    }
}

static bool _isKnown(const String& word) {
    if (word == "يمين" || word == "اتجه يمين" || word == "يميناً") return true;
    if (word == "شمال" || word == "اتجه شمال" || word == "يسار") return true;
    if (word == "قدام" || word == "تقدم" || word == "امام" || word == "الأمام") return true;
    if (word == "ورا" || word == "للخلف" || word == "تراجع" || word == "الخلف") return true;
    if (word == "وقف" || word == "توقف" || word == "استنى" || word == "قف") return true;
    return false;
}

void executeCommand(const String& word) {
    lastCmdTime = millis();

    if (_isKnown(word)) {
        if (word == "يمين" || word == "اتجه يمين" || word == "يميناً") {
            turnRight();
            motorStopTime = millis() + MOTOR_DURATION_TURN;
            motorRunning = true;
            pushLCD("يمين");
        } else if (word == "شمال" || word == "اتجه شمال" || word == "يسار") {
            turnLeft();
            motorStopTime = millis() + MOTOR_DURATION_TURN;
            motorRunning = true;
            pushLCD("شمال");
        } else if (word == "قدام" || word == "تقدم" || word == "امام" || word == "الأمام") {
            moveForward();
            motorStopTime = millis() + MOTOR_DURATION_MOVE;
            motorRunning = true;
            pushLCD("قدام");
        } else if (word == "ورا" || word == "للخلف" || word == "تراجع" || word == "الخلف") {
            moveBackward();
            motorStopTime = millis() + MOTOR_DURATION_MOVE;
            motorRunning = true;
            pushLCD("ورا");
        } else if (word == "وقف" || word == "توقف" || word == "استنى" || word == "قف") {
            stopMotors();
            motorRunning = false;
            pushLCD("Stopped");
        }
        pushMotorStates();
        return;
    }

    moveQueueLen = 0;

    String w = word;
    w.replace("و", "ف");

    int start = 0;
    while (true) {
        int idx = w.indexOf("ف", start);
        String part;
        if (idx < 0) {
            part = w.substring(start);
        } else {
            part = w.substring(start, idx);
        }
        if (part.length() > 0) {
            _parseAndQueue(part);
        }
        if (idx < 0) break;
        start = idx + 1;
    }

    if (moveQueueLen > 0) {
        runNextMove();
        pushLCD("Sequence");
    }
    pushMotorStates();
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
        if (Firebase.ready()) {
            Firebase.setString(fbdo, "/status/motor1", s1);
            Firebase.setString(fbdo, "/status/motor2", s2);
            Firebase.setString(fbdo, "/status/motor3", s3);
            Firebase.setString(fbdo, "/status/motor4", s4);
        }
        refreshOLED();
    }
}
