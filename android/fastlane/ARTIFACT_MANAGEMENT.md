# Build Artifact Management

This document describes the build artifact generation and naming system implemented for the Fastlane environment configuration.

## Overview

The artifact management system provides:
- Environment-specific APK/AAB naming conventions
- Build metadata generation (build info JSON files)
- Structured directory organization for build artifacts
- Build artifact validation and checksums
- Automated cleanup and maintenance tools

## Features

### 1. Environment-Specific Naming

Build artifacts are automatically renamed using a consistent convention:

**Format**: `{app-name}-{environment}-{build-type}-v{version}-{build-number}-{timestamp}.{extension}`

**Examples**:
- `mix-fit-development-debug-v1.0.0-1-20250821-083656.apk`
- `mix-fit-production-release-v2.1.0-42-20250821-143022.aab`

### 2. Structured Directory Organization

```
build/android/
├── development/
│   ├── 20250821_083656/          # Timestamped build directory
│   │   ├── apk/                  # APK files
│   │   ├── aab/                  # AAB files
│   │   ├── metadata/             # Build metadata and checksums
│   │   ├── logs/                 # Build logs
│   │   └── build-info.json      # Simplified build info
│   └── latest -> 20250821_083656 # Symlink to latest build
├── staging/
└── production/
```

### 3. Build Metadata

Each build generates comprehensive metadata including:

#### build-info.json (Simplified)
```json
{
  "environment": "production",
  "app_name": "Mix Fit",
  "bundle_id": "com.ankhanh.mixfit.prod",
  "version_name": "1.0.0",
  "version_code": 1,
  "build_type": "release",
  "build_time": "2025-08-21T08:36:56Z",
  "api_base_url": "https://api.mixfit.com",
  "websocket_url": "wss://ws.mixfit.com"
}
```

#### metadata/build-info.json (Detailed)
```json
{
  "build_info": {
    "environment": "production",
    "app_name": "Mix Fit",
    "bundle_id": "com.ankhanh.mixfit.prod",
    "version_name": "1.0.0",
    "version_code": 1,
    "build_type": "release",
    "build_time": "2025-08-21T08:36:56Z",
    "build_timestamp": 1724234216
  },
  "configuration": {
    "api_base_url": "https://api.mixfit.com",
    "websocket_url": "wss://ws.mixfit.com",
    "flavor": "production",
    "obfuscate": true,
    "shrink_resources": true
  },
  "artifacts": {
    "apk_files": [
      {
        "filename": "mix-fit-production-release-v1.0.0-1-20250821-083656.apk",
        "size": 25165824,
        "size_human": "24.0 MB",
        "checksum": "a1b2c3d4e5f6...",
        "build_type": "release"
      }
    ],
    "aab_files": [
      {
        "filename": "mix-fit-production-release-v1.0.0-1-20250821-083656.aab",
        "size": 23068672,
        "size_human": "22.0 MB",
        "checksum": "f6e5d4c3b2a1...",
        "build_type": "release"
      }
    ]
  },
  "git_info": {
    "commit_hash": "abc123def456...",
    "commit_short": "abc123d",
    "branch": "main",
    "commit_message": "Add artifact management",
    "commit_author": "Developer Name",
    "commit_date": "2025-08-21 08:30:00 +0000",
    "is_dirty": false
  },
  "system_info": {
    "platform": "x86_64-linux",
    "ruby_version": "3.0.0",
    "fastlane_version": "2.219.0",
    "build_machine": "developer",
    "build_os": "linux-gnu",
    "build_arch": "x86_64"
  }
}
```

### 4. Checksum Validation

Each build generates SHA256 checksums for all artifacts:

#### metadata/checksums.txt
```
# Build Artifact Checksums
# Generated at: 2025-08-21T08:36:56Z
# Environment: production

a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890  apk/mix-fit-production-release-v1.0.0-1-20250821-083656.apk
f6e5d4c3b2a1098765432109876543210987654321098765432109876543210987  aab/mix-fit-production-release-v1.0.0-1-20250821-083656.aab
```

## Usage

### Building with Artifact Management

The artifact management is automatically integrated into the build process:

```bash
# Build with automatic artifact organization
fastlane build env:production

# Build specific environment
fastlane dev                    # Development build
fastlane staging upload:true    # Staging build with upload
fastlane prod upload:true       # Production build with upload
```

### Artifact Management Commands

#### List Recent Builds
```bash
# List last 10 builds for development
fastlane list_builds env:development

# List last 20 builds for production
fastlane list_builds env:production limit:20
```

#### Show Latest Build Info
```bash
# Show latest build information
fastlane latest_build env:production
```

#### Validate Artifacts
```bash
# Validate latest build artifacts
fastlane validate_artifacts env:production
```

#### Generate Reports
```bash
# Generate text report
fastlane artifact_report env:production

# Generate JSON report
fastlane artifact_report env:production format:json
```

#### Cleanup Old Builds
```bash
# Clean builds older than 30 days (default)
fastlane cleanup_builds env:development

# Clean builds older than 7 days
fastlane cleanup_builds env:development keep_days:7
```

## Integration with Notifications

Build notifications now include artifact information:

### Slack Notification Example
```
✅ Build completed successfully for production environment
📱 App: Mix Fit
🔢 Version: 1.0.0 (1)
🏗️ Build Type: release
⏰ Build Time: 2025-08-21T08:36:56Z

📦 APK Files:
  • mix-fit-production-release-v1.0.0-1-20250821-083656.apk (24.0 MB)

📦 AAB Files:
  • mix-fit-production-release-v1.0.0-1-20250821-083656.aab (22.0 MB)

📁 Build Directory: ./build/android/production/20250821_083656
```

## File Structure

### Core Files
- `artifact_manager.rb` - Main artifact management class
- `config_loader.rb` - Enhanced with artifact organization
- `Fastfile` - Updated with artifact management lanes

### Generated Files
- `build-info.json` - Simplified build information
- `metadata/build-info.json` - Detailed build metadata
- `metadata/checksums.txt` - SHA256 checksums for all artifacts

## Configuration

Artifact management uses the existing environment configuration files:

```yaml
# config/environments/production.yaml
app:
  name: "Mix Fit"                    # Used in artifact naming
  version_name: "1.0.0"             # Used in artifact naming
  version_code: 1                   # Used in artifact naming

build:
  build_type: "release"             # Used in artifact naming
  obfuscate: true                   # Included in metadata
  shrink_resources: true            # Included in metadata

notifications:
  slack_webhook: "SLACK_WEBHOOK_URL" # For artifact notifications
  email_recipients: ["dev@example.com"]
```

## Error Handling

The system includes comprehensive error handling:

### Validation Errors
- Missing APK/AAB files
- File size mismatches
- Checksum validation failures
- Missing required metadata files

### Recovery Mechanisms
- Automatic retry for transient failures
- Detailed error logging
- Graceful degradation when optional features fail

## Security Considerations

### Checksum Verification
- SHA256 checksums for all artifacts
- Automatic validation during build process
- Tamper detection for distributed artifacts

### Access Control
- Build directories use secure permissions
- Sensitive information excluded from logs
- Audit trail for all artifact operations

## Maintenance

### Automatic Cleanup
- Configurable retention period (default: 30 days)
- Preserves latest build symlinks
- Removes old build directories and artifacts

### Monitoring
- Build size tracking over time
- Performance metrics collection
- Error rate monitoring

## Testing

The implementation includes comprehensive tests:

```bash
# Run artifact manager tests
cd frontend/android/fastlane
ruby test_artifact_manager.rb
```

Test coverage includes:
- Basic artifact organization
- Filename generation
- Metadata generation
- Checksum validation
- Build directory structure

## Troubleshooting

### Common Issues

#### Missing APK/AAB Files
```bash
# Check Flutter build output
ls -la ../../build/app/outputs/flutter-apk/
ls -la ../../build/app/outputs/bundle/release/
```

#### Checksum Validation Failures
```bash
# Manually verify checksums
sha256sum build/android/production/latest/apk/*.apk
```

#### Permission Issues
```bash
# Fix directory permissions
chmod -R 755 build/android/
```

### Debug Mode
Enable verbose logging by setting environment variable:
```bash
export FASTLANE_VERBOSE=1
fastlane build env:development
```

## Future Enhancements

### Planned Features
- Artifact signing verification
- Build performance analytics
- Automated artifact distribution
- Integration with CI/CD artifact storage
- Build comparison tools
- Automated testing of artifacts

### Configuration Extensions
- Custom naming patterns
- Artifact retention policies
- Distribution platform integration
- Advanced notification templates