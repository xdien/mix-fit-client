import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/loaders/environment_config_loader.dart';
import 'package:app_config/services/environment_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('YamlEnvironmentConfigLoader', () {
    late YamlEnvironmentConfigLoader loader;

    setUp(() {
      loader = YamlEnvironmentConfigLoader();
    });

    test('should provide default config', () {
      final defaultConfig = loader.getDefaultConfig();

      expect(defaultConfig.environment.name, 'development');
      expect(defaultConfig.app.bundleId, 'com.placeholder.module.default');
      expect(defaultConfig.network.apiBaseUrl, 'http://localhost:3000');
    });

    test('should validate config correctly', () async {
      final validConfig = EnvironmentConfig(
        environment: EnvironmentInfo(
          name: 'development',
          displayName: 'Development',
        ),
        app: AppConfig(
          name: 'Test App',
          bundleId: 'com.test.app',
        ),
        network: NetworkConfig(
          apiBaseUrl: 'https://api.test.com',
        ),
      );

      final isValid = await loader.validateConfig(validConfig);
      expect(isValid, true);
    });

    test('should reject invalid config', () async {
      final invalidConfig = EnvironmentConfig(
        environment: EnvironmentInfo(
          name: 'invalid_env',
          displayName: 'Invalid Environment',
        ),
        app: AppConfig(
          name: 'Test App',
          bundleId: 'invalid-bundle-id',
        ),
        network: NetworkConfig(
          apiBaseUrl: 'not-a-url',
        ),
      );

      final isValid = await loader.validateConfig(invalidConfig);
      expect(isValid, false);
    });
  });

  group('EnvironmentConfigService', () {
    test('should throw error when not initialized', () {
      final service = EnvironmentConfigService();
      expect(() => service.config, throwsStateError);
    });

    test('should provide service properties after initialization', () async {
      final service = EnvironmentConfigService();
      
      // This will use default config since YAML files may not be available in test
      await service.initialize('development');
      
      expect(service.isInitialized, true);
      expect(service.environmentName, 'development');
      expect(service.apiBaseUrl, isNotEmpty);
      expect(service.appName, isNotEmpty);
      expect(service.bundleId, isNotEmpty);
      expect(service.isDebugMode, true);
      expect(service.isProduction, false);
    });
  });
}