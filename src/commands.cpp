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

void executeCommand(const String& word) {
    lastCmdTime = millis();

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
    } else {
        pushLCD(word);
    }
    pushMotorStates();
}