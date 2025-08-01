import 'package:flutter/foundation.dart';
import '../models/environment_config.dart';
import '../loaders/environment_config_loader.dart';

class EnvironmentConfigService {
  static final EnvironmentConfigService _instance = EnvironmentConfigService._internal();
  factory EnvironmentConfigService() => _instance;
  EnvironmentConfigService._internal();

  EnvironmentConfig? _config;
  final EnvironmentConfigLoader _loader = YamlEnvironmentConfigLoader();

  /// Initialize the configuration service with the specified environment
  Future<void> initialize([String? environment]) async {
    final env = environment ?? 
                const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    try {
      _config = await _loader.loadConfig(env);
      debugPrint('Environment configuration loaded successfully for: $env');
      debugPrint('API Base URL: ${_config!.network.apiBaseUrl}');
      debugPrint('App Name: ${_config!.app.name}');
    } catch (e) {
      debugPrint('Failed to load environment configuration: $e');
      debugPrint('Using default configuration');
      _config = _loader.getDefaultConfig();
    }
  }

  /// Get the current configuration
  EnvironmentConfig get config {
    if (_config == null) {
      throw StateError(
        'EnvironmentConfigService not initialized. Call initialize() first.',
      );
    }
    return _config!;
  }

  /// Check if the service is initialized
  bool get isInitialized => _config != null;

  /// Get API base URL
  String get apiBaseUrl => config.network.apiBaseUrl;

  /// Get WebSocket URL
  String? get websocketUrl => config.network.websocketUrl;

  /// Get app name
  String get appName => config.app.name;

  /// Get bundle ID
  String get bundleId => config.app.bundleId;

  /// Get environment name
  String get environmentName => config.environment.name;

  /// Get environment display name
  String get environmentDisplayName => config.environment.displayName;

  /// Get network timeout
  int get timeout => config.network.timeout;

  /// Check if debug mode is enabled (based on environment)
  bool get isDebugMode => config.environment.name == 'development';

  /// Check if production mode
  bool get isProduction => config.environment.name == 'production';

  /// Check if staging mode
  bool get isStaging => config.environment.name == 'staging';

  /// Validate current configuration
  Future<bool> validateCurrentConfig() async {
    if (_config == null) return false;
    return await _loader.validateConfig(_config!);
  }

  /// Reload configuration
  Future<void> reload([String? environment]) async {
    _config = null;
    await initialize(environment);
  }

  /// Get configuration as JSON for debugging
  Map<String, dynamic> toJson() => config.toJson();

  @override
  String toString() {
    if (_config == null) return 'EnvironmentConfigService(not initialized)';
    return 'EnvironmentConfigService(${config.environment.name}: ${config.app.name})';
  }
}