import 'package:flutter/foundation.dart';
import 'websocket_config_manager.dart';

/// Manages WebSocket feature flags and provides runtime feature checking
class WebSocketFeatureManager {
  static final WebSocketFeatureManager _instance = WebSocketFeatureManager._internal();
  factory WebSocketFeatureManager() => _instance;
  WebSocketFeatureManager._internal();

  final WebSocketConfigManager _configManager = WebSocketConfigManager();
  final Map<String, bool> _runtimeOverrides = {};

  /// Available WebSocket features
  static const String realTimeUpdates = 'realTimeUpdates';
  static const String offlineSupport = 'offlineSupport';
  static const String backgroundSync = 'backgroundSync';
  static const String pushNotifications = 'pushNotifications';

  /// Get all available feature names
  static List<String> get availableFeatures => [
    realTimeUpdates,
    offlineSupport,
    backgroundSync,
    pushNotifications,
  ];

  /// Check if a specific feature is enabled
  bool isFeatureEnabled(String featureName) {
    // Check runtime overrides first
    if (_runtimeOverrides.containsKey(featureName)) {
      final overrideValue = _runtimeOverrides[featureName]!;
      debugPrint('WebSocket feature $featureName using runtime override: $overrideValue');
      return overrideValue;
    }

    // Fall back to configuration
    switch (featureName) {
      case realTimeUpdates:
        return _configManager.isRealTimeUpdatesEnabled();
      case offlineSupport:
        return _configManager.isOfflineSupportEnabled();
      case backgroundSync:
        return _configManager.isBackgroundSyncEnabled();
      case pushNotifications:
        return _configManager.isPushNotificationsEnabled();
      default:
        debugPrint('Unknown WebSocket feature: $featureName');
        return false;
    }
  }

  /// Check if real-time updates are enabled
  bool get isRealTimeUpdatesEnabled => isFeatureEnabled(realTimeUpdates);

  /// Check if offline support is enabled
  bool get isOfflineSupportEnabled => isFeatureEnabled(offlineSupport);

  /// Check if background sync is enabled
  bool get isBackgroundSyncEnabled => isFeatureEnabled(backgroundSync);

  /// Check if push notifications are enabled
  bool get isPushNotificationsEnabled => isFeatureEnabled(pushNotifications);

  /// Get all feature flags as a map
  Map<String, bool> getAllFeatureFlags() {
    final flags = <String, bool>{};
    for (final feature in availableFeatures) {
      flags[feature] = isFeatureEnabled(feature);
    }
    return flags;
  }

  /// Set a runtime override for a feature (useful for testing or user preferences)
  void setFeatureOverride(String featureName, bool enabled) {
    if (!availableFeatures.contains(featureName)) {
      debugPrint('Warning: Unknown feature name $featureName');
      return;
    }

    _runtimeOverrides[featureName] = enabled;
    debugPrint('WebSocket feature $featureName override set to: $enabled');
  }

  /// Remove a runtime override for a feature
  void removeFeatureOverride(String featureName) {
    if (_runtimeOverrides.remove(featureName) != null) {
      debugPrint('WebSocket feature $featureName override removed');
    }
  }

  /// Clear all runtime overrides
  void clearAllOverrides() {
    final count = _runtimeOverrides.length;
    _runtimeOverrides.clear();
    debugPrint('Cleared $count WebSocket feature overrides');
  }

  /// Get current runtime overrides
  Map<String, bool> getRuntimeOverrides() {
    return Map.from(_runtimeOverrides);
  }

  /// Check if WebSocket functionality should be enabled at all
  bool get isWebSocketEnabled => _configManager.isEnabled();

  /// Get feature configuration summary
  Map<String, dynamic> getFeatureSummary() {
    return {
      'websocketEnabled': isWebSocketEnabled,
      'features': getAllFeatureFlags(),
      'runtimeOverrides': getRuntimeOverrides(),
      'environment': _configManager.getConfigSummary()['environment'],
    };
  }

  /// Validate feature configuration
  bool validateFeatureConfiguration() {
    try {
      // Check if WebSocket is enabled
      if (!isWebSocketEnabled) {
        debugPrint('WebSocket feature validation: WebSocket is disabled');
        return true; // This is valid - WebSocket can be disabled
      }

      // Validate feature dependencies
      if (isBackgroundSyncEnabled && !isOfflineSupportEnabled) {
        debugPrint('WebSocket feature validation warning: Background sync enabled but offline support disabled');
        // This is a warning, not an error
      }

      if (isPushNotificationsEnabled && !isRealTimeUpdatesEnabled) {
        debugPrint('WebSocket feature validation warning: Push notifications enabled but real-time updates disabled');
        // This is a warning, not an error
      }

      debugPrint('WebSocket feature configuration validation passed');
      return true;
    } catch (e) {
      debugPrint('WebSocket feature configuration validation failed: $e');
      return false;
    }
  }

  /// Enable a feature at runtime (creates override)
  void enableFeature(String featureName) {
    setFeatureOverride(featureName, true);
  }

  /// Disable a feature at runtime (creates override)
  void disableFeature(String featureName) {
    setFeatureOverride(featureName, false);
  }

  /// Toggle a feature at runtime (creates override)
  void toggleFeature(String featureName) {
    final currentState = isFeatureEnabled(featureName);
    setFeatureOverride(featureName, !currentState);
  }

  /// Get feature description for UI display
  String getFeatureDescription(String featureName) {
    switch (featureName) {
      case realTimeUpdates:
        return 'Receive live updates for inventory, customers, and orders';
      case offlineSupport:
        return 'Queue updates when offline and sync when reconnected';
      case backgroundSync:
        return 'Sync data when app returns from background';
      case pushNotifications:
        return 'Show notifications for important real-time events';
      default:
        return 'Unknown feature';
    }
  }

  /// Get feature display name for UI
  String getFeatureDisplayName(String featureName) {
    switch (featureName) {
      case realTimeUpdates:
        return 'Real-time Updates';
      case offlineSupport:
        return 'Offline Support';
      case backgroundSync:
        return 'Background Sync';
      case pushNotifications:
        return 'Push Notifications';
      default:
        return featureName;
    }
  }

  /// Check if feature can be toggled by user
  bool isFeatureUserToggleable(String featureName) {
    // All features can be toggled by user except core functionality
    return availableFeatures.contains(featureName);
  }

  /// Reset all feature settings to configuration defaults
  void resetToDefaults() {
    clearAllOverrides();
    debugPrint('WebSocket features reset to configuration defaults');
  }

  @override
  String toString() {
    final enabledFeatures = availableFeatures.where(isFeatureEnabled).toList();
    return 'WebSocketFeatureManager(enabled: ${enabledFeatures.length}/${availableFeatures.length})';
  }
}