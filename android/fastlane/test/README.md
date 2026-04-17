# Version Manager Test Suite

This directory contains comprehensive tests for the Version Manager functionality in the Fastlane environment configuration system.

## Test Structure

### Unit Tests (`version_manager_test.rb`)
- Tests individual methods and functions of the VersionManager class
- Covers version parsing, validation, and file updates
- Tests error handling and edge cases
- Mocks external dependencies for isolated testing

### Integration Tests (`integration_test.rb`)
- Tests end-to-end workflows and scenarios
- Covers multi-platform file consistency
- Tests Git integration and error recovery
- Simulates realistic project structures and configurations

## Running Tests

### Prerequisites
```bash
# Install test dependencies
cd frontend/android/fastlane/test
bundle install
```

### Run All Tests
```bash
# Using the test runner
ruby test_runner.rb

# Using Rake
rake test
```

### Run Specific Test Suites
```bash
# Unit tests only
rake unit

# Integration tests only
rake integration
```

### Generate Coverage Report
```bash
rake coverage
```

## Test Coverage

The test suite covers the following aspects of version management:

### Core Functionality
- ✅ Version parsing from pubspec.yaml
- ✅ Build number incrementation
- ✅ Version name updates
- ✅ Semantic versioning (patch, minor, major increments)
- ✅ Git tag creation and management

### File Management
- ✅ pubspec.yaml updates
- ✅ Android build.gradle updates
- ✅ iOS Info.plist updates
- ✅ Cross-platform consistency
- ✅ File formatting preservation

### Error Handling
- ✅ Invalid version formats
- ✅ Missing files
- ✅ Corrupted configuration files
- ✅ Git repository errors
- ✅ File permission issues

### Git Integration
- ✅ Commit message generation
- ✅ Tag creation and pushing
- ✅ Non-git repository handling
- ✅ Git command failures

### Edge Cases
- ✅ Large version numbers
- ✅ Concurrent updates
- ✅ Rapid increments
- ✅ Version rollbacks
- ✅ Missing platform files

## Test Requirements Mapping

The tests verify compliance with the following requirements:

### Requirement 5.1: Automatic Build Number Incrementation
- `test_increment_build_number_correctly`
- `test_handle_rapid_version_increments_correctly`
- `test_update_all_platform_files`

### Requirement 5.2: Semantic Versioning Support
- `test_increment_patch_version_correctly`
- `test_increment_minor_version_and_reset_patch`
- `test_increment_major_version_and_reset_minor_and_patch`
- `test_handle_complete_release_workflow`

### Requirement 5.3: Git Integration
- `test_create_git_tag_with_correct_format`
- `test_commit_version_changes_with_correct_message`
- `test_handle_git_operations_correctly`
- `test_handle_git_failures_gracefully`

### Requirement 5.4: Version Information Logging
- `test_show_current_version` (via show_current_version method)
- Git commit and branch information display

### Requirement 5.5: Error Handling and Recovery
- `test_handle_missing_platform_files_gracefully`
- `test_recover_from_corrupted_pubspec_yaml`
- `test_handle_non_git_repository_gracefully`
- `test_handle_file_system_permissions`

## Test Data and Mocking

### Mock Project Structure
Tests create realistic Flutter project structures with:
- Complete pubspec.yaml with dependencies
- Android build.gradle with proper configuration
- iOS Info.plist with bundle information
- Proper directory structure

### External Dependencies
- UI methods are mocked for consistent output
- Git commands are intercepted and validated
- File system operations are isolated to temporary directories

## Continuous Integration

The test suite is designed to run in CI/CD environments:

### GitHub Actions Integration
```yaml
- name: Run Version Manager Tests
  run: |
    cd frontend/android/fastlane/test
    bundle install
    rake test
```

### Test Reports
- JUnit XML reports generated in `test/reports/`
- Coverage reports available when enabled
- Detailed test output with minitest-reporters

## Performance Considerations

### Test Isolation
- Each test runs in a temporary directory
- No shared state between tests
- Proper cleanup after each test

### Mock Efficiency
- External commands are mocked to avoid actual Git operations
- File operations are limited to temporary directories
- Network calls are avoided entirely

## Troubleshooting

### Common Issues

#### Test Failures Due to File Permissions
```bash
# Ensure proper permissions on test files
chmod +x test_runner.rb
```

#### Missing Dependencies
```bash
# Install required gems
bundle install
```

#### Git Configuration Issues
Tests mock Git operations, but if you see Git-related errors:
```bash
# Configure Git for testing (if needed)
git config --global user.email "test@example.com"
git config --global user.name "Test User"
```

### Debug Mode
Enable verbose output for debugging:
```bash
# Run with verbose output
ruby test_runner.rb -v

# Run specific test with debugging
ruby -I. test/version_manager_test.rb -n test_increment_build_number_correctly -v
```

## Contributing

When adding new version management features:

1. Add corresponding unit tests in `version_manager_test.rb`
2. Add integration scenarios in `integration_test.rb`
3. Update this README with new test coverage
4. Ensure all tests pass before submitting changes

### Test Naming Conventions
- Use descriptive test names: `test_should_handle_specific_scenario`
- Group related tests in describe blocks
- Use meaningful assertions with clear error messages

### Mock Guidelines
- Mock external dependencies consistently
- Preserve the interface of mocked objects
- Use realistic return values for mocked methods