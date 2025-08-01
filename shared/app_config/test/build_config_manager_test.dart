import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/config/build_config_manager.dart';

void main() {
  group('BuildConfigManager', () {
    late EnvironmentConfig testConfig;
    late BuildConfigManager buildConfigManager;

    setUp(() {
      testConfig = const EnvironmentConfig(
        environment: EnvironmentInfo(
          name: 'test',
          displayName: 'Test Environment',
        ),
        app: AppConfig(
          name: 'Test App',
          bundleId: 'com.test.app',
          versionName: '1.0.0',
          versionCode: 1,
        ),
        network: NetworkConfig(
          apiBaseUrl: 'https://api.test.com',
          websocketUrl: 'wss://ws.test.com',
          timeout: 30000,
        ),
        build: BuildConfig(
          flavor: 'test',
          buildType: 'debug',
          obfuscate: false,
          shrinkResources: false,
        ),
        signing: SigningConfig(
          storeFile: 'test.keystore',
          storePasswordEnv: 'TEST_STORE_PASSWORD',
          keyAlias: 'test',
          keyPasswordEnv: 'TEST_KEY_PASSWORD',
        ),
        distribution: DistributionConfig(
          platform: 'google_play',
          track: 'internal',
        ),
        notifications: NotificationConfig(
          slackWebhook: 'https://hooks.slack.com/test',
          emailRecipients: ['test@example.com'],
        ),
      );

      buildConfigManager = BuildConfigManager(
        environmentConfig: testConfig,
        buildVariant: 'debug',
        isDebugMode: true,
      );
    });

    group('Basic Properties', () {
      test('should return correct application ID', () {
        expect(buildConfigManager.applicationId, equals('com.test.app'));
      });

      test('should return correct application name', () {
        expect(buildConfigManager.applicationName, equals('Test App'));
      });

      test('should return correct display name', () {
        expect(buildConfigManager.displayName, equals('Test Environment'));
      });

      test('should return correct build variant', () {
        expect(buildConfigManager.buildVariant, equals('debug'));
      });

      test('should return correct build type', () {
        expect(buildConfigManager.buildType, equals('debug'));
      });

      test('should return correct flavor', () {
        expect(buildConfigManager.flavor, equals('test'));
      });

      test('should return correct version information', () {
        expect(buildConfigManager.versionName, equals('1.0.0'));
        expect(buildConfigManager.versionCode, equals(1));
      });
    });

    group('Build Mode Detection', () {
      test('should correctly identify debug build', () {
        expect(buildConfigManager.isDebugBuild, isTrue);
        expect(buildConfigManager.isReleaseBuild, isFalse);
      });

      test('should correctly identify release build', () {
        final releaseManager = BuildConfigManager(
          environmentConfig: testConfig,
          buildVariant: 'release',
          isDebugMode: false,
        );

        expect(releaseManager.isDebugBuild, isFalse);
        expect(releaseManager.isReleaseBuild, isTrue);
      });
    });

    group('Build Settings', () {
      test('should return correct obfuscation setting', () {
        expect(buildConfigManager.shouldObfuscate, isFalse);
      });

      test('should return correct resource shrinking setting', () {
        expect(buildConfigManager.shouldShrinkResources, isFalse);
      });

      test('should default obfuscation to release build setting', () {
        final configWithoutBuild = testConfig.copyWith(build: null);
        final releaseManager = BuildConfigManager(
          environmentConfig: configWithoutBuild,
          buildVariant: 'release',
          isDebugMode: false,
        );

        expect(releaseManager.shouldObfuscate, isTrue);
        expect(releaseManager.shouldShrinkResources, isTrue);
      });
    });

    group('Configuration Generation', () {
      test('should generate correct build settings map', () {
        final settings = buildConfigManager.getBuildSettings();

        expect(settings['applicationId'], equals('com.test.app'));
        expect(settings['applicationName'], equals('Test App'));
        expect(settings['displayName'], equals('Test Environment'));
        expect(settings['buildVariant'], equals('debug'));
        expect(settings['buildType'], equals('debug'));
        expect(settings['flavor'], equals('test'));
        expect(settings['versionName'], equals('1.0.0'));
        expect(settings['versionCode'], equals(1));
        expect(settings['isDebugBuild'], isTrue);
        expect(settings['isReleaseBuild'], isFalse);
        expect(settings['shouldObfuscate'], isFalse);
        expect(settings['shouldShrinkResources'], isFalse);
        expect(settings['environment'], equals('test'));
      });

      test('should generate correct Gradle properties', () {
        final properties = buildConfigManager.generateGradleProperties();

        expect(properties['flutter.applicationId'], equals('com.test.app'));
        expect(properties['flutter.applicationName'], equals('Test App'));
        expect(properties['flutter.versionName'], equals('1.0.0'));
        expect(properties['flutter.versionCode'], equals('1'));
        expect(properties['flutter.buildType'], equals('debug'));
        expect(properties['flutter.flavor'], equals('test'));
        expect(properties['flutter.environment'], equals('test'));
        expect(properties['flutter.obfuscate'], equals('false'));
        expect(properties['flutter.shrinkResources'], equals('false'));
      });

      test('should generate correct environment variables', () {
        final envVars = buildConfigManager.generateEnvironmentVariables();

        expect(envVars['FLUTTER_APP_NAME'], equals('Test App'));
        expect(envVars['FLUTTER_BUNDLE_ID'], equals('com.test.app'));
        expect(envVars['FLUTTER_VERSION_NAME'], equals('1.0.0'));
        expect(envVars['FLUTTER_VERSION_CODE'], equals('1'));
        expect(envVars['FLUTTER_BUILD_VARIANT'], equals('debug'));
        expect(envVars['FLUTTER_BUILD_TYPE'], equals('debug'));
        expect(envVars['FLUTTER_FLAVOR'], equals('test'));
        expect(envVars['FLUTTER_ENVIRONMENT'], equals('test'));
        expect(envVars['FLUTTER_API_BASE_URL'], equals('https://api.test.com'));
        expect(envVars['FLUTTER_WEBSOCKET_URL'], equals('wss://ws.test.com'));
        expect(envVars['FLUTTER_NETWORK_TIMEOUT'], equals('30000'));
      });

      test('should generate correct Fastlane configuration', () {
        final config = buildConfigManager.generateFastlaneConfig();

        expect(config['app_identifier'], equals('com.test.app'));
        expect(config['app_name'], equals('Test App'));
        expect(config['version_name'], equals('1.0.0'));
        expect(config['version_code'], equals(1));
        expect(config['build_type'], equals('debug'));
        expect(config['flavor'], equals('test'));
        expect(config['environment'], equals('test'));

        final signing = config['signing'] as Map<String, dynamic>;
        expect(signing['store_file'], equals('test.keystore'));
        expect(signing['store_password_env'], equals('TEST_STORE_PASSWORD'));
        expect(signing['key_alias'], equals('test'));
        expect(signing['key_password_env'], equals('TEST_KEY_PASSWORD'));

        final distribution = config['distribution'] as Map<String, dynamic>;
        expect(distribution['platform'], equals('google_play'));
        expect(distribution['track'], equals('internal'));
      });
    });

    group('Configuration Validation', () {
      test('should validate correct configuration', () {
        final result = buildConfigManager.validateConfiguration();

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should detect invalid bundle ID', () {
        final invalidConfig = testConfig.copyWith(
          app: testConfig.app.copyWith(bundleId: 'invalid-bundle-id'),
        );
        final manager = BuildConfigManager(
          environmentConfig: invalidConfig,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        final result = manager.validateConfiguration();

        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('Invalid bundle ID format')));
      });

      test('should detect invalid version code', () {
        final invalidConfig = testConfig.copyWith(
          app: testConfig.app.copyWith(versionCode: 0),
        );
        final manager = BuildConfigManager(
          environmentConfig: invalidConfig,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        final result = manager.validateConfiguration();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Version code must be greater than 0'));
      });

      test('should detect empty version name', () {
        final invalidConfig = testConfig.copyWith(
          app: testConfig.app.copyWith(versionName: ''),
        );
        final manager = BuildConfigManager(
          environmentConfig: invalidConfig,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        final result = manager.validateConfiguration();

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Version name cannot be empty'));
      });

      test('should detect invalid API URL', () {
        final invalidConfig = testConfig.copyWith(
          network: testConfig.network.copyWith(apiBaseUrl: 'invalid-url'),
        );
        final manager = BuildConfigManager(
          environmentConfig: invalidConfig,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        final result = manager.validateConfiguration();

        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('Invalid API base URL')));
      });

      test('should detect invalid WebSocket URL', () {
        final invalidConfig = testConfig.copyWith(
          network: testConfig.network.copyWith(websocketUrl: 'invalid-ws-url'),
        );
        final manager = BuildConfigManager(
          environmentConfig: invalidConfig,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        final result = manager.validateConfiguration();

        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('Invalid WebSocket URL')));
      });

      test('should warn about missing signing config for release builds', () {
        final configWithoutSigning = testConfig.copyWith(signing: null);
        final releaseManager = BuildConfigManager(
          environmentConfig: configWithoutSigning,
          buildVariant: 'release',
          isDebugMode: false,
        );

        final result = releaseManager.validateConfiguration();

        expect(result.isValid, isTrue);
        expect(result.warnings, contains('No signing configuration found for release build'));
      });
    });

    group('Default Values', () {
      test('should use default values when configuration is missing', () {
        final minimalConfig = const EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'minimal',
            displayName: 'Minimal Environment',
          ),
          app: AppConfig(
            name: 'Minimal App',
            bundleId: 'com.minimal.app',
          ),
          network: NetworkConfig(
            apiBaseUrl: 'https://api.minimal.com',
          ),
        );

        final manager = BuildConfigManager(
          environmentConfig: minimalConfig,
        );

        expect(manager.versionName, equals('1.0.0'));
        expect(manager.versionCode, equals(1));
        expect(manager.buildType, equals(manager.buildVariant));
        expect(manager.flavor, equals('minimal'));
      });
    });

    group('Copy With', () {
      test('should create copy with updated configuration', () {
        final newConfig = testConfig.copyWith(
          app: testConfig.app.copyWith(name: 'Updated App'),
        );

        final newManager = buildConfigManager.copyWith(
          environmentConfig: newConfig,
          buildVariant: 'release',
          isDebugMode: false,
        );

        expect(newManager.applicationName, equals('Updated App'));
        expect(newManager.buildVariant, equals('release'));
        expect(newManager.isDebugBuild, isFalse);

        // Original should remain unchanged
        expect(buildConfigManager.applicationName, equals('Test App'));
        expect(buildConfigManager.buildVariant, equals('debug'));
        expect(buildConfigManager.isDebugBuild, isTrue);
      });
    });

    group('ToString', () {
      test('should provide meaningful string representation', () {
        final string = buildConfigManager.toString();

        expect(string, contains('BuildConfigManager'));
        expect(string, contains('environment: test'));
        expect(string, contains('buildVariant: debug'));
        expect(string, contains('applicationId: com.test.app'));
        expect(string, contains('applicationName: Test App'));
      });
    });
  });

  group('BuildConfigValidationResult', () {
    test('should correctly identify errors and warnings', () {
      const result = BuildConfigValidationResult(
        isValid: false,
        errors: ['Error 1', 'Error 2'],
        warnings: ['Warning 1'],
      );

      expect(result.hasErrors, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.errors.length, equals(2));
      expect(result.warnings.length, equals(1));
    });

    test('should provide meaningful string representation', () {
      const result = BuildConfigValidationResult(
        isValid: false,
        errors: ['Test error'],
        warnings: ['Test warning'],
      );

      final string = result.toString();

      expect(string, contains('BuildConfigValidationResult(isValid: false)'));
      expect(string, contains('Errors:'));
      expect(string, contains('Test error'));
      expect(string, contains('Warnings:'));
      expect(string, contains('Test warning'));
    });
  });
}