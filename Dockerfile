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

# Install common Python dependencies for both projects
RUN pip install \
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

# Install python-audio-separator with explicit dependencies
RUN git clone https://github.com/schnicklfritz/python-audio-separator.git /app/python-audio-separator || \
    (sleep 5 && git clone https://github.com/schnicklfritz/python-audio-separator.git /app/python-audio-separator) || \
    (sleep 10 && git clone https://github.com/schnicklfritz/python-audio-separator.git /app/python-audio-separator)
WORKDIR /app/python-audio-separator
# Try to install from setup.py or pyproject.toml, fallback to manual install
RUN if [ -f "setup.py" ]; then \
        pip install -e .; \
    elif [ -f "pyproject.toml" ]; then \
        pip install -e .; \
    else \
        echo "No setup.py or pyproject.toml found, installing common audio separation dependencies"; \
        pip install demucs torchaudio; \
    fi

# Install Applio with specific version handling
WORKDIR /app
RUN git clone https://github.com/schnicklfritz/Applio.git /app/Applio || \
    (sleep 5 && git clone https://github.com/schnicklfritz/Applio.git /app/Applio) || \
    (sleep 10 && git clone https://github.com/schnicklfritz/Applio.git /app/Applio)
WORKDIR /app/Applio
# Install requirements with error handling
RUN if [ -f "requirements.txt" ]; then \
        pip install -r requirements.txt || echo "Some requirements failed, continuing..."; \
    else \
        echo "No requirements.txt found"; \
    fi

# Install PyTorch with CUDA support (required by both projects) with retry
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 || \
    (sleep 10 && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118) || \
    (sleep 30 && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118)

# Install additional dependencies that might be missing
RUN pip install \
    faiss-cpu==1.7.3 \
    PyYAML \
    gradio \
    transformers \
    accelerate

# Create a wrapper script to run both applications
WORKDIR /app
RUN echo '#!/bin/bash\n\
# AICoverMaker wrapper script\n\
# This script can run either python-audio-separator or Applio\n\
# based on the command provided\n\
\n\
if [ "$1" = "separator" ]; then\n\
    shift\n\
    cd /app/python-audio-separator\n\
    python3 -m audio_separator "$@"\n\
elif [ "$1" = "applio" ]; then\n\
    shift\n\
    cd /app/Applio\n\
    python3 app.py "$@"\n\
else\n\
    echo "Usage: $0 {separator|applio} [args...]"\n\
    echo "  separator: Run python-audio-separator"\n\
    echo "  applio:    Run Applio voice conversion"\n\
    exit 1\n\
fi' > /usr/local/bin/aicovermaker && \
    chmod +x /usr/local/bin/aicovermaker

# Create test script to verify installation
RUN echo '#!/bin/bash\n\
echo "Testing AICoverMaker installation..."\n\
echo "1. Checking Python version..."\n\
python3 --version\n\
echo "2. Checking PyTorch CUDA availability..."\n\
python3 -c "import torch; print(f\"PyTorch version: {torch.__version__}\"); print(f\"CUDA available: {torch.cuda.is_available()}\")"\n\
echo "3. Checking python-audio-separator..."\n\
cd /app/python-audio-separator && python3 -c "import audio_separator; print(\"audio_separator imported successfully\")" 2>/dev/null || echo "audio_separator import failed"\n\
echo "4. Checking Applio..."\n\
cd /app/Applio && python3 -c "import app; print(\"Applio imported successfully\")" 2>/dev/null || echo "Applio import failed"\n\
echo "Installation test complete!"' > /usr/local/bin/test-aicovermaker && \
    chmod +x /usr/local/bin/test-aicovermaker

# Set up volume for models and data
VOLUME ["/app/models", "/app/data"]

# Default command - run tests and show help
CMD ["aicovermaker", "--help"]
