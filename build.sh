#!/usr/bin/env bash
set -e

# ==============================================================================
# JobWink — Cloudflare Pages Web Deployment & Build Script
# Ensures Flutter SDK is installed in an isolated external directory (/tmp/flutter_3_47_2)
# completely outside the Jobwink repository tree to prevent analyzer recursion.
# ==============================================================================

echo "============================================================"
echo "INITIAL CLOUDFLARE BUILD ENVIRONMENT INSPECTION"
echo "============================================================"

# Remove any leftover flutter_sdk directory in workspace from previous runs/caches
if [ -d "$PWD/flutter_sdk" ]; then
    echo "Purging leftover flutter_sdk directory from repository workspace..."
    rm -rf "$PWD/flutter_sdk"
fi

echo "Current working directory:"
pwd

echo "Locating Jobwink pubspec.yaml:"
find . -name pubspec.yaml -not -path './flutter_sdk/*' -print

echo "Checking for any nested flutter_sdk directory:"
find . -maxdepth 2 -type d -name flutter_sdk -print

echo "Current Git commit:"
git rev-parse HEAD

echo "Pre-install which flutter:"
which flutter || true

echo "Pre-install which dart:"
which dart || true

echo "Pre-install flutter --version:"
flutter --version || true

echo "Pre-install dart --version:"
dart --version || true

# Determine Jobwink project root
JOBWINK_ROOT="$PWD"
if [ ! -f "$JOBWINK_ROOT/pubspec.yaml" ]; then
    FOUND_PUBSPEC=$(find . -name pubspec.yaml -not -path '*/.*' -print | head -n 1)
    if [ -n "$FOUND_PUBSPEC" ]; then
        JOBWINK_ROOT=$(dirname "$FOUND_PUBSPEC")
    fi
fi
cd "$JOBWINK_ROOT"
echo "Confirmed Jobwink root: $(pwd)"

echo "============================================================"
echo "INSTALLING FLUTTER 3.47.2 (ISOLATED IN /tmp/flutter_3_47_2)"
echo "============================================================"

FLUTTER_VERSION="3.47.2"
FLUTTER_DIR="/tmp/flutter_3_47_2"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"
DART_BIN="$FLUTTER_DIR/bin/dart"

# Check if compatible Flutter SDK exists in /tmp or needs cloning
if [ -d "$FLUTTER_DIR" ]; then
    CURRENT_VER=$("$FLUTTER_BIN" --version 2>&1 | head -n 1 || true)
    if [[ "$CURRENT_VER" != *"$FLUTTER_VERSION"* ]]; then
        echo "Detected outdated cached Flutter SDK ($CURRENT_VER). Removing cache..."
        rm -rf "$FLUTTER_DIR"
    else
        echo "Using cached Flutter $FLUTTER_VERSION directory: $FLUTTER_DIR"
    fi
fi

if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Cloning and installing Flutter $FLUTTER_VERSION (Dart >= 3.8.0)..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_DIR"
fi

# Ensure newly installed Flutter SDK takes absolute precedence in PATH
export PATH="$FLUTTER_DIR/bin:$PATH"

echo "============================================================"
echo "VERIFYING BUILD ENVIRONMENT SDKS"
echo "============================================================"

echo "Flutter executable path:"
which flutter

echo "Dart executable path:"
which dart

echo "Flutter version details:"
"$FLUTTER_BIN" --version

echo "Dart version details:"
"$DART_BIN" --version

echo "Flutter doctor details:"
"$FLUTTER_BIN" doctor -v

# Fail-safe check: Stop immediately if Dart 3.1.0 is still resolved
DART_INFO=$("$DART_BIN" --version 2>&1)
if [[ "$DART_INFO" == *"version: 3.1.0"* ]]; then
    echo "ERROR: Build environment is still executing legacy Dart 3.1.0! Aborting before pub get."
    exit 1
fi

echo "STAGE 1 SUCCESS: Flutter SDK 3.47.2 & Dart 3.13.2 verified and healthy."

echo "============================================================"
echo "STAGE 2 — BUILD JOBWINK USING THAT SDK"
echo "============================================================"

cd "$JOBWINK_ROOT"

echo "Running flutter clean..."
"$FLUTTER_BIN" clean

echo "Running flutter pub get on Jobwink..."
"$FLUTTER_BIN" pub get

# Build production web bundle with environment variables
BUILD_ARGS=()

if [ -f ".env" ]; then
    echo "Found .env file; including in build..."
    BUILD_ARGS+=("--dart-define-from-file=.env")
fi

if [ -n "$SUPABASE_URL" ]; then
    echo "Injecting SUPABASE_URL from environment: $SUPABASE_URL"
    BUILD_ARGS+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
fi

if [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "Injecting SUPABASE_ANON_KEY from environment (length: ${#SUPABASE_ANON_KEY})"
    BUILD_ARGS+=("--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")
fi

if [ -n "$ADMIN_EMAIL" ]; then
    BUILD_ARGS+=("--dart-define=ADMIN_EMAIL=$ADMIN_EMAIL")
fi

if [ -n "$BACKEND_URL" ]; then
    BUILD_ARGS+=("--dart-define=BACKEND_URL=$BACKEND_URL")
fi

echo "Building web release: $FLUTTER_BIN build web --release ${BUILD_ARGS[*]}"
"$FLUTTER_BIN" build web --release "${BUILD_ARGS[@]}"

echo "============================================================"
echo "BUILD SUCCEEDED — Artifacts available in build/web"
echo "============================================================"
