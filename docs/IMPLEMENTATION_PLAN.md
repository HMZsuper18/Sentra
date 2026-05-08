# Implementation Plan

## 1. App-Local Screen & Motor State

### Problem
Currently, the app fetches all state from the ESP32 board via Firebase. This creates unnecessary overhead and latency.

### Solution
Keep screen and motor states locally in the app, only sending commands to the board.

### Changes Required

#### Firebase Structure
```
/sentra/
  /command/       <- App writes commands here
    /word: "يمين"
  /status/        <- Board writes status here
    /sensors: {...}
    /timestamp: ...
```

#### App Changes
- Remove polling `/status/motors` from Firebase
- Remove polling `/status/lcd` from Firebase
- Store motor state locally in app memory
- Store screen state locally in app memory
- When user sends command, update local state immediately (optimistic update)
- Board sends motor status to Firebase only for logging/debugging, not required by app

#### ESP32 Changes
- Remove LCD updates to Firebase (optional, for debugging only)
- Keep sensor data to Firebase (required for app display)

---

## 2. Repeated Android Microphone Connect Sound

### Problem
Every time the app reconnects to Firebase or the speech recognition restarts, the Android system plays the "microphone connected" sound repeatedly.

### Possible Solutions

#### Option A: Suppress Sound via AudioManager (Android)
```kotlin
val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
```

#### Option B: Use Silent Audio Focus
Request audio focus with `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` which tells the system to lower other sounds rather than play feedback.

#### Option C: Check Connection State
Only initialize speech recognition when there's an actual need, not on every app resume.

#### Option D: Use EXCLUSIVE mode
Use `AudioManager.setMode(AudioManager.MODE_IN_COMMUNICATION)` to put the phone in call mode, which suppresses the microphone feedback sound.

### Recommended Approach
Implement **Option D + Option C**:
1. Set audio mode to `MODE_IN_COMMUNICATION` when speech recognition starts
2. Track connection state and only restart speech recognition when transitioning from disconnected to connected
3. Add debounce/throttle on speech recognition restarts

### Implementation Steps

1. **Audio Mode Management**
   - Add `AudioManager` initialization in SpeechRecognitionService
   - Set mode to `MODE_IN_COMMUNICATION` on start
   - Reset to `MODE_NORMAL` on stop

2. **Connection State Tracking**
   - Add boolean flag `isSpeechRecognitionActive`
   - Only start speech recognition if not already active
   - Add minimum delay between restarts (e.g., 2 seconds)

3. **Lifecycle Handling**
   - Properly handle `onDestroy` to release audio resources
   - Ensure audio mode is reset even if app crashes

---

## Summary

| Task | Priority | Effort |
|------|----------|--------|
| Remove motors/lcd polling from app | High | Medium |
| Add local state management | High | Medium |
| Fix microphone connect sound | Medium | Low |
| Test Firebase data flow | High | Low |

---

## Files to Modify

- `app/src/main/kotlin/.../MainActivity.kt` - Remove Firebase listeners for motors/lcd
- `app/src/main/kotlin/.../SpeechRecognitionService.kt` - Add audio mode handling
- `src/esp32_main.cpp` - Remove LCD push to Firebase (optional)