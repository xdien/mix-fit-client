#!/bin/bash

# Script to update Linux CMakeLists.txt based on environment configuration
# This script reads the config YAML and updates the binary name and application ID

set -e

echo "🔧 Updating Linux configuration from environment config..."

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the frontend directory"
    exit 1
fi

# Read config values from YAML
CONFIG_FILE="config/environments/development.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Extract values using simple grep and sed
APP_NAME=$(grep -A 10 "^app:" "$CONFIG_FILE" | grep "name:" | head -1 | sed 's/.*name: *//')
BUNDLE_ID=$(grep -A 10 "^app:" "$CONFIG_FILE" | grep "bundle_id:" | head -1 | sed 's/.*bundle_id: *//')
VERSION_NAME=$(grep -A 10 "^app:" "$CONFIG_FILE" | grep "version_name:" | head -1 | sed 's/.*version_name: *//')
VERSION_CODE=$(grep -A 10 "^app:" "$CONFIG_FILE" | grep "version_code:" | head -1 | sed 's/.*version_code: *//')

# Convert app name to binary name (lowercase, replace spaces with underscores)
BINARY_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')

echo "📋 Config values:"
echo "  App Name: $APP_NAME"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Version: $VERSION_NAME ($VERSION_CODE)"
echo "  Binary Name: $BINARY_NAME"

# Update CMakeLists.txt
CMAKELISTS_FILE="linux/CMakeLists.txt"

if [ ! -f "$CMAKELISTS_FILE" ]; then
    echo "❌ Error: CMakeLists.txt not found: $CMAKELISTS_FILE"
    exit 1
fi

echo "📝 Updating $CMAKELISTS_FILE..."

# Create backup
cp "$CMAKELISTS_FILE" "$CMAKELISTS_FILE.backup"

# Update BINARY_NAME
sed -i "s/set(BINARY_NAME \"[^\"]*\")/set(BINARY_NAME \"$BINARY_NAME\")/" "$CMAKELISTS_FILE"

# Update APPLICATION_ID
sed -i "s/set(APPLICATION_ID \"[^\"]*\")/set(APPLICATION_ID \"$BUNDLE_ID\")/" "$CMAKELISTS_FILE"

echo "✅ Linux configuration updated successfully!"
echo "  Binary Name: $BINARY_NAME"
echo "  Application ID: $BUNDLE_ID"

# Update pubspec.yaml version if different
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: *//')
EXPECTED_VERSION="$VERSION_NAME+$VERSION_CODE"

if [ "$CURRENT_VERSION" != "$EXPECTED_VERSION" ]; then
    echo "📝 Updating pubspec.yaml version from $CURRENT_VERSION to $EXPECTED_VERSION..."
    sed -i "s/^version: .*/version: $EXPECTED_VERSION/" pubspec.yaml
    echo "✅ Version updated in pubspec.yaml"
fi

echo "🎉 Configuration update completed!"
echo ""
echo "Next steps:"
echo "  1. Run: flutter clean"
echo "  2. Run: flutter pub get"
echo "  3. Run: flutter run -d linux"
echo ""
echo "The bundle will now be named: $BINARY_NAME" 