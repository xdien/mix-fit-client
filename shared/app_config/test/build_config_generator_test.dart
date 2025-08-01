import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/config/build_config_manager.dart';
import 'package:app_config/config/build_config_generator.dart';
import 'package:path/path.dart' as path;

void main() {
  group('BuildConfigGenerator', () {
    late EnvironmentConfig testConfig;
    late BuildConfigManager buildConfigManager;
    late BuildConfigGenerator generator;

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
      );

      buildConfigManager = BuildConfigManager(
        environmentConfig: testConfig,
        buildVariant: 'debug',
        isDebugMode: true,
      );

      generator = BuildConfigGenerator(buildConfigManager);
    });

    group('Gradle Properties Generation', () {
      test('should generate correct gradle.properties content', () {
        final content = generator.generateGradleProperties();

        expect(content, contains('# Generated build configuration'));
        expect(content, contains('# Environment: test'));
        expect(content, contains('# Build variant: debug'));
        expect(content, contains('flutter.applicationId=com.test.app'));
        expect(content, contains('flutter.applicationName=Test App'));
        expect(content, contains('flutter.versionName=1.0.0'));
        expect(content, contains('flutter.versionCode=1'));
        expect(content, contains('flutter.buildType=debug'));
        expect(content, contains('flutter.flavor=test'));
        expect(content, contains('flutter.environment=test'));
        expect(content, contains('flutter.obfuscate=false'));
        expect(content, contains('flutter.shrinkResources=false'));
      });
    });

    group('Android Build Gradle Generation', () {
      test('should generate correct build.gradle snippet', () {
        final content = generator.generateAndroidBuildGradle();

        expect(content, contains('android {'));
        expect(content, contains('defaultConfig {'));
        expect(content, contains('applicationId "com.test.app"'));
        expect(content, contains('versionCode 1'));
        expect(content, contains('versionName "1.0.0"'));
        expect(content, contains('buildTypes {'));
        expect(content, contains('debug {'));
        expect(content, contains('minifyEnabled false'));
        expect(content, contains('shrinkResources false'));
      });

      test('should include flavor configuration when different from build type', () {
        final customConfig = testConfig.copyWith(
          build: testConfig.build?.copyWith(flavor: 'custom'),
        );
        final customManager = BuildConfigManager(
          environmentConfig: customConfig,
          buildVariant: 'debug',
          isDebugMode: true,
        );
        final customGenerator = BuildConfigGenerator(customManager);

        final content = customGenerator.generateAndroidBuildGradle();

        expect(content, contains('flavorDimensions "environment"'));
        expect(content, contains('productFlavors {'));
        expect(content, contains('custom {'));
        expect(content, contains('dimension "environment"'));
        expect(content, contains('applicationIdSuffix ".custom"'));
        expect(content, contains('versionNameSuffix "-custom"'));
      });
    });

    group('iOS Info.plist Generation', () {
      test('should generate correct Info.plist configuration', () {
        final config = generator.generateIOSInfoPlist();

        expect(config['CFBundleIdentifier'], equals('com.test.app'));
        expect(config['CFBundleName'], equals('Test App'));
        expect(config['CFBundleDisplayName'], equals('Test Environment'));
        expect(config['CFBundleShortVersionString'], equals('1.0.0'));
        expect(config['CFBundleVersion'], equals('1'));
      });
    });

    group('Fastlane Configuration Generation', () {
      test('should generate correct Fastlane configuration', () {
        final content = generator.generateFastlaneConfig();

        expect(content, contains('# Fastlane configuration'));
        expect(content, contains('# Environment: test'));
        expect(content, contains('FASTLANE_CONFIG = {'));
        expect(content, contains('app_identifier: "com.test.app"'));
        expect(content, contains('app_name: "Test App"'));
        expect(content, contains('version_name: "1.0.0"'));
        expect(content, contains('version_code: "1"'));
        expect(content, contains('build_type: "debug"'));
        expect(content, contains('flavor: "test"'));
        expect(content, contains('environment: "test"'));
        expect(content, contains('signing: {'));
        expect(content, contains('store_file: "test.keystore"'));
        expect(content, contains('distribution: {'));
        expect(content, contains('platform: "google_play"'));
      });
    });

    group('Environment Script Generation', () {
      test('should generate bash script correctly', () {
        final content = generator.generateEnvironmentScript(format: 'bash');

        expect(content, contains('#!/bin/bash'));
        expect(content, contains('# Environment variables for test'));
        expect(content, contains('export FLUTTER_APP_NAME="Test App"'));
        expect(content, contains('export FLUTTER_BUNDLE_ID="com.test.app"'));
        expect(content, contains('export FLUTTER_API_BASE_URL="https://api.test.com"'));
        expect(content, contains('export FLUTTER_WEBSOCKET_URL="wss://ws.test.com"'));
      });

      test('should generate PowerShell script correctly', () {
        final content = generator.generateEnvironmentScript(format: 'powershell');

        expect(content, contains('# Environment variables for test'));
        expect(content, contains(r'$env:FLUTTER_APP_NAME = "Test App"'));
        expect(content, contains(r'$env:FLUTTER_BUNDLE_ID = "com.test.app"'));
        expect(content, contains(r'$env:FLUTTER_API_BASE_URL = "https://api.test.com"'));
      });

      test('should generate batch script correctly', () {
        final content = generator.generateEnvironmentScript(format: 'batch');

        expect(content, contains('@echo off'));
        expect(content, contains('REM Environment variables for test'));
        expect(content, contains('set FLUTTER_APP_NAME=Test App'));
        expect(content, contains('set FLUTTER_BUNDLE_ID=com.test.app'));
        expect(content, contains('set FLUTTER_API_BASE_URL=https://api.test.com'));
      });

      test('should throw error for unsupported script format', () {
        expect(
          () => generator.generateEnvironmentScript(format: 'unsupported'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('JSON Configuration Generation', () {
      test('should generate correct JSON configuration', () {
        final content = generator.generateJsonConfig();
        final config = json.decode(content) as Map<String, dynamic>;

        expect(config['build_info'], isA<Map<String, dynamic>>());
        expect(config['environment_variables'], isA<Map<String, dynamic>>());
        expect(config['generated_at'], isA<String>());

        final buildInfo = config['build_info'] as Map<String, dynamic>;
        expect(buildInfo['applicationId'], equals('com.test.app'));
        expect(buildInfo['applicationName'], equals('Test App'));

        final envVars = config['environment_variables'] as Map<String, dynamic>;
        expect(envVars['FLUTTER_APP_NAME'], equals('Test App'));
        expect(envVars['FLUTTER_BUNDLE_ID'], equals('com.test.app'));
      });
    });

    group('YAML Configuration Generation', () {
      test('should generate correct YAML configuration', () {
        final content = generator.generateYamlConfig();

        expect(content, contains('# Build configuration for test'));
        expect(content, contains('build_info:'));
        expect(content, contains('  applicationId: com.test.app'));
        expect(content, contains('  applicationName: Test App'));
        expect(content, contains('environment_variables:'));
        expect(content, contains('  FLUTTER_APP_NAME: Test App'));
        expect(content, contains('  FLUTTER_BUNDLE_ID: com.test.app'));
      });
    });

    group('File Writing', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('build_config_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should write all configuration files correctly', () async {
        await generator.writeConfigurationFiles(tempDir.path);

        // Check that all expected files are created
        final expectedFiles = [
          'gradle.properties',
          'build.gradle.snippet',
          'Info.plist.json',
          'fastlane_config.rb',
          'env_vars.sh',
          'env_vars.ps1',
          'env_vars.bat',
          'build_config.json',
          'build_config.yaml',
        ];

        for (final fileName in expectedFiles) {
          final file = File(path.join(tempDir.path, fileName));
          expect(await file.exists(), isTrue, reason: 'File $fileName should exist');
          expect(await file.length(), greaterThan(0), reason: 'File $fileName should not be empty');
        }
      });

      test('should create output directory if it does not exist', () async {
        final nonExistentDir = path.join(tempDir.path, 'nested', 'directory');
        
        await generator.writeConfigurationFiles(nonExistentDir);

        final dir = Directory(nonExistentDir);
        expect(await dir.exists(), isTrue);

        final gradleFile = File(path.join(nonExistentDir, 'gradle.properties'));
        expect(await gradleFile.exists(), isTrue);
      });

      test('should write gradle.properties with correct content', () async {
        await generator.writeConfigurationFiles(tempDir.path);

        final file = File(path.join(tempDir.path, 'gradle.properties'));
        final content = await file.readAsString();

        expect(content, contains('flutter.applicationId=com.test.app'));
        expect(content, contains('flutter.applicationName=Test App'));
      });

      test('should write Info.plist.json with correct content', () async {
        await generator.writeConfigurationFiles(tempDir.path);

        final file = File(path.join(tempDir.path, 'Info.plist.json'));
        final content = await file.readAsString();
        final config = json.decode(content) as Map<String, dynamic>;

        expect(config['CFBundleIdentifier'], equals('com.test.app'));
        expect(config['CFBundleName'], equals('Test App'));
      });

      test('should write build_config.json with correct content', () async {
        await generator.writeConfigurationFiles(tempDir.path);

        final file = File(path.join(tempDir.path, 'build_config.json'));
        final content = await file.readAsString();
        final config = json.decode(content) as Map<String, dynamic>;

        expect(config['build_info'], isA<Map<String, dynamic>>());
        expect(config['environment_variables'], isA<Map<String, dynamic>>());
      });
    });

    group('Edge Cases', () {
      test('should handle configuration without optional fields', () {
        const minimalConfig = EnvironmentConfig(
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

        final minimalManager = BuildConfigManager(
          environmentConfig: minimalConfig,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        final minimalGenerator = BuildConfigGenerator(minimalManager);

        expect(() => minimalGenerator.generateGradleProperties(), returnsNormally);
        expect(() => minimalGenerator.generateAndroidBuildGradle(), returnsNormally);
        expect(() => minimalGenerator.generateFastlaneConfig(), returnsNormally);
        expect(() => minimalGenerator.generateJsonConfig(), returnsNormally);
      });

      test('should handle configuration without WebSocket URL', () {
        final configWithoutWs = testConfig.copyWith(
          network: testConfig.network.copyWith(websocketUrl: null),
        );

        final manager = BuildConfigManager(
          environmentConfig: configWithoutWs,
          buildVariant: 'debug',
          isDebugMode: true,
        );

        final generatorWithoutWs = BuildConfigGenerator(manager);
        final envVars = manager.generateEnvironmentVariables();

        expect(envVars.containsKey('FLUTTER_WEBSOCKET_URL'), isFalse);

        final content = generatorWithoutWs.generateEnvironmentScript();
        expect(content, isNot(contains('FLUTTER_WEBSOCKET_URL')));
      });
    });
  });
}