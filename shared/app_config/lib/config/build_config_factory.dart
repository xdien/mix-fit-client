import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/environment_config.dart';
import '../services/environment_config_service.dart';
import 'build_config_manager.dart';

/// Factory for creating BuildConfigManager instances
class BuildConfigFactory {
  static BuildConfigFactory? _instance;
  
  BuildConfigFactory._();
  
  static BuildConfigFactory get instance {
    _instance ??= BuildConfigFactory._();
    return _instance!;
  }

  /// Creates a BuildConfigManager from environment configuration
  BuildConfigManager createFromEnvironmentConfig(
    EnvironmentConfig environmentConfig, {
    String? buildVariant,
    bool? isDebugMode,
  }) {
    return BuildConfigManager(
      environmentConfig: environmentConfig,
      buildVariant: buildVariant,
      isDebugMode: isDebugMode,
    );
  }

  /// Creates a BuildConfigManager from environment name
  Future<BuildConfigManager> createFromEnvironment(
    String environmentName, {
    String? buildVariant,
    bool? isDebugMode,
  }) async {
    final configService = EnvironmentConfigService();
    await configService.initialize(environmentName);
    
    return BuildConfigManager(
      environmentConfig: configService.config,
      buildVariant: buildVariant,
      isDebugMode: isDebugMode,
    );
  }

  /// Creates a BuildConfigManager with current environment settings
  Future<BuildConfigManager> createCurrent({
    String? buildVariant,
    bool? isDebugMode,
  }) async {
    final environment = _getCurrentEnvironment();
    return createFromEnvironment(
      environment,
      buildVariant: buildVariant,
      isDebugMode: isDebugMode,
    );
  }

  /// Creates a BuildConfigManager for development environment
  Future<BuildConfigManager> createDevelopment({
    String? buildVariant,
    bool? isDebugMode,
  }) async {
    return createFromEnvironment(
      'development',
      buildVariant: buildVariant ?? 'debug',
      isDebugMode: isDebugMode ?? true,
    );
  }

  /// Creates a BuildConfigManager for staging environment
  Future<BuildConfigManager> createStaging({
    String? buildVariant,
    bool? isDebugMode,
  }) async {
    return createFromEnvironment(
      'staging',
      buildVariant: buildVariant ?? 'release',
      isDebugMode: isDebugMode ?? false,
    );
  }

  /// Creates a BuildConfigManager for production environment
  Future<BuildConfigManager> createProduction({
    String? buildVariant,
    bool? isDebugMode,
  }) async {
    return createFromEnvironment(
      'production',
      buildVariant: buildVariant ?? 'release',
      isDebugMode: isDebugMode ?? false,
    );
  }

  /// Creates multiple BuildConfigManager instances for different environments
  Future<Map<String, BuildConfigManager>> createForAllEnvironments({
    String? buildVariant,
    bool? isDebugMode,
  }) async {
    final environments = ['development', 'staging', 'production'];
    final managers = <String, BuildConfigManager>{};

    for (final env in environments) {
      try {
        managers[env] = await createFromEnvironment(
          env,
          buildVariant: buildVariant,
          isDebugMode: isDebugMode,
        );
      } catch (e) {
        // Skip environments that don't have configuration files
        debugPrint('Skipping environment $env: $e');
      }
    }

    return managers;
  }

  /// Creates a BuildConfigManager with custom configuration
  BuildConfigManager createCustom({
    required String environmentName,
    required String displayName,
    required String appName,
    required String bundleId,
    required String apiBaseUrl,
    String? websocketUrl,
    String? versionName,
    int? versionCode,
    String? buildVariant,
    bool? isDebugMode,
  }) {
    final config = EnvironmentConfig(
      environment: EnvironmentInfo(
        name: environmentName,
        displayName: displayName,
      ),
      app: AppConfig(
        name: appName,
        bundleId: bundleId,
        versionName: versionName,
        versionCode: versionCode,
      ),
      network: NetworkConfig(
        apiBaseUrl: apiBaseUrl,
        websocketUrl: websocketUrl,
      ),
    );

    return BuildConfigManager(
      environmentConfig: config,
      buildVariant: buildVariant,
      isDebugMode: isDebugMode,
    );
  }

  /// Gets the current environment from various sources
  String _getCurrentEnvironment() {
    // Check environment variable first
    final envVar = Platform.environment['FLUTTER_ENVIRONMENT'];
    if (envVar != null && envVar.isNotEmpty) {
      return envVar;
    }

    // Check compile-time environment
    const compileTimeEnv = String.fromEnvironment('ENVIRONMENT');
    if (compileTimeEnv.isNotEmpty) {
      return compileTimeEnv;
    }

    // Default based on build mode
    return kDebugMode ? 'development' : 'production';
  }

  /// Validates that all required environments have valid configurations
  Future<Map<String, BuildConfigValidationResult>> validateAllEnvironments() async {
    final managers = await createForAllEnvironments();
    final results = <String, BuildConfigValidationResult>{};

    for (final entry in managers.entries) {
      results[entry.key] = entry.value.validateConfiguration();
    }

    return results;
  }

  /// Creates a BuildConfigManager for testing purposes
  BuildConfigManager createForTesting({
    String environmentName = 'test',
    String displayName = 'Test Environment',
    String appName = 'Test App',
    String bundleId = 'com.test.app',
    String apiBaseUrl = 'https://api.test.com',
    String? websocketUrl,
    String buildVariant = 'debug',
    bool isDebugMode = true,
  }) {
    return createCustom(
      environmentName: environmentName,
      displayName: displayName,
      appName: appName,
      bundleId: bundleId,
      apiBaseUrl: apiBaseUrl,
      websocketUrl: websocketUrl,
      buildVariant: buildVariant,
      isDebugMode: isDebugMode,
    );
  }
}