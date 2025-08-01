import 'package:flutter/foundation.dart';
import '../models/environment_config.dart';
import '../loaders/environment_config_loader.dart';

class EnvironmentConfigService {
  static final EnvironmentConfigService _instance = EnvironmentConfigService._internal();
  factory EnvironmentConfigService() => _instance;
  EnvironmentConfigService._internal();

  EnvironmentConfig? _config;
  String? _currentEnvironment;
  EnvironmentConfigLoader _loader = YamlEnvironmentConfigLoader();

  /// Initialize the configuration service with the specified environment
  Future<void> initialize([String? environment]) async {
    final env = environment ?? 
                const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    _currentEnvironment = env;
    
    try {
      _config = await _loader.loadConfig(env);
      
      // Apply environment variable overrides if available
      _config = _applyEnvironmentVariableOverrides(_config!);
      
      debugPrint('Environment configuration loaded successfully for: $env');
      debugPrint('API Base URL: ${_config!.network.apiBaseUrl}');
      debugPrint('App Name: ${_config!.app.name}');
      debugPrint('Bundle ID: ${_config!.app.bundleId}');
    } catch (e) {
      debugPrint('Failed to load environment configuration: $e');
      debugPrint('Using default configuration with environment variable overrides');
      _config = _applyEnvironmentVariableOverrides(_loader.getDefaultConfig());
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

  /// Get current environment name
  String? get currentEnvironment => _currentEnvironment;

  /// Get build configuration
  BuildConfig? get buildConfig => config.build;

  /// Get signing configuration
  SigningConfig? get signingConfig => config.signing;

  /// Get distribution configuration
  DistributionConfig? get distributionConfig => config.distribution;

  /// Get notification configuration
  NotificationConfig? get notificationConfig => config.notifications;

  /// Get version name
  String? get versionName => config.app.versionName;

  /// Get version code
  int? get versionCode => config.app.versionCode;

  /// Apply environment variable overrides to configuration
  EnvironmentConfig _applyEnvironmentVariableOverrides(EnvironmentConfig config) {
    // Check for environment variable overrides
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const websocketUrl = String.fromEnvironment('WEBSOCKET_URL');
    const appName = String.fromEnvironment('APP_NAME');
    const bundleId = String.fromEnvironment('BUNDLE_ID');
    const timeoutStr = String.fromEnvironment('NETWORK_TIMEOUT');
    
    // Parse timeout if provided
    int? timeout;
    if (timeoutStr.isNotEmpty) {
      timeout = int.tryParse(timeoutStr);
    }

    // Apply overrides if environment variables are set
    if (apiBaseUrl.isNotEmpty || 
        websocketUrl.isNotEmpty || 
        appName.isNotEmpty || 
        bundleId.isNotEmpty ||
        timeout != null) {
      
      debugPrint('Applying environment variable overrides...');
      
      return config.copyWith(
        app: config.app.copyWith(
          name: appName.isNotEmpty ? appName : config.app.name,
          bundleId: bundleId.isNotEmpty ? bundleId : config.app.bundleId,
        ),
        network: config.network.copyWith(
          apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : config.network.apiBaseUrl,
          websocketUrl: websocketUrl.isNotEmpty ? websocketUrl : config.network.websocketUrl,
          timeout: timeout ?? config.network.timeout,
        ),
      );
    }

    return config;
  }

  /// Initialize with custom loader (for testing)
  Future<void> initializeWithLoader(EnvironmentConfigLoader loader, [String? environment]) async {
    _loader = loader; // Set the loader to be used for validation
    
    final env = environment ?? 
                const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    _currentEnvironment = env;
    
    try {
      _config = await loader.loadConfig(env);
      _config = _applyEnvironmentVariableOverrides(_config!);
      
      debugPrint('Environment configuration loaded successfully for: $env');
    } catch (e) {
      debugPrint('Failed to load environment configuration: $e');
      debugPrint('Using default configuration');
      _config = _applyEnvironmentVariableOverrides(loader.getDefaultConfig());
    }
  }

  /// Reset the service (for testing)
  void reset() {
    _config = null;
    _currentEnvironment = null;
    _loader = YamlEnvironmentConfigLoader(); // Reset to default loader
  }

  /// Get configuration as JSON for debugging
  Map<String, dynamic> toJson() => config.toJson();

  @override
  String toString() {
    if (_config == null) return 'EnvironmentConfigService(not initialized)';
    return 'EnvironmentConfigService(${config.environment.name}: ${config.app.name})';
  }
}