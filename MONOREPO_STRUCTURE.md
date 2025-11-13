# OpenTranscribe Monorepo Structure

## Overview

This document outlines the monorepo structure for OpenTranscribe, a real-time speech-to-text transcription system that enables users to speak and have text appear wherever their cursor is on macOS.

## Architecture Summary

- **Backend**: FastAPI WebSocket service with RealtimeSTT + faster-whisper turbo running on Kubernetes GPU nodes
- **Client**: Native macOS app (Swift) that captures audio, streams to backend, and types transcriptions
- **Infrastructure**: Kubernetes deployment with NVIDIA GPU support, NGINX ingress
- **CI/CD**: GitHub Actions with self-hosted Kubernetes runners (ARC), Docker builds, DockerHub registry

## Monorepo Structure

```
opentranscribe/
├── README.md                          # Main project documentation
├── plan.md                            # Implementation plan (existing)
├── dockerhub-setup.md                 # CI/CD setup guide (existing)
├── MONOREPO_STRUCTURE.md              # This file
│
├── .github/
│   └── workflows/
│       ├── backend-build.yml          # Backend Docker build & push
│       └── client-build.yml           # macOS client build (optional)
│
├── backend/                           # FastAPI WebSocket STT service
│   ├── Dockerfile                     # CUDA 12.3 + cuDNN 9 base image
│   ├── requirements.txt               # Python dependencies
│   ├── .dockerignore
│   ├── main.py                        # FastAPI app entry point
│   ├── app/
│   │   ├── __init__.py
│   │   ├── websocket.py               # WebSocket endpoint handler
│   │   ├── stt.py                     # RealtimeSTT integration
│   │   └── config.py                  # Configuration management
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── test_websocket.py          # WebSocket tests
│   │   └── test_stt.py                # STT integration tests
│   └── scripts/
│       ├── test_local_gpu.py          # Local GPU validation script
│       └── test_realtime_stt.py       # RealtimeSTT integration test
│
├── client/                            # macOS native application
│   ├── OpenTranscribe/                # Xcode project root
│   │   ├── OpenTranscribe.xcodeproj/
│   │   ├── OpenTranscribe/
│   │   │   ├── AppDelegate.swift      # App lifecycle
│   │   │   ├── ContentView.swift      # Main UI
│   │   │   ├── ViewModels/
│   │   │   │   ├── TranscriptionViewModel.swift
│   │   │   │   └── AudioCaptureViewModel.swift
│   │   │   ├── Services/
│   │   │   │   ├── STTManager.swift   # WebSocket client
│   │   │   │   ├── AudioCaptureService.swift  # AVAudioEngine wrapper
│   │   │   │   └── KeystrokeService.swift     # CGEvent keyboard typing
│   │   │   ├── Models/
│   │   │   │   └── TranscriptionMessage.swift
│   │   │   ├── Utils/
│   │   │   │   └── AudioConverter.swift       # 44.1k → 16k mono conversion
│   │   │   └── Resources/
│   │   │       ├── Info.plist
│   │   │       └── Assets.xcassets
│   │   └── OpenTranscribeTests/
│   │       └── OpenTranscribeTests.swift
│   └── README.md                      # Client setup instructions
│
├── k8s/                               # Kubernetes manifests
│   ├── namespace.yaml                 # Namespace definition
│   ├── backend/
│   │   ├── deployment.yaml            # Backend deployment with GPU
│   │   ├── service.yaml               # ClusterIP service
│   │   └── configmap.yaml             # Configuration (optional)
│   ├── ingress/
│   │   └── ingress.yaml               # NGINX ingress with WebSocket support
│   └── README.md                      # Deployment instructions
│
├── docs/                              # Additional documentation
│   ├── architecture.md                # System architecture details
│   ├── deployment.md                  # Deployment guide
│   └── development.md                 # Development setup guide
│
└── upstream/                          # Reference only (not for execution)
    └── ...                            # Existing reference code
```

## Component Details

### Backend (`backend/`)

**Purpose**: FastAPI WebSocket service that receives PCM audio chunks and returns real-time transcriptions.

**Key Files**:
- `main.py`: FastAPI application with WebSocket endpoint at `/stream`
- `app/websocket.py`: WebSocket connection handler, manages RealtimeSTT instances per connection
- `app/stt.py`: RealtimeSTT wrapper with faster-whisper turbo backend
- `app/config.py`: Environment-based configuration (model, device, compute_type)

**Dependencies**:
- FastAPI + uvicorn[standard]
- RealtimeSTT
- faster-whisper
- PyTorch 2.5.1+cu121
- nvidia-cublas-cu12, nvidia-cudnn-cu12==9.*

**Docker Base Image**: `nvidia/cuda:12.3.2-cudnn9-runtime-ubuntu22.04`

**Port**: 8000

### Client (`client/`)

**Purpose**: Native macOS application that captures microphone audio, streams to backend, and types transcriptions.

**Key Components**:
- `STTManager`: WebSocket client using URLSessionWebSocketTask
- `AudioCaptureService`: AVAudioEngine wrapper for microphone capture
- `AudioConverter`: AVAudioConverter for 44.1k stereo → 16k mono PCM
- `KeystrokeService`: CGEvent-based keyboard event synthesis
- `TranscriptionViewModel`: State management (committedText, interim text)

**Requirements**:
- macOS 12.0+ (for URLSessionWebSocketTask)
- Accessibility permission (for keystroke synthesis)
- Microphone permission

**Build**: Xcode project, can be built with `xcodebuild` or Xcode IDE

### Kubernetes (`k8s/`)

**Components**:
- **Deployment**: Single replica with `nvidia.com/gpu: 1` request/limit
- **Service**: ClusterIP on port 8000
- **Ingress**: NGINX ingress with WebSocket annotations:
  - `nginx.ingress.kubernetes.io/websocket-services: opentranscribe-backend`
  - `nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"`
  - Host: `stt.yourdomain.com` (configurable)

**GPU Requirements**:
- NVIDIA GPU Operator installed (✅ confirmed)
- CUDA 12.8 runtime available (✅ confirmed)
- Time-slicing enabled (4 GPUs available)

### CI/CD (`.github/workflows/`)

**Backend Workflow** (`backend-build.yml`):
- Triggers on push to `main` branch
- Uses `arc-runner-set` runner (self-hosted Kubernetes)
- Builds Docker image with CUDA base
- Pushes to DockerHub: `$DOCKERHUB_USERNAME/opentranscribe-backend:latest` and `:$GITHUB_SHA`
- Updates `k8s/backend/deployment.yaml` with new image tag

**Client Workflow** (`client-build.yml`):
- Optional: Build macOS app artifacts
- May require macOS runner (GitHub-hosted or self-hosted)
- Can be skipped for MVP if building locally

**Required Secrets**:
- `DOCKERHUB_USERNAME`: DockerHub username
- `DOCKERHUB_TOKEN`: DockerHub Personal Access Token (Read, Write & Delete)

## Development Workflow

### Local Backend Development

1. **GPU Validation** (Step 1 from plan.md):
   ```bash
   cd backend
   python3.11 -m venv venv
   source venv/bin/activate
   pip install torch==2.5.1+cu121 torchaudio==2.5.1 \
     --index-url https://download.pytorch.org/whl/cu121
   pip install nvidia-cublas-cu12 nvidia-cudnn-cu12==9.* faster-whisper
   python scripts/test_local_gpu.py
   ```

2. **RealtimeSTT Integration** (Step 2):
   ```bash
   pip install RealtimeSTT fastapi uvicorn[standard] websockets
   python scripts/test_realtime_stt.py
   ```

3. **FastAPI WebSocket Service** (Step 3):
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

### Local Client Development

1. **Open Xcode Project**:
   ```bash
   cd client/OpenTranscribe
   open OpenTranscribe.xcodeproj
   ```

2. **Configure Backend URL**:
   - Update `STTManager.swift` with backend WebSocket URL
   - For local testing: `ws://localhost:8000/stream`
   - For production: `wss://stt.yourdomain.com/stream`

3. **Build & Run**:
   - Build in Xcode (Cmd+B)
   - Run (Cmd+R)
   - Grant microphone and accessibility permissions when prompted

### Docker Build & Test

```bash
cd backend
docker build -t opentranscribe-backend:local .
docker run --gpus all -p 8000:8000 opentranscribe-backend:local
```

### Kubernetes Deployment

```bash
# Apply manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend/
kubectl apply -f k8s/ingress/

# Verify deployment
kubectl get pods -n opentranscribe
kubectl logs -n opentranscribe -l app=opentranscribe-backend

# Check GPU allocation
kubectl describe pod -n opentranscribe <pod-name> | grep -i gpu
```

## Implementation Order

Following the plan.md rollout sequence:

1. ✅ **Backend GPU Test** - Local faster-whisper turbo validation
2. ✅ **Backend RealtimeSTT Integration** - Local RealtimeSTT + turbo test
3. ✅ **Backend WebSocket Service** - FastAPI WebSocket endpoint
4. ✅ **Docker + K8s** - Containerize and deploy to cluster
5. ✅ **macOS App Phase 1** - UI + dummy transcription
6. ✅ **macOS App Phase 2** - Audio capture + WebSocket streaming
7. ✅ **macOS App Phase 3** - Keystroke synthesis (typing mode)

## File Naming Conventions

- **Python**: snake_case (`websocket.py`, `stt_service.py`)
- **Swift**: PascalCase (`STTManager.swift`, `AudioCaptureService.swift`)
- **Kubernetes**: kebab-case (`deployment.yaml`, `service.yaml`)
- **Documentation**: kebab-case (`MONOREPO_STRUCTURE.md`, `deployment.md`)

## Environment Variables

### Backend

- `MODEL`: Whisper model (default: `"turbo"`)
- `DEVICE`: Device (default: `"cuda"`)
- `COMPUTE_TYPE`: Compute type (default: `"float16"`)
- `LOG_LEVEL`: Logging level (default: `"INFO"`)

### Client

- `BACKEND_URL`: WebSocket backend URL (default: `wss://stt.yourdomain.com/stream`)

## Testing Strategy

### Backend Tests

- **Unit Tests**: `tests/test_stt.py` - RealtimeSTT integration
- **Integration Tests**: `tests/test_websocket.py` - WebSocket protocol
- **Local GPU Tests**: `scripts/test_local_gpu.py` - GPU validation

### Client Tests

- **Unit Tests**: Xcode test target
- **Integration Tests**: Manual testing with local backend
- **End-to-End**: Full flow from microphone → backend → typing

## Monitoring & Logging

### Backend

- Structured logging with Python `logging` module
- Log levels: DEBUG, INFO, WARNING, ERROR
- WebSocket connection lifecycle logging
- STT processing time metrics

### Client

- Console logging for debugging
- UI indicators for connection status
- Error dialogs for permission failures

## Security Considerations

1. **WebSocket Security**: Use `wss://` in production (TLS)
2. **Accessibility Permission**: Required for keystroke synthesis
3. **Microphone Permission**: Required for audio capture
4. **Backend Authentication**: Consider adding auth for multi-user scenarios (future)

## Future Enhancements

- Multi-user support with authentication
- Model caching with PersistentVolume
- Health check endpoints
- Metrics collection (Prometheus)
- Client auto-update mechanism
- Configuration UI in macOS app

## References

- **plan.md**: Detailed implementation plan
- **dockerhub-setup.md**: CI/CD pipeline setup
- **RealtimeSTT Docs**: https://github.com/KoljaB/RealtimeSTT
- **faster-whisper Docs**: https://github.com/guillaumekln/faster-whisper
- **FastAPI WebSocket Docs**: https://fastapi.tiangolo.com/advanced/websockets/

