# Environment Configuration System

This package provides a comprehensive environment configuration system for Flutter applications with Fastlane integration support.

## Features

- **YAML Configuration Files**: Environment-specific configuration using YAML files
- **JSON Schema Validation**: Automatic validation of configuration files
- **Type-Safe Models**: Freezed-generated models with JSON serialization
- **Environment Service**: Singleton service for accessing configuration at runtime
- **Validation System**: Comprehensive validation with detailed error reporting
- **Backward Compatibility**: Maintains compatibility with existing JSON configuration

## Configuration Structure

### Environment Files

Configuration files are located in `config/environments/`:

- `development.yaml` - Development environment
- `staging.yaml` - Staging environment  
- `production.yaml` - Production environment

### Configuration Schema

Each configuration file follows this structure:

```yaml
environment:
  name: "development"
  display_name: "Development Environment"

app:
  name: "Flutter App Dev"
  bundle_id: "com.example.app.development"
  version_name: "1.0.0"
  version_code: 1

network:
  api_base_url: "http://localhost:3000"
  websocket_url: "ws://localhost:3001"
  timeout: 30000

build:
  flavor: "development"
  build_type: "debug"
  obfuscate: false
  shrink_resources: false

signing:
  store_file: "debug.keystore"
  store_password_env: "DEBUG_STORE_PASSWORD"
  key_alias: "debug"
  key_password_env: "DEBUG_KEY_PASSWORD"

distribution:
  platform: "internal"
  track: "internal"

notifications:
  slack_webhook: "SLACK_WEBHOOK_URL_DEV"
  email_recipients: ["dev@example.com"]
```

## Usage

### Basic Usage

```dart
import 'package:app_config/app_config.dart';

// Initialize the service
await EnvironmentConfigService().initialize('development');

// Access configuration
final service = EnvironmentConfigService();
print('API URL: ${service.apiBaseUrl}');
print('App Name: ${service.appName}');
print('Environment: ${service.environmentName}');
```

### Using with ConfiguredApp

```dart
import 'package:app_config/app_config.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConfiguredApp(
      environment: 'development',
      useNewConfigSystem: true,
      builder: (context) => MaterialApp(
        title: EnvironmentConfigService().appName,
        home: MyHomePage(),
      ),
    );
  }
}
```

### Manual Configuration Loading

```dart
import 'package:app_config/app_config.dart';

final loader = YamlEnvironmentConfigLoader();
final config = await loader.loadConfig('production');

// Validate configuration
final isValid = await loader.validateConfig(config);
if (!isValid) {
  print('Configuration validation failed');
}
```

## Validation

The system includes comprehensive validation:

### JSON Schema Validation
- Validates structure and data types
- Ensures required fields are present
- Validates format constraints (URLs, bundle IDs, etc.)

### Business Logic Validation
- Bundle ID format validation
- URL format validation
- Environment name validation
- Build type validation

### Custom Validation

```dart
import 'package:app_config/app_config.dart';

// Validate bundle ID
final result = ConfigValidator.validateBundleId('com.example.app');
if (!result.isValid) {
  print('Bundle ID validation failed: ${result.errorMessage}');
}

// Validate URL
final urlResult = ConfigValidator.validateUrl('https://api.example.com', 'api_url');
if (!urlResult.isValid) {
  print('URL validation failed: ${urlResult.errorMessage}');
}
```

## Environment Variables

The system supports environment variable substitution in configuration files:

```yaml
network:
  api_base_url: "${API_BASE_URL}"
  
signing:
  store_password_env: "STORE_PASSWORD"
  key_password_env: "KEY_PASSWORD"
```

## Error Handling

The system provides detailed error reporting:

```dart
try {
  await EnvironmentConfigService().initialize('invalid-env');
} catch (e) {
  if (e is ConfigValidationError) {
    print('Field: ${e.field}');
    print('Value: ${e.value}');
    print('Message: ${e.message}');
  }
}
```

## Testing

Run tests with:

```bash
flutter test
```

The test suite includes:
- Configuration model serialization tests
- Validation logic tests
- Service initialization tests
- Error handling tests

## Integration with Fastlane

This configuration system is designed to work with Fastlane for automated builds:

1. **Environment Selection**: Fastlane can specify which environment to use
2. **Build Configuration**: Build settings are automatically applied
3. **Signing Configuration**: Code signing is configured per environment
4. **Distribution Settings**: Upload targets are environment-specific

## Migration from Legacy System

The new system maintains backward compatibility with the existing JSON configuration:

```dart
// Legacy usage (still supported)
await AppConfig().load('development');
final endpoint = AppConfig().endpoint;

// New usage (recommended)
await EnvironmentConfigService().initialize('development');
final apiUrl = EnvironmentConfigService().apiBaseUrl;
```

## File Structure

```
shared/app_config/
├── lib/
│   ├── models/
│   │   └── environment_config.dart          # Freezed models
│   ├── loaders/
│   │   └── environment_config_loader.dart   # Configuration loading
│   ├── services/
│   │   └── environment_config_service.dart  # Runtime service
│   ├── validation/
│   │   └── config_validator.dart            # Validation logic
│   ├── examples/
│   │   └── usage_example.dart               # Usage examples
│   ├── app_config.dart                      # Main export file
│   └── configured_app.dart                  # App wrapper widget
├── assets/
│   └── config/
│       ├── schema/
│       │   └── environment_config_schema.json
│       ├── development_config.json          # Legacy config
│       └── production_config.json           # Legacy config
└── test/
    ├── simple_test.dart                     # Basic tests
    └── yaml_loader_test.dart                # Loader tests
```

## Dependencies

- `yaml: ^3.1.2` - YAML parsing
- `json_schema: ^5.1.4` - JSON schema validation
- `freezed: ^2.4.7` - Code generation
- `json_annotation: ^4.9.0` - JSON serialization

## Contributing

When adding new configuration options:

1. Update the YAML configuration files
2. Update the JSON schema for validation
3. Add corresponding fields to the Dart models
4. Run code generation: `flutter packages pub run build_runner build`
5. Add tests for the new functionality