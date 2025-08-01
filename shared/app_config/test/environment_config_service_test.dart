import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/loaders/environment_config_loader.dart';
import 'package:app_config/services/environment_config_service.dart';

// Mock loader for testing
class MockEnvironmentConfigLoader implements EnvironmentConfigLoader {
  final Map<String, EnvironmentConfig> _configs = {};
  final Map<String, bool> _validationResults = {};
  bool _shouldThrowOnLoad = false;
  
  void setConfig(String environment, EnvironmentConfig config) {
    _configs[environment] = config;
  }
  
  void setValidationResult(String environment, bool isValid) {
    _validationResults[environment] = isValid;
  }
  
  void setShouldThrowOnLoad(bool shouldThrow) {
    _shouldThrowOnLoad = shouldThrow;
  }

  @override
  Future<EnvironmentConfig> loadConfig(String environment) async {
    if (_shouldThrowOnLoad) {
      throw Exception('Mock load error');
    }
    
    if (_configs.containsKey(environment)) {
      return _configs[environment]!;
    }
    
    throw Exception('Configuration not found for environment: $environment');
  }

  @override
  Future<bool> validateConfig(EnvironmentConfig config) async {
    final env = config.environment.name;
    return _validationResults[env] ?? true;
  }

  @override
  EnvironmentConfig getDefaultConfig() {
    return const EnvironmentConfig(
      environment: EnvironmentInfo(
        name: 'development',
        displayName: 'Test Development',
      ),
      app: AppConfig(
        name: 'Test App',
        bundleId: 'com.test.app',
        versionName: '1.0.0',
        versionCode: 1,
      ),
      network: NetworkConfig(
        apiBaseUrl: 'http://localhost:3000',
        websocketUrl: 'ws://localhost:3001',
        timeout: 30000,
      ),
      build: BuildConfig(
        flavor: 'development',
        buildType: 'debug',
        obfuscate: false,
        shrinkResources: false,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('EnvironmentConfigService', () {
    late EnvironmentConfigService service;
    late MockEnvironmentConfigLoader mockLoader;

    setUp(() {
      service = EnvironmentConfigService();
      service.reset(); // Reset singleton state
      mockLoader = MockEnvironmentConfigLoader();
    });

    tearDown(() {
      service.reset();
    });

    group('Initialization', () {
      test('should initialize successfully with valid configuration', () async {
        final testConfig = const EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'development',
            displayName: 'Development Environment',
          ),
          app: AppConfig(
            name: 'Test App',
            bundleId: 'com.test.app',
          ),
          network: NetworkConfig(
            apiBaseUrl: 'https://api.test.com',
          ),
        );

        mockLoader.setConfig('development', testConfig);
        
        await service.initializeWithLoader(mockLoader, 'development');

        expect(service.isInitialized, true);
        expect(service.environmentName, 'development');
        expect(service.appName, 'Test App');
        expect(service.apiBaseUrl, 'https://api.test.com');
        expect(service.bundleId, 'com.test.app');
      });

      test('should use default configuration when loading fails', () async {
        mockLoader.setShouldThrowOnLoad(true);
        
        await service.initializeWithLoader(mockLoader, 'invalid');

        expect(service.isInitialized, true);
        expect(service.environmentName, 'development');
        expect(service.appName, 'Test App');
        expect(service.apiBaseUrl, 'http://localhost:3000');
      });

      test('should throw StateError when accessing config before initialization', () {
        expect(() => service.config, throwsStateError);
        expect(() => service.apiBaseUrl, throwsStateError);
        expect(() => service.appName, throwsStateError);
      });
    });

    group('Configuration Properties', () {
      setUp(() async {
        final testConfig = const EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'production',
            displayName: 'Production Environment',
          ),
          app: AppConfig(
            name: 'Production App',
            bundleId: 'com.production.app',
            versionName: '2.1.0',
            versionCode: 21,
          ),
          network: NetworkConfig(
            apiBaseUrl: 'https://api.production.com',
            websocketUrl: 'wss://ws.production.com',
            timeout: 60000,
          ),
          build: BuildConfig(
            flavor: 'production',
            buildType: 'release',
            obfuscate: true,
            shrinkResources: true,
          ),
          signing: SigningConfig(
            storeFile: 'release.keystore',
            storePasswordEnv: 'STORE_PASSWORD',
            keyAlias: 'release',
            keyPasswordEnv: 'KEY_PASSWORD',
          ),
          distribution: DistributionConfig(
            platform: 'google_play',
            track: 'production',
          ),
          notifications: NotificationConfig(
            slackWebhook: 'https://hooks.slack.com/test',
            emailRecipients: ['dev@test.com'],
          ),
        );

        mockLoader.setConfig('production', testConfig);
        await service.initializeWithLoader(mockLoader, 'production');
      });

      test('should provide correct basic properties', () {
        expect(service.environmentName, 'production');
        expect(service.environmentDisplayName, 'Production Environment');
        expect(service.appName, 'Production App');
        expect(service.bundleId, 'com.production.app');
        expect(service.versionName, '2.1.0');
        expect(service.versionCode, 21);
        expect(service.currentEnvironment, 'production');
      });

      test('should provide correct network properties', () {
        expect(service.apiBaseUrl, 'https://api.production.com');
        expect(service.websocketUrl, 'wss://ws.production.com');
        expect(service.timeout, 60000);
      });

      test('should provide correct environment flags', () {
        expect(service.isProduction, true);
        expect(service.isStaging, false);
        expect(service.isDebugMode, false);
      });

      test('should provide correct build configuration', () {
        final buildConfig = service.buildConfig;
        expect(buildConfig, isNotNull);
        expect(buildConfig!.flavor, 'production');
        expect(buildConfig.buildType, 'release');
        expect(buildConfig.obfuscate, true);
        expect(buildConfig.shrinkResources, true);
      });

      test('should provide correct signing configuration', () {
        final signingConfig = service.signingConfig;
        expect(signingConfig, isNotNull);
        expect(signingConfig!.storeFile, 'release.keystore');
        expect(signingConfig.keyAlias, 'release');
      });

      test('should provide correct distribution configuration', () {
        final distributionConfig = service.distributionConfig;
        expect(distributionConfig, isNotNull);
        expect(distributionConfig!.platform, 'google_play');
        expect(distributionConfig.track, 'production');
      });

      test('should provide correct notification configuration', () {
        final notificationConfig = service.notificationConfig;
        expect(notificationConfig, isNotNull);
        expect(notificationConfig!.slackWebhook, 'https://hooks.slack.com/test');
        expect(notificationConfig.emailRecipients, ['dev@test.com']);
      });
    });

    group('Environment Flags', () {
      test('should correctly identify development environment', () async {
        final devConfig = const EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'development',
            displayName: 'Development',
          ),
          app: AppConfig(
            name: 'Dev App',
            bundleId: 'com.dev.app',
          ),
          network: NetworkConfig(
            apiBaseUrl: 'http://localhost:3000',
          ),
        );

        mockLoader.setConfig('development', devConfig);
        await service.initializeWithLoader(mockLoader, 'development');

        expect(service.isDebugMode, true);
        expect(service.isProduction, false);
        expect(service.isStaging, false);
      });

      test('should correctly identify staging environment', () async {
        final stagingConfig = const EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'staging',
            displayName: 'Staging',
          ),
          app: AppConfig(
            name: 'Staging App',
            bundleId: 'com.staging.app',
          ),
          network: NetworkConfig(
            apiBaseUrl: 'https://api.staging.com',
          ),
        );

        mockLoader.setConfig('staging', stagingConfig);
        await service.initializeWithLoader(mockLoader, 'staging');

        expect(service.isDebugMode, false);
        expect(service.isProduction, false);
        expect(service.isStaging, true);
      });
    });

    group('Validation', () {
      test('should validate current configuration successfully', () async {
        final testConfig = const EnvironmentConfig(
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

        mockLoader.setConfig('development', testConfig);
        mockLoader.setValidationResult('development', true);
        
        await service.initializeWithLoader(mockLoader, 'development');

        final isValid = await service.validateCurrentConfig();
        expect(isValid, true);
      });

      test('should return false for invalid configuration', () async {
        final testConfig = const EnvironmentConfig(
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

        mockLoader.setConfig('development', testConfig);
        mockLoader.setValidationResult('development', false);
        
        await service.initializeWithLoader(mockLoader, 'development');

        final isValid = await service.validateCurrentConfig();
        // The mock loader should return false for validation
        expect(isValid, false);
      });

      test('should return false when not initialized', () async {
        final isValid = await service.validateCurrentConfig();
        expect(isValid, false);
      });
    });

    group('Reload', () {
      test('should reload configuration successfully', () async {
        final initialConfig = const EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'development',
            displayName: 'Development',
          ),
          app: AppConfig(
            name: 'Initial App',
            bundleId: 'com.initial.app',
          ),
          network: NetworkConfig(
            apiBaseUrl: 'https://api.initial.com',
          ),
        );

        final reloadedConfig = const EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'development',
            displayName: 'Development',
          ),
          app: AppConfig(
            name: 'Reloaded App',
            bundleId: 'com.reloaded.app',
          ),
          network: NetworkConfig(
            apiBaseUrl: 'https://api.reloaded.com',
          ),
        );

        mockLoader.setConfig('development', initialConfig);
        await service.initializeWithLoader(mockLoader, 'development');
        
        expect(service.appName, 'Initial App');

        // Update mock config and reload with the same mock loader
        mockLoader.setConfig('development', reloadedConfig);
        await service.initializeWithLoader(mockLoader, 'development');

        expect(service.appName, 'Reloaded App');
        expect(service.apiBaseUrl, 'https://api.reloaded.com');
      });
    });

    group('JSON Serialization', () {
      test('should provide configuration as JSON', () async {
        final testConfig = const EnvironmentConfig(
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

        mockLoader.setConfig('development', testConfig);
        await service.initializeWithLoader(mockLoader, 'development');

        final json = service.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json['environment']['name'], 'development');
        expect(json['app']['name'], 'Test App');
        expect(json['network']['api_base_url'], 'https://api.test.com');
      });
    });

    group('toString', () {
      test('should provide meaningful string representation when initialized', () async {
        final testConfig = const EnvironmentConfig(
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

        mockLoader.setConfig('development', testConfig);
        await service.initializeWithLoader(mockLoader, 'development');

        final stringRepresentation = service.toString();
        expect(stringRepresentation, contains('EnvironmentConfigService'));
        expect(stringRepresentation, contains('development'));
        expect(stringRepresentation, contains('Test App'));
      });

      test('should indicate not initialized state', () {
        final stringRepresentation = service.toString();
        expect(stringRepresentation, 'EnvironmentConfigService(not initialized)');
      });
    });
  });
}