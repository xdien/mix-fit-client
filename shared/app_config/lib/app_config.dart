// AppConfig - Updated to use new environment configuration system
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'utils/environment_variables.dart';

// Export new environment configuration system
export 'models/environment_config.dart';
export 'loaders/environment_config_loader.dart';
export 'services/environment_config_service.dart';
export 'validation/config_validator.dart';
export 'examples/usage_example.dart';
export 'examples/integration_example.dart';
export 'configured_app.dart';

// Export build configuration management
export 'config/build_config_manager.dart';
export 'config/build_config_factory.dart';
export 'config/build_config_generator.dart';
export 'examples/build_config_usage_example.dart';
export 'examples/flutter_integration_example.dart';

// Export integration helpers
export 'integration/config_integration_helper.dart';

// Export environment variables
export 'utils/environment_variables.dart';

class AppConfig {
  static final AppConfig instance = AppConfig._internal();
  factory AppConfig() => instance;
  AppConfig._internal();

  Map<String, dynamic> _config = {};
  bool _isLoaded = false;

  String? _endpoint;
  String? _apiKey;
  bool? _debugMode;

  String get endpoint => _endpoint ?? EnvironmentVariables.apiEndpoint;
  String get apiKey => _apiKey ?? EnvironmentVariables.apiKey;
  bool get debugMode => _debugMode ?? kDebugMode;

  Future<void> load(String env) async {
    if (_isLoaded) {
      debugPrint('Config already loaded, skipping...');
      return;
    }

    try {
      debugPrint('Loading configuration using environment configuration system for $env environment');
      
      // Use environment variables or defaults
      _endpoint = EnvironmentVariables.apiEndpoint;
      _apiKey = EnvironmentVariables.apiKey;
      _debugMode = kDebugMode;
      
      // Create config map from environment configuration
      _config = {
        'endpoint': _endpoint,
        'apiKey': _apiKey,
        'debugMode': _debugMode,
        'environment': env,
        'appName': EnvironmentVariables.appName,
        'bundleId': EnvironmentVariables.bundleId,
        'timeout': EnvironmentVariables.networkTimeout,
        'websocketUrl': EnvironmentVariables.websocketUrl,
      };

      debugPrint('Using environment config for $env environment');
      debugPrint('API Endpoint: $_endpoint');
    } catch (e) {
      debugPrint('Failed to load configuration: $e');
      debugPrint('Using fallback configuration');
      
      // Fallback configuration
      _config = {
        'endpoint': EnvironmentVariables.apiEndpoint,
        'apiKey': EnvironmentVariables.apiKey,
        'debugMode': kDebugMode,
        'environment': env,
        'appName': EnvironmentVariables.appName,
        'bundleId': EnvironmentVariables.bundleId,
        'timeout': EnvironmentVariables.networkTimeout,
        'websocketUrl': EnvironmentVariables.websocketUrl,
      };
      
      _endpoint = _config['endpoint'];
      _apiKey = _config['apiKey'];
      _debugMode = _config['debugMode'];
    }
    
    _isLoaded = true;
  }

  /// Get configuration value by key with fallback
  T getValue<T>(String key, T defaultValue) {
    try {
      return _config[key] as T? ?? defaultValue;
    } catch (e) {
      debugPrint('Failed to get config value for key $key: $e');
      return defaultValue;
    }
  }

  /// Get all configuration as map
  Map<String, dynamic> get config => Map.from(_config);

  /// Check if configuration is loaded
  bool get isLoaded => _isLoaded;

  /// Reset configuration (for testing)
  void reset() {
    _config = {};
    _endpoint = null;
    _apiKey = null;
    _debugMode = null;
    _isLoaded = false;
  }
}
