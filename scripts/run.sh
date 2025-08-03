#!/bin/bash

# Script runner for Flutter app (similar to yarn/npm scripts)
# Usage: ./scripts/run.sh start:dev
# Usage: ./scripts/run.sh build:staging

set -e

# Check if we're in the frontend directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the frontend directory"
    exit 1
fi

# Get the script name from argument
SCRIPT_NAME=${1:-"start"}

# Define available scripts
declare -A SCRIPTS=(
    ["start"]="bash scripts/start-dev.sh"
    ["start:dev"]="bash scripts/start-dev.sh"
    ["start:staging"]="bash scripts/start-staging.sh"
    ["start:prod"]="bash scripts/start-prod.sh"
    ["build"]="bash scripts/build_with_config.sh"
    ["build:dev"]="bash scripts/build_with_config.sh development"
    ["build:staging"]="bash scripts/build_with_config.sh staging"
    ["build:prod"]="bash scripts/build_with_config.sh production"
    ["update-config"]="bash scripts/update_linux_config.sh"
    ["clean"]="flutter clean"
    ["get"]="flutter pub get"
    ["test"]="flutter test"
    ["format"]="dart format ."
    ["analyze"]="flutter analyze"
)

# Check if script exists
if [[ ! ${SCRIPTS[$SCRIPT_NAME]} ]]; then
    echo "❌ Error: Script '$SCRIPT_NAME' not found"
    echo ""
    echo "Available scripts:"
    for script in "${!SCRIPTS[@]}"; do
        echo "  $script"
    done
    exit 1
fi

# Execute the script
echo "🚀 Running: $SCRIPT_NAME"
echo "Command: ${SCRIPTS[$SCRIPT_NAME]}"
echo ""

eval "${SCRIPTS[$SCRIPT_NAME]}" 