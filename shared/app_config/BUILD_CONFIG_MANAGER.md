# BuildConfigManager Documentation

The BuildConfigManager is a comprehensive system for managing build configurations across different environments and build variants in Flutter applications. It provides dynamic bundle ID and app name configuration, build variant management, and integration with Fastlane for automated builds.

## Features

- **Environment-specific Configuration**: Manage different settings for development, staging, and production environments
- **Build Variant Support**: Handle debug and release build variants with appropriate settings
- **Dynamic Configuration**: Dynamically configure bundle IDs, app names, and other build parameters
- **Validation**: Comprehensive validation of configuration settings
- **File Generation**: Generate configuration files for various platforms and tools
- **Fastlane Integration**: Generate Fastlane-compatible configuration files

## Core Components

### 1. BuildConfigManager

The main class that manages build configuration for a specific environment and build variant.

```dart
import 'package:app_config/config/build_config_manager.dart';

final manager = BuildConfigManager(
  environmentConfig: environmentConfig,
  buildVariant: 'debug',
  isDebugMode: true,
);

// Access configuration properties
print('App Name: ${manager.applicationName}');
print('Bundle ID: ${manager.applicationId}');
print('Build Variant: ${manager.buildVariant}');
print('Is Debug: ${manager.isDebugBuild}');
```

### 2. BuildConfigFactory

Factory class for creating BuildConfigManager instances with various configurations.

```dart
import 'package:app_config/config/build_config_factory.dart';

final factory = BuildConfigFactory.instance;

// Create for current environment
final currentConfig = await factory.createCurrent();

// Create for specific environments
final devConfig = await factory.createDevelopment();
final prodConfig = await factory.createProduction();

// Create custom configuration
final customConfig = factory.createCustom(
  environmentName: 'custom',
  displayName: 'Custom Environment',
  appName: 'Custom App',
  bundleId: 'com.custom.app',
  apiBaseUrl: 'https://api.custom.com',
);
```

### 3. BuildConfigGenerator

Generates configuration files for different platforms and build tools.

```dart
import 'package:app_config/config/build_config_generator.dart';

final generator = BuildConfigGenerator(buildConfigManager);

// Generate different configuration formats
final gradleProps = generator.generateGradleProperties();
final androidBuildGradle = generator.generateAndroidBuildGradle();
final fastlaneConfig = generator.generateFastlaneConfig();
final envScript = generator.generateEnvironmentScript(format: 'bash');

// Write all configuration files
await generator.writeConfigurationFiles('/path/to/output');
```

## Configuration Properties

### Application Configuration
- `applicationId`: Bundle ID for the application
- `applicationName`: Display name of the application
- `displayName`: Environment-specific display name
- `versionName`: Version string (e.g., "1.0.0")
- `versionCode`: Numeric version code

### Build Configuration
- `buildVariant`: Current build variant (debug/release)
- `buildType`: Build type from configuration
- `flavor`: Environment flavor name
- `isDebugBuild`: Whether this is a debug build
- `isReleaseBuild`: Whether this is a release build
- `shouldObfuscate`: Whether code obfuscation should be enabled
- `shouldShrinkResources`: Whether resource shrinking should be enabled

## Usage Examples

### Basic Usage

```dart
import 'package:app_config/app_config.dart';

// Initialize environment configuration
final configService = EnvironmentConfigService();
await configService.initialize('production');

// Create build config manager
final factory = BuildConfigFactory.instance;
final buildConfig = factory.createFromEnvironmentConfig(
  configService.config,
  buildVariant: 'release',
  isDebugMode: false,
);

// Use configuration
print('Building ${buildConfig.applicationName}');
print('Bundle ID: ${buildConfig.applicationId}');
print('Version: ${buildConfig.versionName}');
```

### Generate Configuration Files

```dart
// Create build config for production
final prodConfig = await factory.createProduction();
final generator = BuildConfigGenerator(prodConfig);

// Generate and write configuration files
await generator.writeConfigurationFiles('build/config/production');

// Files generated:
// - gradle.properties
// - build.gradle.snippet
// - Info.plist.json
// - fastlane_config.rb
// - env_vars.sh
// - env_vars.ps1
// - env_vars.bat
// - build_config.json
// - build_config.yaml
```

### Environment Variables

```dart
final envVars = buildConfig.generateEnvironmentVariables();

// Generated variables include:
// FLUTTER_APP_NAME=MyApp
// FLUTTER_BUNDLE_ID=com.example.myapp
// FLUTTER_VERSION_NAME=1.0.0
// FLUTTER_VERSION_CODE=1
// FLUTTER_BUILD_VARIANT=release
// FLUTTER_API_BASE_URL=https://api.example.com
// FLUTTER_WEBSOCKET_URL=wss://ws.example.com
```

### Gradle Properties

```dart
final gradleProps = buildConfig.generateGradleProperties();

// Generated properties include:
// flutter.applicationId=com.example.myapp
// flutter.applicationName=MyApp
// flutter.versionName=1.0.0
// flutter.versionCode=1
// flutter.buildType=release
// flutter.flavor=production
```

### Fastlane Configuration

```dart
final fastlaneConfig = buildConfig.generateFastlaneConfig();

// Generated Ruby hash format:
// FASTLANE_CONFIG = {
//   app_identifier: "com.example.myapp",
//   app_name: "MyApp",
//   version_name: "1.0.0",
//   version_code: "1",
//   build_type: "release",
//   flavor: "production",
//   environment: "production",
//   signing: { ... },
//   distribution: { ... }
// }
```

## Configuration Validation

The BuildConfigManager includes comprehensive validation:

```dart
final result = buildConfig.validateConfiguration();

if (result.isValid) {
  print('Configuration is valid');
} else {
  print('Validation errors:');
  for (final error in result.errors) {
    print('  - $error');
  }
}

if (result.hasWarnings) {
  print('Warnings:');
  for (final warning in result.warnings) {
    print('  - $warning');
  }
}
```

### Validation Rules

- **Bundle ID Format**: Must follow reverse domain notation (e.g., com.example.app)
- **Version Code**: Must be greater than 0
- **Version Name**: Cannot be empty
- **URLs**: API and WebSocket URLs must be valid URIs
- **Signing Configuration**: Warns if missing for release builds

## Integration with Flutter App

### Service Integration

```dart
class AppConfigurationService {
  BuildConfigManager? _buildConfigManager;
  
  Future<void> initialize() async {
    final configService = EnvironmentConfigService();
    await configService.initialize();
    
    final factory = BuildConfigFactory.instance;
    _buildConfigManager = factory.createFromEnvironmentConfig(
      configService.config,
    );
  }
  
  BuildConfigManager get buildConfig => _buildConfigManager!;
  
  bool get isDebugBuild => buildConfig.isDebugBuild;
  bool get isProduction => buildConfig.flavor == 'production';
}
```

### Widget Integration

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BuildConfigManager? buildConfig;
  
  @override
  void initState() {
    super.initState();
    _initializeBuildConfig();
  }
  
  Future<void> _initializeBuildConfig() async {
    final factory = BuildConfigFactory.instance;
    final config = await factory.createCurrent();
    
    setState(() {
      buildConfig = config;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (buildConfig == null) {
      return CircularProgressIndicator();
    }
    
    return MaterialApp(
      title: buildConfig!.applicationName,
      // ... rest of app configuration
    );
  }
}
```

## Build Variant Handling

### Debug vs Release Configuration

```dart
// Debug configuration
final debugConfig = factory.createForTesting(
  buildVariant: 'debug',
  isDebugMode: true,
);

print('Debug build settings:');
print('  Obfuscate: ${debugConfig.shouldObfuscate}'); // false
print('  Shrink Resources: ${debugConfig.shouldShrinkResources}'); // false

// Release configuration
final releaseConfig = factory.createForTesting(
  buildVariant: 'release',
  isDebugMode: false,
);

print('Release build settings:');
print('  Obfuscate: ${releaseConfig.shouldObfuscate}'); // true
print('  Shrink Resources: ${releaseConfig.shouldShrinkResources}'); // true
```

### Dynamic Variant Switching

```dart
// Switch from debug to release
final newConfig = originalConfig.copyWith(
  buildVariant: 'release',
  isDebugMode: false,
);

print('Switched from ${originalConfig.buildVariant} to ${newConfig.buildVariant}');
```

## Testing

The BuildConfigManager includes comprehensive test coverage:

```bash
# Run all build config tests
flutter test test/build_config_*.dart

# Run specific test files
flutter test test/build_config_manager_test.dart
flutter test test/build_config_factory_test.dart
flutter test test/build_config_generator_test.dart
```

### Test Utilities

```dart
// Create test configuration
final testConfig = factory.createForTesting(
  environmentName: 'test',
  appName: 'Test App',
  bundleId: 'com.test.app',
  apiBaseUrl: 'https://api.test.com',
  buildVariant: 'debug',
  isDebugMode: true,
);

// Validate test configuration
final result = testConfig.validateConfiguration();
expect(result.isValid, isTrue);
```

## Best Practices

1. **Initialize Early**: Initialize the BuildConfigManager early in your app lifecycle
2. **Use Factory Methods**: Use BuildConfigFactory for consistent configuration creation
3. **Validate Configuration**: Always validate configuration before using in production
4. **Environment Separation**: Keep environment-specific settings in separate configuration files
5. **Version Management**: Use semantic versioning for version names
6. **Security**: Store sensitive configuration (signing keys) in environment variables
7. **Testing**: Use the factory's testing methods for unit tests

## Error Handling

```dart
try {
  final buildConfig = await factory.createProduction();
  final validation = buildConfig.validateConfiguration();
  
  if (!validation.isValid) {
    throw ConfigurationException('Invalid configuration: ${validation.errors}');
  }
  
  // Use configuration
} catch (e) {
  print('Configuration error: $e');
  // Fall back to default configuration or show error to user
}
```

## File Generation Output

When using `BuildConfigGenerator.writeConfigurationFiles()`, the following files are generated:

- **gradle.properties**: Android Gradle properties
- **build.gradle.snippet**: Android build.gradle configuration snippet
- **Info.plist.json**: iOS Info.plist configuration in JSON format
- **fastlane_config.rb**: Fastlane configuration in Ruby format
- **env_vars.sh**: Environment variables script for Bash
- **env_vars.ps1**: Environment variables script for PowerShell
- **env_vars.bat**: Environment variables script for Windows Batch
- **build_config.json**: Complete build configuration in JSON format
- **build_config.yaml**: Complete build configuration in YAML format

These files can be used by various build tools and CI/CD systems to configure builds consistently across different environments.