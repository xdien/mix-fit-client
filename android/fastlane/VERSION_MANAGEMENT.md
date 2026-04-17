# Version Management System

This document describes the comprehensive version management system implemented for the Fastlane environment configuration.

## Overview

The version management system provides automated version and build number management with the following features:

- **Automatic Build Number Incrementation**: Each build gets a unique build number
- **Semantic Versioning Support**: Patch, minor, and major version increments
- **Git Integration**: Automatic commits and tagging
- **Version History Tracking**: Complete audit trail of all version changes
- **Multi-Platform Support**: Updates Flutter, Android, and iOS version files
- **Error Recovery**: Graceful handling of failures with fallback mechanisms

## Core Components

### 1. VersionManager (`version_manager.rb`)

The main class responsible for version operations:

```ruby
version_manager = VersionManager.new(environment, config)
```

#### Key Methods

- `increment_build_number()` - Increments build number by 1
- `update_version_name(version)` - Sets specific version name
- `increment_patch()` - Increments patch version (1.0.0 → 1.0.1)
- `increment_minor()` - Increments minor version (1.0.0 → 1.1.0)
- `increment_major()` - Increments major version (1.0.0 → 2.0.0)
- `create_tag(message)` - Creates Git tag for current version
- `show_current_version()` - Displays current version information

### 2. VersionHistoryManager (`version_history_manager.rb`)

Tracks and manages version change history:

```ruby
history_manager = VersionHistoryManager.new(project_root)
```

#### Key Methods

- `record_version_change(old, new, type, env)` - Records version changes
- `get_history(limit)` - Retrieves version history
- `get_statistics()` - Calculates version statistics
- `generate_changelog(since_version)` - Generates changelog
- `export_history(format, output_file)` - Exports history to various formats
- `cleanup_history(keep_days)` - Removes old history entries

## Usage Examples

### Basic Version Operations

```bash
# Show current version information
fastlane show_version env:development

# Increment build number
fastlane increment_build env:production

# Update to specific version
fastlane update_version version:2.1.0 env:staging

# Increment semantic versions
fastlane increment_patch env:production
fastlane increment_minor env:production
fastlane increment_major env:production

# Create Git tag
fastlane create_tag message:"Release v2.1.0" env:production
```

### Version History Operations

```bash
# Show recent version history
fastlane version_history env:development limit:10

# Show version statistics
fastlane version_stats env:development

# Generate changelog
fastlane generate_changelog env:production since:1.0.0

# Export version history
fastlane export_version_history format:json env:production
fastlane export_version_history format:csv env:production
fastlane export_version_history format:markdown env:production

# Clean up old history
fastlane cleanup_version_history keep_days:90 env:development
```

### Build Integration

```bash
# Build with automatic version increment
fastlane build_with_version env:production build_type:release create_tag:true

# Development build (increments build number)
fastlane dev

# Staging build with upload
fastlane staging upload:true

# Production build with upload and tagging
fastlane prod upload:true
```

## File Updates

The version management system automatically updates the following files:

### 1. Flutter (`pubspec.yaml`)
```yaml
version: 1.2.3+45
```

### 2. Android (`android/app/build.gradle`)
```gradle
defaultConfig {
    versionCode 45
    versionName "1.2.3"
}
```

### 3. iOS (`ios/Runner/Info.plist`)
```xml
<key>CFBundleShortVersionString</key>
<string>1.2.3</string>
<key>CFBundleVersion</key>
<string>45</string>
```

## Version History Format

Version changes are tracked in `version_history.json`:

```json
{
  "version": "1.0",
  "created": "2024-01-01T00:00:00Z",
  "last_updated": "2024-01-15T10:30:00Z",
  "changes": [
    {
      "timestamp": "2024-01-15T10:30:00Z",
      "old_version": {
        "version_name": "1.0.0",
        "build_number": 1
      },
      "new_version": {
        "version_name": "1.0.1",
        "build_number": 1
      },
      "change_type": "patch",
      "environment": "production",
      "commit_hash": "abc123def456",
      "branch": "main"
    }
  ]
}
```

## Change Types

- `build_increment` - Build number incremented
- `patch` - Patch version incremented (bug fixes)
- `minor` - Minor version incremented (new features)
- `major` - Major version incremented (breaking changes)
- `manual` - Manual version update

## Git Integration

### Automatic Commits

Version changes are automatically committed with descriptive messages:

```
chore: increment build number to 45
chore: update version to 1.2.3+45
```

### Git Tags

Release tags are created with the format `v{version}`:

```bash
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3
```

### Branch and Commit Tracking

Each version change records:
- Current Git branch
- Commit hash at time of change
- Environment where change occurred

## Error Handling

The system implements robust error handling per requirement 5.5:

### Version Update Failures

If version update fails:
1. Error is logged with details
2. Build process continues with current version
3. Warning message is displayed
4. No partial updates are left in inconsistent state

### Git Operation Failures

If Git operations fail:
1. Version files are still updated
2. Warning is logged about Git failure
3. Build process continues normally
4. Manual Git operations may be needed

### File Permission Issues

If files cannot be updated:
1. Specific error is reported
2. Alternative approaches are attempted
3. Process fails gracefully with clear message

## Configuration

### Environment-Specific Settings

Version management respects environment configurations:

```yaml
# config/environments/production.yaml
environment:
  name: "production"
  
app:
  version_name: "1.0.0"
  version_code: 1
```

### Git Configuration

Ensure Git is properly configured:

```bash
git config user.name "Build System"
git config user.email "build@example.com"
```

## Testing

Comprehensive test suite covers:

### Unit Tests (`test/version_manager_test.rb`)
- Version parsing and validation
- File update operations
- Error handling scenarios
- Git integration mocking

### History Tests (`test/version_history_manager_test.rb`)
- History recording and retrieval
- Statistics calculation
- Export functionality
- Cleanup operations

### Integration Tests (`test/integration_test.rb`)
- End-to-end workflows
- Multi-platform consistency
- Error recovery scenarios
- Performance testing

### Running Tests

```bash
# All tests
cd frontend/android/fastlane/test
ruby test_runner.rb

# Specific test suites
rake unit
rake integration
rake test
```

## Troubleshooting

### Common Issues

#### Version Not Updating
```bash
# Check file permissions
ls -la pubspec.yaml android/app/build.gradle ios/Runner/Info.plist

# Verify Git repository
git status
```

#### Git Errors
```bash
# Check Git configuration
git config --list

# Verify repository state
git status
git log --oneline -5
```

#### History File Corruption
```bash
# Backup and reset history
cp version_history.json version_history.json.backup
rm version_history.json
# History will be recreated on next version change
```

### Debug Mode

Enable verbose logging:

```bash
# Run with debug output
fastlane show_version env:development --verbose

# Check Fastlane logs
cat ~/.fastlane/logs/fastlane.log
```

## Best Practices

### Version Numbering

Follow semantic versioning:
- **Major** (X.0.0): Breaking changes
- **Minor** (X.Y.0): New features, backward compatible
- **Patch** (X.Y.Z): Bug fixes, backward compatible

### Build Numbers

- Increment for every build
- Never reuse build numbers
- Use for internal tracking and debugging

### Git Workflow

1. Create feature branch
2. Develop and test
3. Merge to main/develop
4. Use version management for releases
5. Tag stable releases

### Environment Strategy

- **Development**: Frequent build increments
- **Staging**: Minor/patch increments for testing
- **Production**: Controlled major/minor releases

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0
          
      - name: Install Fastlane
        run: |
          cd frontend/android
          bundle install
          
      - name: Build and Deploy
        run: |
          cd frontend/android
          fastlane build_with_version env:production create_tag:true
        env:
          STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
```

### Environment Variables

Required for CI/CD:
- `STORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password
- `SLACK_WEBHOOK_URL` - Notification webhook (optional)

## Monitoring and Analytics

### Version Statistics

Track version patterns:
- Release frequency
- Change type distribution
- Environment usage
- Error rates

### Build Metrics

Monitor build performance:
- Version update duration
- File update success rates
- Git operation reliability
- History file size growth

## Future Enhancements

Planned improvements:
- Automated changelog generation from Git commits
- Integration with issue tracking systems
- Advanced version branching strategies
- Rollback capabilities
- Version approval workflows