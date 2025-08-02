#!/bin/bash

# Comprehensive Android Code Signing Setup Script
# This script sets up code signing for all environments with security best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Check if running from correct directory
if [ ! -f "fastlane/Fastfile" ]; then
    print_error "Please run this script from the android directory"
    exit 1
fi

print_header "Android Code Signing Setup"

# Create necessary directories
print_status "Creating directory structure..."
mkdir -p keystores
mkdir -p ../build/security
mkdir -p ../build/audit

# Set secure permissions for keystores directory
chmod 700 keystores
print_success "Directory structure created with secure permissions"

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    print_error "keytool not found. Please install Java JDK"
    exit 1
fi

# Check if fastlane is available
if ! command -v fastlane &> /dev/null; then
    print_error "fastlane not found. Please install fastlane"
    exit 1
fi

print_header "Setting up Development Environment"

# Generate debug keystore if it doesn't exist
if [ ! -f "keystores/debug.keystore" ]; then
    print_status "Generating debug keystore..."
    keytool -genkey -v \
        -keystore keystores/debug.keystore \
        -storepass android \
        -alias debug \
        -keypass android \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US"
    
    chmod 600 keystores/debug.keystore
    print_success "Debug keystore created"
else
    print_success "Debug keystore already exists"
fi

print_header "Environment Configuration"

# Function to setup environment
setup_environment() {
    local env=$1
    local keystore_name=$2
    local store_password_var=$3
    local key_password_var=$4
    local key_alias=$5
    
    print_status "Setting up $env environment..."
    
    # Check if keystore exists
    if [ ! -f "keystores/$keystore_name" ] && [ "$env" != "development" ]; then
        print_warning "Keystore keystores/$keystore_name not found for $env environment"
        
        read -p "Do you want to generate a new keystore for $env? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Generating keystore for $env environment..."
            
            # Get keystore details
            echo "Please provide the following information for the $env keystore:"
            read -p "Organization (O): " org
            read -p "Organizational Unit (OU): " ou
            read -p "City (L): " city
            read -p "State (ST): " state
            read -p "Country Code (C): " country
            
            # Generate strong password
            read -s -p "Enter store password: " store_pass
            echo
            read -s -p "Confirm store password: " store_pass_confirm
            echo
            
            if [ "$store_pass" != "$store_pass_confirm" ]; then
                print_error "Passwords do not match"
                return 1
            fi
            
            read -s -p "Enter key password: " key_pass
            echo
            read -s -p "Confirm key password: " key_pass_confirm
            echo
            
            if [ "$key_pass" != "$key_pass_confirm" ]; then
                print_error "Key passwords do not match"
                return 1
            fi
            
            # Generate keystore
            keytool -genkey -v \
                -keystore "keystores/$keystore_name" \
                -storepass "$store_pass" \
                -alias "$key_alias" \
                -keypass "$key_pass" \
                -keyalg RSA \
                -keysize 2048 \
                -validity 10000 \
                -dname "CN=$org, OU=$ou, L=$city, ST=$state, C=$country"
            
            chmod 600 "keystores/$keystore_name"
            print_success "Keystore generated for $env environment"
            
            # Update environment file
            if [ -f ".env.$env" ]; then
                # Update existing environment file
                sed -i.bak "s/^$store_password_var=.*/$store_password_var=$store_pass/" ".env.$env"
                sed -i.bak "s/^$key_password_var=.*/$key_password_var=$key_pass/" ".env.$env"
                rm ".env.$env.bak"
                print_success "Updated .env.$env with new passwords"
            fi
        else
            print_warning "Skipping keystore generation for $env"
        fi
    elif [ -f "keystores/$keystore_name" ]; then
        print_success "Keystore exists for $env environment"
        
        # Validate keystore
        print_status "Validating keystore for $env..."
        if [ -f ".env.$env" ]; then
            source ".env.$env"
            store_pass_value=$(eval echo \$$store_password_var)
            
            if [ -n "$store_pass_value" ] && [ "$store_pass_value" != "your_${env}_store_password" ]; then
                keytool -list -keystore "keystores/$keystore_name" -storepass "$store_pass_value" -alias "$key_alias" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    print_success "Keystore validation passed for $env"
                else
                    print_warning "Keystore validation failed for $env - check passwords"
                fi
            else
                print_warning "Store password not set for $env environment"
            fi
        fi
    fi
}

# Setup environments
setup_environment "staging" "staging.keystore" "STAGING_STORE_PASSWORD" "STAGING_KEY_PASSWORD" "staging"
setup_environment "production" "release.keystore" "RELEASE_STORE_PASSWORD" "RELEASE_KEY_PASSWORD" "release"

print_header "Security Configuration"

# Check file permissions
print_status "Checking file permissions..."
for keystore in keystores/*.keystore; do
    if [ -f "$keystore" ]; then
        perms=$(stat -c "%a" "$keystore" 2>/dev/null || stat -f "%A" "$keystore" 2>/dev/null)
        if [ "$perms" = "600" ]; then
            print_success "$(basename $keystore): Secure permissions (600)"
        else
            print_warning "$(basename $keystore): Insecure permissions ($perms), fixing..."
            chmod 600 "$keystore"
            print_success "$(basename $keystore): Permissions fixed"
        fi
    fi
done

# Generate credentials template if it doesn't exist
if [ ! -f "credentials.yaml" ] && [ ! -f "credentials.yaml.template" ]; then
    print_status "Generating credentials template..."
    fastlane setup_credentials env:production
    print_success "Credentials template generated"
fi

print_header "Validation"

# Validate all environments
print_status "Validating environment configurations..."
for env in development staging production; do
    print_status "Validating $env environment..."
    if fastlane validate_config env:$env > /dev/null 2>&1; then
        print_success "$env: Configuration valid"
    else
        print_warning "$env: Configuration validation failed"
    fi
done

# Run security audit for development environment
print_status "Running security audit..."
if fastlane security_audit env:development > /dev/null 2>&1; then
    print_success "Security audit passed"
else
    print_warning "Security audit found issues - check logs"
fi

print_header "Setup Complete"

print_success "Android code signing setup completed!"
echo
print_status "Next steps:"
echo "1. Update .env files with your actual passwords"
echo "2. Add credentials.yaml to .gitignore"
echo "3. Test builds with: fastlane dev, fastlane staging, fastlane prod"
echo "4. Run security audit: fastlane security_audit env:production"
echo
print_status "Available commands:"
echo "  fastlane dev                    - Build development version"
echo "  fastlane staging                - Build staging version"
echo "  fastlane prod                   - Build production version"
echo "  fastlane validate_certificates  - Validate certificates"
echo "  fastlane security_audit         - Run security audit"
echo "  fastlane encrypt_credentials    - Encrypt credentials file"
echo
print_warning "Remember to:"
echo "- Keep your keystores secure and backed up"
echo "- Use strong passwords for production keystores"
echo "- Never commit keystores or credentials to version control"
echo "- Regularly check certificate expiry dates"