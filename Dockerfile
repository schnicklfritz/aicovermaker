# AICoverMaker Docker Image - Combines python-audio-separator and Applio
FROM nvidia/cuda:12.8.0-runtime-ubuntu24.04

# Set working directory
WORKDIR /app

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Install system dependencies with retry logic
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf && \
    apt-get update || (sleep 5 && apt-get update) || (sleep 10 && apt-get update) && \
    apt-get install -y --no-install-recommends \
    # Python and build tools
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    build-essential \
    # Audio/video processing
    ffmpeg \
    sox \
    libsndfile1 \
    libportaudio2 \
    # Git for cloning repositories
    git \
    # Utilities
    curl \
    wget \
    # Additional libraries for audio processing
    libasound2-dev \
    libpulse-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Upgrade pip and setuptools
RUN python3 -m pip install --upgrade pip setuptools wheel

# Create virtual environments for each project
RUN python3 -m venv /app/venv/separator && \
    python3 -m venv /app/venv/applio

# Install common Python dependencies in both virtual environments
RUN /app/venv/separator/bin/pip install \
    numpy==1.26.4 \
    requests==2.31.0 \
    tqdm \
    wget \
    ffmpeg-python==0.2.0 \
    librosa==0.11.0 \
    scipy==1.11.1 \
    soundfile==0.12.1 \
    noisereduce \
    pedalboard \
    stftpitchshift \
    soxr

RUN /app/venv/applio/bin/pip install \
    numpy==1.26.4 \
    requests==2.31.0 \
    tqdm \
    wget \
    ffmpeg-python==0.2.0 \
    librosa==0.11.0 \
    scipy==1.11.1 \
    soundfile==0.12.1 \
    noisereduce \
    pedalboard \
    stftpitchshift \
    soxr

# Install python-audio-separator with explicit dependencies in its own virtual environment
RUN git clone https://github.com/schnicklfritz/python-audio-separator.git /app/python-audio-separator || \
    (sleep 5 && git clone https://github.com/schnicklfritz/python-audio-separator.git /app/python-audio-separator) || \
    (sleep 10 && git clone https://github.com/schnicklfritz/python-audio-separator.git /app/python-audio-separator)
WORKDIR /app/python-audio-separator
# Install in separator virtual environment
RUN /app/venv/separator/bin/pip install -e . || \
    (echo "Installation from repo failed, installing common audio separation dependencies" && \
     /app/venv/separator/bin/pip install demucs torchaudio)

# Install Applio with specific version handling in its own virtual environment
WORKDIR /app
RUN git clone https://github.com/schnicklfritz/Applio.git /app/Applio || \
    (sleep 5 && git clone https://github.com/schnicklfritz/Applio.git /app/Applio) || \
    (sleep 10 && git clone https://github.com/schnicklfritz/Applio.git /app/Applio)
WORKDIR /app/Applio
# Install requirements in applio virtual environment
RUN if [ -f "requirements.txt" ]; then \
        /app/venv/applio/bin/pip install -r requirements.txt || echo "Some requirements failed, continuing..."; \
    else \
        echo "No requirements.txt found"; \
    fi

# Install PyTorch with CUDA 12.1 support (compatible with CUDA 12.8) in both virtual environments
RUN /app/venv/separator/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 || \
    (sleep 10 && /app/venv/separator/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121) || \
    (sleep 30 && /app/venv/separator/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121)

RUN /app/venv/applio/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 || \
    (sleep 10 && /app/venv/applio/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121) || \
    (sleep 30 && /app/venv/applio/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121)

# Install additional dependencies that might be missing including CUDA 12 compatible onnxruntime
RUN /app/venv/separator/bin/pip install \
    faiss-cpu==1.7.3 \
    PyYAML \
    gradio \
    transformers \
    accelerate \
    onnxruntime-gpu==1.17.1

RUN /app/venv/applio/bin/pip install \
    faiss-cpu==1.7.3 \
    PyYAML \
    gradio \
    transformers \
    accelerate \
    onnxruntime-gpu==1.17.1

# Create a wrapper script to run both applications using their respective virtual environments
WORKDIR /app
RUN echo '#!/bin/bash\n\
# AICoverMaker wrapper script\n\
# This script can run either python-audio-separator or Applio\n\
# using their respective virtual environments\n\
\n\
if [ "$1" = "separator" ]; then\n\
    shift\n\
    cd /app/python-audio-separator\n\
    source /app/venv/separator/bin/activate\n\
    python -m audio_separator "$@"\n\
elif [ "$1" = "applio" ]; then\n\
    shift\n\
    cd /app/Applio\n\
    source /app/venv/applio/bin/activate\n\
    python app.py "$@"\n\
else\n\
    echo "Usage: $0 {separator|applio} [args...]"\n\
    echo "  separator: Run python-audio-separator"\n\
    echo "  applio:    Run Applio voice conversion"\n\
    exit 1\n\
fi' > /usr/local/bin/aicovermaker && \
    chmod +x /usr/local/bin/aicovermaker

# Create test script to verify installation in both virtual environments
RUN echo '#!/bin/bash\n\
echo "Testing AICoverMaker installation..."\n\
echo "1. Checking Python versions..."\n\
/app/venv/separator/bin/python --version\n\
/app/venv/applio/bin/python --version\n\
echo "2. Checking PyTorch CUDA availability in separator environment..."\n\
/app/venv/separator/bin/python -c "import torch; print(f\"PyTorch version: {torch.__version__}\"); print(f\"CUDA available: {torch.cuda.is_available()}\")"\n\
echo "3. Checking PyTorch CUDA availability in applio environment..."\n\
/app/venv/applio/bin/python -c "import torch; print(f\"PyTorch version: {torch.__version__}\"); print(f\"CUDA available: {torch.cuda.is_available()}\")"\n\
echo "4. Checking python-audio-separator..."\n\
cd /app/python-audio-separator && /app/venv/separator/bin/python -c "import audio_separator; print(\"audio_separator imported successfully\")" 2>/dev/null || echo "audio_separator import failed"\n\
echo "5. Checking Applio..."\n\
cd /app/Applio && /app/venv/applio/bin/python -c "import app; print(\"Applio imported successfully\")" 2>/dev/null || echo "Applio import failed"\n\
echo "Installation test complete!"' > /usr/local/bin/test-aicovermaker && \
    chmod +x /usr/local/bin/test-aicovermaker

# Set up volume for models and data
VOLUME ["/app/models", "/app/data"]

# Default command - run tests and show help
CMD ["aicovermaker", "--help"]
