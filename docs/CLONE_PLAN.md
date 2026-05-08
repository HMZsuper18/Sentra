# Clone App to Website Plan

## Project Overview

This project consists of 3 main components:
1. **Mobile App** - Flutter voice-controlled robot controller
2. **Website** - Firebase-hosted web interface
3. **ESP32 Firmware** - Motor control hardware

## Architecture

```
┌─────────────┐     Firebase      ┌─────────────┐
│  Flutter    │ ─────────────────► │  Realtime   │
│  App        │     Database       │  Database   │
└─────────────┘                    └─────────────┘
                                          │
                                          ▼
                                   ┌─────────────┐
                                   │  ESP32      │
                                   │  Firmware   │
                                   └─────────────┘
```

## Current State

### 1. Mobile App (`app/`)
- **Framework**: Flutter 3.11.4+
- **Language**: Dart
- **Features**:
  - Voice input using `speech_to_text` package
  - Arabic voice commands recognition
  - Sends commands to Firebase Realtime Database
- **Dependencies**:
  - `speech_to_text: ^7.0.0`
  - `http: ^1.2.1`
  - `permission_handler: ^11.3.1`

### 2. Website (`website/`)
- **Platform**: Firebase Hosting
- **Type**: Static HTML/JS
- **Purpose**: Web interface to view/status and control robot

### 3. ESP32 Firmware (`src/`)
- **Language**: C++ (Arduino framework)
- **Platform**: PlatformIO
- **Controls**: 4 motors via ESP32

## Cloning Plan

### Option 1: Replicate Full App Functionality to Web

1. **Voice Input for Web**
   - Use Web Speech API (`SpeechRecognition`)
   - Fallback: Browser-based STT services

2. **Web App Structure**
   - Single-page web app using vanilla JS or React/Vue
   - Same Firebase backend integration
   - Same keyword mapping logic

3. **Implementation Steps**
   - [ ] Create web app in `website/app/` directory
   - [ ] Implement voice input using Web Speech API
   - [ ] Copy keyword mapping from `app/lib/main.dart`
   - [ ] Integrate Firebase SDK for web
   - [ ] Build and deploy

### Option 2: Website as Companion Interface

1. **Enhance Existing Website**
   - Add voice command input to existing `index.html`
   - Display real-time status from Firebase
   - Add manual controls as fallback

2. **Implementation Steps**
   - [ ] Modify `website/index.html` to include voice input
   - [ ] Add Firebase web SDK
   - [ ] Copy command logic from mobile app
   - [ ] Add status display panel

## Files to Create/Modify

### New Files
```
website/
  ├── app/
  │   ├── index.html
  │   ├── css/
  │   │   └── style.css
  │   ├── js/
  │   │   ├── app.js
  │   │   ├── firebase.js
  │   │   └── commands.js
  │   └── assets/
  │       └── noise.png
  └── docs/
      └── CLONE_PLAN.md (this file)
```

### Modified Files
- `website/index.html` - Update existing interface

## Voice Command Keywords

Current keywords from `app/lib/main.dart`:

| Command | Arabic Variants |
|---------|-----------------|
| يمين (Right) | 24 variants |
| شمال (Left) | 16 variants |
| قدام (Forward) | 16 variants |
| ورا (Backward) | 15 variants |
| توقف (Stop) | 17 variants |

## Firebase Configuration

Endpoints (from `app/lib/main.dart`):
- Command: `https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/command/word.json`
- Status LCD: `status/lcd.json`
- Status Motors: `status/motor1.json` - `status/motor4.json`

## Implementation Priority

1. **Phase 1**: Add voice input to existing website
2. **Phase 2**: Implement command processing
3. **Phase 3**: Add status display
4. **Phase 4**: Add manual controls
5. **Phase 5**: Test and deploy

## Tech Stack for Web Clone

- **Frontend**: Vanilla JS or React
- **Voice**: Web Speech API
- **Database**: Firebase Web SDK
- **Hosting**: Firebase Hosting (existing)

## Testing Checklist

- [ ] Voice input works in Chrome/Edge
- [ ] Commands sent to Firebase
- [ ] Status updates display correctly
- [ ] Fallback manual controls work
- [ ] Responsive design works on mobile
- [ ] Offline fallback behavior

## Notes

- Web Speech API has limited browser support (mainly Chrome/Edge)
- Consider adding cloud STT service for better cross-browser support
- Firebase credentials are hardcoded in app - consider using environment variables for web version