"""RealtimeSTT integration for speech-to-text transcription."""
import logging
from typing import Optional, Callable
from RealtimeSTT import AudioToTextRecorder
from app.config import MODEL, DEVICE, COMPUTE_TYPE

logger = logging.getLogger(__name__)


class STTService:
    """Service for real-time speech-to-text transcription using RealtimeSTT."""
    
    def __init__(self, on_text_callback: Optional[Callable[[str, bool], None]] = None):
        """
        Initialize STT service.
        
        Args:
            on_text_callback: Optional callback function(text: str, is_final: bool) -> None
        """
        self.on_text_callback = on_text_callback
        self.recorder: Optional[AudioToTextRecorder] = None
        self._initialize_recorder()
    
    def _initialize_recorder(self):
        """Initialize the RealtimeSTT recorder."""
        try:
            logger.info(f"Initializing RealtimeSTT with model={MODEL}, device={DEVICE}, compute_type={COMPUTE_TYPE}")
            
            self.recorder = AudioToTextRecorder(
                model=MODEL,
                device=DEVICE,
                compute_type=COMPUTE_TYPE,
                use_microphone=False,  # We feed audio manually
                enable_realtime_transcription=True,
                on_recording_start=None,
                on_recording_stop=None,
                on_transcription_update=self._on_transcription_update if self.on_text_callback else None,
            )
            
            logger.info("RealtimeSTT recorder initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize RealtimeSTT recorder: {e}")
            raise
    
    def _on_transcription_update(self, text: str):
        """Handle transcription updates from RealtimeSTT."""
        if self.on_text_callback:
            # RealtimeSTT provides interim transcriptions
            # We'll treat all updates as interim unless explicitly marked final
            self.on_text_callback(text, is_final=False)
    
    def feed_audio(self, audio_data: bytes):
        """
        Feed audio data to the recorder.
        
        Args:
            audio_data: Raw PCM audio bytes (16kHz, 16-bit, mono)
        """
        if not self.recorder:
            raise RuntimeError("Recorder not initialized")
        
        try:
            self.recorder.feed_audio(audio_data)
        except Exception as e:
            logger.error(f"Error feeding audio: {e}")
            raise
    
    def get_text(self) -> tuple[str, bool]:
        """
        Get the current transcription text.
        
        Returns:
            Tuple of (text, is_final)
        """
        if not self.recorder:
            return "", False
        
        try:
            text = self.recorder.text()
            # For now, we'll mark text as final if it's non-empty
            # In a more sophisticated implementation, we'd track sentence boundaries
            is_final = len(text.strip()) > 0
            return text, is_final
        except Exception as e:
            logger.error(f"Error getting text: {e}")
            return "", False
    
    def cleanup(self):
        """Clean up resources."""
        if self.recorder:
            try:
                # RealtimeSTT cleanup if needed
                del self.recorder
                self.recorder = None
                logger.info("STT recorder cleaned up")
            except Exception as e:
                logger.error(f"Error during cleanup: {e}")

