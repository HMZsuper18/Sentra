#ifndef MOTORS_H
#define MOTORS_H

// ── Pin definitions ──────────────────────────────────────────────────────────
#define IN1 14
#define IN2 27
#define IN3 26
#define IN4 25

// ── Motor states ─────────────────────────────────────────────────────────────
enum MotorState { MOTOR_IDLE, MOTOR_FORWARD, MOTOR_BACKWARD };
MotorState motorStates[4] = {MOTOR_IDLE, MOTOR_IDLE, MOTOR_IDLE, MOTOR_IDLE};

// ── Init ─────────────────────────────────────────────────────────────────────
void initMotors() {
    const uint8_t pins[] = {IN1, IN2, IN3, IN4};
    for (uint8_t p : pins) { pinMode(p, OUTPUT); digitalWrite(p, LOW); }
}

// ── Direction control ─────────────────────────────────────────────────────────
// Left motor: IN1/IN2  |  Right motor: IN3/IN4
void moveForward()  {
    digitalWrite(IN1,HIGH); digitalWrite(IN2,LOW);
    digitalWrite(IN3,HIGH); digitalWrite(IN4,LOW);
    motorStates[0] = MOTOR_FORWARD;
    motorStates[1] = MOTOR_FORWARD;
    motorStates[2] = MOTOR_FORWARD;
    motorStates[3] = MOTOR_FORWARD;
}
void moveBackward() {
    digitalWrite(IN1,LOW);  digitalWrite(IN2,HIGH);
    digitalWrite(IN3,LOW); digitalWrite(IN4,HIGH);
    motorStates[0] = MOTOR_BACKWARD;
    motorStates[1] = MOTOR_BACKWARD;
    motorStates[2] = MOTOR_BACKWARD;
    motorStates[3] = MOTOR_BACKWARD;
}
void turnLeft()     {
    digitalWrite(IN1,LOW);  digitalWrite(IN2,HIGH);
    digitalWrite(IN3,HIGH); digitalWrite(IN4,LOW);
    motorStates[0] = MOTOR_BACKWARD;
    motorStates[1] = MOTOR_BACKWARD;
    motorStates[2] = MOTOR_FORWARD;
    motorStates[3] = MOTOR_FORWARD;
}
void turnRight()    {
    digitalWrite(IN1,HIGH); digitalWrite(IN2,LOW);
    digitalWrite(IN3,LOW);  digitalWrite(IN4,HIGH);
    motorStates[0] = MOTOR_FORWARD;
    motorStates[1] = MOTOR_FORWARD;
    motorStates[2] = MOTOR_BACKWARD;
    motorStates[3] = MOTOR_BACKWARD;
}
void stopMotors()   {
    digitalWrite(IN1,LOW); digitalWrite(IN2,LOW);
    digitalWrite(IN3,LOW); digitalWrite(IN4,LOW);
    motorStates[0] = MOTOR_IDLE;
    motorStates[1] = MOTOR_IDLE;
    motorStates[2] = MOTOR_IDLE;
    motorStates[3] = MOTOR_IDLE;
}

#endif