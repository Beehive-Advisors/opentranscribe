"""OpenTranscribe Backend - FastAPI WebSocket server for real-time STT."""
import logging
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from app.websocket import websocket_endpoint
from app.config import LOG_LEVEL, HOST, PORT

# Configure logging
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="OpenTranscribe Backend",
    description="Real-time speech-to-text transcription service",
    version="0.1.0"
)

# CORS middleware (allow all origins for MVP)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "service": "OpenTranscribe Backend",
        "status": "running",
        "version": "0.1.0"
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.websocket("/stream")
async def stream(websocket: WebSocket):
    """
    WebSocket endpoint for audio streaming and transcription.
    
    Client sends: Binary PCM audio chunks (16kHz, 16-bit, mono)
    Server sends: JSON messages {"text": "...", "final": bool}
    """
    await websocket_endpoint(websocket)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=HOST, port=PORT)

