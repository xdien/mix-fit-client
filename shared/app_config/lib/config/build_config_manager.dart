import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/environment_config.dart';

/// Manages build configuration for different environments and build variants
class BuildConfigManager {
  final EnvironmentConfig _environmentConfig;
  final String _buildVariant;
  final bool _isDebugMode;

  BuildConfigManager({
    required EnvironmentConfig environmentConfig,
    String? buildVariant,
    bool? isDebugMode,
  })  : _environmentConfig = environmentConfig,
        _buildVariant = buildVariant ?? _determineBuildVariant(),
        _isDebugMode = isDebugMode ?? kDebugMode;

  /// Determines the build variant based on the current build mode
  static String _determineBuildVariant() {
    return kDebugMode ? 'debug' : 'release';
  }

  /// Gets the application ID/bundle ID for the current environment
  String get applicationId => _environmentConfig.app.bundleId;

  /// Gets the application name for the current environment
  String get applicationName => _environmentConfig.app.name;

  /// Gets the display name for the current environment
  String get displayName => _environmentConfig.environment.displayName;

  /// Gets the current build variant (debug/release)
  String get buildVariant => _buildVariant;

  /// Gets the build type from configuration or defaults to build variant
  String get buildType => _environmentConfig.build?.buildType ?? _buildVariant;

  /// Gets the flavor from configuration or defaults to environment name
  String get flavor => _environmentConfig.build?.flavor ?? _environmentConfig.environment.name;

  /// Checks if this is a debug build
  bool get isDebugBuild => _isDebugMode || _buildVariant == 'debug';

  /// Checks if this is a release build
  bool get isReleaseBuild => !isDebugBuild;

  /// Gets the version name from configuration
  String get versionName => _environmentConfig.app.versionName ?? '1.0.0';

  /// Gets the version code from configuration
  int get versionCode => _environmentConfig.app.versionCode ?? 1;

  /// Checks if code obfuscation should be enabled
  bool get shouldObfuscate => _environmentConfig.build?.obfuscate ?? isReleaseBuild;

  /// Checks if resource shrinking should be enabled
  bool get shouldShrinkResources => _environmentConfig.build?.shrinkResources ?? isReleaseBuild;

  /// Gets environment-specific build settings as a map
  Map<String, dynamic> getBuildSettings() {
    return {
      'applicationId': applicationId,
      'applicationName': applicationName,
      'displayName': displayName,
      'buildVariant': buildVariant,
      'buildType': buildType,
      'flavor': flavor,
      'versionName': versionName,
      'versionCode': versionCode,
      'isDebugBuild': isDebugBuild,
      'isReleaseBuild': isReleaseBuild,
      'shouldObfuscate': shouldObfuscate,
      'shouldShrinkResources': shouldShrinkResources,
      'environment': _environmentConfig.environment.name,
    };
  }

  /// Generates Gradle properties for Android builds
  Map<String, String> generateGradleProperties() {
    return {
      'flutter.applicationId': applicationId,
      'flutter.applicationName': applicationName,
      'flutter.versionName': versionName,
      'flutter.versionCode': versionCode.toString(),
      'flutter.buildType': buildType,
      'flutter.flavor': flavor,
      'flutter.environment': _environmentConfig.environment.name,
      'flutter.obfuscate': shouldObfuscate.toString(),
      'flutter.shrinkResources': shouldShrinkResources.toString(),
    };
  }

  /// Generates environment variables for build processes
  Map<String, String> generateEnvironmentVariables() {
    return {
      'FLUTTER_APP_NAME': applicationName,
      'FLUTTER_BUNDLE_ID': applicationId,
      'FLUTTER_VERSION_NAME': versionName,
      'FLUTTER_VERSION_CODE': versionCode.toString(),
      'FLUTTER_BUILD_VARIANT': buildVariant,
      'FLUTTER_BUILD_TYPE': buildType,
      'FLUTTER_FLAVOR': flavor,
      'FLUTTER_ENVIRONMENT': _environmentConfig.environment.name,
      'FLUTTER_API_BASE_URL': _environmentConfig.network.apiBaseUrl,
      if (_environmentConfig.network.websocketUrl != null)
        'FLUTTER_WEBSOCKET_URL': _environmentConfig.network.websocketUrl!,
      'FLUTTER_NETWORK_TIMEOUT': _environmentConfig.network.timeout.toString(),
    };
  }

  /// Generates build configuration for Fastlane
  Map<String, dynamic> generateFastlaneConfig() {
    final config = <String, dynamic>{
      'app_identifier': applicationId,
      'app_name': applicationName,
      'version_name': versionName,
      'version_code': versionCode,
      'build_type': buildType,
      'flavor': flavor,
      'environment': _environmentConfig.environment.name,
    };

    // Add signing configuration if available
    if (_environmentConfig.signing != null) {
      final signing = _environmentConfig.signing!;
      config['signing'] = {
        if (signing.storeFile != null) 'store_file': signing.storeFile,
        if (signing.storePasswordEnv != null) 'store_password_env': signing.storePasswordEnv,
        if (signing.keyAlias != null) 'key_alias': signing.keyAlias,
        if (signing.keyPasswordEnv != null) 'key_password_env': signing.keyPasswordEnv,
      };
    }

    // Add distribution configuration if available
    if (_environmentConfig.distribution != null) {
      final distribution = _environmentConfig.distribution!;
      config['distribution'] = {
        if (distribution.platform != null) 'platform': distribution.platform,
        if (distribution.track != null) 'track': distribution.track,
      };
    }

    return config;
  }

  /// Validates the build configuration
  BuildConfigValidationResult validateConfiguration() {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate application ID format
    if (!_isValidBundleId(applicationId)) {
      errors.add('Invalid bundle ID format: $applicationId');
    }

    // Validate version information
    if (versionCode <= 0) {
      errors.add('Version code must be greater than 0');
    }

    if (versionName.isEmpty) {
      errors.add('Version name cannot be empty');
    }

    // Validate signing configuration for release builds
    if (isReleaseBuild && _environmentConfig.signing == null) {
      warnings.add('No signing configuration found for release build');
    }

    // Validate network configuration
    if (!_isValidUrl(_environmentConfig.network.apiBaseUrl)) {
      errors.add('Invalid API base URL: ${_environmentConfig.network.apiBaseUrl}');
    }

    if (_environmentConfig.network.websocketUrl != null &&
        !_isValidUrl(_environmentConfig.network.websocketUrl!)) {
      errors.add('Invalid WebSocket URL: ${_environmentConfig.network.websocketUrl}');
    }

    return BuildConfigValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates bundle ID format
  bool _isValidBundleId(String bundleId) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$');
    return regex.hasMatch(bundleId);
  }

  /// Validates URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Creates a copy of this manager with updated configuration
  BuildConfigManager copyWith({
    EnvironmentConfig? environmentConfig,
    String? buildVariant,
    bool? isDebugMode,
  }) {
    return BuildConfigManager(
      environmentConfig: environmentConfig ?? _environmentConfig,
      buildVariant: buildVariant ?? _buildVariant,
      isDebugMode: isDebugMode ?? _isDebugMode,
    );
  }

  @override
  String toString() {
    return 'BuildConfigManager('
        'environment: ${_environmentConfig.environment.name}, '
        'buildVariant: $_buildVariant, '
        'applicationId: $applicationId, '
        'applicationName: $applicationName'
        ')';
  }
}

/// Result of build configuration validation
class BuildConfigValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const BuildConfigValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('BuildConfigValidationResult(isValid: $isValid)');
    
    if (hasErrors) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    
    if (hasWarnings) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    return buffer.toString();
  }
}