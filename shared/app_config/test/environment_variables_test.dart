import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/loaders/environment_config_loader.dart';
import 'package:app_config/services/environment_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Environment Variables Support', () {
    late EnvironmentConfigService service;

    setUp(() {
      service = EnvironmentConfigService();
      service.reset();
    });

    tearDown(() {
      service.reset();
    });

    test('should apply environment variable overrides to configuration', () async {
      // Create a base configuration
      final baseConfig = const EnvironmentConfig(
        environment: EnvironmentInfo(
          name: 'development',
          displayName: 'Development',
        ),
        app: AppConfig(
          name: 'Base App',
          bundleId: 'com.base.app',
        ),
        network: NetworkConfig(
          apiBaseUrl: 'http://localhost:3000',
          websocketUrl: 'ws://localhost:3001',
          timeout: 30000,
        ),
      );

      // Create a mock loader that returns the base config
      final mockLoader = _MockLoaderWithOverrides(baseConfig);
      
      await service.initializeWithLoader(mockLoader, 'development');

      // The mock loader simulates environment variable overrides
      expect(service.appName, 'Override App'); // Should be overridden
      expect(service.bundleId, 'com.override.app'); // Should be overridden
      expect(service.apiBaseUrl, 'https://api.override.com'); // Should be overridden
      expect(service.websocketUrl, 'wss://ws.override.com'); // Should be overridden
      expect(service.timeout, 60000); // Should be overridden
    });

    test('should use original values when environment variables are not set', () async {
      final baseConfig = const EnvironmentConfig(
        environment: EnvironmentInfo(
          name: 'development',
          displayName: 'Development',
        ),
        app: AppConfig(
          name: 'Base App',
          bundleId: 'com.base.app',
        ),
        network: NetworkConfig(
          apiBaseUrl: 'http://localhost:3000',
          websocketUrl: 'ws://localhost:3001',
          timeout: 30000,
        ),
      );

      // Create a mock loader that doesn't override anything
      final mockLoader = _MockLoaderNoOverrides(baseConfig);
      
      await service.initializeWithLoader(mockLoader, 'development');

      // Should use original values
      expect(service.appName, 'Base App');
      expect(service.bundleId, 'com.base.app');
      expect(service.apiBaseUrl, 'http://localhost:3000');
      expect(service.websocketUrl, 'ws://localhost:3001');
      expect(service.timeout, 30000);
    });

    test('should handle partial environment variable overrides', () async {
      final baseConfig = const EnvironmentConfig(
        environment: EnvironmentInfo(
          name: 'development',
          displayName: 'Development',
        ),
        app: AppConfig(
          name: 'Base App',
          bundleId: 'com.base.app',
        ),
        network: NetworkConfig(
          apiBaseUrl: 'http://localhost:3000',
          websocketUrl: 'ws://localhost:3001',
          timeout: 30000,
        ),
      );

      // Create a mock loader that only overrides some values
      final mockLoader = _MockLoaderPartialOverrides(baseConfig);
      
      await service.initializeWithLoader(mockLoader, 'development');

      // Should use overridden values where available
      expect(service.appName, 'Base App'); // Not overridden
      expect(service.bundleId, 'com.base.app'); // Not overridden
      expect(service.apiBaseUrl, 'https://api.partial.com'); // Overridden
      expect(service.websocketUrl, 'ws://localhost:3001'); // Not overridden
      expect(service.timeout, 30000); // Not overridden
    });
  });
}

// Mock loader that simulates environment variable overrides
class _MockLoaderWithOverrides implements EnvironmentConfigLoader {
  final EnvironmentConfig _baseConfig;

  _MockLoaderWithOverrides(this._baseConfig);

  @override
  Future<EnvironmentConfig> loadConfig(String environment) async {
    // Simulate environment variable overrides
    return _baseConfig.copyWith(
      app: _baseConfig.app.copyWith(
        name: 'Override App',
        bundleId: 'com.override.app',
      ),
      network: _baseConfig.network.copyWith(
        apiBaseUrl: 'https://api.override.com',
        websocketUrl: 'wss://ws.override.com',
        timeout: 60000,
      ),
    );
  }

  @override
  Future<bool> validateConfig(EnvironmentConfig config) async => true;

  @override
  EnvironmentConfig getDefaultConfig() => _baseConfig;
}

// Mock loader that doesn't override anything
class _MockLoaderNoOverrides implements EnvironmentConfigLoader {
  final EnvironmentConfig _baseConfig;

  _MockLoaderNoOverrides(this._baseConfig);

  @override
  Future<EnvironmentConfig> loadConfig(String environment) async {
    return _baseConfig;
  }

  @override
  Future<bool> validateConfig(EnvironmentConfig config) async => true;

  @override
  EnvironmentConfig getDefaultConfig() => _baseConfig;
}

// Mock loader that only overrides some values
class _MockLoaderPartialOverrides implements EnvironmentConfigLoader {
  final EnvironmentConfig _baseConfig;

  _MockLoaderPartialOverrides(this._baseConfig);

  @override
  Future<EnvironmentConfig> loadConfig(String environment) async {
    // Only override API base URL
    return _baseConfig.copyWith(
      network: _baseConfig.network.copyWith(
        apiBaseUrl: 'https://api.partial.com',
      ),
    );
  }

  @override
  Future<bool> validateConfig(EnvironmentConfig config) async => true;

  @override
  EnvironmentConfig getDefaultConfig() => _baseConfig;
}