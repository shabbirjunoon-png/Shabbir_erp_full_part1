#!/bin/bash
set -e

# Kill any process on port 5000
fuser -k 5000/tcp 2>/dev/null || true
sleep 1

echo "Building Flutter web app..."
flutter build web --no-frequency-based-minification

echo "Starting web server on port 5000..."
python3 serve.py
