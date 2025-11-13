"""WebSocket handler for real-time audio streaming and transcription."""
import json
import logging
import asyncio
from typing import Dict
from fastapi import WebSocket, WebSocketDisconnect
from app.stt import STTService

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections and their associated STT services."""
    
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.stt_services: Dict[str, STTService] = {}
    
    async def connect(self, websocket: WebSocket, client_id: str):
        """Accept a WebSocket connection and initialize STT service."""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        
        # Initialize STT service with callback
        def on_text(text: str, is_final: bool):
            """Callback for transcription updates."""
            asyncio.create_task(self._send_transcription(client_id, text, is_final))
        
        stt_service = STTService(on_text_callback=on_text)
        self.stt_services[client_id] = stt_service
        
        logger.info(f"Client {client_id} connected. Total connections: {len(self.active_connections)}")
    
    async def disconnect(self, client_id: str):
        """Close connection and cleanup STT service."""
        if client_id in self.active_connections:
            del self.active_connections[client_id]
        
        if client_id in self.stt_services:
            self.stt_services[client_id].cleanup()
            del self.stt_services[client_id]
        
        logger.info(f"Client {client_id} disconnected. Total connections: {len(self.active_connections)}")
    
    async def _send_transcription(self, client_id: str, text: str, is_final: bool):
        """Send transcription message to client."""
        if client_id not in self.active_connections:
            return
        
        try:
            message = {
                "text": text,
                "final": is_final
            }
            await self.active_connections[client_id].send_json(message)
        except Exception as e:
            logger.error(f"Error sending transcription to {client_id}: {e}")
    
    async def process_audio(self, client_id: str, audio_data: bytes):
        """Process incoming audio data."""
        if client_id not in self.stt_services:
            logger.warning(f"No STT service found for client {client_id}")
            return
        
        try:
            self.stt_services[client_id].feed_audio(audio_data)
        except Exception as e:
            logger.error(f"Error processing audio for {client_id}: {e}")


# Global connection manager
manager = ConnectionManager()


async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for audio streaming and transcription.
    
    Protocol:
    - Client sends: Binary messages (PCM audio chunks, 16kHz, 16-bit, mono)
    - Server sends: JSON messages {"text": "...", "final": bool}
    """
    import uuid
    client_id = str(uuid.uuid4())
    
    try:
        await manager.connect(websocket, client_id)
        
        while True:
            # Receive binary audio data
            data = await websocket.receive_bytes()
            
            # Process audio chunk
            await manager.process_audio(client_id, data)
            
            # Optionally get and send current text
            # (RealtimeSTT callback handles this, but we can also poll)
            stt_service = manager.stt_services.get(client_id)
            if stt_service:
                text, is_final = stt_service.get_text()
                if text:
                    await manager._send_transcription(client_id, text, is_final)
    
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for client {client_id}")
    except Exception as e:
        logger.error(f"WebSocket error for client {client_id}: {e}")
    finally:
        await manager.disconnect(client_id)

