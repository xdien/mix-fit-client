#!/bin/bash

# Simple script to setup development configuration
# This script copies the example file to create development.yaml

set -e

echo "🔧 Setting up development configuration..."

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the frontend directory"
    exit 1
fi

# Check if development.yaml already exists
if [ -f "config/environments/development.yaml" ]; then
    echo "✅ Development config already exists"
    echo "   If you want to reset it, delete the file and run this script again"
    exit 0
fi

# Check if example file exists
if [ ! -f "config/environments/development.yaml.example" ]; then
    echo "❌ Error: Example file not found at config/environments/development.yaml.example"
    exit 1
fi

# Copy example to development.yaml
echo "📋 Copying development.yaml.example to development.yaml..."
cp config/environments/development.yaml.example config/environments/development.yaml

echo "✅ Development configuration created successfully!"
echo ""
echo "📝 You can now customize the configuration in config/environments/development.yaml"
echo "   - Update API endpoints for your local backend"
echo "   - Update WebSocket URL for your local server"
echo "   - Adjust other settings as needed"
echo ""
echo "🚀 Ready to run Flutter commands:"
echo "   flutter pub get"
echo "   flutter run" 