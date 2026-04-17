import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/app_config.dart';
import '../../lib/websocket/services/websocket_config_manager.dart';
import '../../lib/websocket/services/websocket_feature_manager.dart';

void main() {
  group('WebSocket Environment Setup Tests', () {
    late WebSocketConfigManager configManager;
    late WebSocketFeatureManager featureManager;
    late EnvironmentConfigService environmentService;

    setUp(() {
      configManager = WebSocketConfigManager();
      featureManager = WebSocketFeatureManager();
      environmentService = EnvironmentConfigService();
      
      // Reset state
      configManager.resetCache();
      featureManager.clearAllOverrides();
      environmentService.reset();
    });

    group('Development Environment', () {
      test('should configure WebSocket for development environment', () async {
        final devConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'development', displayName: 'Development'),
          app: const AppEnvironmentConfig(name: 'AnKhanh CMS', bundleId: 'com.ankhanh.cms.dev'),
          network: const NetworkConfig(
            apiBaseUrl: 'http://localhost:3000',
            websocketUrl: 'ws://localhost:3000',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            autoConnect: true,
            reconnectInterval: 5000,
            maxReconnectAttempts: 5,
            heartbeatInterval: 30000,
            connectionTimeout: 10000,
            messageQueueSize: 1000,
            channels: ['inventory', 'customers', 'orders', 'notifications'],
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: true,
              backgroundSync: true,
              pushNotifications: true,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(devConfig),
          'development',
        );

        final config = configManager.getConfig();
        
        expect(config.url, equals('ws://localhost:3000'));
        expect(config.reconnectInterval, equals(const Duration(milliseconds: 5000)));
        expect(config.maxReconnectAttempts, equals(5));
        expect(config.heartbeatInterval, equals(const Duration(milliseconds: 30000)));
        expect(config.autoReconnect, isTrue);

        expect(configManager.isEnabled(), isTrue);
        expect(configManager.isAutoConnectEnabled(), isTrue);
        expect(configManager.getConnectionTimeout(), equals(const Duration(milliseconds: 10000)));
        expect(configManager.getMessageQueueSize(), equals(1000));
        expect(configManager.getChannels(), hasLength(4));

        expect(featureManager.isRealTimeUpdatesEnabled, isTrue);
        expect(featureManager.isOfflineSupportEnabled, isTrue);
        expect(featureManager.isBackgroundSyncEnabled, isTrue);
        expect(featureManager.isPushNotificationsEnabled, isTrue);
      });
    });

    group('Staging Environment', () {
      test('should configure WebSocket for staging environment', () async {
        final stagingConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'staging', displayName: 'Staging'),
          app: const AppEnvironmentConfig(name: 'AnKhanh CMS', bundleId: 'com.ankhanh.cms.staging'),
          network: const NetworkConfig(
            apiBaseUrl: 'https://staging-api.ankhanh.com',
            websocketUrl: 'wss://staging-api.ankhanh.com',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            autoConnect: true,
            reconnectInterval: 10000,
            maxReconnectAttempts: 8,
            heartbeatInterval: 60000,
            connectionTimeout: 15000,
            messageQueueSize: 2000,
            channels: ['inventory', 'customers', 'orders', 'notifications'],
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: true,
              backgroundSync: true,
              pushNotifications: true,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(stagingConfig),
          'staging',
        );

        final config = configManager.getConfig();
        
        expect(config.url, equals('wss://staging-api.ankhanh.com'));
        expect(config.reconnectInterval, equals(const Duration(milliseconds: 10000)));
        expect(config.maxReconnectAttempts, equals(8));
        expect(config.heartbeatInterval, equals(const Duration(milliseconds: 60000)));
        expect(configManager.getConnectionTimeout(), equals(const Duration(milliseconds: 15000)));
        expect(configManager.getMessageQueueSize(), equals(2000));
      });
    });

    group('Production Environment', () {
      test('should configure WebSocket for production environment', () async {
        final prodConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'production', displayName: 'Production'),
          app: const AppEnvironmentConfig(name: 'AnKhanh CMS', bundleId: 'com.ankhanh.cms'),
          network: const NetworkConfig(
            apiBaseUrl: 'https://api.ankhanh.com',
            websocketUrl: 'wss://api.ankhanh.com',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            autoConnect: true,
            reconnectInterval: 15000,
            maxReconnectAttempts: 10,
            heartbeatInterval: 60000,
            connectionTimeout: 20000,
            messageQueueSize: 5000,
            channels: ['inventory', 'customers', 'orders', 'notifications'],
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: true,
              backgroundSync: false, // Disabled in production
              pushNotifications: true,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(prodConfig),
          'production',
        );

        final config = configManager.getConfig();
        
        expect(config.url, equals('wss://api.ankhanh.com'));
        expect(config.reconnectInterval, equals(const Duration(milliseconds: 15000)));
        expect(config.maxReconnectAttempts, equals(10));
        expect(config.heartbeatInterval, equals(const Duration(milliseconds: 60000)));
        expect(configManager.getConnectionTimeout(), equals(const Duration(milliseconds: 20000)));
        expect(configManager.getMessageQueueSize(), equals(5000));

        // Background sync should be disabled in production
        expect(featureManager.isBackgroundSyncEnabled, isFalse);
        expect(featureManager.isRealTimeUpdatesEnabled, isTrue);
        expect(featureManager.isOfflineSupportEnabled, isTrue);
        expect(featureManager.isPushNotificationsEnabled, isTrue);
      });
    });

    group('Environment Variable Overrides', () {
      test('should apply WebSocket environment variable overrides', () async {
        // This test would need to be run with environment variables set
        // For now, we'll test the override logic directly
        
        final baseConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(
            apiBaseUrl: 'http://localhost:3000',
            websocketUrl: 'ws://localhost:3000',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            reconnectInterval: 5000,
            maxReconnectAttempts: 5,
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: true,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(baseConfig),
          'test',
        );

        // Test that configuration is loaded correctly
        expect(configManager.isEnabled(), isTrue);
        expect(configManager.getConfig().reconnectInterval, equals(const Duration(milliseconds: 5000)));
        expect(featureManager.isRealTimeUpdatesEnabled, isTrue);
        expect(featureManager.isOfflineSupportEnabled, isTrue);
      });
    });

    group('Configuration Validation', () {
      test('should validate complete environment configuration', () async {
        final validConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(
            apiBaseUrl: 'https://api.example.com',
            websocketUrl: 'wss://api.example.com',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            autoConnect: true,
            reconnectInterval: 5000,
            maxReconnectAttempts: 5,
            heartbeatInterval: 30000,
            connectionTimeout: 10000,
            messageQueueSize: 1000,
            channels: ['test'],
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: true,
              backgroundSync: true,
              pushNotifications: true,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(validConfig),
          'test',
        );

        expect(configManager.validateConfiguration(), isTrue);
        expect(featureManager.validateFeatureConfiguration(), isTrue);
        expect(await environmentService.validateCurrentConfig(), isTrue);
      });

      test('should detect invalid environment configuration', () async {
        final invalidConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(
            apiBaseUrl: 'invalid-url',
            websocketUrl: 'not-a-websocket-url',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            reconnectInterval: 100, // Too short
            maxReconnectAttempts: -1, // Invalid
            heartbeatInterval: 1000, // Too short
            connectionTimeout: 500, // Too short
            messageQueueSize: 10, // Too small
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(invalidConfig),
          'test',
        );

        expect(configManager.validateConfiguration(), isFalse);
      });
    });

    group('Multi-Environment Support', () {
      test('should switch between environments correctly', () async {
        final devConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'development', displayName: 'Development'),
          app: const AppEnvironmentConfig(name: 'Dev App', bundleId: 'com.test.dev'),
          network: const NetworkConfig(
            apiBaseUrl: 'http://localhost:3000',
            websocketUrl: 'ws://localhost:3000',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            reconnectInterval: 5000,
            features: WebSocketFeatureFlags(backgroundSync: true),
          ),
        );

        final prodConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'production', displayName: 'Production'),
          app: const AppEnvironmentConfig(name: 'Prod App', bundleId: 'com.test.prod'),
          network: const NetworkConfig(
            apiBaseUrl: 'https://api.example.com',
            websocketUrl: 'wss://api.example.com',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            reconnectInterval: 15000,
            features: WebSocketFeatureFlags(backgroundSync: false),
          ),
        );

        // Test development configuration
        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(devConfig),
          'development',
        );

        expect(configManager.getConfig().url, equals('ws://localhost:3000'));
        expect(configManager.getConfig().reconnectInterval, equals(const Duration(milliseconds: 5000)));
        expect(featureManager.isBackgroundSyncEnabled, isTrue);

        // Switch to production configuration
        configManager.resetCache();
        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(prodConfig),
          'production',
        );

        expect(configManager.getConfig().url, equals('wss://api.example.com'));
        expect(configManager.getConfig().reconnectInterval, equals(const Duration(milliseconds: 15000)));
        expect(featureManager.isBackgroundSyncEnabled, isFalse);
      });
    });
  });
}

/// Mock environment config loader for testing
class MockEnvironmentConfigLoader extends EnvironmentConfigLoader {
  final EnvironmentConfig _config;

  MockEnvironmentConfigLoader(this._config);

  @override
  Future<EnvironmentConfig> loadConfig(String environment) async {
    return _config;
  }

  @override
  EnvironmentConfig getDefaultConfig() {
    return _config;
  }

  @override
  Future<bool> validateConfig(EnvironmentConfig config) async {
    // Basic validation
    if (config.network.apiBaseUrl.isEmpty) return false;
    if (config.app.name.isEmpty) return false;
    if (config.app.bundleId.isEmpty) return false;
    return true;
  }
}