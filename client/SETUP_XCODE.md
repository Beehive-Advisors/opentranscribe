# Xcode Project Setup

Since you want to keep everything in the same directory, here's how to create the Xcode project and point it to the existing Swift files.

## Quick Setup

1. **Open Xcode** and create a new project:
   - File → New → Project
   - Choose "macOS" → "App"
   - Product Name: `OpenTranscribe`
   - Language: Swift
   - Interface: SwiftUI
   - **Important**: Save location should be `client/OpenTranscribe/` (where the Swift files already are)

2. **Replace the default files**:
   - Delete the default `ContentView.swift` and `OpenTranscribeApp.swift` that Xcode creates
   - The existing Swift files in `OpenTranscribe/OpenTranscribe/` will be automatically included

3. **Add existing files** (if not automatically detected):
   - Right-click on the project in Navigator
   - "Add Files to OpenTranscribe..."
   - Select all Swift files from `OpenTranscribe/OpenTranscribe/`
   - Make sure "Copy items if needed" is **unchecked** (to keep files in place)

4. **Configure Info.plist**:
   - The `Info.plist` is already in `OpenTranscribe/OpenTranscribe/Resources/`
   - Xcode should pick it up automatically, or add it manually

5. **Configure Capabilities**:
   - Select project → "Signing & Capabilities"
   - Add "App Sandbox"
   - Enable "Outgoing Connections (Client)"
   - Enable "Microphone" input

6. **Update Backend URL** (if needed):
   - Open `STTManager.swift`
   - Update `backendURL` if using a different endpoint

## File Structure

Your Xcode project should reference these files (already in place):

```
OpenTranscribe/
├── OpenTranscribe.xcodeproj/     # Xcode project (you'll create this)
└── OpenTranscribe/               # Source files (already exist)
    ├── AppDelegate.swift
    ├── ContentView.swift
    ├── Models/
    │   └── TranscriptionMessage.swift
    ├── Services/
    │   ├── STTManager.swift
    │   ├── AudioCaptureService.swift
    │   └── KeystrokeService.swift
    ├── Utils/
    │   └── AudioConverter.swift
    ├── ViewModels/
    │   └── TranscriptionViewModel.swift
    └── Resources/
        └── Info.plist
```

## Build & Run

1. Build: `Cmd+B`
2. Run: `Cmd+R`
3. Grant permissions when prompted:
   - Microphone permission
   - Accessibility permission (for typing)

## Notes

- All Swift files stay in `client/OpenTranscribe/OpenTranscribe/`
- Xcode project will be created in `client/OpenTranscribe/`
- No files need to be moved - everything stays in the same directory structure

