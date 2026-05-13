#!/bin/bash
set -e
echo "Building Flutter web app for production..."
flutter build web --no-frequency-based-minification
echo "Build complete."
