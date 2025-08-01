#!/bin/bash

# Android Code Signing Setup Script
# This script helps set up code signing for different environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSTORES_DIR="$SCRIPT_DIR/keystores"
ANDROID_DIR="$SCRIPT_DIR"

echo "🔐 Android Code Signing Setup"
echo "=============================="

# Create keystores directory
mkdir -p "$KEYSTORES_DIR"
chmod 700 "$KEYSTORES_DIR"

echo "📁 Created keystores directory: $KEYSTORES_DIR"

# Function to generate keystore
generate_keystore() {
    local env=$1
    local keystore_name=$2
    local alias=$3
    local keystore_path="$KEYSTORES_DIR/$keystore_name"
    
    if [[ -f "$keystore_path" ]]; then
        echo "⚠️  Keystore already exists: $keystore_path"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping $env keystore generation"
            return
        fi
    fi
    
    echo "🔨 Generating $env keystore..."
    
    # Get keystore details
    read -p "Enter organization name (default: Your Organization): " org_name
    org_name=${org_name:-"Your Organization"}
    
    read -p "Enter organizational unit (default: IT Department): " org_unit
    org_unit=${org_unit:-"IT Department"}
    
    read -p "Enter city (default: Your City): " city
    city=${city:-"Your City"}
    
    read -p "Enter state/province (default: Your State): " state
    state=${state:-"Your State"}
    
    read -p "Enter country code (default: US): " country
    country=${country:-"US"}
    
    # Generate keystore
    keytool -genkey -v \
        -keystore "$keystore_path" \
        -alias "$alias" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=$org_name, OU=$org_unit, L=$city, ST=$state, C=$country"
    
    # Set secure permissions
    chmod 600 "$keystore_path"
    
    echo "✅ Generated keystore: $keystore_path"
}

# Function to setup environment variables
setup_env_vars() {
    local env=$1
    local env_file="$ANDROID_DIR/.env.$env"
    
    echo "🔧 Setting up environment variables for $env"
    
    case $env in
        "development")
            cat > "$env_file" << EOF
# Development environment variables
DEBUG_STORE_PASSWORD=android
DEBUG_KEY_PASSWORD=android
EOF
            ;;
        "staging")
            echo "Enter staging keystore passwords:"
            read -s -p "Store password: " store_pass
            echo
            read -s -p "Key password: " key_pass
            echo
            
            cat > "$env_file" << EOF
# Staging environment variables
STAGING_STORE_PASSWORD=$store_pass
STAGING_KEY_PASSWORD=$key_pass
EOF
            ;;
        "production")
            echo "Enter production keystore passwords:"
            read -s -p "Store password: " store_pass
            echo
            read -s -p "Key password: " key_pass
            echo
            
            cat > "$env_file" << EOF
# Production environment variables
RELEASE_STORE_PASSWORD=$store_pass
RELEASE_KEY_PASSWORD=$key_pass
EOF
            ;;
    esac
    
    chmod 600 "$env_file"
    echo "✅ Environment variables saved to $env_file"
}

# Function to validate setup
validate_setup() {
    local env=$1
    
    echo "🔍 Validating $env setup..."
    
    cd "$ANDROID_DIR"
    
    # Source environment variables
    if [[ -f ".env.$env" ]]; then
        source ".env.$env"
    fi
    
    # Run Fastlane validation
    if command -v fastlane &> /dev/null; then
        fastlane validate_certificates env:$env
    else
        echo "⚠️  Fastlane not found. Install with: gem install fastlane"
    fi
}

# Main menu
while true; do
    echo
    echo "Select an option:"
    echo "1) Generate development keystore"
    echo "2) Generate staging keystore"
    echo "3) Generate production keystore"
    echo "4) Setup environment variables"
    echo "5) Validate setup"
    echo "6) Show current keystores"
    echo "7) Exit"
    echo
    
    read -p "Enter your choice (1-7): " choice
    
    case $choice in
        1)
            generate_keystore "development" "debug.keystore" "debug"
            setup_env_vars "development"
            ;;
        2)
            generate_keystore "staging" "staging.keystore" "staging"
            setup_env_vars "staging"
            ;;
        3)
            generate_keystore "production" "release.keystore" "release"
            setup_env_vars "production"
            ;;
        4)
            echo "Select environment:"
            echo "1) Development"
            echo "2) Staging"
            echo "3) Production"
            read -p "Enter choice (1-3): " env_choice
            
            case $env_choice in
                1) setup_env_vars "development" ;;
                2) setup_env_vars "staging" ;;
                3) setup_env_vars "production" ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
        5)
            echo "Select environment to validate:"
            echo "1) Development"
            echo "2) Staging"
            echo "3) Production"
            read -p "Enter choice (1-3): " env_choice
            
            case $env_choice in
                1) validate_setup "development" ;;
                2) validate_setup "staging" ;;
                3) validate_setup "production" ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
        6)
            echo "📋 Current keystores:"
            if [[ -d "$KEYSTORES_DIR" ]]; then
                ls -la "$KEYSTORES_DIR"/*.keystore 2>/dev/null || echo "No keystores found"
            else
                echo "Keystores directory not found"
            fi
            ;;
        7)
            echo "👋 Setup complete!"
            echo
            echo "Next steps:"
            echo "1. Review the generated keystores in: $KEYSTORES_DIR"
            echo "2. Add environment variables to your CI/CD system"
            echo "3. Test building with: fastlane build env:development"
            echo "4. Read the documentation: SIGNING_SETUP.md"
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1-7."
            ;;
    esac
done