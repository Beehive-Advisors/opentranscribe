# OpenTranscribe macOS Client

Native macOS application for real-time speech-to-text transcription.

## Features

- Real-time microphone audio capture
- WebSocket streaming to backend
- Live transcription display
- Automatic text typing into active application

## Requirements

- macOS 12.0 or later
- Xcode 14.0 or later
- Microphone permission
- Accessibility permission (for typing)

## Setup

### Create Xcode Project

1. Open Xcode
2. Create new project → macOS → App
3. Product Name: `OpenTranscribe`
4. Language: Swift
5. Interface: SwiftUI
6. Save to: `client/OpenTranscribe/`

### Add Source Files

Copy all Swift files from `OpenTranscribe/OpenTranscribe/` into your Xcode project:

- `Models/TranscriptionMessage.swift`
- `Services/STTManager.swift`
- `Services/AudioCaptureService.swift`
- `Services/KeystrokeService.swift`
- `Utils/AudioConverter.swift`
- `ViewModels/TranscriptionViewModel.swift`
- `ContentView.swift`
- `AppDelegate.swift`

### Configure Info.plist

Add microphone usage description (already in `Resources/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>OpenTranscribe needs microphone access to capture audio for transcription.</string>
```

### Configure Backend URL

Update `STTManager.swift` with your backend URL:

```swift
private let backendURL = "wss://stt.beehive-advisors.com/stream"
// For local testing: "ws://localhost:8000/stream"
```

### Enable Capabilities

1. Select project in Xcode
2. Go to "Signing & Capabilities"
3. Add "App Sandbox" capability
4. Enable "Outgoing Connections (Client)"
5. Enable "Microphone" input

## Build & Run

1. Build: `Cmd+B`
2. Run: `Cmd+R`

## Permissions

On first run, the app will request:
1. **Microphone Permission**: Required for audio capture
2. **Accessibility Permission**: Required for typing text into other apps
   - Go to System Settings → Privacy & Security → Accessibility
   - Enable OpenTranscribe

## Usage

1. Launch the app
2. Click "Start Transcription"
3. Grant permissions when prompted
4. Start speaking
5. Text will appear in the app window and be typed into the active application

## Architecture

- **STTManager**: WebSocket client for backend communication
- **AudioCaptureService**: AVAudioEngine wrapper for microphone capture
- **AudioConverter**: Converts audio to 16kHz mono PCM
- **KeystrokeService**: CGEvent-based keyboard synthesis
- **TranscriptionViewModel**: State management and coordination

## Troubleshooting

### WebSocket Connection Fails

- Check backend URL in `STTManager.swift`
- Verify backend is running and accessible
- Check network connectivity

### No Audio Captured

- Verify microphone permission is granted
- Check System Settings → Privacy & Security → Microphone
- Ensure microphone is not muted

### Text Not Typing

- Verify Accessibility permission is granted
- Check System Settings → Privacy & Security → Accessibility
- Ensure OpenTranscribe is enabled

### Audio Quality Issues

- Check microphone input level
- Verify audio format conversion (should be 16kHz mono PCM)
- Check backend logs for audio processing errors

