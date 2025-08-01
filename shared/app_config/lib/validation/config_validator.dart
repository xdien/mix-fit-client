import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:json_schema/json_schema.dart';
import '../models/environment_config.dart';

class ConfigValidationError extends Error {
  final String field;
  final dynamic value;
  final String message;

  ConfigValidationError(this.field, this.value, this.message);

  @override
  String toString() => 'Configuration error in $field: $message';
}

class ConfigValidator {
  static JsonSchema? _schema;

  static Future<void> _loadSchema() async {
    if (_schema != null) return;

    try {
      final schemaString = await rootBundle.loadString(
        'assets/config/schema/environment_config_schema.json',
      );
      final schemaJson = json.decode(schemaString);
      _schema = JsonSchema.create(schemaJson);
    } catch (e) {
      throw ConfigValidationError(
        'schema',
        null,
        'Failed to load validation schema: $e',
      );
    }
  }

  static Future<ValidationResult> validate(Map<String, dynamic> config) async {
    await _loadSchema();

    final validationResult = _schema!.validate(config);
    
    if (validationResult.isValid) {
      return ValidationResult.success();
    }

    final errors = validationResult.errors.map((error) {
      return ConfigValidationError(
        error.instancePath,
        null, // ValidationError doesn't expose instance data
        error.message,
      );
    }).toList();

    return ValidationResult.failure(errors);
  }

  static ValidationResult validateBundleId(String bundleId) {
    final bundleIdRegex = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$');
    
    if (!bundleIdRegex.hasMatch(bundleId)) {
      return ValidationResult.failure([
        ConfigValidationError(
          'app.bundle_id',
          bundleId,
          'Invalid bundle ID format. Must follow reverse domain notation (e.g., com.example.app)',
        ),
      ]);
    }

    return ValidationResult.success();
  }

  static ValidationResult validateUrl(String url, String fieldName) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return ValidationResult.failure([
          ConfigValidationError(
            fieldName,
            url,
            'Invalid URL format. Must include scheme and authority',
          ),
        ]);
      }
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure([
        ConfigValidationError(
          fieldName,
          url,
          'Invalid URL format: $e',
        ),
      ]);
    }
  }

  static Future<ValidationResult> validateEnvironmentConfig(EnvironmentConfig config) async {
    // First validate using JSON schema
    final configJson = config.toJson();
    final schemaResult = await validate(configJson);
    
    if (!schemaResult.isValid) {
      return schemaResult;
    }

    // Then do additional business logic validation
    final errors = <ConfigValidationError>[];

    // Validate bundle ID
    final bundleIdResult = validateBundleId(config.app.bundleId);
    if (!bundleIdResult.isValid) {
      errors.addAll(bundleIdResult.errors);
    }

    // Validate API URL
    final apiUrlResult = validateUrl(config.network.apiBaseUrl, 'network.api_base_url');
    if (!apiUrlResult.isValid) {
      errors.addAll(apiUrlResult.errors);
    }

    // Validate WebSocket URL if provided
    if (config.network.websocketUrl != null) {
      final wsUrlResult = validateUrl(config.network.websocketUrl!, 'network.websocket_url');
      if (!wsUrlResult.isValid) {
        errors.addAll(wsUrlResult.errors);
      }
    }

    // Validate timeout
    if (config.network.timeout < 1000) {
      errors.add(ConfigValidationError(
        'network.timeout',
        config.network.timeout,
        'Timeout must be at least 1000ms',
      ));
    }

    // Validate environment name
    const validEnvironments = ['development', 'staging', 'production'];
    if (!validEnvironments.contains(config.environment.name)) {
      errors.add(ConfigValidationError(
        'environment.name',
        config.environment.name,
        'Environment name must be one of: ${validEnvironments.join(', ')}',
      ));
    }

    // Validate build type if provided
    if (config.build?.buildType != null) {
      const validBuildTypes = ['debug', 'release'];
      if (!validBuildTypes.contains(config.build!.buildType)) {
        errors.add(ConfigValidationError(
          'build.build_type',
          config.build!.buildType,
          'Build type must be one of: ${validBuildTypes.join(', ')}',
        ));
      }
    }

    return errors.isEmpty 
        ? ValidationResult.success() 
        : ValidationResult.failure(errors);
  }
}

class ValidationResult {
  final bool isValid;
  final List<ConfigValidationError> errors;

  ValidationResult._(this.isValid, this.errors);

  factory ValidationResult.success() => ValidationResult._(true, []);
  factory ValidationResult.failure(List<ConfigValidationError> errors) => 
      ValidationResult._(false, errors);

  String get errorMessage => errors.map((e) => e.toString()).join('\n');
}