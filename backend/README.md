# OpenTranscribe Backend

FastAPI WebSocket service for real-time speech-to-text transcription using RealtimeSTT + faster-whisper turbo.

## Quick Start

### Local Development

```bash
# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Docker Build

```bash
docker build -t opentranscribe-backend:local .
docker run --gpus all -p 8000:8000 opentranscribe-backend:local
```

## API Endpoints

- `GET /`: Health check
- `GET /health`: Health check
- `WebSocket /stream`: Audio streaming and transcription

## WebSocket Protocol

- **Client → Server**: Binary PCM chunks (16kHz, 16-bit, mono)
- **Server → Client**: JSON messages `{"text": "...", "final": bool}`

## Testing

```bash
# GPU validation
python scripts/test_local_gpu.py

# RealtimeSTT integration
python scripts/test_realtime_stt.py
```

## Configuration

See `app/config.py` for configuration options.

