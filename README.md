# AICoverMaker - AI Audio Separation & Voice Conversion

A Docker image that combines [python-audio-separator](https://github.com/schnicklfritz/python-audio-separator) and [Applio](https://github.com/schnicklfritz/Applio) for AI-powered audio processing and voice conversion.

## Quick Start

### Pull the Image
```bash
docker pull schnicklfritz/aicovermaker:latest
```

### Basic Audio Separation
```bash
docker run --gpus all -v $(pwd):/app/data schnicklfritz/aicovermaker:latest separator \
  --input /app/data/song.mp3 \
  --output_dir /app/data/separated
```

### Voice Conversion (Web UI)
```bash
docker run --gpus all -p 7860:7860 schnicklfritz/aicovermaker:latest applio
# Open http://localhost:7860
```

## Features

- **AI Audio Separation**: Separate stems (vocals, instrumental, drums, bass) using multiple AI models
- **Voice Conversion**: Convert voice using RVC (Retrieval-based Voice Conversion) technology
- **GPU Acceleration**: NVIDIA CUDA support for fast processing
- **Multiple Interfaces**: Command-line separation + Web UI for voice conversion
- **Batch Processing**: Scripts for automated processing of multiple files

## Complete Documentation

For comprehensive documentation including all available plugins, usage guides, and automation scripts, see:
- [AICoverMaker-COMPREHENSIVE.md](AICoverMaker-COMPREHENSIVE.md) - Complete documentation (100+ pages)

## Available Models

### Separation Models
- **UVR Models**: uvr_vocals, uvr_instrumental, uvr_bass, uvr_drums
- **Demucs Models**: htdemucs, htdemucs_ft, hdemucs_mmi
- **MDX Models**: mdx_extra, mdx_q

### Voice Conversion Models
- Pre-trained: default, female_voice_1, male_voice_1, artist_voice, anime_voice
- Custom model training support

## Building the Image

```bash
# Clone repository
git clone https://github.com/schnicklfritz/aicovermaker.git
cd aicovermaker

# Build Docker image
docker build -t schnicklfritz/aicovermaker:latest .

# Build with GPU support
docker build --build-arg CUDA_VERSION=12.8 -t schnicklfritz/aicovermaker:gpu .
```

## GitHub Actions

This repository includes automated builds via GitHub Actions:
- **Triggers**: Push to main branch or manual workflow_dispatch
- **Features**: Multi-platform builds, registry caching
- **Output**: Images pushed to Docker Hub with multiple tags

## Usage Examples

### Advanced Separation
```bash
docker run --gpus all -v $(pwd):/app/data schnicklfritz/aicovermaker:latest separator \
  --input /app/data/input.mp3 \
  --output_dir /app/data/output \
  --model_name htdemucs \
  --output_format wav \
  --bitrate 44100
```

### With Persistent Storage
```bash
mkdir -p models data

docker run --gpus all \
  -v $(pwd)/models:/app/models \
  -v $(pwd)/data:/app/data \
  -p 7860:7860 \
  schnicklfritz/aicovermaker:latest applio
```

## Volume Mounts

- `/app/data` - Input/output audio files
- `/app/models` - AI models (persistent storage recommended)

## Environment Variables

- `CUDA_VISIBLE_DEVICES` - Control which GPUs are visible
- `PYTHONUNBUFFERED` - Set to 1 for unbuffered Python output
- `LOG_LEVEL` - DEBUG, INFO, WARNING, ERROR (default: INFO)

## License

MIT License

## Support

- GitHub Issues: https://github.com/schnicklfritz/aicovermaker/issues
- Documentation: [AICoverMaker-COMPREHENSIVE.md](AICoverMaker-COMPREHENSIVE.md)
