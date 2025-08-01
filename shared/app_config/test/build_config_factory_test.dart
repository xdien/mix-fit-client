import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/config/build_config_factory.dart';
import 'package:app_config/config/build_config_manager.dart';

void main() {
  group('BuildConfigFactory', () {
    late BuildConfigFactory factory;

    setUp(() {
      factory = BuildConfigFactory.instance;
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = BuildConfigFactory.instance;
        final instance2 = BuildConfigFactory.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Create from Environment Config', () {
      test('should create BuildConfigManager from environment config', () {
        const config = EnvironmentConfig(
          environment: EnvironmentInfo(
            name: 'test',
            displayName: 'Test Environment',
          ),
          app: AppConfig(
            name: 'Test App',
            bundleId: 'com.test.app',
          ),
          network: NetworkConfig(
            apiBaseUrl: 'https://api.test.com',
          ),
        );

        final manager = factory.createFromEnvironmentConfig(
          config,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        expect(manager.applicationId, equals('com.test.app'));
        expect(manager.applicationName, equals('Test App'));
        expect(manager.buildVariant, equals('debug'));
        expect(manager.isDebugBuild, isTrue);
      });
    });

    group('Create for Testing', () {
      test('should create BuildConfigManager for testing with defaults', () {
        final manager = factory.createForTesting();

        expect(manager.applicationId, equals('com.test.app'));
        expect(manager.applicationName, equals('Test App'));
        expect(manager.buildVariant, equals('debug'));
        expect(manager.isDebugBuild, isTrue);
        expect(manager.flavor, equals('test'));
      });

      test('should create BuildConfigManager for testing with custom values', () {
        final manager = factory.createForTesting(
          environmentName: 'custom_test',
          displayName: 'Custom Test Environment',
          appName: 'Custom Test App',
          bundleId: 'com.custom.test',
          apiBaseUrl: 'https://api.custom.test',
          websocketUrl: 'wss://ws.custom.test',
          buildVariant: 'release',
          isDebugMode: false,
        );

        expect(manager.applicationId, equals('com.custom.test'));
        expect(manager.applicationName, equals('Custom Test App'));
        expect(manager.displayName, equals('Custom Test Environment'));
        expect(manager.buildVariant, equals('release'));
        expect(manager.isDebugBuild, isFalse);
        expect(manager.flavor, equals('custom_test'));
      });
    });

    group('Create Custom', () {
      test('should create BuildConfigManager with custom configuration', () {
        final manager = factory.createCustom(
          environmentName: 'custom',
          displayName: 'Custom Environment',
          appName: 'Custom App',
          bundleId: 'com.custom.app',
          apiBaseUrl: 'https://api.custom.com',
          websocketUrl: 'wss://ws.custom.com',
          versionName: '2.0.0',
          versionCode: 20,
          buildVariant: 'release',
          isDebugMode: false,
        );

        expect(manager.applicationId, equals('com.custom.app'));
        expect(manager.applicationName, equals('Custom App'));
        expect(manager.displayName, equals('Custom Environment'));
        expect(manager.versionName, equals('2.0.0'));
        expect(manager.versionCode, equals(20));
        expect(manager.buildVariant, equals('release'));
        expect(manager.isDebugBuild, isFalse);
        expect(manager.flavor, equals('custom'));
      });
    });

    group('Validation', () {
      test('should validate custom configuration', () {
        final manager = factory.createCustom(
          environmentName: 'test',
          displayName: 'Test Environment',
          appName: 'Test App',
          bundleId: 'com.test.app',
          apiBaseUrl: 'https://api.test.com',
        );

        final result = manager.validateConfiguration();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should detect validation errors in custom configuration', () {
        final manager = factory.createCustom(
          environmentName: 'test',
          displayName: 'Test Environment',
          appName: 'Test App',
          bundleId: 'invalid-bundle-id',
          apiBaseUrl: 'invalid-url',
        );

        final result = manager.validateConfiguration();
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
      });
    });

    group('Build Settings Generation', () {
      test('should generate correct build settings', () {
        final manager = factory.createForTesting(
          appName: 'Test Build App',
          bundleId: 'com.test.build',
          buildVariant: 'debug',
        );

        final settings = manager.getBuildSettings();

        expect(settings['applicationId'], equals('com.test.build'));
        expect(settings['applicationName'], equals('Test Build App'));
        expect(settings['buildVariant'], equals('debug'));
        expect(settings['isDebugBuild'], isTrue);
      });

      test('should generate correct Gradle properties', () {
        final manager = factory.createForTesting(
          appName: 'Gradle Test App',
          bundleId: 'com.gradle.test',
          buildVariant: 'release',
          isDebugMode: false,
        );

        final properties = manager.generateGradleProperties();

        expect(properties['flutter.applicationId'], equals('com.gradle.test'));
        expect(properties['flutter.applicationName'], equals('Gradle Test App'));
        expect(properties['flutter.buildType'], equals('release'));
        expect(properties['flutter.obfuscate'], equals('true'));
      });

      test('should generate correct environment variables', () {
        final manager = factory.createForTesting(
          appName: 'Env Test App',
          bundleId: 'com.env.test',
          apiBaseUrl: 'https://api.env.test',
          websocketUrl: 'wss://ws.env.test',
        );

        final envVars = manager.generateEnvironmentVariables();

        expect(envVars['FLUTTER_APP_NAME'], equals('Env Test App'));
        expect(envVars['FLUTTER_BUNDLE_ID'], equals('com.env.test'));
        expect(envVars['FLUTTER_API_BASE_URL'], equals('https://api.env.test'));
        expect(envVars['FLUTTER_WEBSOCKET_URL'], equals('wss://ws.env.test'));
      });

      test('should generate correct Fastlane configuration', () {
        final manager = factory.createForTesting(
          appName: 'Fastlane Test App',
          bundleId: 'com.fastlane.test',
          environmentName: 'fastlane_test',
        );

        final config = manager.generateFastlaneConfig();

        expect(config['app_identifier'], equals('com.fastlane.test'));
        expect(config['app_name'], equals('Fastlane Test App'));
        expect(config['environment'], equals('fastlane_test'));
      });
    });

    group('Different Build Variants', () {
      test('should handle debug build variant correctly', () {
        final manager = factory.createForTesting(
          buildVariant: 'debug',
          isDebugMode: true,
        );

        expect(manager.buildVariant, equals('debug'));
        expect(manager.isDebugBuild, isTrue);
        expect(manager.isReleaseBuild, isFalse);
        expect(manager.shouldObfuscate, isFalse);
        expect(manager.shouldShrinkResources, isFalse);
      });

      test('should handle release build variant correctly', () {
        final manager = factory.createForTesting(
          buildVariant: 'release',
          isDebugMode: false,
        );

        expect(manager.buildVariant, equals('release'));
        expect(manager.isDebugBuild, isFalse);
        expect(manager.isReleaseBuild, isTrue);
        expect(manager.shouldObfuscate, isTrue);
        expect(manager.shouldShrinkResources, isTrue);
      });
    });

    group('Copy With Functionality', () {
      test('should create copy with updated values', () {
        final originalManager = factory.createForTesting(
          appName: 'Original App',
          buildVariant: 'debug',
        );

        final copiedManager = originalManager.copyWith(
          buildVariant: 'release',
          isDebugMode: false,
        );

        expect(originalManager.applicationName, equals('Original App'));
        expect(originalManager.buildVariant, equals('debug'));
        expect(originalManager.isDebugBuild, isTrue);

        expect(copiedManager.applicationName, equals('Original App'));
        expect(copiedManager.buildVariant, equals('release'));
        expect(copiedManager.isDebugBuild, isFalse);
      });
    });

    group('String Representation', () {
      test('should provide meaningful toString output', () {
        final manager = factory.createForTesting(
          environmentName: 'string_test',
          appName: 'String Test App',
          bundleId: 'com.string.test',
          buildVariant: 'debug',
        );

        final string = manager.toString();

        expect(string, contains('BuildConfigManager'));
        expect(string, contains('environment: string_test'));
        expect(string, contains('buildVariant: debug'));
        expect(string, contains('applicationId: com.string.test'));
        expect(string, contains('applicationName: String Test App'));
      });
    });
  });
}