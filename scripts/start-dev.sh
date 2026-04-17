#!/bin/bash

# Script to start Flutter app in development environment
# Similar to: yarn start:dev

set -e

echo "🚀 Starting Flutter app in DEVELOPMENT environment..."

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the frontend directory"
    exit 1
fi

# Update Linux configuration for development
echo "🔧 Updating Linux configuration for development..."
./scripts/update_linux_config.sh

# Start the app with development environment
echo "🎮 Starting app with development environment..."
flutter run -d linux \
  --dart-define=ENVIRONMENT=development \
  --dart-define=FLAVOR=development 