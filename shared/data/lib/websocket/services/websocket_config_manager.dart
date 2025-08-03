import 'package:flutter/foundation.dart';
import 'package:app_config/app_config.dart';
import '../models/websocket_config.dart';

/// Manages WebSocket configuration by integrating environment configuration
/// with WebSocket-specific settings and feature flags
class WebSocketConfigManager {
  static final WebSocketConfigManager _instance = WebSocketConfigManager._internal();
  factory WebSocketConfigManager() => _instance;
  WebSocketConfigManager._internal();

  final EnvironmentConfigService _environmentService = EnvironmentConfigService();
  WebSocketConfig? _cachedConfig;

  /// Get the current WebSocket configuration
  WebSocketConfig getConfig() {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    // Build configuration from environment settings
    final envConfig = _environmentService.config;
    final websocketEnvConfig = envConfig.websocket;
    
    if (websocketEnvConfig == null) {
      // Fallback to default configuration if no WebSocket config is provided
      _cachedConfig = _getDefaultConfig();
    } else {
      _cachedConfig = WebSocketConfig(
        url: _environmentService.websocketUrl ?? _getDefaultWebSocketUrl(),
        reconnectInterval: Duration(milliseconds: websocketEnvConfig.reconnectInterval),
        maxReconnectAttempts: websocketEnvConfig.maxReconnectAttempts,
        heartbeatInterval: Duration(milliseconds: websocketEnvConfig.heartbeatInterval),
        autoReconnect: websocketEnvConfig.autoConnect,
      );
    }

    debugPrint('WebSocket configuration loaded: ${_cachedConfig!.url}');
    return _cachedConfig!;
  }

  /// Check if WebSocket is enabled in the current environment
  bool isEnabled() {
    return _environmentService.isWebSocketEnabled;
  }

  /// Check if auto-connect is enabled
  bool isAutoConnectEnabled() {
    return _environmentService.websocketConfig?.autoConnect ?? true;
  }

  /// Get connection timeout duration
  Duration getConnectionTimeout() {
    final timeout = _environmentService.websocketConnectionTimeout;
    return Duration(milliseconds: timeout);
  }

  /// Get message queue size
  int getMessageQueueSize() {
    return _environmentService.websocketMessageQueueSize;
  }

  /// Get configured channels for subscription
  List<String> getChannels() {
    return _environmentService.websocketChannels;
  }

  /// Check if real-time updates feature is enabled
  bool isRealTimeUpdatesEnabled() {
    return _environmentService.isRealTimeUpdatesEnabled;
  }

  /// Check if offline support feature is enabled
  bool isOfflineSupportEnabled() {
    return _environmentService.isOfflineSupportEnabled;
  }

  /// Check if background sync feature is enabled
  bool isBackgroundSyncEnabled() {
    return _environmentService.isBackgroundSyncEnabled;
  }

  /// Check if push notifications feature is enabled
  bool isPushNotificationsEnabled() {
    return _environmentService.isPushNotificationsEnabled;
  }

  /// Get feature flags as a map for easy checking
  Map<String, bool> getFeatureFlags() {
    return {
      'realTimeUpdates': isRealTimeUpdatesEnabled(),
      'offlineSupport': isOfflineSupportEnabled(),
      'backgroundSync': isBackgroundSyncEnabled(),
      'pushNotifications': isPushNotificationsEnabled(),
    };
  }

  /// Check if a specific feature is enabled
  bool isFeatureEnabled(String featureName) {
    final flags = getFeatureFlags();
    return flags[featureName] ?? false;
  }

  /// Get environment-specific configuration summary
  Map<String, dynamic> getConfigSummary() {
    final config = getConfig();
    return {
      'environment': _environmentService.environmentName,
      'websocketUrl': config.url,
      'enabled': isEnabled(),
      'autoConnect': isAutoConnectEnabled(),
      'reconnectInterval': config.reconnectInterval.inMilliseconds,
      'maxReconnectAttempts': config.maxReconnectAttempts,
      'heartbeatInterval': config.heartbeatInterval.inMilliseconds,
      'connectionTimeout': getConnectionTimeout().inMilliseconds,
      'messageQueueSize': getMessageQueueSize(),
      'channels': getChannels(),
      'features': getFeatureFlags(),
    };
  }

  /// Validate current configuration
  bool validateConfiguration() {
    try {
      final config = getConfig();
      
      // Basic validation checks
      if (config.url.isEmpty) {
        debugPrint('WebSocket configuration validation failed: URL is empty');
        return false;
      }
      
      if (!config.url.startsWith('ws://') && !config.url.startsWith('wss://')) {
        debugPrint('WebSocket configuration validation failed: Invalid URL scheme');
        return false;
      }
      
      if (config.maxReconnectAttempts < 0) {
        debugPrint('WebSocket configuration validation failed: Invalid max reconnect attempts');
        return false;
      }
      
      if (config.reconnectInterval.inMilliseconds < 1000) {
        debugPrint('WebSocket configuration validation failed: Reconnect interval too short');
        return false;
      }
      
      if (config.heartbeatInterval.inMilliseconds < 5000) {
        debugPrint('WebSocket configuration validation failed: Heartbeat interval too short');
        return false;
      }
      
      if (getConnectionTimeout().inMilliseconds < 1000) {
        debugPrint('WebSocket configuration validation failed: Connection timeout too short');
        return false;
      }
      
      if (getMessageQueueSize() < 100) {
        debugPrint('WebSocket configuration validation failed: Message queue size too small');
        return false;
      }
      
      debugPrint('WebSocket configuration validation passed');
      return true;
    } catch (e) {
      debugPrint('WebSocket configuration validation failed with error: $e');
      return false;
    }
  }

  /// Reset cached configuration (useful for testing or environment changes)
  void resetCache() {
    _cachedConfig = null;
    debugPrint('WebSocket configuration cache reset');
  }

  /// Get default WebSocket configuration
  WebSocketConfig _getDefaultConfig() {
    return WebSocketConfig(
      url: _getDefaultWebSocketUrl(),
      reconnectInterval: const Duration(seconds: 5),
      maxReconnectAttempts: 5,
      heartbeatInterval: const Duration(seconds: 30),
      autoReconnect: true,
    );
  }

  /// Get default WebSocket URL based on environment
  String _getDefaultWebSocketUrl() {
    final apiBaseUrl = _environmentService.apiBaseUrl;
    
    // Convert HTTP/HTTPS to WS/WSS
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    } else if (apiBaseUrl.startsWith('http://')) {
      return apiBaseUrl.replaceFirst('http://', 'ws://');
    }
    
    // Fallback to localhost for development
    return 'ws://localhost:3000';
  }

  /// Get configuration for specific environment (useful for testing)
  Future<WebSocketConfig> getConfigForEnvironment(String environment) async {
    // Temporarily switch environment
    final currentEnv = _environmentService.currentEnvironment;
    
    try {
      await _environmentService.initialize(environment);
      final config = getConfig();
      return config;
    } finally {
      // Restore original environment
      if (currentEnv != null) {
        await _environmentService.initialize(currentEnv);
      }
      resetCache();
    }
  }

  @override
  String toString() {
    if (_cachedConfig == null) {
      return 'WebSocketConfigManager(not initialized)';
    }
    return 'WebSocketConfigManager(${_environmentService.environmentName}: ${_cachedConfig!.url})';
  }
}