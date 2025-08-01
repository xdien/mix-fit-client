#!/bin/bash

# Build script for Android with environment configuration
# Usage: ./build.sh [environment] [options]
# Examples:
#   ./build.sh development
#   ./build.sh staging --upload
#   ./build.sh production --upload

set -e

ENVIRONMENT=${1:-development}
UPLOAD_FLAG=""

# Check for upload flag
if [[ "$*" == *"--upload"* ]]; then
    UPLOAD_FLAG="upload:true"
fi

echo "🚀 Building Android app for $ENVIRONMENT environment"

# Validate environment
case $ENVIRONMENT in
    development|staging|production)
        echo "✅ Valid environment: $ENVIRONMENT"
        ;;
    *)
        echo "❌ Invalid environment: $ENVIRONMENT"
        echo "Valid environments: development, staging, production"
        exit 1
        ;;
esac

# Check if Fastlane is available
if ! command -v fastlane &> /dev/null; then
    echo "❌ Fastlane is not installed or not in PATH"
    echo "Please install Fastlane: https://docs.fastlane.tools/getting-started/android/setup/"
    exit 1
fi

# Run the build
echo "🔨 Executing: fastlane build env:$ENVIRONMENT $UPLOAD_FLAG"
fastlane build env:$ENVIRONMENT $UPLOAD_FLAG

echo "✅ Build completed successfully!"