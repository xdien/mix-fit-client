import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/services/environment_config_service.dart';
import 'package:app_config/loaders/environment_config_loader.dart';
import '../../lib/websocket/services/websocket_config_manager.dart';
import '../../lib/websocket/services/websocket_feature_manager.dart';
import '../../lib/websocket/models/websocket_config.dart';

void main() {
  group('WebSocket Configuration Tests', () {
    late WebSocketConfigManager configManager;
    late WebSocketFeatureManager featureManager;
    late EnvironmentConfigService environmentService;

    setUp(() {
      configManager = WebSocketConfigManager();
      featureManager = WebSocketFeatureManager();
      environmentService = EnvironmentConfigService();
      
      // Reset any cached state
      configManager.resetCache();
      featureManager.clearAllOverrides();
      environmentService.reset();
    });

    group('WebSocketConfigManager', () {
      test('should provide default configuration when environment config is missing', () async {
        // Mock environment service to return minimal config
        final mockConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(apiBaseUrl: 'http://localhost:3000'),
        );

        // Initialize with mock config
        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(mockConfig),
          'test',
        );

        final config = configManager.getConfig();

        expect(config.url, equals('ws://localhost:3000'));
        expect(config.reconnectInterval, equals(const Duration(seconds: 5)));
        expect(config.maxReconnectAttempts, equals(5));
        expect(config.heartbeatInterval, equals(const Duration(seconds: 30)));
        expect(config.autoReconnect, isTrue);
      });

      test('should use environment-specific WebSocket configuration', () async {
        final mockConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(
            apiBaseUrl: 'http://localhost:3000',
            websocketUrl: 'ws://localhost:3001',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            autoConnect: false,
            reconnectInterval: 10000,
            maxReconnectAttempts: 3,
            heartbeatInterval: 60000,
            connectionTimeout: 15000,
            messageQueueSize: 2000,
            channels: ['test-channel'],
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: false,
              backgroundSync: true,
              pushNotifications: false,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(mockConfig),
          'test',
        );

        final config = configManager.getConfig();

        expect(config.url, equals('ws://localhost:3001'));
        expect(config.reconnectInterval, equals(const Duration(milliseconds: 10000)));
        expect(config.maxReconnectAttempts, equals(3));
        expect(config.heartbeatInterval, equals(const Duration(milliseconds: 60000)));
        expect(config.autoReconnect, isFalse);

        expect(configManager.isEnabled(), isTrue);
        expect(configManager.getConnectionTimeout(), equals(const Duration(milliseconds: 15000)));
        expect(configManager.getMessageQueueSize(), equals(2000));
        expect(configManager.getChannels(), equals(['test-channel']));
      });

      test('should validate configuration correctly', () async {
        final validConfig = EnvironmentConfig(
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
            heartbeatInterval: 30000,
            connectionTimeout: 10000,
            messageQueueSize: 1000,
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(validConfig),
          'test',
        );

        expect(configManager.validateConfiguration(), isTrue);
      });

      test('should fail validation for invalid configuration', () async {
        final invalidConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(
            apiBaseUrl: 'http://localhost:3000',
            websocketUrl: 'invalid-url',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            reconnectInterval: 500, // Too short
            maxReconnectAttempts: -1, // Invalid
            heartbeatInterval: 1000, // Too short
            connectionTimeout: 500, // Too short
            messageQueueSize: 50, // Too small
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(invalidConfig),
          'test',
        );

        expect(configManager.validateConfiguration(), isFalse);
      });

      test('should convert HTTP URLs to WebSocket URLs', () async {
        final httpConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(apiBaseUrl: 'https://api.example.com'),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(httpConfig),
          'test',
        );

        final config = configManager.getConfig();
        expect(config.url, equals('wss://api.example.com'));
      });

      test('should provide configuration summary', () async {
        final mockConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(
            apiBaseUrl: 'http://localhost:3000',
            websocketUrl: 'ws://localhost:3000',
          ),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            channels: ['inventory', 'orders'],
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: true,
              backgroundSync: false,
              pushNotifications: true,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(mockConfig),
          'test',
        );

        final summary = configManager.getConfigSummary();

        expect(summary['environment'], equals('test'));
        expect(summary['websocketUrl'], equals('ws://localhost:3000'));
        expect(summary['enabled'], isTrue);
        expect(summary['channels'], equals(['inventory', 'orders']));
        expect(summary['features']['realTimeUpdates'], isTrue);
        expect(summary['features']['backgroundSync'], isFalse);
      });
    });

    group('WebSocketFeatureManager', () {
      test('should check feature flags from configuration', () async {
        final mockConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(apiBaseUrl: 'http://localhost:3000'),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: false,
              backgroundSync: true,
              pushNotifications: false,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(mockConfig),
          'test',
        );

        expect(featureManager.isRealTimeUpdatesEnabled, isTrue);
        expect(featureManager.isOfflineSupportEnabled, isFalse);
        expect(featureManager.isBackgroundSyncEnabled, isTrue);
        expect(featureManager.isPushNotificationsEnabled, isFalse);
      });

      test('should handle runtime feature overrides', () async {
        final mockConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(apiBaseUrl: 'http://localhost:3000'),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            features: WebSocketFeatureFlags(
              realTimeUpdates: false,
              offlineSupport: true,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(mockConfig),
          'test',
        );

        // Initial state from configuration
        expect(featureManager.isRealTimeUpdatesEnabled, isFalse);
        expect(featureManager.isOfflineSupportEnabled, isTrue);

        // Apply runtime overrides
        featureManager.enableFeature(WebSocketFeatureManager.realTimeUpdates);
        featureManager.disableFeature(WebSocketFeatureManager.offlineSupport);

        // Check overridden state
        expect(featureManager.isRealTimeUpdatesEnabled, isTrue);
        expect(featureManager.isOfflineSupportEnabled, isFalse);

        // Clear overrides
        featureManager.clearAllOverrides();

        // Should return to configuration defaults
        expect(featureManager.isRealTimeUpdatesEnabled, isFalse);
        expect(featureManager.isOfflineSupportEnabled, isTrue);
      });

      test('should provide feature metadata', () {
        expect(WebSocketFeatureManager.availableFeatures, hasLength(4));
        expect(WebSocketFeatureManager.availableFeatures, contains('realTimeUpdates'));
        expect(WebSocketFeatureManager.availableFeatures, contains('offlineSupport'));
        expect(WebSocketFeatureManager.availableFeatures, contains('backgroundSync'));
        expect(WebSocketFeatureManager.availableFeatures, contains('pushNotifications'));

        expect(featureManager.getFeatureDisplayName('realTimeUpdates'), equals('Real-time Updates'));
        expect(featureManager.getFeatureDescription('offlineSupport'), 
               contains('Queue updates when offline'));
        expect(featureManager.isFeatureUserToggleable('backgroundSync'), isTrue);
      });

      test('should validate feature configuration', () async {
        final validConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(apiBaseUrl: 'http://localhost:3000'),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
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

        expect(featureManager.validateFeatureConfiguration(), isTrue);
      });

      test('should provide feature summary', () async {
        final mockConfig = EnvironmentConfig(
          environment: const EnvironmentInfo(name: 'test', displayName: 'Test'),
          app: const AppEnvironmentConfig(name: 'Test App', bundleId: 'com.test.app'),
          network: const NetworkConfig(apiBaseUrl: 'http://localhost:3000'),
          websocket: const WebSocketEnvironmentConfig(
            enabled: true,
            features: WebSocketFeatureFlags(
              realTimeUpdates: true,
              offlineSupport: false,
            ),
          ),
        );

        await environmentService.initializeWithLoader(
          MockEnvironmentConfigLoader(mockConfig),
          'test',
        );

        featureManager.setFeatureOverride('backgroundSync', true);

        final summary = featureManager.getFeatureSummary();

        expect(summary['websocketEnabled'], isTrue);
        expect(summary['features']['realTimeUpdates'], isTrue);
        expect(summary['features']['offlineSupport'], isFalse);
        expect(summary['features']['backgroundSync'], isTrue);
        expect(summary['runtimeOverrides']['backgroundSync'], isTrue);
        expect(summary['environment'], equals('test'));
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
    return true;
  }
}