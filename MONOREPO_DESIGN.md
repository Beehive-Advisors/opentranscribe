# OpenTranscribe Monorepo Design Decisions

## Executive Summary

This document explains the design decisions for structuring OpenTranscribe as a monorepo, integrating the requirements from `plan.md` with the CI/CD pipeline from `dockerhub-setup.md`.

## Why Monorepo?

1. **Single Source of Truth**: All code, configs, and docs in one repository
2. **Atomic Changes**: Backend and client changes can be coordinated in single commits
3. **Simplified CI/CD**: One repository, one set of workflows
4. **Easier Development**: Developers can see the full system context
5. **Version Alignment**: Backend and client versions stay in sync

## Structure Rationale

### Top-Level Organization

```
opentranscribe/
├── backend/          # Python/FastAPI service
├── client/           # macOS Swift application
├── k8s/              # Kubernetes manifests
├── .github/          # CI/CD workflows
└── docs/             # Documentation
```

**Reasoning**:
- Clear separation of concerns (backend vs client vs infrastructure)
- Each component can be developed independently
- Easy to navigate and understand
- Follows common monorepo patterns

### Backend Structure (`backend/`)

```
backend/
├── Dockerfile              # Single Dockerfile at root
├── requirements.txt        # Python dependencies
├── main.py                 # FastAPI entry point
├── app/                    # Application code
│   ├── websocket.py        # WebSocket handler
│   ├── stt.py              # STT integration
│   └── config.py           # Configuration
├── tests/                  # Test suite
└── scripts/                # Utility scripts
```

**Design Decisions**:
- **Single Dockerfile**: Simpler than multi-stage builds for MVP
- **`app/` package**: Standard Python package structure
- **`scripts/` directory**: Reusable scripts for local testing (from plan.md steps 1-2)
- **`tests/` directory**: Unit and integration tests

**Alignment with plan.md**:
- Step 3.1: Local GPU validation → `scripts/test_local_gpu.py`
- Step 3.2: RealtimeSTT integration → `scripts/test_realtime_stt.py`
- Step 3.3: FastAPI WebSocket → `app/websocket.py`
- Step 3.4: Dockerization → `Dockerfile`

### Client Structure (`client/`)

```
client/
├── OpenTranscribe/         # Xcode project root
│   ├── OpenTranscribe.xcodeproj/
│   └── OpenTranscribe/     # Source code
│       ├── Services/       # Core services
│       ├── ViewModels/     # SwiftUI view models
│       ├── Models/         # Data models
│       └── Utils/          # Utilities
```

**Design Decisions**:
- **Xcode Project Structure**: Standard macOS app layout
- **Service Layer**: Separates WebSocket, audio, and keystroke concerns
- **ViewModels**: SwiftUI MVVM pattern for UI state
- **Utils**: Reusable components (AudioConverter)

**Alignment with plan.md**:
- Step 5.1: UI + dummy transcription → `ContentView.swift`
- Step 5.2: Audio capture → `AudioCaptureService.swift`
- Step 5.3: WebSocket → `STTManager.swift`
- Step 5.4: Keystroke synthesis → `KeystrokeService.swift`

### Kubernetes Structure (`k8s/`)

```
k8s/
├── namespace.yaml          # Namespace definition
├── backend/
│   ├── deployment.yaml     # Backend deployment
│   └── service.yaml        # ClusterIP service
└── ingress/
    └── ingress.yaml        # NGINX ingress
```

**Design Decisions**:
- **Separate directories**: `backend/` and `ingress/` for clarity
- **Namespace**: Isolated namespace for OpenTranscribe
- **Deployment + Service**: Standard K8s pattern
- **Ingress**: Separate file for routing configuration

**Alignment with plan.md**:
- Step 3.5: Kubernetes deployment → `k8s/backend/deployment.yaml`
- NGINX ingress with WebSocket support → `k8s/ingress/ingress.yaml`

### CI/CD Structure (`.github/workflows/`)

```
.github/workflows/
├── backend-build.yml       # Backend Docker build
└── client-build.yml         # Client build (optional)
```

**Design Decisions**:
- **Separate workflows**: Backend and client can build independently
- **Backend workflow**: Required for Docker image building
- **Client workflow**: Optional (can build locally for MVP)

**Alignment with dockerhub-setup.md**:
- Uses `arc-runner-set` runner (self-hosted Kubernetes)
- DockerHub authentication via secrets
- Image tagging: `latest` and `$GITHUB_SHA`
- Updates Kubernetes manifests with new image tags

## Integration Points

### Backend ↔ Client

**Protocol**: WebSocket binary messages
- **Client → Backend**: Raw PCM chunks (16kHz, 16-bit, mono)
- **Backend → Client**: JSON messages `{"text": "...", "final": bool}`

**Connection**: 
- Local: `ws://localhost:8000/stream`
- Production: `wss://stt.yourdomain.com/stream`

### Backend ↔ Kubernetes

**Deployment**:
- Image: `$DOCKERHUB_USERNAME/opentranscribe-backend:$GITHUB_SHA`
- GPU: `nvidia.com/gpu: 1` (request and limit)
- Port: 8000

**Service**:
- Type: ClusterIP
- Port: 80 → 8000

**Ingress**:
- Host: `stt.yourdomain.com`
- WebSocket annotations for NGINX
- TLS: Managed by ingress controller

### CI/CD ↔ Infrastructure

**Build Process**:
1. GitHub Actions triggers on push to `main`
2. Uses `arc-runner-set` runner (Kubernetes pod)
3. Builds Docker image with CUDA base
4. Pushes to DockerHub
5. Updates `k8s/backend/deployment.yaml` with new tag

**Deployment Process**:
1. Manual: `kubectl apply -f k8s/`
2. Future: ArgoCD or Flux for GitOps

## Technology Stack Alignment

### Backend Stack (from plan.md)

- **Base Image**: `nvidia/cuda:12.3.2-cudnn9-runtime-ubuntu22.04`
- **Python**: 3.11
- **PyTorch**: 2.5.1+cu121
- **CUDA Libs**: nvidia-cublas-cu12, nvidia-cudnn-cu12==9.*
- **STT**: RealtimeSTT + faster-whisper turbo
- **Web Framework**: FastAPI + uvicorn

**Verified Compatibility**:
- ✅ CUDA 12.8 runtime available in cluster
- ✅ NVIDIA GPU Operator installed
- ✅ GPU time-slicing enabled (4 GPUs available)

### Client Stack (from plan.md)

- **Language**: Swift
- **Framework**: SwiftUI
- **Audio**: AVAudioEngine + AVAudioConverter
- **Networking**: URLSessionWebSocketTask
- **Keystrokes**: CGEvent APIs
- **Platform**: macOS 12.0+

### Infrastructure Stack

- **Orchestration**: Kubernetes (k3s)
- **Ingress**: NGINX Ingress Controller
- **GPU**: NVIDIA GPU Operator
- **CI/CD**: GitHub Actions + ARC (Actions Runner Controller)
- **Registry**: DockerHub

## Development Workflow

### Local Development

1. **Backend**: Python venv → test locally → Docker build → test container
2. **Client**: Xcode → build → run → test with local backend
3. **Integration**: Local backend + local client → end-to-end test

### CI/CD Workflow

1. **Push to `main`** → GitHub Actions triggers
2. **Backend Build** → Docker image → DockerHub
3. **Manifest Update** → `k8s/backend/deployment.yaml` updated
4. **Deploy** → Manual `kubectl apply` (or automated GitOps)

### Testing Strategy

- **Backend**: Unit tests (STT), integration tests (WebSocket)
- **Client**: Unit tests (services), manual integration tests
- **E2E**: Manual testing with local backend → production backend

## File Organization Principles

1. **Separation of Concerns**: Backend, client, and infrastructure are separate
2. **Convention Over Configuration**: Standard naming and structure
3. **Documentation Co-location**: Docs near relevant code
4. **Test Co-location**: Tests in `tests/` directories
5. **Scripts for Automation**: Reusable scripts in `scripts/`

## Scalability Considerations

### Current (MVP)

- **Backend**: 1 replica, 1 GPU
- **Client**: Single user (you)
- **Deployment**: Manual `kubectl apply`

### Future Enhancements

- **Multi-user**: Add authentication to backend
- **Scaling**: Horizontal pod autoscaling
- **Model Caching**: PersistentVolume for HuggingFace cache
- **GitOps**: ArgoCD or Flux for automated deployments
- **Monitoring**: Prometheus + Grafana
- **Logging**: Centralized logging (Loki or similar)

## Security Considerations

1. **WebSocket**: TLS in production (`wss://`)
2. **Permissions**: macOS Accessibility and Microphone permissions
3. **Backend Auth**: Not needed for MVP (single user), add later
4. **Secrets**: DockerHub tokens stored as GitHub secrets
5. **Kubernetes**: Namespace isolation

## Compliance with Requirements

### From plan.md

✅ **Backend**: FastAPI + RealtimeSTT + faster-whisper turbo  
✅ **Client**: macOS app with AVAudioEngine + WebSocket  
✅ **GPU**: CUDA 12.3 + cuDNN 9, PyTorch 2.5.1+cu121  
✅ **WebSocket**: Binary PCM up, JSON text down  
✅ **Keystroke Synthesis**: CGEvent-based typing  

### From dockerhub-setup.md

✅ **CI/CD**: GitHub Actions with `arc-runner-set` runner  
✅ **Docker**: DockerHub registry  
✅ **Kubernetes**: Deployment manifests  
✅ **Secrets**: DockerHub username and token  

## Next Steps

1. **Create Directory Structure**: Set up folders as outlined
2. **Initialize Backend**: Create `backend/` with Dockerfile and Python code
3. **Initialize Client**: Create Xcode project in `client/`
4. **Create K8s Manifests**: Set up `k8s/` directory with deployment files
5. **Set Up CI/CD**: Create `.github/workflows/backend-build.yml`
6. **Documentation**: Create `docs/` with architecture and deployment guides

## Questions & Decisions Needed

1. **Domain Name**: What domain will be used for `stt.yourdomain.com`?
2. **DockerHub Username**: Confirm DockerHub username for image tags
3. **Namespace**: Use `opentranscribe` namespace or existing namespace?
4. **Client Build**: Build locally or set up macOS runner for CI/CD?
5. **Model Cache**: Use PersistentVolume for model cache (recommended)?

## Conclusion

This monorepo structure provides:
- ✅ Clear separation of backend, client, and infrastructure
- ✅ Alignment with plan.md implementation steps
- ✅ Integration with dockerhub-setup.md CI/CD pipeline
- ✅ Scalability path for future enhancements
- ✅ Standard patterns for maintainability

The structure is designed to be:
- **Simple**: Easy to understand and navigate
- **Practical**: Follows established patterns
- **Flexible**: Can evolve as requirements change
- **Complete**: Covers all aspects from development to deployment

