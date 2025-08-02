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

The legacy `AppConfig` class has been updated to work with the new environment configuration system while maintaining backward compatibility:

```dart
class AppConfig {
  // ... existing code ...
  
  Future<void> load(String env) async {
    try {
      // Try to load from legacy JSON config first
      final configFile = 'assets/config/${env}_config.json';
      final configString = await rootBundle.loadString(configFile);
      
      // Parse JSON and set values
      // ...
    } catch (e) {
      // Fallback to environment configuration adapter
      debugPrint('Failed to load legacy config, using environment configuration: $e');
      
      _endpoint = _adapter.endpoint;
      _apiKey = _adapter.apiKey;
      _debugMode = _adapter.debugMode;
      
      // Create a mock config map for backward compatibility
      _config = {
        'endpoint': _endpoint,
        'apiKey': _apiKey,
        'debugMode': _debugMode,
        'environment': _adapter.environmentName,
        'appName': _adapter.appName,
        'bundleId': _adapter.bundleId,
        'timeout': _adapter.timeout,
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

### LegacyConfigAdapter

**File**: `frontend/shared/app_config/lib/adapters/legacy_config_adapter.dart`

Bridges the gap between legacy configuration expectations and the new environment configuration system:

```dart
final adapter = LegacyConfigAdapter();

// Access configuration with automatic fallback
final endpoint = adapter.endpoint;
final websocketUrl = adapter.websocketUrl;
final debugMode = adapter.debugMode;
```

## Configuration Flow

1. **App Startup**: Environment configuration is initialized in `main.dart`
2. **Service Registration**: Configuration services are registered in dependency injection
3. **API Client Setup**: Endpoints class uses environment configuration for URLs
4. **WebSocket Setup**: Socket service uses environment configuration for connection
5. **Fallback Chain**: If environment config fails, system falls back to environment variables or defaults

## Fallback Strategy

The integration implements a robust fallback strategy:

1. **Primary**: Environment configuration from YAML files
2. **Secondary**: Environment variables (compile-time)
3. **Tertiary**: Hard-coded defaults

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

### For Legacy Code

```dart
// Legacy code continues to work unchanged
final legacyConfig = AppConfig();
await legacyConfig.load('development');

final endpoint = legacyConfig.endpoint;
final debugMode = legacyConfig.debugMode;
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

The system uses YAML configuration files located in `frontend/config/environments/`:

- `development.yaml` - Development environment configuration
- `staging.yaml` - Staging environment configuration  
- `production.yaml` - Production environment configuration

## Benefits

1. **Seamless Integration**: Existing code continues to work without changes
2. **Modern Configuration**: New code can use the advanced environment configuration system
3. **Robust Fallbacks**: Multiple fallback levels ensure reliability
4. **Easy Migration**: Gradual migration path from legacy to new configuration
5. **Environment Awareness**: Proper support for different deployment environments
6. **Type Safety**: Strong typing for configuration values
7. **Validation**: Built-in configuration validation

## Migration Guide

To migrate existing code to use the new configuration system:

1. **Replace direct endpoint usage**:
   ```dart
   // Old
   const apiUrl = 'http://localhost:3000';
   
   // New
   final apiUrl = ConfigIntegrationHelper().getApiBaseUrl();
   ```

2. **Update service initialization**:
   ```dart
   // Old
   final service = ApiService(baseUrl: 'http://localhost:3000');
   
   // New
   final integrationHelper = ConfigIntegrationHelper();
   final service = ApiService(baseUrl: integrationHelper.getApiBaseUrl());
   ```

3. **Use environment-aware configuration**:
   ```dart
   // Old
   final isDebug = kDebugMode;
   
   // New
   final isDebug = ConfigIntegrationHelper().isDebugMode();
   ```

This integration ensures that the Flutter app can seamlessly work with the Fastlane environment configuration system while maintaining full backward compatibility with existing code.