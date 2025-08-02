# Android Code Signing Setup Guide

This guide explains how to set up code signing for the Android application across different environments.

## Overview

The application supports environment-specific code signing with the following features:

- **Environment-specific keystores**: Different signing certificates for development, staging, and production
- **Secure credential management**: Environment variables and encrypted storage for sensitive data
- **Certificate validation**: Automatic validation of certificate expiry and strength
- **Audit logging**: Track all signing operations for security compliance

## Environment Configuration

Each environment has its own signing configuration in the respective YAML files:

- `config/environments/development.yaml`
- `config/environments/staging.yaml`
- `config/environments/production.yaml`

### Signing Configuration Structure

```yaml
signing:
  store_file: "release.keystore"           # Keystore filename
  store_password_env: "RELEASE_STORE_PASSWORD"  # Environment variable for store password
  key_alias: "release"                     # Key alias within keystore
  key_password_env: "RELEASE_KEY_PASSWORD" # Environment variable for key password
```

## Keystore Management

### Keystore Locations

The system searches for keystores in the following order:

1. `android/keystores/` (recommended)
2. `android/app/`
3. `android/`
4. `~/.android/`
5. Absolute path (if specified)

### Development Environment

For development, a debug keystore is automatically created if it doesn't exist:

```bash
# Generate debug keystore manually
cd android
fastlane generate_debug_keystore
```

### Production Keystores

For staging and production environments, you need to provide your own keystores:

1. **Generate a new keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore android/keystores/release.keystore \
     -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Place existing keystore** in `android/keystores/` directory

3. **Set secure permissions**:
   ```bash
   chmod 600 android/keystores/*.keystore
   ```

## Credential Management

### Environment Variables

Set the following environment variables for each environment:

#### Development
```bash
export DEBUG_STORE_PASSWORD="android"
export DEBUG_KEY_PASSWORD="android"
```

#### Staging
```bash
export STAGING_STORE_PASSWORD="your-staging-store-password"
export STAGING_KEY_PASSWORD="your-staging-key-password"
```

#### Production
```bash
export RELEASE_STORE_PASSWORD="your-production-store-password"
export RELEASE_KEY_PASSWORD="your-production-key-password"
```

### Credentials File (Alternative)

You can also use a credentials file for local development:

1. **Generate template**:
   ```bash
   cd android
   fastlane setup_credentials env:production
   ```

2. **Edit credentials.yaml**:
   ```yaml
   development:
     DEBUG_STORE_PASSWORD: "android"
     DEBUG_KEY_PASSWORD: "android"
   staging:
     STAGING_STORE_PASSWORD: "your-staging-password"
     STAGING_KEY_PASSWORD: "your-staging-password"
   production:
     RELEASE_STORE_PASSWORD: "your-production-password"
     RELEASE_KEY_PASSWORD: "your-production-password"
   ```

3. **Load credentials**:
   ```bash
   fastlane load_credentials env:production
   ```

### Security Best Practices

- **Never commit keystores or credentials** to version control
- **Use strong passwords** (minimum 8 characters, mixed case, numbers, symbols)
- **Set secure file permissions** (600 for keystores, 600 for credentials)
- **Rotate certificates** before expiry
- **Use different certificates** for each environment

## CI/CD Integration

### GitHub Actions

```yaml
- name: Setup signing credentials
  env:
    RELEASE_STORE_PASSWORD: ${{ secrets.RELEASE_STORE_PASSWORD }}
    RELEASE_KEY_PASSWORD: ${{ secrets.RELEASE_KEY_PASSWORD }}
  run: |
    echo "${{ secrets.RELEASE_KEYSTORE }}" | base64 -d > android/keystores/release.keystore
    cd android
    fastlane build env:production upload:true
```

### Environment Secrets

Store the following secrets in your CI/CD system:

- `RELEASE_KEYSTORE`: Base64-encoded keystore file
- `RELEASE_STORE_PASSWORD`: Keystore password
- `RELEASE_KEY_PASSWORD`: Key password
- `STAGING_KEYSTORE`: Base64-encoded staging keystore
- `STAGING_STORE_PASSWORD`: Staging keystore password
- `STAGING_KEY_PASSWORD`: Staging key password

## Fastlane Commands

### Building with Signing

```bash
# Build development (debug keystore)
fastlane dev

# Build staging with signing
fastlane staging

# Build production with signing
fastlane prod

# Build specific environment
fastlane build env:production
```

### Certificate Management

```bash
# Validate certificates for specific environment
fastlane validate_certificates env:production

# Validate all environment certificates
fastlane validate_all_certificates

# Setup credentials
fastlane setup_credentials env:production

# Load credentials from file
fastlane load_credentials env:production file:path/to/credentials.yaml

# Audit signing access
fastlane audit_signing env:production
```

### Certificate Validation

```bash
# Check certificate details
fastlane validate_certificates env:production

# This will check:
# - Certificate expiry date
# - Key strength (RSA 2048+ recommended)
# - Signature algorithm (SHA-256+ recommended)
# - Certificate chain validity
```

## Troubleshooting

### Common Issues

1. **"Keystore not found"**
   - Check keystore location and filename
   - Ensure file permissions are correct
   - Verify path in environment configuration

2. **"Invalid keystore password"**
   - Check environment variable is set correctly
   - Verify password matches keystore
   - Ensure no extra spaces or characters

3. **"Certificate expired"**
   - Generate new keystore with longer validity
   - Update app signing configuration
   - Re-sign and redistribute app

4. **"Weak signature algorithm"**
   - Generate new keystore with SHA-256 or higher
   - Use RSA 2048-bit or ECDSA keys
   - Update signing configuration

### Debug Commands

```bash
# Check keystore details
keytool -list -v -keystore android/keystores/release.keystore

# Verify certificate
keytool -list -keystore android/keystores/release.keystore -alias release

# Test keystore access
keytool -list -keystore android/keystores/release.keystore -storepass your-password
```

## Security Audit

The system automatically logs all signing operations:

- **Audit logs**: Stored in `build/audit/signing-audit-YYYYMMDD.json`
- **Certificate reports**: Stored in `build/certificate-report.txt`
- **Summary reports**: Stored in `build/certificate-summary.json`

### Audit Information Includes

- Timestamp of signing operation
- Environment and user information
- Git commit hash
- CI/CD environment detection
- Certificate validity status

## File Structure

```
android/
├── keystores/              # Keystore files (gitignored)
│   ├── debug.keystore     # Development keystore
│   ├── staging.keystore   # Staging keystore
│   └── release.keystore   # Production keystore
├── fastlane/
│   ├── signing_manager.rb      # Main signing logic
│   ├── certificate_validator.rb # Certificate validation
│   ├── credential_manager.rb   # Credential management
│   └── Fastfile               # Fastlane configuration
├── credentials.yaml       # Local credentials (gitignored)
└── build.gradle          # Updated with signing config
```

## Enhanced Security Features

### Encrypted Credential Storage

For additional security, you can encrypt your credentials file:

```bash
# Encrypt credentials
fastlane encrypt_credentials env:production key:your-encryption-key file:credentials.yaml

# Decrypt and load credentials
fastlane decrypt_credentials env:production key:your-encryption-key file:credentials.encrypted
```

### Comprehensive Security Audit

Run a complete security audit of your signing setup:

```bash
# Full security audit
fastlane security_audit env:production

# Generate security report
fastlane security_report env:production

# Validate keystore integrity
fastlane validate_keystore env:production

# Comprehensive certificate validation
fastlane comprehensive_cert_validation env:production
```

### Automated Setup

Use the comprehensive setup script to configure signing for all environments:

```bash
cd android
./setup_signing_comprehensive.sh
```

This script will:
- Create secure directory structure
- Generate debug keystore
- Guide you through production keystore setup
- Validate configurations
- Run security checks
- Set proper file permissions

## Security Best Practices

### Keystore Security
- **Use strong passwords**: Minimum 12 characters with mixed case, numbers, and symbols
- **Secure file permissions**: 600 for keystores, 700 for keystores directory
- **Regular backups**: Store keystores in secure, encrypted backup locations
- **Access control**: Limit who has access to production keystores
- **Certificate rotation**: Plan for certificate renewal before expiry

### Credential Management
- **Environment variables**: Use secure environment variables in CI/CD
- **Encrypted storage**: Use encrypted credential files for local development
- **No version control**: Never commit keystores or credentials
- **Audit trails**: Monitor all signing operations
- **Principle of least privilege**: Grant minimal necessary access

### CI/CD Security
- **Secure secrets**: Use your CI/CD platform's secure secret storage
- **Environment isolation**: Separate credentials for each environment
- **Build isolation**: Use clean build environments
- **Artifact signing**: Verify all build artifacts are properly signed
- **Access logging**: Log all build and deployment activities

## Advanced Commands

### Certificate Management
```bash
# Validate all environment certificates
fastlane validate_all_certificates

# Generate comprehensive certificate report
fastlane comprehensive_cert_validation env:production

# Check certificate chain and usage
fastlane validate_certificates env:production
```

### Credential Operations
```bash
# Setup CI/CD credentials
fastlane setup_ci_credentials env:production

# Load credentials from custom file
fastlane load_credentials env:production file:path/to/credentials.yaml

# Generate credentials template
fastlane setup_credentials env:production
```

### Security Operations
```bash
# Run complete security audit
fastlane security_audit env:production

# Generate security report
fastlane security_report env:production

# Audit signing access
fastlane audit_signing env:production
```

## Troubleshooting

### Enhanced Diagnostics

1. **Security Audit Issues**
   ```bash
   fastlane security_audit env:production
   # Check build/security/ for detailed reports
   ```

2. **Certificate Problems**
   ```bash
   fastlane comprehensive_cert_validation env:production
   # Check build/comprehensive-certificate-report.json
   ```

3. **Credential Issues**
   ```bash
   fastlane validate_keystore env:production
   # Validates keystore integrity and access
   ```

### Common Security Issues

1. **Insecure File Permissions**
   - Run: `chmod 600 keystores/*.keystore`
   - Run: `chmod 700 keystores/`

2. **Weak Passwords**
   - Use password generators for strong passwords
   - Avoid common passwords like "android", "password"
   - Use different passwords for store and key

3. **Certificate Expiry**
   - Monitor certificate expiry dates
   - Plan renewal 90 days before expiry
   - Test with new certificates in staging first

4. **Credential Exposure**
   - Check environment variables don't contain real passwords
   - Use encrypted credential storage
   - Audit credential access regularly

## Support

For issues with code signing setup:

1. Check this documentation
2. Run `fastlane security_audit env:your-environment`
3. Run `fastlane validate_certificates env:your-environment`
4. Check security reports in `build/security/`
5. Check audit logs in `build/audit/`
6. Verify environment configuration files
7. Test keystore access manually with keytool
8. Use the setup script: `./setup_signing_comprehensive.sh`