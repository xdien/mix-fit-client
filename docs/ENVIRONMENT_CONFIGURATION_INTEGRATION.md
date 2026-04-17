# Environment Configuration Integration

This document explains how the Fastlane environment configuration system has been integrated with the existing Flutter app architecture.

## Overview

The integration provides a seamless bridge between the new environment configuration system and the existing Flutter app components, ensuring backward compatibility while enabling modern configuration management.

## Integration Components

### 1. Updated API Client Configuration

**File**: `frontend/shared/data/lib/network/constants/endpoints.dart`

The `Endpoints` class now uses the environment configuration service to get API URLs and timeouts:

```dart
class Endpoints {
  // Get environment configuration service
  static EnvironmentConfigService get _configService => EnvironmentConfigService();

  // base url - use environment config if available, fallback to environment variable
  static String get baseUrl {
    try {
      if (_configService.isInitialized) {
        return _configService.apiBaseUrl;
      }
    } catch (e) {
      // Fallback to environment variable if config service is not available
    }
    return const String.fromEnvironment("BASE_URL", defaultValue: "http://localhost:3000");
  }

  // WebSocket URL - use environment config if available
  static String? get websocketUrl {
    try {
      if (_configService.isInitialized) {
        return _configService.websocketUrl;
      }
    } catch (e) {
      // Fallback to environment variable if config service is not available
    }
    return const String.fromEnvironment("WEBSOCKET_URL", defaultValue: "ws://localhost:3001");
  }
}
```

### 2. WebSocket Connection Integration

**File**: `frontend/lib/data/di/module/network_module.dart`

The WebSocket service now uses the environment configuration for connection URLs:

```dart
getIt.registerSingleton<SocketService>(
  SocketService(
     url: Endpoints.websocketUrl ?? Endpoints.baseUrl,
     tokenProvider: () async => await getIt<SharedPreferenceHelper>().authToken,
  ),
);
```

### 3. App Initialization Integration

**File**: `frontend/lib/main.dart`

The main application now initializes the environment configuration before other services:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setPreferredOrientations();
  
  // Initialize environment configuration before other services
  await _initializeEnvironmentConfig();
  
  await ServiceLocator.configureDependencies();
  await ModuleManager.instance.initialize();
  await ModuleManager.instance.registerDependencies(getIt);
  runApp(MyApp());
}

Future<void> _initializeEnvironmentConfig() async {
  try {
    final integrationHelper = ConfigIntegrationHelper();
    await integrationHelper.initialize();
    
    debugPrint('Configuration system initialized successfully');
    debugPrint('Configuration summary: ${integrationHelper.getConfigurationSummary()}');
    
    // Validate configuration
    final isValid = await integrationHelper.validateConfiguration();
    if (!isValid) {
      debugPrint('Warning: Configuration validation failed');
    }
  } catch (e) {
    debugPrint('Failed to initialize configuration system: $e');
    debugPrint('Application will continue with fallback configuration');
  }
}
```

### 4. Backward Compatibility

**File**: `frontend/shared/app_config/lib/app_config.dart`

The `AppConfig` class has been updated to work with the new environment configuration system while maintaining backward compatibility:

```dart
class AppConfig {
  // ... existing code ...
  
  Future<void> load(String env) async {
    try {
      debugPrint('Loading configuration using environment configuration system for $env environment');
      
      // Use centralized environment variables
      _endpoint = EnvironmentVariables.apiEndpoint;
      _apiKey = EnvironmentVariables.apiKey;
      _debugMode = kDebugMode;
      
      // Create config map from environment configuration
      _config = {
        'endpoint': _endpoint,
        'apiKey': _apiKey,
        'debugMode': _debugMode,
        'environment': env,
        'appName': EnvironmentVariables.appName,
        'bundleId': EnvironmentVariables.bundleId,
        'timeout': EnvironmentVariables.networkTimeout,
        'websocketUrl': EnvironmentVariables.websocketUrl,
      };
    } catch (e) {
      debugPrint('Failed to load configuration: $e');
      // Fallback configuration using centralized environment variables
      _config = {
        'endpoint': EnvironmentVariables.apiEndpoint,
        'apiKey': EnvironmentVariables.apiKey,
        'debugMode': kDebugMode,
        'environment': env,
        'appName': EnvironmentVariables.appName,
        'bundleId': EnvironmentVariables.bundleId,
        'timeout': EnvironmentVariables.networkTimeout,
        'websocketUrl': EnvironmentVariables.websocketUrl,
      };
    }
  }
}
```

## Integration Helpers

### ConfigIntegrationHelper

**File**: `frontend/shared/app_config/lib/integration/config_integration_helper.dart`

Provides a unified interface for accessing configuration with proper fallback chains:

```dart
final integrationHelper = ConfigIntegrationHelper();
await integrationHelper.initialize();

// Get configuration values with fallback
final apiBaseUrl = integrationHelper.getApiBaseUrl();
final websocketUrl = integrationHelper.getWebSocketUrl();
final appName = integrationHelper.getAppName();
final timeout = integrationHelper.getTimeout();
```

### EnvironmentVariables

**File**: `frontend/shared/app_config/lib/utils/environment_variables.dart`

Centralized management of all environment variables. This class provides a single source of truth for all environment variable access:

```dart
// Access environment variables directly
final apiUrl = EnvironmentVariables.apiEndpoint;
final appName = EnvironmentVariables.appName;
final bundleId = EnvironmentVariables.bundleId;
final timeout = EnvironmentVariables.networkTimeout;

// Get all variables as a map for debugging
final allVars = EnvironmentVariables.toMap();
```

## Configuration Flow

1. **App Startup**: Environment configuration is initialized in `main.dart`
2. **Service Registration**: Configuration services are registered in dependency injection
3. **API Client Setup**: Endpoints class uses environment configuration for URLs
4. **WebSocket Setup**: Socket service uses environment configuration for connection
5. **Fallback Chain**: If environment config fails, system falls back to centralized environment variables

## Fallback Strategy

The integration implements a robust fallback strategy:

1. **Primary**: Environment configuration from YAML files
2. **Secondary**: Centralized environment variables via `EnvironmentVariables` class
3. **Tertiary**: Hard-coded defaults in `EnvironmentVariables` class

This ensures the application continues to work even if configuration files are missing or invalid.

## Usage Examples

### For New Code

```dart
// Use the integration helper for new code
final integrationHelper = ConfigIntegrationHelper();
await integrationHelper.initialize();

final apiUrl = integrationHelper.getApiBaseUrl();
final isDebug = integrationHelper.isDebugMode();
```

### For Direct Environment Variable Access

```dart
// Direct access to centralized environment variables
final apiUrl = EnvironmentVariables.apiEndpoint;
final appName = EnvironmentVariables.appName;
final timeout = EnvironmentVariables.networkTimeout;
```

### For Backward Compatibility

```dart
// Backward compatibility code continues to work unchanged
final appConfig = AppConfig();
await appConfig.load('development');

final endpoint = appConfig.endpoint;
final debugMode = appConfig.debugMode;
```

### For Direct Environment Config Access

```dart
// Direct access to environment configuration
final configService = EnvironmentConfigService();
await configService.initialize();

final apiUrl = configService.apiBaseUrl;
final appName = configService.appName;
```

## Testing

The integration includes comprehensive tests in `frontend/test/integration/config_integration_test.dart` that verify:

- Configuration initialization
- Fallback behavior
- Backward compatibility
- API client integration
- WebSocket integration

## Environment Files

The system uses YAML configuration files located in `frontend/shared/app_config/config/environments/`:

- `development.yaml` - Development environment configuration
- `staging.yaml` - Staging environment configuration  
- `production.yaml` - Production environment configuration

## Benefits

1. **Single Source of Truth**: All environment variables are managed in one place
2. **Modern Configuration**: New code can use the advanced environment configuration system
3. **Robust Fallbacks**: Multiple fallback levels ensure reliability
4. **Easy Migration**: Gradual migration path from old to new configuration
5. **Environment Awareness**: Proper support for different deployment environments
6. **Type Safety**: Strong typing for configuration values
7. **Centralized Management**: No more scattered `String.fromEnvironment` calls