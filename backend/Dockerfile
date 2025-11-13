FROM nvidia/cuda:12.3.2-cudnn9-runtime-ubuntu22.04

ENV PYTHONUNBUFFERED=1
WORKDIR /app

RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3-pip \
    portaudio19-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN python3.11 -m pip install --upgrade pip

# PyTorch (CUDA 12.X build)
RUN pip install torch==2.5.1+cu121 torchaudio==2.5.1 \
    --index-url https://download.pytorch.org/whl/cu121

# CUDA libs for faster-whisper
RUN pip install nvidia-cublas-cu12 nvidia-cudnn-cu12==9.*

# faster-whisper + RealtimeSTT + web stack
RUN pip install \
    faster-whisper \
    RealtimeSTT \
    fastapi uvicorn[standard] websockets

COPY . /app

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

