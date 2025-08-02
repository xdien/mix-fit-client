// Legacy AppConfig - kept for backward compatibility
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adapters/legacy_config_adapter.dart';

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

// Export adapters and integration helpers
export 'adapters/legacy_config_adapter.dart';
export 'integration/config_integration_helper.dart';

class AppConfig {
  static final AppConfig instance = AppConfig._internal();
  factory AppConfig() => instance;
  AppConfig._internal();

  Map<String, dynamic> _config = {};
  final LegacyConfigAdapter _adapter = LegacyConfigAdapter();
  bool _isLoaded = false;

  String? _endpoint;
  String? _apiKey;
  bool? _debugMode;

  String get endpoint => _endpoint ?? _adapter.endpoint;
  String get apiKey => _apiKey ?? _adapter.apiKey;
  bool get debugMode => _debugMode ?? _adapter.debugMode;

  Future<void> load(String env) async {
    if (_isLoaded) {
      debugPrint('Config already loaded, skipping...');
      return;
    }

    try {
      // Try to load from legacy JSON config first
      final configFile = 'assets/config/${env}_config.json';
      final configString = await rootBundle.loadString(configFile);
      
      // Parse JSON
      _config = json.decode(configString) as Map<String, dynamic>;

      _endpoint = _config['endpoint'] as String;
      _apiKey = _config['apiKey'] as String;
      _debugMode = _config['debugMode'] as bool;

      debugPrint('Loaded legacy config for $env environment');
      debugPrint('API Endpoint: $_endpoint');
    } catch (e) {
      // Fallback to environment configuration adapter
      debugPrint('Failed to load legacy config, using environment configuration: $e');
      
      _endpoint = _adapter.endpoint;
      _apiKey = _adapter.apiKey;
      _debugMode = _adapter.debugMode;
      
      // Create a mock config map for backward compatibility
      _config = {
        'endpoint': _endpoint,
        'apiKey': _apiKey,
        'debugMode': _debugMode,
        'environment': _adapter.environmentName,
        'appName': _adapter.appName,
        'bundleId': _adapter.bundleId,
        'timeout': _adapter.timeout,
      };

      debugPrint('Using environment config adapter for $env environment');
      debugPrint('API Endpoint: $_endpoint');
    }
    
    _isLoaded = true;
  }

  /// Get configuration value by key with fallback to adapter
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
