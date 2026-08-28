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

# Automatically load local .env variables if present (for local testing/builds)
if [ -f "$JOBWINK_ROOT/.env" ]; then
    echo "Local .env file detected; loading environment variables..."
    while IFS='=' read -r key val || [ -n "$key" ]; do
        # Trim leading/trailing whitespace
        key=$(echo "$key" | xargs)
        # Skip comments and empty lines
        if [[ -n "$key" && ! "$key" =~ ^# ]]; then
            # Remove any surrounding quotes from value
            val=$(echo "$val" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            # Only set if not already present in environment
            if [ -z "${!key}" ]; then
                export "$key"="$val"
            fi
        fi
    done < "$JOBWINK_ROOT/.env"
fi

echo "============================================================"
echo "CHECKING PRODUCTION BUILD-TIME ENVIRONMENT VARIABLES"
echo "============================================================"
echo "SUPABASE_URL_PRESENT: ${SUPABASE_URL:+YES}"
echo "SUPABASE_ANON_KEY_PRESENT: ${SUPABASE_ANON_KEY:+YES}"
echo "BACKEND_URL_PRESENT: ${BACKEND_URL:+YES}"
echo "ADMIN_EMAIL_PRESENT: ${ADMIN_EMAIL:+YES}"
echo "GEMINI_API_KEY_PRESENT: ${GEMINI_API_KEY:+YES}"
echo "OPENAI_API_KEY_PRESENT: ${OPENAI_API_KEY:+YES}"
echo "GROQ_API_KEY_PRESENT: ${GROQ_API_KEY:+YES}"
echo "XAI_API_KEY_PRESENT: ${XAI_API_KEY:+YES}"
echo "MISTRAL_API_KEY_PRESENT: ${MISTRAL_API_KEY:+YES}"
echo "CEREBRAS_API_KEY_PRESENT: ${CEREBRAS_API_KEY:+YES}"
echo "NVIDIA_API_KEY_PRESENT: ${NVIDIA_API_KEY:+YES}"
echo "============================================================"

# Verification check: Fail fast if essential Supabase credentials are missing
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo ""
    echo "FATAL BUILD ERROR: Supabase production configuration is missing!"
    echo "SUPABASE_URL_PRESENT: ${SUPABASE_URL:+YES:-NO}"
    echo "SUPABASE_ANON_KEY_PRESENT: ${SUPABASE_ANON_KEY:+YES:-NO}"
    echo ""
    echo "Action required:"
    echo "1. Go to Cloudflare Pages Dashboard -> Jobwink -> Settings -> Environment variables."
    echo "2. Add SUPABASE_URL and SUPABASE_ANON_KEY under the Production environment."
    echo "3. Save and trigger a new deployment."
    echo ""
    exit 1
fi

# Build a temporary JSON file for --dart-define-from-file to safely pass all config
DEFINES_JSON="$JOBWINK_ROOT/dart_defines.json"
trap 'rm -f "$DEFINES_JSON"' EXIT INT TERM

# Create valid JSON from environment variables
python3 -c "
import os, json
keys = [
    'SUPABASE_URL', 'SUPABASE_ANON_KEY', 'BACKEND_URL', 'ADMIN_EMAIL',
    'GEMINI_API_KEY', 'GCP_PROJECT_NUMBER', 'OPENAI_API_KEY',
    'GROQ_API_KEY', 'XAI_API_KEY', 'MISTRAL_API_KEY',
    'CEREBRAS_API_KEY', 'NVIDIA_API_KEY'
]
data = {k: os.environ[k] for k in keys if k in os.environ and os.environ[k]}
with open('$DEFINES_JSON', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || node -e "
const fs = require('fs');
const keys = [
    'SUPABASE_URL', 'SUPABASE_ANON_KEY', 'BACKEND_URL', 'ADMIN_EMAIL',
    'GEMINI_API_KEY', 'GCP_PROJECT_NUMBER', 'OPENAI_API_KEY',
    'GROQ_API_KEY', 'XAI_API_KEY', 'MISTRAL_API_KEY',
    'CEREBRAS_API_KEY', 'NVIDIA_API_KEY'
];
const data = {};
for (const k of keys) {
    if (process.env[k]) data[k] = process.env[k];
}
fs.writeFileSync('$DEFINES_JSON', JSON.stringify(data, null, 2));
" 2>/dev/null || {
    echo "{" > "$DEFINES_JSON"
    first=1
    for var in SUPABASE_URL SUPABASE_ANON_KEY BACKEND_URL ADMIN_EMAIL GEMINI_API_KEY GCP_PROJECT_NUMBER OPENAI_API_KEY GROQ_API_KEY XAI_API_KEY MISTRAL_API_KEY CEREBRAS_API_KEY NVIDIA_API_KEY; do
        val="${!var}"
        if [ -n "$val" ]; then
            if [ $first -eq 0 ]; then echo "," >> "$DEFINES_JSON"; fi
            escaped_val=$(printf '%s' "$val" | sed 's/\\/\\\\/g; s/"/\\"/g')
            printf '  "%s": "%s"' "$var" "$escaped_val" >> "$DEFINES_JSON"
            first=0
        fi
    done
    echo "" >> "$DEFINES_JSON"
    echo "}" >> "$DEFINES_JSON"
}

echo "Successfully generated compile-time Dart configuration definition."
echo "Executing: $FLUTTER_BIN build web --release --dart-define-from-file=dart_defines.json"
"$FLUTTER_BIN" build web --release --dart-define-from-file="$DEFINES_JSON"

echo "============================================================"
echo "BUILD SUCCEEDED — Artifacts available in build/web"
echo "============================================================"

