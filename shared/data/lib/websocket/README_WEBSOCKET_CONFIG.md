# WebSocket Configuration and Environment Setup

This document describes the WebSocket configuration and environment setup implementation for the AnKhanh CMS mobile application.

## Overview

The WebSocket configuration system provides environment-specific configuration management, feature flags, and runtime configuration validation for WebSocket connectivity. It integrates with the existing environment configuration system to provide seamless configuration management across development, staging, and production environments.

## Key Components

### 1. WebSocketConfigManager

Manages WebSocket configuration by integrating environment configuration with WebSocket-specific settings.

**Key Features:**
- Environment-specific WebSocket configuration
- Automatic URL conversion (HTTP/HTTPS to WS/WSS)
- Configuration validation
- Runtime configuration caching
- Integration with existing environment configuration system

**Usage:**
```dart
final configManager = WebSocketConfigManager();
final config = configManager.getConfig();

if (configManager.isEnabled()) {
  // Initialize WebSocket with configuration
  print('WebSocket URL: ${config.url}');
  print('Reconnect interval: ${config.reconnectInterval}');
}
```

### 2. WebSocketFeatureManager

Manages WebSocket feature flags and provides runtime feature checking.

**Available Features:**
- `realTimeUpdates`: Enable/disable real-time data updates
- `offlineSupport`: Enable/disable offline message queuing
- `backgroundSync`: Enable/disable background synchronization
- `pushNotifications`: Enable/disable push notifications

**Usage:**
```dart
final featureManager = WebSocketFeatureManager();

if (featureManager.isRealTimeUpdatesEnabled) {
  // Initialize real-time updates
}

// Runtime overrides
featureManager.enableFeature(WebSocketFeatureManager.realTimeUpdates);
featureManager.disableFeature(WebSocketFeatureManager.backgroundSync);
```

### 3. Environment Configuration

WebSocket configuration is defined in environment-specific YAML files:

- `frontend/config/environments/development.yaml`
- `frontend/config/environments/staging.yaml`
- `frontend/config/environments/production.yaml`

## Configuration Structure

### Environment Configuration Format

```yaml
environment:
  name: development
  display_name: Development

app:
  name: AnKhanh CMS
  bundle_id: com.ankhanh.cms.dev

network:
  api_base_url: http://localhost:3000
  websocket_url: ws://localhost:3000
  timeout: 30000

websocket:
  enabled: true
  auto_connect: true
  reconnect_interval: 5000
  max_reconnect_attempts: 5
  heartbeat_interval: 30000
  connection_timeout: 10000
  message_queue_size: 1000
  channels:
    - inventory
    - customers
    - orders
    - notifications
  features:
    real_time_updates: true
    offline_support: true
    background_sync: true
    push_notifications: true
```

### Environment Variable Overrides

The system supports environment variable overrides for configuration values:

**Network Configuration:**
- `API_BASE_URL`: Override API base URL
- `WEBSOCKET_URL`: Override WebSocket URL
- `NETWORK_TIMEOUT`: Override network timeout

**WebSocket Configuration:**
- `WEBSOCKET_ENABLED`: Enable/disable WebSocket (true/false)
- `WEBSOCKET_AUTO_CONNECT`: Enable/disable auto-connect (true/false)
- `WEBSOCKET_RECONNECT_INTERVAL`: Override reconnect interval (milliseconds)
- `WEBSOCKET_MAX_RECONNECT_ATTEMPTS`: Override max reconnect attempts
- `WEBSOCKET_HEARTBEAT_INTERVAL`: Override heartbeat interval (milliseconds)
- `WEBSOCKET_CONNECTION_TIMEOUT`: Override connection timeout (milliseconds)
- `WEBSOCKET_MESSAGE_QUEUE_SIZE`: Override message queue size

**Feature Flags:**
- `WEBSOCKET_REAL_TIME_UPDATES`: Enable/disable real-time updates (true/false)
- `WEBSOCKET_OFFLINE_SUPPORT`: Enable/disable offline support (true/false)
- `WEBSOCKET_BACKGROUND_SYNC`: Enable/disable background sync (true/false)
- `WEBSOCKET_PUSH_NOTIFICATIONS`: Enable/disable push notifications (true/false)

## Environment-Specific Configurations

### Development Environment

- **WebSocket URL**: `ws://localhost:3000`
- **Reconnect Interval**: 5 seconds
- **Max Reconnect Attempts**: 5
- **All Features**: Enabled for testing

### Staging Environment

- **WebSocket URL**: `wss://staging-api.ankhanh.com`
- **Reconnect Interval**: 10 seconds
- **Max Reconnect Attempts**: 8
- **All Features**: Enabled for testing

### Production Environment

- **WebSocket URL**: `wss://api.ankhanh.com`
- **Reconnect Interval**: 15 seconds
- **Max Reconnect Attempts**: 10
- **Background Sync**: Disabled for battery optimization

## Configuration Validation

The system includes comprehensive configuration validation:

### WebSocket Configuration Validation

- URL format validation (must start with ws:// or wss://)
- Minimum reconnect interval (1 second)
- Valid max reconnect attempts (>= 0)
- Minimum heartbeat interval (5 seconds)
- Minimum connection timeout (1 second)
- Minimum message queue size (100)

### Feature Configuration Validation

- Dependency validation (e.g., background sync requires offline support)
- Warning detection for potentially problematic configurations
- Runtime validation of feature combinations

## Integration with Existing Systems

### Environment Configuration Service

The WebSocket configuration integrates seamlessly with the existing `EnvironmentConfigService`:

```dart
final environmentService = EnvironmentConfigService();
await environmentService.initialize('development');

final configManager = WebSocketConfigManager();
final config = configManager.getConfig(); // Uses environment configuration
```

### WebSocket Service Integration

```dart
class WebSocketService {
  final WebSocketConfigManager _configManager = WebSocketConfigManager();
  final WebSocketFeatureManager _featureManager = WebSocketFeatureManager();
  
  Future<void> initialize() async {
    if (!_configManager.isEnabled()) return;
    
    final config = _configManager.getConfig();
    // Initialize WebSocket with configuration
    
    if (_featureManager.isRealTimeUpdatesEnabled) {
      // Enable real-time features
    }
  }
}
```

## Testing

The implementation includes comprehensive tests:

### Configuration Tests (`websocket_config_test.dart`)

- Default configuration handling
- Environment-specific configuration
- Configuration validation
- Feature flag management
- Runtime overrides

### Environment Tests (`websocket_environment_test.dart`)

- Development environment configuration
- Staging environment configuration
- Production environment configuration
- Environment variable overrides
- Multi-environment switching

### Running Tests

```bash
# Run WebSocket configuration tests
flutter test test/websocket/websocket_config_test.dart

# Run environment setup tests
flutter test test/websocket/websocket_environment_test.dart

# Run all WebSocket tests
flutter test test/websocket/
```

## Usage Examples

### Basic Configuration Usage

```dart
import 'package:data/websocket/websocket.dart';

final configManager = WebSocketConfigManager();
final featureManager = WebSocketFeatureManager();

// Check if WebSocket is enabled
if (configManager.isEnabled()) {
  final config = configManager.getConfig();
  print('Connecting to: ${config.url}');
  
  // Check features
  if (featureManager.isRealTimeUpdatesEnabled) {
    // Enable real-time updates
  }
}
```

### Runtime Feature Management

```dart
// Enable a feature at runtime
featureManager.enableFeature(WebSocketFeatureManager.realTimeUpdates);

// Check feature status
if (featureManager.isFeatureEnabled('realTimeUpdates')) {
  // Feature is enabled
}

// Get all feature flags
final features = featureManager.getAllFeatureFlags();
print('Features: $features');
```

### Configuration Validation

```dart
// Validate configuration
if (configManager.validateConfiguration()) {
  print('Configuration is valid');
} else {
  print('Configuration validation failed');
}

// Validate features
if (featureManager.validateFeatureConfiguration()) {
  print('Feature configuration is valid');
}
```

## Best Practices

1. **Initialize Early**: Initialize the environment configuration service before using WebSocket configuration
2. **Validate Configuration**: Always validate configuration before using it
3. **Handle Disabled State**: Check if WebSocket is enabled before initializing services
4. **Use Feature Flags**: Use feature flags to conditionally enable/disable functionality
5. **Environment-Specific Behavior**: Adapt behavior based on the current environment
6. **Runtime Overrides**: Use runtime overrides for testing and user preferences
7. **Error Handling**: Handle configuration errors gracefully

## Troubleshooting

### Common Issues

1. **Configuration Not Loaded**: Ensure `EnvironmentConfigService.initialize()` is called first
2. **Invalid URL**: Check that WebSocket URLs use `ws://` or `wss://` schemes
3. **Feature Not Working**: Verify that the feature flag is enabled in configuration
4. **Environment Variables Not Applied**: Check environment variable names and values

### Debug Information

```dart
// Get configuration summary
final summary = configManager.getConfigSummary();
print('Config Summary: $summary');

// Get feature summary
final featureSummary = featureManager.getFeatureSummary();
print('Feature Summary: $featureSummary');
```

## Future Enhancements

1. **Dynamic Configuration Updates**: Support for updating configuration at runtime
2. **Configuration UI**: User interface for managing WebSocket settings
3. **Advanced Validation**: More sophisticated configuration validation rules
4. **Performance Monitoring**: Integration with performance monitoring systems
5. **A/B Testing**: Support for A/B testing different configurations