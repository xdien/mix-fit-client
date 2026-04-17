#!/bin/bash

# Script to start Flutter app in staging environment
# Similar to: yarn start:staging

set -e

echo "🚀 Starting Flutter app in STAGING environment..."

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the frontend directory"
    exit 1
fi

# Update Linux configuration for staging
echo "🔧 Updating Linux configuration for staging..."
ENVIRONMENT=staging ./scripts/update_linux_config.sh

# Start the app with staging environment
echo "🎮 Starting app with staging environment..."
flutter run -d linux \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=FLAVOR=staging 