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

  /// Get WebSocket configuration
  WebSocketEnvironmentConfig? get websocketConfig => config.websocket;

  /// Check if WebSocket is enabled
  bool get isWebSocketEnabled => config.websocket?.enabled ?? false;

  /// Get WebSocket reconnect interval
  int get websocketReconnectInterval => config.websocket?.reconnectInterval ?? 5000;

  /// Get WebSocket max reconnect attempts
  int get websocketMaxReconnectAttempts => config.websocket?.maxReconnectAttempts ?? 5;

  /// Get WebSocket heartbeat interval
  int get websocketHeartbeatInterval => config.websocket?.heartbeatInterval ?? 30000;

  /// Get WebSocket connection timeout
  int get websocketConnectionTimeout => config.websocket?.connectionTimeout ?? 10000;

  /// Get WebSocket message queue size
  int get websocketMessageQueueSize => config.websocket?.messageQueueSize ?? 1000;

  /// Get WebSocket channels
  List<String> get websocketChannels => config.websocket?.channels ?? [];

  /// Get WebSocket feature flags
  WebSocketFeatureFlags? get websocketFeatures => config.websocket?.features;

  /// Check if real-time updates are enabled
  bool get isRealTimeUpdatesEnabled => config.websocket?.features?.realTimeUpdates ?? true;

  /// Check if offline support is enabled
  bool get isOfflineSupportEnabled => config.websocket?.features?.offlineSupport ?? true;

  /// Check if background sync is enabled
  bool get isBackgroundSyncEnabled => config.websocket?.features?.backgroundSync ?? true;

  /// Check if push notifications are enabled
  bool get isPushNotificationsEnabled => config.websocket?.features?.pushNotifications ?? true;

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
    
    // WebSocket environment variable overrides
    const websocketEnabledStr = String.fromEnvironment('WEBSOCKET_ENABLED');
    const websocketAutoConnectStr = String.fromEnvironment('WEBSOCKET_AUTO_CONNECT');
    const websocketReconnectIntervalStr = String.fromEnvironment('WEBSOCKET_RECONNECT_INTERVAL');
    const websocketMaxReconnectAttemptsStr = String.fromEnvironment('WEBSOCKET_MAX_RECONNECT_ATTEMPTS');
    const websocketHeartbeatIntervalStr = String.fromEnvironment('WEBSOCKET_HEARTBEAT_INTERVAL');
    const websocketConnectionTimeoutStr = String.fromEnvironment('WEBSOCKET_CONNECTION_TIMEOUT');
    const websocketMessageQueueSizeStr = String.fromEnvironment('WEBSOCKET_MESSAGE_QUEUE_SIZE');
    
    // Feature flag overrides
    const realTimeUpdatesStr = String.fromEnvironment('WEBSOCKET_REAL_TIME_UPDATES');
    const offlineSupportStr = String.fromEnvironment('WEBSOCKET_OFFLINE_SUPPORT');
    const backgroundSyncStr = String.fromEnvironment('WEBSOCKET_BACKGROUND_SYNC');
    const pushNotificationsStr = String.fromEnvironment('WEBSOCKET_PUSH_NOTIFICATIONS');
    
    // Parse values if provided
    int? timeout;
    if (timeoutStr.isNotEmpty) {
      timeout = int.tryParse(timeoutStr);
    }
    
    bool? websocketEnabled;
    if (websocketEnabledStr.isNotEmpty) {
      websocketEnabled = websocketEnabledStr.toLowerCase() == 'true';
    }
    
    bool? websocketAutoConnect;
    if (websocketAutoConnectStr.isNotEmpty) {
      websocketAutoConnect = websocketAutoConnectStr.toLowerCase() == 'true';
    }
    
    int? websocketReconnectInterval;
    if (websocketReconnectIntervalStr.isNotEmpty) {
      websocketReconnectInterval = int.tryParse(websocketReconnectIntervalStr);
    }
    
    int? websocketMaxReconnectAttempts;
    if (websocketMaxReconnectAttemptsStr.isNotEmpty) {
      websocketMaxReconnectAttempts = int.tryParse(websocketMaxReconnectAttemptsStr);
    }
    
    int? websocketHeartbeatInterval;
    if (websocketHeartbeatIntervalStr.isNotEmpty) {
      websocketHeartbeatInterval = int.tryParse(websocketHeartbeatIntervalStr);
    }
    
    int? websocketConnectionTimeout;
    if (websocketConnectionTimeoutStr.isNotEmpty) {
      websocketConnectionTimeout = int.tryParse(websocketConnectionTimeoutStr);
    }
    
    int? websocketMessageQueueSize;
    if (websocketMessageQueueSizeStr.isNotEmpty) {
      websocketMessageQueueSize = int.tryParse(websocketMessageQueueSizeStr);
    }
    
    bool? realTimeUpdates;
    if (realTimeUpdatesStr.isNotEmpty) {
      realTimeUpdates = realTimeUpdatesStr.toLowerCase() == 'true';
    }
    
    bool? offlineSupport;
    if (offlineSupportStr.isNotEmpty) {
      offlineSupport = offlineSupportStr.toLowerCase() == 'true';
    }
    
    bool? backgroundSync;
    if (backgroundSyncStr.isNotEmpty) {
      backgroundSync = backgroundSyncStr.toLowerCase() == 'true';
    }
    
    bool? pushNotifications;
    if (pushNotificationsStr.isNotEmpty) {
      pushNotifications = pushNotificationsStr.toLowerCase() == 'true';
    }

    // Check if any overrides are needed
    final hasNetworkOverrides = apiBaseUrl.isNotEmpty || 
        websocketUrl.isNotEmpty || 
        appName.isNotEmpty || 
        bundleId.isNotEmpty ||
        timeout != null;
        
    final hasWebSocketOverrides = websocketEnabled != null ||
        websocketAutoConnect != null ||
        websocketReconnectInterval != null ||
        websocketMaxReconnectAttempts != null ||
        websocketHeartbeatInterval != null ||
        websocketConnectionTimeout != null ||
        websocketMessageQueueSize != null ||
        realTimeUpdates != null ||
        offlineSupport != null ||
        backgroundSync != null ||
        pushNotifications != null;

    // Apply overrides if environment variables are set
    if (hasNetworkOverrides || hasWebSocketOverrides) {
      debugPrint('Applying environment variable overrides...');
      
      var updatedConfig = config;
      
      // Apply network overrides
      if (hasNetworkOverrides) {
        updatedConfig = updatedConfig.copyWith(
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
      
      // Apply WebSocket overrides
      if (hasWebSocketOverrides) {
        final currentWebSocketConfig = config.websocket ?? const WebSocketEnvironmentConfig();
        final currentFeatures = currentWebSocketConfig.features ?? const WebSocketFeatureFlags();
        
        final updatedFeatures = currentFeatures.copyWith(
          realTimeUpdates: realTimeUpdates ?? currentFeatures.realTimeUpdates,
          offlineSupport: offlineSupport ?? currentFeatures.offlineSupport,
          backgroundSync: backgroundSync ?? currentFeatures.backgroundSync,
          pushNotifications: pushNotifications ?? currentFeatures.pushNotifications,
        );
        
        final updatedWebSocketConfig = currentWebSocketConfig.copyWith(
          enabled: websocketEnabled ?? currentWebSocketConfig.enabled,
          autoConnect: websocketAutoConnect ?? currentWebSocketConfig.autoConnect,
          reconnectInterval: websocketReconnectInterval ?? currentWebSocketConfig.reconnectInterval,
          maxReconnectAttempts: websocketMaxReconnectAttempts ?? currentWebSocketConfig.maxReconnectAttempts,
          heartbeatInterval: websocketHeartbeatInterval ?? currentWebSocketConfig.heartbeatInterval,
          connectionTimeout: websocketConnectionTimeout ?? currentWebSocketConfig.connectionTimeout,
          messageQueueSize: websocketMessageQueueSize ?? currentWebSocketConfig.messageQueueSize,
          features: updatedFeatures,
        );
        
        updatedConfig = updatedConfig.copyWith(
          websocket: updatedWebSocketConfig,
        );
      }
      
      return updatedConfig;
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