# OpenTranscribe

Real-time speech-to-text transcription system that enables users to speak and have text appear wherever their cursor is on macOS.

## Features

- 🎤 **Real-time Audio Capture**: Captures microphone audio using AVAudioEngine
- 🔄 **WebSocket Streaming**: Streams audio to backend for processing
- 🧠 **GPU-Powered Transcription**: Uses faster-whisper turbo model on NVIDIA GPU
- ⌨️ **Automatic Typing**: Types transcriptions directly into active applications
- 🚀 **Kubernetes Deployment**: Scalable backend deployment with GPU support

## Architecture

```
macOS Client (Swift) → WebSocket → Backend (FastAPI + RealtimeSTT) → GPU (faster-whisper turbo)
```

### Components

- **Backend**: FastAPI WebSocket service with RealtimeSTT + faster-whisper turbo
- **Client**: Native macOS app (Swift/SwiftUI)
- **Infrastructure**: Kubernetes deployment with NVIDIA GPU support

## Quick Start

### Prerequisites

- Kubernetes cluster with NVIDIA GPU Operator
- DockerHub account
- macOS 12.0+ (for client)
- Python 3.11 (for backend development)

### Backend Deployment

1. **Configure GitHub Secrets**:
   - `DOCKERHUB_USERNAME`: Your DockerHub username
   - `DOCKERHUB_TOKEN`: DockerHub Personal Access Token

2. **Update Kubernetes Manifests**:
   ```bash
   # Edit k8s/backend/deployment.yaml
   # Replace YOUR-DOCKERHUB-USERNAME with your DockerHub username
   ```

3. **Deploy**:
   ```bash
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/backend/
   kubectl apply -f k8s/ingress/
   ```

4. **Verify**:
   ```bash
   kubectl get pods -n opentranscribe
   kubectl logs -n opentranscribe -l app=opentranscribe-backend
   ```

### Client Setup

1. **Open Xcode Project**:
   ```bash
   cd client/OpenTranscribe
   open OpenTranscribe.xcodeproj
   ```

2. **Configure Backend URL**:
   - Update `STTManager.swift` with your backend URL
   - For local: `ws://localhost:8000/stream`
   - For production: `wss://stt.beehive-advisors.com/stream`

3. **Build & Run**:
   - Build: `Cmd+B`
   - Run: `Cmd+R`
   - Grant microphone and accessibility permissions

## Project Structure

```
opentranscribe/
├── backend/              # FastAPI WebSocket backend
│   ├── app/              # Application code
│   ├── tests/            # Test suite
│   ├── scripts/          # Utility scripts
│   └── Dockerfile        # Container definition
├── client/               # macOS client application
│   └── OpenTranscribe/   # Xcode project
├── k8s/                  # Kubernetes manifests
│   ├── backend/          # Backend deployment
│   └── ingress/          # NGINX ingress
├── .github/workflows/    # CI/CD pipelines
└── docs/                 # Documentation
```

## Documentation

### User Guides
- [Architecture](docs/architecture.md) - System architecture and design
- [Deployment](docs/deployment.md) - Kubernetes deployment guide
- [Development](docs/development.md) - Local development setup

### Planning & Implementation
Planning documents are in `docs/planning/` numbered chronologically:
- [01-plan.md](docs/planning/01-plan.md) - Original implementation plan
- [02-dockerhub-setup.md](docs/planning/02-dockerhub-setup.md) - CI/CD pipeline setup
- [03-monorepo-structure.md](docs/planning/03-monorepo-structure.md) - Repository organization
- [04-monorepo-design.md](docs/planning/04-monorepo-design.md) - Design decisions
- [05-16](docs/planning/) - Implementation and troubleshooting notes

## Technology Stack

### Backend
- **Framework**: FastAPI
- **STT**: RealtimeSTT + faster-whisper
- **Model**: Whisper turbo (large-v3-turbo)
- **GPU**: CUDA 12.3 + cuDNN 9, PyTorch 2.5.1+cu121
- **Base Image**: `nvidia/cuda:12.3.2-cudnn9-runtime-ubuntu22.04`

### Client
- **Language**: Swift
- **Framework**: SwiftUI
- **Audio**: AVAudioEngine + AVAudioConverter
- **Networking**: URLSessionWebSocketTask
- **Keystrokes**: CGEvent APIs

### Infrastructure
- **Orchestration**: Kubernetes (k3s)
- **Ingress**: NGINX Ingress Controller
- **GPU**: NVIDIA GPU Operator
- **CI/CD**: GitHub Actions + ARC (Actions Runner Controller)
- **Registry**: DockerHub

## Development

### Backend Development

```bash
cd backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Client Development

1. Open `client/OpenTranscribe/OpenTranscribe.xcodeproj` in Xcode
2. Build and run (`Cmd+R`)
3. Grant permissions when prompted

## Testing

### Backend Tests

```bash
cd backend

# GPU validation
python scripts/test_local_gpu.py

# RealtimeSTT integration
python scripts/test_realtime_stt.py
```

### End-to-End Test

1. Start backend (local or deployed)
2. Launch macOS client
3. Click "Start Transcription"
4. Speak into microphone
5. Verify text appears in app and types into active application

## CI/CD

The project uses GitHub Actions with self-hosted Kubernetes runners:

- **Workflow**: `.github/workflows/backend-build.yml`
- **Runner**: `arc-runner-set` (self-hosted Kubernetes)
- **Registry**: DockerHub
- **Auto-deploy**: Updates Kubernetes manifests with new image tags

## Configuration

### Backend Environment Variables

- `MODEL`: Whisper model (default: `"turbo"`)
- `DEVICE`: Device (default: `"cuda"`)
- `COMPUTE_TYPE`: Compute type (default: `"float16"`)
- `LOG_LEVEL`: Logging level (default: `"INFO"`)

### Client Configuration

- Backend URL: Update `STTManager.swift`
- Permissions: Configured in `Info.plist`

## Troubleshooting

### Backend Issues

- **GPU not allocated**: Check GPU Operator installation
- **Model loading fails**: Verify CUDA/cuDNN versions
- **WebSocket errors**: Check ingress annotations

### Client Issues

- **No audio captured**: Check microphone permission
- **Text not typing**: Check Accessibility permission
- **Connection fails**: Verify backend URL and network

See [Deployment Guide](docs/deployment.md) for detailed troubleshooting.

## License

Internal use only.

## Contributing

1. Create feature branch
2. Make changes
3. Test locally
4. Submit pull request

## References

- [Implementation Plan](docs/planning/01-plan.md) - Detailed implementation plan
- [CI/CD Setup](docs/planning/02-dockerhub-setup.md) - CI/CD pipeline configuration
- [RealtimeSTT](https://github.com/KoljaB/RealtimeSTT) - STT library
- [faster-whisper](https://github.com/guillaumekln/faster-whisper) - Whisper implementation
