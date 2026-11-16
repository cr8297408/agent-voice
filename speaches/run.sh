#!/usr/bin/env bash
# (Re)create the Speaches container on the NVIDIA GPU and make sure both models are downloaded and loaded.
# Bound to 127.0.0.1 only: the Mac reaches it through SSH, never over the network.
set -euo pipefail
IMAGE=ghcr.io/speaches-ai/speaches:latest-cuda
STT=deepdml/faster-whisper-large-v3-turbo-ct2
TTS=speaches-ai/Kokoro-82M-v1.0-ONNX
URL=http://127.0.0.1:8000

docker rm -f speaches >/dev/null 2>&1 || true
# WHISPER__TTL=-1 keeps models in VRAM forever; Speaches reuses it for Kokoro too.
docker run -d --name speaches --restart unless-stopped --gpus all \
  -e WHISPER__TTL=-1 -e LOG_LEVEL=info \
  -p 127.0.0.1:8000:8000 \
  -v speaches-hf-cache:/home/ubuntu/.cache/huggingface/hub \
  "$IMAGE" >/dev/null

until curl -sf "$URL/health" >/dev/null; do sleep 2; done
for m in "$STT" "$TTS"; do curl -sf -X POST "$URL/v1/models/$m" >/dev/null; done

wav=$(mktemp --suffix .wav)
trap 'rm -f "$wav"' EXIT
curl -sf -o "$wav" "$URL/v1/audio/speech" -H 'Content-Type: application/json' \
  -d "{\"model\":\"$TTS\",\"voice\":\"ef_dora\",\"input\":\"Listo.\",\"response_format\":\"wav\"}"
curl -sf "$URL/v1/audio/transcriptions" -F "file=@$wav" -F "model=$STT" >/dev/null
echo "speaches up on $URL with $STT and $TTS loaded"
