# Clone Website to App Plan

## Overview

The website has been enhanced with features that should be mirrored back to the Flutter app for feature parity. This document outlines the plan to clone website features back to the mobile app.

## Current State Comparison

| Feature | Flutter App | Website |
|--------|------------|---------|
| Voice Input | speech_to_text | Web Speech API |
| Keyword Matching | ✓ | ✓ |
| Firebase Commands | ✓ | ✓ |
| LCD Status | ✓ | ✓ |
| Motor Status | ✓ | ✓ |
| Manual Controls | ✗ | ✓ |
| Visual Animations | Advanced | Basic |
| Arabic UI | ✓ | ✓ |

## Features to Add to Flutter App

### 1. Manual Controls (Priority: High)

**Current State:**
- App has NO manual control buttons
- Only voice control

**Website Implementation:**
- Grid layout with 5 buttons: يمين, شمال, قدام, ورا, وقف
- Touch-friendly sizing (48px+ tap targets)
- Visual feedback on press

**Plan:**
- [ ] Add manual control buttons to UI
- [ ] Implement `sendCommand()` function similar to website
- [ ] Add visual feedback (scale animation)
- [ ] Add haptic feedback on press
- [ ] Position below voice control section

**Implementation Location:**
- `app/lib/main.dart` around line 549 (build method)
- Add `_sendCommand()` method in `_SentraHomeState`

### 2. Enhanced Keyword Mapping (Priority: High)

**Current State:**
- App has limited keyword variants
- Website has expanding duplicate entries

**Plan:**
- [ ] Review keyword mappings in both apps
- [ ] Consolidate unique variants (remove duplicates)
- [ ] Ensure websites keywords cover all app keywords

**Files:**
- `app/lib/main.dart` lines 24-125 (`_keywordMap`)
- `website/index.html` lines 169-217 (`KEYWORD_MAP`)

### 3. Better Error Handling (Priority: Medium)

**Current State:**
- App handles limited errors (`_ignoredErrors`)
- Website shows "تم الرفض" on mic denial

**Plan:**
- [ ] Add timeout handling for voice recognition
- [ ] Show user-friendly messages for permissions
- [ ] Add offline indicator when no network

### 4. UI Enhancements (Priority: Medium)

**Current State:**
- App has particle effects but no manual controls

**Plan:**
- [ ] Add manual control section with consistent styling
- [ ] Add motor status indicators (on/off dots similar to website)
- [ ] Add LCD text display in current command area

**Existing UI in App:**
- Multiple animated orbs
- Ripple rings around mic
- Waveform bars
- Particle effects
- LCD-style display in center

### 5. Status Panel (Priority: Low)

**Current State:**
- App shows LCD in center and motor states in `_motorStates`

**Plan:**
- [ ] Add dedicated status panel section at bottom
- [ ] Show LCD and motor status together
- [ ] Use consistent glass-morphism styling

## Implementation Steps

### Step 1: Add Manual Control Buttons
```
Location: app/lib/main.dart ~line 549
Add after: _buildMainCard() or in the main Stack
```

New widget structure:
```dart
Widget _buildManualControls() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.12)),
    ),
    child: Column(
      children: [
        Text('التحكم اليدوي', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton('يمين', '→'),
            _buildControlButton('شمال', '←'),
            _buildControlButton('قدام', '↑'),
            _buildControlButton('ورا', '↓'),
          ],
        ),
        SizedBox(height: 8),
        _buildControlButton('وقف', '■', fullWidth: true),
      ],
    ),
  );
}
```

### Step 2: Add Command Sending Function
```dart
void _sendCommand(String command) {
  _sendToFirebase(command);
  setState(() {
    _keyword = command;
    _lcdText = command == 'وقف' ? 'Stopped' : 'CMD: $command';
  });
  _popCtrl.forward(from: 0);
}
```

### Step 3: Connect Buttons to State
```dart
Widget _buildControlButton(String label, String icon, {bool fullWidth = false}) {
  return GestureDetector(
    onTap: () => _sendCommand(label),
    child: Container(
      // styling similar to website .control-btn
    ),
  );
}
```

### Step 4: Add Motor Status Dots (Already exists in app)
The app already has motor state tracking in `_motorStates`. Verify display matches website:

- Active motor: cyan color (#38bdf8)
- Inactive: white with 20% opacity

## Files to Modify

```
app/
  └── lib/
      └── main.dart (main implementation)
```

## Testing Checklist

- [ ] Manual buttons appear and are tappable
- [ ] Tapping button sends command to Firebase
- [ ] Button shows visual feedback (animation)
- [ ] Motor status updates after command
- [ ] Keyword mapping works correctly
- [ ] App doesn't crash on voice timeout

## Firebase Integration

Already implemented in app:
- Command URL: `https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/command/word.json`
- Auth: `zuUhC4VNiO0quwQ3JlmtH6hLf2Lx8YvODFCCuZVC`
- Status URLs: lcd, motor1-4

No changes needed to Firebase integration.

## Dependencies

Current pubspec.yaml (no changes needed):
```yaml
dependencies:
  flutter:
    sdk: flutter
  speech_to_text: ^7.0.0
  http: ^1.2.1
  permission_handler: ^11.3.1
```

## Summary

The main feature to add to the Flutter app is **manual control buttons** to match the website's functionality. The app already has:
- Voice control (speech_to_text)
- Firebase integration
- Animated UI
- Motor status display

Adding manual buttons will complete the feature parity between website and app.