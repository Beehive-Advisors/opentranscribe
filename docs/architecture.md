# OpenTranscribe Architecture

## System Overview

OpenTranscribe is a real-time speech-to-text transcription system that enables users to speak and have text appear wherever their cursor is on macOS. The system consists of:

1. **Backend**: FastAPI WebSocket service with RealtimeSTT + faster-whisper turbo running on Kubernetes GPU nodes
2. **Client**: Native macOS app (Swift) that captures audio, streams to backend, and types transcriptions
3. **Infrastructure**: Kubernetes deployment with NVIDIA GPU support, NGINX ingress

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    macOS Client (Swift)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ AVAudioEngine│→ │AudioConverter│→ │STTManager    │       │
│  │  (Capture)   │  │ (16k mono)   │  │(WebSocket)   │       │
│  └──────────────┘  └──────────────┘  └──────┬───────┘       │
│                                               │               │
│  ┌──────────────┐  ┌──────────────┐         │               │
│  │Keystroke     │← │Transcription │←────────┘               │
│  │Service       │  │ViewModel     │                          │
│  └──────────────┘  └──────────────┘                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ WebSocket (wss://)
                            │ Binary PCM → JSON Text
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (NGINX Ingress)              │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Backend Pod (FastAPI + RealtimeSTT)         │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │WebSocket     │→ │STTService    │                │   │
│  │  │Handler       │  │(RealtimeSTT)  │                │   │
│  │  └──────────────┘  └──────┬───────┘                │   │
│  │                            │                        │   │
│  │  ┌──────────────┐         │                        │   │
│  │  │faster-whisper│←────────┘                        │   │
│  │  │turbo (GPU)   │                                  │   │
│  │  └──────────────┘                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                    NVIDIA GPU (RTX 4090)                    │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Backend (`backend/`)

**Technology Stack**:
- **Framework**: FastAPI with WebSocket support
- **STT Library**: RealtimeSTT
- **Model**: faster-whisper with Whisper turbo model
- **GPU**: CUDA 12.3 + cuDNN 9, PyTorch 2.5.1+cu121
- **Base Image**: `nvidia/cuda:12.3.2-cudnn9-runtime-ubuntu22.04`

**Key Components**:
- `main.py`: FastAPI application entry point
- `app/websocket.py`: WebSocket connection handler
- `app/stt.py`: RealtimeSTT integration wrapper
- `app/config.py`: Configuration management

**Protocol**:
- **Client → Server**: Binary PCM chunks (16kHz, 16-bit, mono)
- **Server → Client**: JSON messages `{"text": "...", "final": bool}`

**Deployment**:
- Kubernetes Deployment with GPU request/limit
- ClusterIP Service on port 80
- NGINX Ingress with WebSocket support

### Client (`client/`)

**Technology Stack**:
- **Language**: Swift
- **Framework**: SwiftUI
- **Audio**: AVAudioEngine + AVAudioConverter
- **Networking**: URLSessionWebSocketTask
- **Keystrokes**: CGEvent APIs
- **Platform**: macOS 12.0+

**Key Components**:
- `STTManager`: WebSocket client for backend communication
- `AudioCaptureService`: Microphone capture with AVAudioEngine
- `AudioConverter`: Audio format conversion (44.1k → 16k mono)
- `KeystrokeService`: Keyboard event synthesis
- `TranscriptionViewModel`: State management

**Permissions Required**:
- Microphone: For audio capture
- Accessibility: For typing text into other apps

## Data Flow

### Audio Capture → Transcription

1. **macOS Client**:
   - AVAudioEngine captures microphone audio (typically 44.1kHz stereo)
   - AVAudioConverter converts to 16kHz mono PCM
   - PCM chunks sent as binary WebSocket messages

2. **Backend**:
   - Receives binary PCM chunks via WebSocket
   - Feeds chunks to RealtimeSTT via `feed_audio()`
   - RealtimeSTT processes with faster-whisper turbo on GPU
   - Transcription updates sent back as JSON

3. **macOS Client**:
   - Receives JSON transcription messages
   - Updates UI with interim text
   - Types final text using CGEvent APIs

## GPU Configuration

- **GPU**: NVIDIA RTX 4090 (time-sliced, 4 replicas)
- **CUDA**: 12.8 runtime
- **Driver**: 570.195.03
- **GPU Operator**: Installed and configured
- **Model**: Whisper turbo (large-v3-turbo with fewer decoder layers)

## Network Architecture

- **Ingress**: NGINX Ingress Controller
- **TLS**: cert-manager with Let's Encrypt
- **WebSocket**: NGINX annotations for WebSocket upgrade
- **Domain**: `stt.beehive-advisors.com`

## Scalability

### Current (MVP)
- 1 backend replica
- 1 GPU per pod
- Single user (you)

### Future Enhancements
- Horizontal pod autoscaling
- Multi-user support with authentication
- Model caching with PersistentVolume
- Load balancing across multiple pods

## Security Considerations

1. **WebSocket**: TLS in production (`wss://`)
2. **Permissions**: macOS Accessibility and Microphone permissions
3. **Backend Auth**: Not needed for MVP (single user)
4. **Kubernetes**: Namespace isolation
5. **Secrets**: DockerHub tokens stored as GitHub secrets

## Monitoring & Logging

- **Backend**: Structured logging with Python `logging`
- **Client**: Console logging for debugging
- **Kubernetes**: Pod logs via `kubectl logs`
- **Future**: Prometheus metrics, centralized logging

