#!/bin/bash

# Script to start Flutter app in production environment
# Similar to: yarn start:prod

set -e

echo "🚀 Starting Flutter app in PRODUCTION environment..."

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the frontend directory"
    exit 1
fi

# Update Linux configuration for production
echo "🔧 Updating Linux configuration for production..."
ENVIRONMENT=production ./scripts/update_linux_config.sh

# Start the app with production environment
echo "🎮 Starting app with production environment..."
flutter run -d linux \
  --dart-define=ENVIRONMENT=production \
  --dart-define=FLAVOR=production 