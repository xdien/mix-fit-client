import 'package:flutter/foundation.dart';
import 'package:app_config/app_config.dart';
import '../services/websocket_config_manager.dart';
import '../services/websocket_feature_manager.dart';

/// Example demonstrating how to use WebSocket configuration and feature management
class WebSocketConfigUsageExample {
  static final WebSocketConfigManager _configManager = WebSocketConfigManager();
  static final WebSocketFeatureManager _featureManager = WebSocketFeatureManager();
  static final EnvironmentConfigService _environmentService = EnvironmentConfigService();

  /// Initialize the configuration system
  static Future<void> initialize([String? environment]) async {
    // Initialize environment configuration first
    await _environmentService.initialize(environment);
    
    debugPrint('WebSocket configuration initialized for environment: ${_environmentService.environmentName}');
  }

  /// Example: Basic configuration usage
  static void demonstrateBasicConfiguration() {
    debugPrint('\n=== Basic WebSocket Configuration ===');
    
    // Check if WebSocket is enabled
    if (!_configManager.isEnabled()) {
      debugPrint('WebSocket is disabled in current environment');
      return;
    }

    // Get WebSocket configuration
    final config = _configManager.getConfig();
    debugPrint('WebSocket URL: ${config.url}');
    debugPrint('Auto-reconnect: ${config.autoReconnect}');
    debugPrint('Reconnect interval: ${config.reconnectInterval.inSeconds}s');
    debugPrint('Max reconnect attempts: ${config.maxReconnectAttempts}');
    debugPrint('Heartbeat interval: ${config.heartbeatInterval.inSeconds}s');

    // Get additional configuration
    debugPrint('Connection timeout: ${_configManager.getConnectionTimeout().inSeconds}s');
    debugPrint('Message queue size: ${_configManager.getMessageQueueSize()}');
    debugPrint('Configured channels: ${_configManager.getChannels()}');
  }

  /// Example: Feature flag usage
  static void demonstrateFeatureFlags() {
    debugPrint('\n=== WebSocket Feature Flags ===');
    
    // Check individual features
    debugPrint('Real-time updates: ${_featureManager.isRealTimeUpdatesEnabled}');
    debugPrint('Offline support: ${_featureManager.isOfflineSupportEnabled}');
    debugPrint('Background sync: ${_featureManager.isBackgroundSyncEnabled}');
    debugPrint('Push notifications: ${_featureManager.isPushNotificationsEnabled}');

    // Get all feature flags
    final allFeatures = _featureManager.getAllFeatureFlags();
    debugPrint('All features: $allFeatures');

    // Check specific feature
    if (_featureManager.isFeatureEnabled(WebSocketFeatureManager.realTimeUpdates)) {
      debugPrint('Real-time updates are enabled - setting up live data sync');
    }
  }

  /// Example: Runtime feature overrides
  static void demonstrateRuntimeOverrides() {
    debugPrint('\n=== Runtime Feature Overrides ===');
    
    // Show initial state
    debugPrint('Initial real-time updates: ${_featureManager.isRealTimeUpdatesEnabled}');
    
    // Apply runtime override
    _featureManager.enableFeature(WebSocketFeatureManager.realTimeUpdates);
    debugPrint('After enabling override: ${_featureManager.isRealTimeUpdatesEnabled}');
    
    // Toggle feature
    _featureManager.toggleFeature(WebSocketFeatureManager.realTimeUpdates);
    debugPrint('After toggling: ${_featureManager.isRealTimeUpdatesEnabled}');
    
    // Show runtime overrides
    final overrides = _featureManager.getRuntimeOverrides();
    debugPrint('Current overrides: $overrides');
    
    // Clear overrides
    _featureManager.clearAllOverrides();
    debugPrint('After clearing overrides: ${_featureManager.isRealTimeUpdatesEnabled}');
  }

  /// Example: Configuration validation
  static void demonstrateConfigurationValidation() {
    debugPrint('\n=== Configuration Validation ===');
    
    // Validate WebSocket configuration
    final configValid = _configManager.validateConfiguration();
    debugPrint('WebSocket configuration valid: $configValid');
    
    // Validate feature configuration
    final featuresValid = _featureManager.validateFeatureConfiguration();
    debugPrint('Feature configuration valid: $featuresValid');
    
    // Validate environment configuration
    _environmentService.validateCurrentConfig().then((envValid) {
      debugPrint('Environment configuration valid: $envValid');
    });
  }

  /// Example: Environment-specific behavior
  static void demonstrateEnvironmentSpecificBehavior() {
    debugPrint('\n=== Environment-Specific Behavior ===');
    
    final environment = _environmentService.environmentName;
    debugPrint('Current environment: $environment');
    
    switch (environment) {
      case 'development':
        debugPrint('Development mode: Using local WebSocket server');
        debugPrint('Debug features enabled');
        break;
      case 'staging':
        debugPrint('Staging mode: Using staging WebSocket server');
        debugPrint('Testing features enabled');
        break;
      case 'production':
        debugPrint('Production mode: Using production WebSocket server');
        debugPrint('Background sync disabled for battery optimization');
        break;
      default:
        debugPrint('Unknown environment: Using default configuration');
    }
  }

  /// Example: Configuration summary
  static void demonstrateConfigurationSummary() {
    debugPrint('\n=== Configuration Summary ===');
    
    // Get WebSocket configuration summary
    final configSummary = _configManager.getConfigSummary();
    debugPrint('WebSocket Config Summary:');
    configSummary.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    
    // Get feature summary
    final featureSummary = _featureManager.getFeatureSummary();
    debugPrint('\nFeature Summary:');
    featureSummary.forEach((key, value) {
      debugPrint('  $key: $value');
    });
  }

  /// Example: Conditional WebSocket initialization
  static Future<bool> shouldInitializeWebSocket() async {
    // Check if WebSocket is enabled
    if (!_configManager.isEnabled()) {
      debugPrint('WebSocket disabled in configuration');
      return false;
    }

    // Check if real-time updates are needed
    if (!_featureManager.isRealTimeUpdatesEnabled) {
      debugPrint('Real-time updates disabled');
      return false;
    }

    // Validate configuration
    if (!_configManager.validateConfiguration()) {
      debugPrint('WebSocket configuration invalid');
      return false;
    }

    debugPrint('WebSocket initialization approved');
    return true;
  }

  /// Example: Feature-based service initialization
  static void initializeServicesBasedOnFeatures() {
    debugPrint('\n=== Feature-Based Service Initialization ===');
    
    if (_featureManager.isRealTimeUpdatesEnabled) {
      debugPrint('Initializing real-time data synchronization service');
      // Initialize real-time sync service
    }
    
    if (_featureManager.isOfflineSupportEnabled) {
      debugPrint('Initializing offline support and message queuing');
      // Initialize offline support
    }
    
    if (_featureManager.isBackgroundSyncEnabled) {
      debugPrint('Initializing background synchronization service');
      // Initialize background sync
    }
    
    if (_featureManager.isPushNotificationsEnabled) {
      debugPrint('Initializing push notification handling');
      // Initialize push notifications
    }
  }

  /// Run all examples
  static Future<void> runAllExamples([String? environment]) async {
    debugPrint('=== WebSocket Configuration Usage Examples ===');
    
    try {
      await initialize(environment);
      
      demonstrateBasicConfiguration();
      demonstrateFeatureFlags();
      demonstrateRuntimeOverrides();
      demonstrateConfigurationValidation();
      demonstrateEnvironmentSpecificBehavior();
      demonstrateConfigurationSummary();
      
      final shouldInit = await shouldInitializeWebSocket();
      if (shouldInit) {
        initializeServicesBasedOnFeatures();
      }
      
      debugPrint('\n=== Examples completed successfully ===');
    } catch (e) {
      debugPrint('Error running examples: $e');
    }
  }
}

/// Example of integrating WebSocket configuration with a service
class ExampleWebSocketService {
  final WebSocketConfigManager _configManager = WebSocketConfigManager();
  final WebSocketFeatureManager _featureManager = WebSocketFeatureManager();
  
  bool _isConnected = false;
  
  /// Initialize the WebSocket service with configuration
  Future<void> initialize() async {
    // Check if WebSocket is enabled
    if (!_configManager.isEnabled()) {
      debugPrint('WebSocket service disabled by configuration');
      return;
    }
    
    // Get configuration
    final config = _configManager.getConfig();
    
    // Validate configuration
    if (!_configManager.validateConfiguration()) {
      throw Exception('Invalid WebSocket configuration');
    }
    
    debugPrint('Initializing WebSocket service with URL: ${config.url}');
    
    // Configure connection parameters
    final connectionTimeout = _configManager.getConnectionTimeout();
    final messageQueueSize = _configManager.getMessageQueueSize();
    
    debugPrint('Connection timeout: ${connectionTimeout.inSeconds}s');
    debugPrint('Message queue size: $messageQueueSize');
    
    // Subscribe to configured channels
    final channels = _configManager.getChannels();
    for (final channel in channels) {
      if (_shouldSubscribeToChannel(channel)) {
        debugPrint('Subscribing to channel: $channel');
        // Subscribe to channel
      }
    }
    
    _isConnected = true;
    debugPrint('WebSocket service initialized successfully');
  }
  
  /// Check if should subscribe to a channel based on features
  bool _shouldSubscribeToChannel(String channel) {
    switch (channel) {
      case 'inventory':
      case 'customers':
      case 'orders':
        return _featureManager.isRealTimeUpdatesEnabled;
      case 'notifications':
        return _featureManager.isPushNotificationsEnabled;
      default:
        return true;
    }
  }
  
  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (!_featureManager.isBackgroundSyncEnabled) {
      switch (state) {
        case AppLifecycleState.paused:
          debugPrint('App paused - disconnecting WebSocket');
          // Disconnect WebSocket
          break;
        case AppLifecycleState.resumed:
          debugPrint('App resumed - reconnecting WebSocket');
          // Reconnect WebSocket
          break;
        default:
          break;
      }
    }
  }
  
  bool get isConnected => _isConnected;
}