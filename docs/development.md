# Development Guide

This guide covers setting up a local development environment for OpenTranscribe.

## Prerequisites

### Backend Development

- Python 3.11
- CUDA-capable GPU (for local GPU testing)
- CUDA 12.x drivers
- Docker (for containerized testing)

### Client Development

- macOS 12.0+
- Xcode 14.0+
- Swift 5.7+

## Backend Development

### Step 1: Local GPU Validation

**Goal**: Verify faster-whisper turbo runs on your GPU before Docker/K8s.

```bash
cd backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On macOS/Linux
# venv\Scripts\activate  # On Windows

# Install PyTorch with CUDA support
pip install torch==2.5.1+cu121 torchaudio==2.5.1 \
  --index-url https://download.pytorch.org/whl/cu121

# Install CUDA libraries and faster-whisper
pip install nvidia-cublas-cu12 nvidia-cudnn-cu12==9.* faster-whisper

# Run GPU validation test
python scripts/test_local_gpu.py
```

**Expected output**:
```
✅ CUDA is available
   Device: NVIDIA GeForce RTX 4090
   CUDA Version: 12.1
✅ Model loaded successfully
✅ GPU validation complete
```

### Step 2: RealtimeSTT Integration

```bash
# Install RealtimeSTT and web dependencies
pip install RealtimeSTT fastapi uvicorn[standard] websockets

# Run RealtimeSTT integration test
python scripts/test_realtime_stt.py
```

### Step 3: Run Backend Locally

```bash
# Install all dependencies
pip install -r requirements.txt

# Run FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Test endpoints**:
- Health: `http://localhost:8000/health`
- WebSocket: `ws://localhost:8000/stream`

### Step 4: Test WebSocket Locally

Create `test_websocket.py`:

```python
import asyncio
import websockets
import json

async def test():
    uri = "ws://localhost:8000/stream"
    async with websockets.connect(uri) as websocket:
        # Send dummy PCM audio (silence)
        test_audio = b'\x00' * 3200  # 0.1s at 16kHz
        await websocket.send(test_audio)
        
        # Receive transcription
        response = await websocket.recv()
        print(json.loads(response))

asyncio.run(test())
```

### Step 5: Docker Build & Test

```bash
cd backend

# Build Docker image
docker build -t opentranscribe-backend:local .

# Run with GPU support
docker run --gpus all -p 8000:8000 opentranscribe-backend:local

# Test
curl http://localhost:8000/health
```

## Client Development

### Step 1: Create Xcode Project

1. Open Xcode
2. Create new project → macOS → App
3. Product Name: `OpenTranscribe`
4. Language: Swift
5. Interface: SwiftUI
6. Save to: `client/OpenTranscribe/`

### Step 2: Add Source Files

Copy all Swift files from `OpenTranscribe/OpenTranscribe/` into your Xcode project:

- `Models/TranscriptionMessage.swift`
- `Services/STTManager.swift`
- `Services/AudioCaptureService.swift`
- `Services/KeystrokeService.swift`
- `Utils/AudioConverter.swift`
- `ViewModels/TranscriptionViewModel.swift`
- `ContentView.swift`
- `AppDelegate.swift`

### Step 3: Configure Info.plist

Add microphone usage description:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>OpenTranscribe needs microphone access to capture audio for transcription.</string>
```

### Step 4: Configure Backend URL

Update `STTManager.swift`:

```swift
// For local development
private let backendURL = "ws://localhost:8000/stream"

// For production
// private let backendURL = "wss://stt.beehive-advisors.com/stream"
```

### Step 5: Enable Capabilities

1. Select project in Xcode
2. Go to "Signing & Capabilities"
3. Add "App Sandbox" capability
4. Enable "Outgoing Connections (Client)"
5. Enable "Microphone" input

### Step 6: Build & Run

1. Build: `Cmd+B`
2. Run: `Cmd+R`
3. Grant permissions when prompted:
   - Microphone permission
   - Accessibility permission (for typing)

## Testing

### Backend Tests

```bash
cd backend

# Run tests (when implemented)
pytest tests/

# Run specific test
pytest tests/test_websocket.py
```

### Client Tests

1. Open Xcode project
2. Run tests: `Cmd+U`
3. Or use Test Navigator: `Cmd+6`

## Debugging

### Backend Debugging

**View logs**:
```bash
# Local development
uvicorn main:app --log-level debug

# Kubernetes
kubectl logs -n opentranscribe -l app=opentranscribe-backend -f
```

**Common issues**:
- GPU not available: Check CUDA installation
- Model loading fails: Verify faster-whisper installation
- WebSocket errors: Check connection and protocol

### Client Debugging

**Xcode Debugger**:
- Set breakpoints: Click line number
- View variables: Debug area (`Cmd+Shift+Y`)
- Console output: Debug area

**Common issues**:
- WebSocket connection fails: Check backend URL and network
- No audio captured: Check microphone permission
- Text not typing: Check Accessibility permission

## Code Style

### Python (Backend)

- Follow PEP 8
- Use type hints
- Docstrings for functions/classes
- Maximum line length: 100 characters

### Swift (Client)

- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Document public APIs
- Maximum line length: 100 characters

## Project Structure

```
opentranscribe/
├── backend/
│   ├── app/              # Application code
│   ├── tests/            # Test suite
│   ├── scripts/          # Utility scripts
│   ├── Dockerfile        # Container definition
│   └── requirements.txt  # Python dependencies
├── client/
│   └── OpenTranscribe/   # Xcode project
├── k8s/                  # Kubernetes manifests
└── docs/                 # Documentation
```

## Contributing

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes
3. Test locally
4. Commit: `git commit -m "Add feature"`
5. Push: `git push origin feature/my-feature`
6. Create pull request

## Resources

- [FastAPI WebSocket Docs](https://fastapi.tiangolo.com/advanced/websockets/)
- [RealtimeSTT Docs](https://github.com/KoljaB/RealtimeSTT)
- [faster-whisper Docs](https://github.com/guillaumekln/faster-whisper)
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui/)
- [AVAudioEngine Docs](https://developer.apple.com/documentation/avfaudio/avaudioengine)

