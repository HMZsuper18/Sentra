#include "control/motor_driver.h"
#include <Arduino.h>

MotorState motorStates[4] = {MOTOR_IDLE, MOTOR_IDLE, MOTOR_IDLE, MOTOR_IDLE};

void initMotors() {
    const uint8_t pins[] = {IN1, IN2, IN3, IN4};
    for (uint8_t i = 0; i < 4; i++) {
        pinMode(pins[i], OUTPUT);
        digitalWrite(pins[i], LOW);
    }
}

void moveForward() {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, LOW);
    digitalWrite(IN3, HIGH);
    digitalWrite(IN4, LOW);
    motorStates[0] = MOTOR_FORWARD;
    motorStates[1] = MOTOR_FORWARD;
    motorStates[2] = MOTOR_FORWARD;
    motorStates[3] = MOTOR_FORWARD;
}

void moveBackward() {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, HIGH);
    motorStates[0] = MOTOR_BACKWARD;
    motorStates[1] = MOTOR_BACKWARD;
    motorStates[2] = MOTOR_BACKWARD;
    motorStates[3] = MOTOR_BACKWARD;
}

void turnLeft() {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);
    digitalWrite(IN3, HIGH);
    digitalWrite(IN4, LOW);
    motorStates[0] = MOTOR_BACKWARD;
    motorStates[1] = MOTOR_BACKWARD;
    motorStates[2] = MOTOR_FORWARD;
    motorStates[3] = MOTOR_FORWARD;
}

void turnRight() {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, LOW);
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, HIGH);
    motorStates[0] = MOTOR_FORWARD;
    motorStates[1] = MOTOR_FORWARD;
    motorStates[2] = MOTOR_BACKWARD;
    motorStates[3] = MOTOR_BACKWARD;
}

void stopMotors() {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
    motorStates[0] = MOTOR_IDLE;
    motorStates[1] = MOTOR_IDLE;
    motorStates[2] = MOTOR_IDLE;
    motorStates[3] = MOTOR_IDLE;
}
