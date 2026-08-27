#!/usr/bin/env bash
set -e

# ==============================================================================
# JobWink — Production Web Deployment & Build Script
# Ensures Flutter 3.47.2 (Dart 3.13.2 >= 3.8.0) is installed and used.
# ==============================================================================

echo "============================================================"
echo "JOBWINK — DEPLOYMENT BUILD INITIALIZATION"
echo "============================================================"

FLUTTER_VERSION="3.47.2"
FLUTTER_DIR="$PWD/flutter_sdk"

# Check if compatible Flutter SDK exists or needs installation
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Installing Flutter $FLUTTER_VERSION..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b $FLUTTER_VERSION "$FLUTTER_DIR"
else
    echo "Using existing Flutter directory: $FLUTTER_DIR"
fi

# Ensure newly installed Flutter SDK takes precedence in PATH
export PATH="$FLUTTER_DIR/bin:$PATH"

echo "============================================================"
echo "VERIFYING BUILD ENVIRONMENT SDKS"
echo "============================================================"

echo "Flutter executable path:"
which flutter

echo "Dart executable path:"
which dart

echo "Flutter version details:"
flutter --version

echo "Dart version details:"
dart --version

echo "============================================================"
echo "RESOLVING DEPENDENCIES & BUILDING WEB APPLICATION"
echo "============================================================"

flutter clean
flutter pub get
flutter analyze

# Build production web bundle
if [ -f ".env" ]; then
    echo "Building with .env definitions..."
    flutter build web --release --dart-define-from-file=.env
else
    echo "Building without .env file..."
    flutter build web --release
fi

echo "============================================================"
echo "BUILD SUCCEEDED — Artifacts available in build/web"
echo "============================================================"
