# AICoverMaker - Comprehensive Documentation

## Overview

AICoverMaker is a Docker image that combines two powerful AI audio tools:
1. **python-audio-separator**: Stem separation (vocals, instrumental, drums, bass)
2. **Applio**: Voice conversion using RVC (Retrieval-based Voice Conversion)

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [python-audio-separator](#python-audio-separator)
   - [Available Models](#available-models)
   - [Command Reference](#command-reference)
   - [Usage Examples](#usage-examples)
4. [Applio](#applio)
   - [Features](#features)
   - [Web UI Guide](#web-ui-guide)
   - [API Usage](#api-usage)
5. [Plugin System](#plugin-system)
6. [Scripting & Automation](#scripting--automation)
7. [GPU Configuration](#gpu-configuration)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Topics](#advanced-topics)

## Quick Start

### Pull and Run
```bash
docker pull schnicklfritz/aicovermaker:latest
docker run --gpus all -p 7860:7860 schnicklfritz/aicovermaker:latest applio
```

### Basic Separation
```bash
docker run --gpus all -v $(pwd):/app/data schnicklfritz/aicovermaker:latest separator \
  --input /app/data/song.mp3 \
  --output_dir /app/data/separated
```

## Architecture

### Container Structure
```
/app
├── python-audio-separator/  # Audio separation tool
├── Applio/                  # Voice conversion tool
├── models/                  # AI models (mounted volume)
└── data/                    # Input/output data (mounted volume)
```

### Tool Selection
- Use `separator` command for audio separation
- Use `applio` command for voice conversion
- Both tools share GPU resources and model storage

## python-audio-separator

### Available Models

#### UVR Models (Primary)
- `uvrmodel` - Default UVR model (best for vocals/instrumental)
- `uvr_vocals` - Optimized for vocal extraction
- `uvr_instrumental` - Optimized for instrumental extraction
- `uvr_bass` - Bass separation
- `uvr_drums` - Drum separation

#### Demucs Models
- `htdemucs` - Hybrid Transformer Demucs (best quality)
- `htdemucs_ft` - Fine-tuned version
- `hdemucs_mmi` - MMI-separated model

#### MDX Models
- `mdx_extra` - Extra separation capabilities
- `mdx_q` - Quality-focused model

### Command Reference

#### Basic Syntax
```bash
aicovermaker separator [OPTIONS]
```

#### All Options
```
--input FILE                Input audio file (required)
--output_dir DIRECTORY      Output directory (default: current directory)
--model_name TEXT           Model name (default: "uvrmodel")
--output_format TEXT        Output format: mp3, wav, flac, ogg (default: "mp3")
--bitrate INTEGER           Bitrate for output files (default: 320)
--cpu_separation           Use CPU instead of GPU
--model_file_dir DIRECTORY Custom model directory
--log_level TEXT           Log level: DEBUG, INFO, WARNING, ERROR
--batch_size INTEGER       Batch size for processing
--overwrite               Overwrite existing files
--help                    Show help message
```

### Usage Examples

#### Basic Vocal Separation
```bash
docker run --gpus all -v $(pwd):/app/data schnicklfritz/aicovermaker:latest separator \
  --input /app/data/input.mp3 \
  --output_dir /app/data/output \
  --model_name uvr_vocals \
  --output_format wav \
  --bitrate 44100
```

#### Batch Processing Multiple Files
```bash
for file in *.mp3; do
  docker run --gpus all -v $(pwd):/app/data schnicklfritz/aicovermaker:latest separator \
    --input "/app/data/$file" \
    --output_dir "/app/data/separated" \
    --model_name htdemucs
done
```

#### Extract All Stems
```bash
# Separate into individual stems
docker run --gpus all -v $(pwd):/app/data schnicklfritz/aicovermaker:latest separator \
  --input /app/data/song.mp3 \
  --output_dir /app/data/stems \
  --model_name htdemucs
```

## Applio

### Features

#### Voice Conversion
- **RVC (Retrieval-based Voice Conversion)**: High-quality voice conversion
- **Real-time Processing**: Low latency conversion
- **Multiple Voices**: Support for various voice models
- **Pitch Control**: Adjust pitch and tone
- **Noise Reduction**: Built-in audio cleaning

#### Supported Formats
- Input: WAV, MP3, FLAC, OGG
- Output: WAV, MP3
- Sample rates: 16kHz, 24kHz, 32kHz, 44.1kHz, 48kHz

### Web UI Guide

#### Accessing the Interface
1. Start container: `docker run --gpus all -p 7860:7860 schnicklfritz/aicovermaker:latest applio`
2. Open browser: `http://localhost:7860`
3. Interface sections:
   - **Model Selection**: Choose voice model
   - **Audio Upload**: Upload source audio
   - **Conversion Settings**: Adjust pitch, speed, etc.
   - **Output Preview**: Listen before download

#### Step-by-Step Conversion
1. **Select Model**: Choose from available voice models
2. **Upload Audio**: Drag and drop or browse for file
3. **Configure Settings**:
   - Pitch shift: -12 to +12 semitones
   - Speed: 0.5x to 2.0x
   - Noise reduction: Low/Medium/High
4. **Process**: Click "Convert" button
5. **Download**: Save converted audio

### API Usage

#### REST API Endpoints
```bash
# Health check
curl http://localhost:7860/health

# List available models
curl http://localhost:7860/api/models

# Convert audio
curl -X POST http://localhost:7860/api/convert \
  -F "audio=@input.wav" \
  -F "model=model_name" \
  -F "pitch_shift=0" \
  -o output.wav
```

#### Python Client Example
```python
import requests

def convert_voice(input_file, output_file, model="default"):
    url = "http://localhost:7860/api/convert"
    files = {"audio": open(input_file, "rb")}
    data = {"model": model, "pitch_shift": 0}
    
    response = requests.post(url, files=files, data=data)
    
    with open(output_file, "wb") as f:
        f.write(response.content)
```

## Plugin System

### Available Plugins

#### python-audio-separator Plugins
1. **Model Manager**: Download and manage separation models
2. **Batch Processor**: Process multiple files automatically
3. **Format Converter**: Convert between audio formats
4. **Metadata Editor**: Edit audio file metadata

#### Applio Plugins
1. **Voice Trainer**: Train custom voice models
2. **Effect Chain**: Apply audio effects (reverb, delay, etc.)
3. **Batch Converter**: Convert multiple files
4. **API Server**: REST API for automation

### Installing Custom Plugins

#### Via Docker Volume
```bash
# Mount plugin directory
docker run --gpus all -p 7860:7860 \
  -v $(pwd)/plugins:/app/Applio/plugins \
  schnicklfritz/aicovermaker:latest applio
```

#### Plugin Development
```python
# Example plugin structure
# plugins/my_plugin/__init__.py
from applio.core import PluginBase

class MyPlugin(PluginBase):
    def process_audio(self, audio_data):
        # Custom processing
        return processed_audio
```

## Scripting & Automation

### Bash Scripts

#### Automated Separation Pipeline
```bash
#!/bin/bash
# automate_separation.sh

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MODEL="${3:-uvrmodel}"

for file in "$INPUT_DIR"/*.mp3; do
    filename=$(basename "$file" .mp3)
    
    echo "Processing: $filename"
    
    docker run --gpus all \
      -v "$INPUT_DIR":/app/input \
      -v "$OUTPUT_DIR":/app/output \
      schnicklfritz/aicovermaker:latest separator \
      --input "/app/input/$(basename "$file")" \
      --output_dir "/app/output/$filename" \
      --model_name "$MODEL" \
      --output_format wav
    
    echo "Completed: $filename"
done
```

#### Batch Voice Conversion
```bash
#!/bin/bash
# batch_convert.sh

MODEL="female_voice_1"
PITCH_SHIFT=2

for file in input/*.wav; do
    output="output/$(basename "$file")"
    
    curl -X POST http://localhost:7860/api/convert \
      -F "audio=@$file" \
      -F "model=$MODEL" \
      -F "pitch_shift=$PITCH_SHIFT" \
      -o "$output"
done
```

### Python Automation

#### Complete Processing Pipeline
```python
import os
import subprocess
import requests

class AICoverMakerAutomation:
    def __init__(self, docker_image="schnicklfritz/aicovermaker:latest"):
        self.docker_image = docker_image
    
    def separate_audio(self, input_file, output_dir, model="htdemucs"):
        """Separate audio using python-audio-separator"""
        cmd = [
            "docker", "run", "--gpus", "all",
            "-v", f"{os.path.dirname(input_file)}:/app/input",
            "-v", f"{output_dir}:/app/output",
            self.docker_image, "separator",
            "--input", f"/app/input/{os.path.basename(input_file)}",
            "--output_dir", "/app/output",
            "--model_name", model,
            "--output_format", "wav"
        ]
        
        subprocess.run(cmd, check=True)
    
    def convert_voice(self, input_file, output_file, model="default", pitch=0):
        """Convert voice using Applio API"""
        url = "http://localhost:7860/api/convert"
        
        with open(input_file, "rb") as f:
            files = {"audio": f}
            data = {"model": model, "pitch_shift": pitch}
            
            response = requests.post(url, files=files, data=data)
            
            with open(output_file, "wb") as out:
                out.write(response.content)
    
    def create_cover(self, original_song, vocal_model, output_file):
        """Complete cover creation pipeline"""
        # Step 1: Separate vocals
        self.separate_audio(original_song, "/tmp/separated", "uvr_vocals")
        
        # Step 2: Convert vocals
        vocal_file = "/tmp/separated/vocals.wav"
        converted_vocals = "/tmp/converted_vocals.wav"
        self.convert_voice(vocal_file, converted_vocals, vocal_model)
        
        # Step 3: Mix with instrumental
        instrumental = "/tmp/separated/instrumental.wav"
        # Use ffmpeg to mix (simplified)
        subprocess.run([
            "ffmpeg", "-i", instrumental, "-i", converted_vocals,
            "-filter_complex", "amix=inputs=2:duration=longest",
            output_file
        ])

# Usage
automator = AICoverMakerAutomation()
automator.create_cover("song.mp3", "artist_voice", "cover.mp3")
```

### Docker Compose Automation

#### Full Stack Configuration
```yaml
version: '3.8'

services:
  aicovermaker:
    image: schnicklfritz/aicovermaker:latest
    container_name: aicovermaker
    runtime: nvidia
    ports:
      - "7860:7860"
    volumes:
      - ./models:/app/models
      - ./data:/app/data
      - ./scripts:/app/scripts
    environment:
      - CUDA_VISIBLE_DEVICES=0
    command: applio
  
  automation:
    image: python:3.11
    container_name: automation
    volumes:
      - ./automation:/app
      - ./data:/data
    working_dir: /app
    depends_on:
      - aicovermaker
    command: python automate.py
  
  redis:
    image: redis:alpine
    container_name: redis
  
  postgres:
    image: postgres:15
    container_name: postgres
    environment:
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## GPU Configuration

### NVIDIA GPU Setup

#### Requirements
- NVIDIA Driver >= 525.60.13
- Docker with NVIDIA Container Toolkit
- CUDA 12.8 compatible GPU

#### Installation
```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Verify installation
docker run --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
```

#### Multi-GPU Configuration
```bash
# Use specific GPU
docker run --gpus '"device=0"' -p 7860:7860 schnicklfritz/aicovermaker:latest applio

# Use multiple GPUs
docker run --gpus all -p 7860:7860 schnicklfritz/aicovermaker:latest applio

# Limit GPU memory
docker run --gpus all --gpus '"device=0,1"' -e CUDA_VISIBLE_DEVICES=0,1 schnicklfritz/aicovermaker:latest applio
```

### Performance Optimization

#### Memory Management
```bash
# Limit Docker memory
docker run --gpus all --memory="8g" --memory-swap="16g" \
  -p 7860:7860 schnicklfritz/aicovermaker:latest applio

# Set GPU memory fraction
docker run --gpus all -e TF_FORCE_GPU_ALLOW_GROWTH=true \
  -p 7860:7860 schnicklfritz/aicovermaker:latest applio
```

#### Batch Processing Optimization
```bash
# Optimal batch size for separation
docker run --gpus all -v $(pwd):/app/data \
  schnicklfritz/aicovermaker:latest separator \
  --input /app/data/song.mp3 \
  --batch_size 4  # Adjust based on GPU memory
```

## Troubleshooting

### Common Issues

#### GPU Not Detected
```bash
# Check GPU access
docker run --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi

# Reinstall NVIDIA Container Toolkit
sudo apt-get remove nvidia-container-toolkit
sudo apt-get install nvidia-container-toolkit
sudo systemctl restart docker
```

#### Audio Issues
```bash
# Check audio permissions
sudo usermod -aG audio $USER

# Test audio in container
docker run --gpus all --device /dev/snd \
  schnicklfritz/aicovermaker:latest separator --help
```

#### Memory Errors
```bash
# Increase Docker memory limit
docker run --gpus all --memory="16g" --memory-swap="32g" \
  schnicklfritz/aicovermaker:latest applio

# Reduce batch size
docker run --gpus all -v $(pwd):/app/data \
  schnicklfritz/aicovermaker:latest separator \
  --input /app/data/song.mp3 \
  --batch_size 2
```

### Logging and Debugging

#### Enable Debug Logs
```bash
docker run --gpus all -p 7860:7860 \
  -e LOG_LEVEL=DEBUG \
  schnicklfritz/aicovermaker:latest applio

docker run --gpus all -v $(pwd):/app/data \
  schnicklfritz/aicovermaker:latest separator \
  --input /app/data/song.mp3 \
  --log_level DEBUG
```

#### Check Container Logs
```bash
# View logs
docker logs <container_id>

# Follow logs
docker logs -f <container_id>

# Check resource usage
docker stats <container_id>
```

## Advanced Topics

### Custom Model Training

#### Training Voice Models
```bash
# Prepare training data
docker run --gpus all -v $(pwd)/training:/app/training \
  schnicklfritz/aicovermaker:latest python3 /app/Applio/train.py \
  --input_dir /app/training/audio \
  --output_model /app/training/model.pth \
  --epochs 100 \
  --batch_size 8
```

#### Fine-tuning Separation Models
```bash
# Fine-tune on custom dataset
docker run --gpus all -v $(pwd)/dataset:/app/dataset \
  schnicklfritz/aicovermaker:latest python3 /app/python-audio-separator/train.py \
  --train_dir /app/dataset/train \
  --val_dir /app/dataset/val \
  --model_name custom
