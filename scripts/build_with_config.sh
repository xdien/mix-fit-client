#!/bin/bash

# Script to build Flutter app with configuration from YAML
# This script updates Linux config and builds the app

set -e

echo "🚀 Building Flutter app with environment configuration..."

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the frontend directory"
    exit 1
fi

# Get environment from argument or default to development
ENVIRONMENT=${1:-development}
CONFIG_FILE="shared/app_config/config/environments/$ENVIRONMENT.yaml"

echo "📋 Using environment: $ENVIRONMENT"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Config file not found: $CONFIG_FILE"
    echo "Available environments:"
    ls -1 shared/app_config/config/environments/*.yaml | sed 's|shared/app_config/config/environments/||' | sed 's|.yaml||'
    exit 1
fi

# Update Linux configuration
echo "🔧 Updating Linux configuration..."
./scripts/update_linux_config.sh

# Clean and get dependencies
echo "🧹 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Build the app
echo "🏗️  Building Linux app..."
flutter build linux --debug

# Get the binary name from config
BINARY_NAME=$(grep -A 10 "^app:" "$CONFIG_FILE" | grep "name:" | head -1 | sed 's/.*name: *//' | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')

echo "✅ Build completed successfully!"
echo "📦 Bundle location: build/linux/x64/debug/bundle/$BINARY_NAME"
echo "🎯 Application ID: $(grep -A 10 "^app:" "$CONFIG_FILE" | grep "bundle_id:" | head -1 | sed 's/.*bundle_id: *//')"

# Optional: Run the app
read -p "🚀 Do you want to run the app? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🎮 Starting the app..."
    flutter run -d linux
fi 