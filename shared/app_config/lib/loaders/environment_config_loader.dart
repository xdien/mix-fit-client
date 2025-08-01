import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/environment_config.dart';
import '../validation/config_validator.dart';

abstract class EnvironmentConfigLoader {
  Future<EnvironmentConfig> loadConfig(String environment);
  Future<bool> validateConfig(EnvironmentConfig config);
  EnvironmentConfig getDefaultConfig();
}

class YamlEnvironmentConfigLoader implements EnvironmentConfigLoader {
  final String configPath;

  YamlEnvironmentConfigLoader({this.configPath = 'assets/../../config/environments'});

  @override
  Future<EnvironmentConfig> loadConfig(String environment) async {
    try {
      final configFile = '$configPath/$environment.yaml';
      final configString = await rootBundle.loadString(configFile);
      
      // Parse YAML
      final yamlDoc = loadYaml(configString);
      final configMap = _yamlToMap(yamlDoc);
      
      // Validate against schema
      final validationResult = await ConfigValidator.validate(configMap);
      if (!validationResult.isValid) {
        throw ConfigValidationError(
          'configuration',
          configMap,
          'Configuration validation failed:\n${validationResult.errorMessage}',
        );
      }

      // Create EnvironmentConfig from validated data
      final config = EnvironmentConfig.fromJson(configMap);
      
      // Additional business logic validation
      final businessValidation = await ConfigValidator.validateEnvironmentConfig(config);
      if (!businessValidation.isValid) {
        throw ConfigValidationError(
          'configuration',
          config,
          'Business validation failed:\n${businessValidation.errorMessage}',
        );
      }

      return config;
    } catch (e) {
      if (e is ConfigValidationError) {
        rethrow;
      }
      
      // If config file doesn't exist, return default config with warning
      if (e.toString().contains('Unable to load asset')) {
        print('Warning: Configuration file not found for environment: $environment');
        print('Using default configuration');
        return getDefaultConfig();
      }
      
      throw ConfigValidationError(
        'loading',
        environment,
        'Failed to load configuration for environment $environment: $e',
      );
    }
  }

  @override
  Future<bool> validateConfig(EnvironmentConfig config) async {
    try {
      final businessValidation = await ConfigValidator.validateEnvironmentConfig(config);
      if (!businessValidation.isValid) {
        print('Business validation failed: ${businessValidation.errorMessage}');
        return false;
      }

      return true;
    } catch (e) {
      print('Validation error: $e');
      return false;
    }
  }

  @override
  EnvironmentConfig getDefaultConfig() {
    return const EnvironmentConfig(
      environment: EnvironmentInfo(
        name: 'development',
        displayName: 'CMS Development (Default)',
      ),
      app: AppConfig(
        name: 'CMS Business',
        bundleId: 'com.placeholder.module.default',
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

  dynamic _yamlToMap(dynamic yamlDoc) {
    if (yamlDoc is YamlMap) {
      final map = <String, dynamic>{};
      for (final entry in yamlDoc.entries) {
        map[entry.key.toString()] = _yamlToMap(entry.value);
      }
      return map;
    } else if (yamlDoc is YamlList) {
      return yamlDoc.map((item) => _yamlToMap(item)).toList();
    } else {
      return yamlDoc;
    }
  }
}