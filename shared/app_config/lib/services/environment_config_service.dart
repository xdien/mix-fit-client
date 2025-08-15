import 'package:flutter/foundation.dart';
import '../models/environment_config.dart';
import '../loaders/environment_config_loader.dart';
import '../validation/config_validator.dart';
import '../utils/environment_variables.dart';

/// Service for managing environment configuration
/// Provides centralized access to configuration values with proper fallbacks
class EnvironmentConfigService {
  static final EnvironmentConfigService _instance = EnvironmentConfigService._internal();
  factory EnvironmentConfigService() => _instance;
  EnvironmentConfigService._internal();

  EnvironmentConfig? _config;
  EnvironmentConfigLoader? _loader;
  String? _currentEnvironment;
  bool _isInitialized = false;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current environment name
  String? get currentEnvironment => _currentEnvironment;

  /// Initialize the service with a specific environment
  Future<void> initialize([String? environment]) async {
    if (_isInitialized && environment == _currentEnvironment) {
      debugPrint('Service already initialized for environment: $environment');
      return;
    }

    _currentEnvironment = environment ?? EnvironmentVariables.environment;
    
    try {
      // Try to load configuration from YAML files
      _loader = YamlEnvironmentConfigLoader();
      _config = await _loader!.loadConfig(_currentEnvironment!);
      
      // Apply environment variable overrides
      _config = _applyEnvironmentVariableOverrides(_config!);
      
      // Validate configuration
      final validationResult = await ConfigValidator.validateEnvironmentConfig(_config!);
      
      if (!validationResult.isValid) {
        debugPrint('Configuration validation failed: ${validationResult.errorMessage}');
        debugPrint('Using default configuration');
        _config = _createDefaultConfig();
      }
      
      _isInitialized = true;
      debugPrint('Environment configuration loaded successfully for: $_currentEnvironment');
    } catch (e) {
      debugPrint('Failed to load environment configuration: $e');
      debugPrint('Using default configuration');
      _config = _createDefaultConfig();
      _isInitialized = true;
    }
  }

  /// Initialize with a custom loader (for testing)
  Future<void> initializeWithLoader(EnvironmentConfigLoader loader, String environment) async {
    _loader = loader;
    _currentEnvironment = environment;
    
    try {
      _config = await loader.loadConfig(environment);
      _config = _applyEnvironmentVariableOverrides(_config!);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to load configuration with custom loader: $e');
      _config = _createDefaultConfig();
      _isInitialized = true;
    }
  }

  /// Create default configuration using environment variables
  EnvironmentConfig _createDefaultConfig() {
    return EnvironmentConfig(
      environment: EnvironmentInfo(
        name: EnvironmentVariables.environment,
        displayName: 'Default Environment',
      ),
      app: AppEnvironmentConfig(
        name: EnvironmentVariables.appName,
        bundleId: EnvironmentVariables.bundleId,
        versionName: '1.0.0',
        versionCode: 1,
      ),
      network: NetworkConfig(
        apiBaseUrl: EnvironmentVariables.apiEndpoint,
        websocketUrl: EnvironmentVariables.websocketUrl,
        timeout: EnvironmentVariables.networkTimeout,
      ),
      websocket: WebSocketEnvironmentConfig(
        enabled: EnvironmentVariables.websocketEnabled,
        autoConnect: EnvironmentVariables.websocketAutoConnect,
        reconnectInterval: EnvironmentVariables.websocketReconnectInterval,
        maxReconnectAttempts: EnvironmentVariables.websocketMaxReconnectAttempts,
        heartbeatInterval: EnvironmentVariables.websocketHeartbeatInterval,
        connectionTimeout: EnvironmentVariables.websocketConnectionTimeout,
        messageQueueSize: EnvironmentVariables.websocketMessageQueueSize,
        features: WebSocketFeatureFlags(
          realTimeUpdates: EnvironmentVariables.websocketRealTimeUpdates,
          offlineSupport: EnvironmentVariables.websocketOfflineSupport,
          backgroundSync: EnvironmentVariables.websocketBackgroundSync,
          pushNotifications: EnvironmentVariables.websocketPushNotifications,
        ),
      ),
      build: BuildConfig(
        flavor: EnvironmentVariables.buildFlavor,
        buildType: EnvironmentVariables.buildType,
        obfuscate: EnvironmentVariables.buildObfuscate,
        shrinkResources: EnvironmentVariables.buildShrinkResources,
      ),
      signing: SigningConfig(
        storeFile: EnvironmentVariables.signingStoreFile.isNotEmpty ? EnvironmentVariables.signingStoreFile : null,
        storePasswordEnv: EnvironmentVariables.signingStorePasswordEnv,
        keyAlias: EnvironmentVariables.signingKeyAlias.isNotEmpty ? EnvironmentVariables.signingKeyAlias : null,
        keyPasswordEnv: EnvironmentVariables.signingKeyPasswordEnv,
      ),
      distribution: DistributionConfig(
        platform: EnvironmentVariables.distributionPlatform.isNotEmpty ? EnvironmentVariables.distributionPlatform : null,
        track: EnvironmentVariables.distributionTrack.isNotEmpty ? EnvironmentVariables.distributionTrack : null,
      ),
      notifications: NotificationConfig(
        slackWebhook: EnvironmentVariables.notificationSlackWebhook.isNotEmpty ? EnvironmentVariables.notificationSlackWebhook : null,
        emailRecipients: EnvironmentVariables.notificationEmailRecipients.isNotEmpty 
            ? EnvironmentVariables.notificationEmailRecipients.split(',').map((e) => e.trim()).toList() 
            : null,
      ),
    );
  }

  /// Apply environment variable overrides to configuration
  EnvironmentConfig _applyEnvironmentVariableOverrides(EnvironmentConfig config) {
    // Check for environment variable overrides
    final apiBaseUrl = EnvironmentVariables.apiBaseUrl;
    final websocketUrl = EnvironmentVariables.websocketUrl;
    final appName = EnvironmentVariables.appName;
    final bundleId = EnvironmentVariables.bundleId;
    final timeout = EnvironmentVariables.networkTimeout;
    
    // WebSocket environment variable overrides
    final websocketEnabled = EnvironmentVariables.websocketEnabled;
    final websocketAutoConnect = EnvironmentVariables.websocketAutoConnect;
    final websocketReconnectInterval = EnvironmentVariables.websocketReconnectInterval;
    final websocketMaxReconnectAttempts = EnvironmentVariables.websocketMaxReconnectAttempts;
    final websocketHeartbeatInterval = EnvironmentVariables.websocketHeartbeatInterval;
    final websocketConnectionTimeout = EnvironmentVariables.websocketConnectionTimeout;
    final websocketMessageQueueSize = EnvironmentVariables.websocketMessageQueueSize;
    
    // Feature flag overrides
    final realTimeUpdates = EnvironmentVariables.websocketRealTimeUpdates;
    final offlineSupport = EnvironmentVariables.websocketOfflineSupport;
    final backgroundSync = EnvironmentVariables.websocketBackgroundSync;
    final pushNotifications = EnvironmentVariables.websocketPushNotifications;

    // Check if any overrides are needed
    final hasNetworkOverrides = apiBaseUrl.isNotEmpty || 
        websocketUrl.isNotEmpty || 
        appName.isNotEmpty || 
        bundleId.isNotEmpty ||
        timeout != 30000; // Check if different from default
        
    final hasWebSocketOverrides = websocketEnabled != true ||
        websocketAutoConnect != true ||
        websocketReconnectInterval != 5000 ||
        websocketMaxReconnectAttempts != 5 ||
        websocketHeartbeatInterval != 30000 ||
        websocketConnectionTimeout != 10000 ||
        websocketMessageQueueSize != 1000 ||
        realTimeUpdates != true ||
        offlineSupport != true ||
        backgroundSync != true ||
        pushNotifications != true;

    if (!hasNetworkOverrides && !hasWebSocketOverrides) {
      return config; // No overrides needed
    }

    // Create new config with overrides
    return config.copyWith(
      app: hasNetworkOverrides ? config.app.copyWith(
        name: appName.isNotEmpty ? appName : config.app.name,
        bundleId: bundleId.isNotEmpty ? bundleId : config.app.bundleId,
      ) : config.app,
      network: hasNetworkOverrides ? config.network.copyWith(
        apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : config.network.apiBaseUrl,
        websocketUrl: websocketUrl.isNotEmpty ? websocketUrl : config.network.websocketUrl,
        timeout: timeout,
      ) : config.network,
      websocket: hasWebSocketOverrides ? (config.websocket ?? WebSocketEnvironmentConfig()).copyWith(
        enabled: websocketEnabled,
        autoConnect: websocketAutoConnect,
        reconnectInterval: websocketReconnectInterval,
        maxReconnectAttempts: websocketMaxReconnectAttempts,
        heartbeatInterval: websocketHeartbeatInterval,
        connectionTimeout: websocketConnectionTimeout,
        messageQueueSize: websocketMessageQueueSize,
        features: WebSocketFeatureFlags(
          realTimeUpdates: realTimeUpdates,
          offlineSupport: offlineSupport,
          backgroundSync: backgroundSync,
          pushNotifications: pushNotifications,
        ),
      ) : config.websocket,
    );
  }

  /// Validate current configuration
  Future<bool> validateCurrentConfig() async {
    if (!_isInitialized) {
      return false;
    }
    
    try {
      final validationResult = await ConfigValidator.validateEnvironmentConfig(_config!);
      return validationResult.isValid;
    } catch (e) {
      debugPrint('Configuration validation failed: $e');
      return false;
    }
  }

  /// Reload configuration
  Future<void> reload() async {
    _isInitialized = false;
    await initialize(_currentEnvironment);
  }

  /// Get configuration as JSON
  Map<String, dynamic> toJson() {
    if (!_isInitialized) {
      throw StateError('Configuration not initialized');
    }
    return _config!.toJson();
  }

  // Getters for configuration values
  EnvironmentConfig get config {
    if (!_isInitialized) {
      throw StateError('Configuration not initialized');
    }
    return _config!;
  }

  String get environmentName => config.environment.name;
  String get environmentDisplayName => config.environment.displayName;
  String get appName => config.app.name;
  String get bundleId => config.app.bundleId;
  String? get versionName => config.app.versionName;
  int? get versionCode => config.app.versionCode;
  String get apiBaseUrl => config.network.apiBaseUrl;
  String? get websocketUrl => config.network.websocketUrl;
  int get timeout => config.network.timeout;
  bool get isDebugMode => kDebugMode;

  /// Check if production mode
  bool get isProduction => config.environment.name == 'production';

  /// Check if staging mode
  bool get isStaging => config.environment.name == 'staging';

  /// Get build configuration
  BuildConfig? get buildConfig => config.build;

  /// Get signing configuration
  SigningConfig? get signingConfig => config.signing;

  /// Get distribution configuration
  DistributionConfig? get distributionConfig => config.distribution;

  /// Get notification configuration
  NotificationConfig? get notificationConfig => config.notifications;

  // WebSocket specific getters
  /// Get WebSocket configuration
  WebSocketEnvironmentConfig? get websocketConfig => config.websocket;

  /// Check if WebSocket is enabled
  bool get isWebSocketEnabled => config.websocket?.enabled ?? EnvironmentVariables.websocketEnabled;

  /// Get WebSocket reconnect interval
  int get websocketReconnectInterval => config.websocket?.reconnectInterval ?? EnvironmentVariables.websocketReconnectInterval;

  /// Get WebSocket max reconnect attempts
  int get websocketMaxReconnectAttempts => config.websocket?.maxReconnectAttempts ?? EnvironmentVariables.websocketMaxReconnectAttempts;

  /// Get WebSocket heartbeat interval
  int get websocketHeartbeatInterval => config.websocket?.heartbeatInterval ?? EnvironmentVariables.websocketHeartbeatInterval;

  /// Get WebSocket connection timeout
  int get websocketConnectionTimeout => config.websocket?.connectionTimeout ?? EnvironmentVariables.websocketConnectionTimeout;

  /// Get WebSocket message queue size
  int get websocketMessageQueueSize => config.websocket?.messageQueueSize ?? EnvironmentVariables.websocketMessageQueueSize;

  /// Get WebSocket channels
  List<String> get websocketChannels => config.websocket?.channels ?? [];

  /// Get WebSocket feature flags
  WebSocketFeatureFlags? get websocketFeatures => config.websocket?.features;

  /// Check if real-time updates are enabled
  bool get isRealTimeUpdatesEnabled => config.websocket?.features?.realTimeUpdates ?? EnvironmentVariables.websocketRealTimeUpdates;

  /// Check if offline support is enabled
  bool get isOfflineSupportEnabled => config.websocket?.features?.offlineSupport ?? EnvironmentVariables.websocketOfflineSupport;

  /// Check if background sync is enabled
  bool get isBackgroundSyncEnabled => config.websocket?.features?.backgroundSync ?? EnvironmentVariables.websocketBackgroundSync;

  /// Check if push notifications are enabled
  bool get isPushNotificationsEnabled => config.websocket?.features?.pushNotifications ?? EnvironmentVariables.websocketPushNotifications;

  @override
  String toString() {
    if (!_isInitialized) {
      return 'EnvironmentConfigService(not initialized)';
    }
    return 'EnvironmentConfigService(environment: $environmentName, app: $appName, apiUrl: $apiBaseUrl)';
  }

  /// Reset service state (for testing)
  void reset() {
    _config = null;
    _loader = null;
    _currentEnvironment = null;
    _isInitialized = false;
  }
}