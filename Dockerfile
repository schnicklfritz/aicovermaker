# AICoverMaker Docker Image - Combines python-audio-separator and Applio
FROM nvidia/cuda:12.8.0-runtime-ubuntu24.04

# Set working directory
WORKDIR /app

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    # Git for cloning repositories
    git \
    # Utilities
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install python-audio-separator
RUN git clone https://github.com/schnicklfritz/python-audio-separator.git /app/python-audio-separator
WORKDIR /app/python-audio-separator
RUN pip install -e .

# Install Applio
WORKDIR /app
RUN git clone https://github.com/schnicklfritz/Applio.git /app/Applio
WORKDIR /app/Applio
# Install Applio dependencies from requirements.txt
RUN pip install -r requirements.txt

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

# Set up volume for models and data
VOLUME ["/app/models", "/app/data"]

# Default command
CMD ["aicovermaker", "--help"]
