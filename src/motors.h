#ifndef MOTORS_H
#define MOTORS_H

// ── Pin definitions ──────────────────────────────────────────────────────────
#define IN1 14
#define IN2 27
#define IN3 26
#define IN4 25

// ── Motor states ─────────────────────────────────────────────────────────────
enum MotorState { MOTOR_IDLE, MOTOR_FORWARD, MOTOR_BACKWARD };
extern MotorState motorStates[4];

// ── Functions ─────────────────────────────────────────────────────────────────
void initMotors();
void moveForward();
void moveBackward();
void turnLeft();
void turnRight();
void stopMotors();

#endif