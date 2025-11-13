"""Configuration management for OpenTranscribe backend."""
import os
from typing import Literal

# Model configuration
MODEL: str = os.getenv("MODEL", "turbo")
DEVICE: Literal["cuda", "cpu"] = os.getenv("DEVICE", "cuda")  # type: ignore
COMPUTE_TYPE: Literal["float16", "float32", "int8"] = os.getenv("COMPUTE_TYPE", "float16")  # type: ignore

# Logging
LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")

# Server configuration
HOST: str = os.getenv("HOST", "0.0.0.0")
PORT: int = int(os.getenv("PORT", "8000"))

