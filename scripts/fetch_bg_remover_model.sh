#!/usr/bin/env bash
# Build-time only: packages the free MediaPipe person-segmentation model
# with the APK. The installed app never downloads a model or uses a server.
set -euo pipefail
mkdir -p assets/models
dest="assets/models/selfie_segmenter.tflite"
url="https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter/float16/latest/selfie_segmenter.tflite"
if [ -s "$dest" ]; then
  echo "Offline segmentation model already present."
  exit 0
fi
curl --fail --location --retry 3 --connect-timeout 20 --max-time 120 "$url" -o "$dest.tmp"
test "$(wc -c < "$dest.tmp")" -gt 100000 || { echo "ERROR: Model download truncated"; rm -f "$dest.tmp"; exit 1; }
mv "$dest.tmp" "$dest"
echo "Bundled MediaPipe selfie segmentation model ($(wc -c < "$dest") bytes)."
