import 'package:freezed_annotation/freezed_annotation.dart';
import 'websocket_message_type.dart';

part 'websocket_preferences.freezed.dart';
part 'websocket_preferences.g.dart';

/// Model representing user preferences for WebSocket notifications and subscriptions
@freezed
class WebSocketPreferences with _$WebSocketPreferences {
  const factory WebSocketPreferences({
    /// Whether real-time updates are enabled globally
    @Default(true) bool enableRealTimeUpdates,
    
    /// Whether to show connection status indicators
    @Default(true) bool showConnectionStatus,
    
    /// Whether to enable push notifications for WebSocket events
    @Default(true) bool enableNotifications,
    
    /// Set of subscribed message types
    @Default({}) Set<WebSocketMessageType> subscribedMessageTypes,
    
    /// Set of subscribed channels
    @Default({}) Set<String> subscribedChannels,
    
    /// Priority levels for different message types (1-5, where 5 is highest)
    @Default({}) Map<WebSocketMessageType, int> messagePriorities,
    
    /// Whether to enable sound notifications
    @Default(false) bool enableSoundNotifications,
    
    /// Whether to enable vibration notifications
    @Default(true) bool enableVibrationNotifications,
    
    /// Whether to show notifications when app is in foreground
    @Default(true) bool showForegroundNotifications,
    
    /// Whether to queue messages when offline
    @Default(true) bool enableOfflineMessageQueue,
    
    /// Maximum number of queued messages
    @Default(100) int maxQueuedMessages,
    
    /// Auto-reconnect preference
    @Default(true) bool enableAutoReconnect,
    
    /// Heartbeat interval preference in seconds
    @Default(30) int heartbeatIntervalSeconds,
    
    /// Last updated timestamp
    DateTime? lastUpdated,
  }) = _WebSocketPreferences;

  factory WebSocketPreferences.fromJson(Map<String, dynamic> json) =>
      _$WebSocketPreferencesFromJson(json);
}

/// Extension to provide default preferences and utility methods
extension WebSocketPreferencesExtension on WebSocketPreferences {
  /// Create default preferences with all message types enabled
  static WebSocketPreferences createDefault() {
    return WebSocketPreferences(
      enableRealTimeUpdates: true,
      showConnectionStatus: true,
      enableNotifications: true,
      subscribedMessageTypes: {
        WebSocketMessageType.customerUpdate,
        WebSocketMessageType.inventoryUpdate,
        WebSocketMessageType.orderStatusUpdate,
        WebSocketMessageType.systemNotification,
      },
      subscribedChannels: {
        'inventory',
        'customers',
        'orders',
        'system',
      },
      messagePriorities: {
        WebSocketMessageType.systemNotification: 5,
        WebSocketMessageType.orderStatusUpdate: 4,
        WebSocketMessageType.inventoryUpdate: 3,
        WebSocketMessageType.customerUpdate: 2,
      },
      enableSoundNotifications: false,
      enableVibrationNotifications: true,
      showForegroundNotifications: true,
      enableOfflineMessageQueue: true,
      maxQueuedMessages: 100,
      enableAutoReconnect: true,
      heartbeatIntervalSeconds: 30,
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if a specific message type is enabled
  bool isMessageTypeEnabled(WebSocketMessageType messageType) {
    return enableRealTimeUpdates && subscribedMessageTypes.contains(messageType);
  }

  /// Check if a specific channel is enabled
  bool isChannelEnabled(String channel) {
    return enableRealTimeUpdates && subscribedChannels.contains(channel);
  }

  /// Get priority for a message type (default to 1 if not set)
  int getPriorityForMessageType(WebSocketMessageType messageType) {
    return messagePriorities[messageType] ?? 1;
  }

  /// Check if notifications should be shown for a message type
  bool shouldShowNotification(WebSocketMessageType messageType, bool isAppInForeground) {
    if (!enableNotifications || !isMessageTypeEnabled(messageType)) {
      return false;
    }
    
    if (isAppInForeground && !showForegroundNotifications) {
      return false;
    }
    
    return true;
  }

  /// Check if sound should be played for a notification
  bool shouldPlaySound(WebSocketMessageType messageType) {
    return enableSoundNotifications && isMessageTypeEnabled(messageType);
  }

  /// Check if vibration should be triggered for a notification
  bool shouldVibrate(WebSocketMessageType messageType) {
    return enableVibrationNotifications && isMessageTypeEnabled(messageType);
  }

  /// Create a copy with updated timestamp
  WebSocketPreferences withUpdatedTimestamp() {
    return copyWith(lastUpdated: DateTime.now());
  }

  /// Create a copy with a message type enabled/disabled
  WebSocketPreferences withMessageTypeEnabled(WebSocketMessageType messageType, bool enabled) {
    final updatedTypes = Set<WebSocketMessageType>.from(subscribedMessageTypes);
    if (enabled) {
      updatedTypes.add(messageType);
    } else {
      updatedTypes.remove(messageType);
    }
    return copyWith(
      subscribedMessageTypes: updatedTypes,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a copy with a channel enabled/disabled
  WebSocketPreferences withChannelEnabled(String channel, bool enabled) {
    final updatedChannels = Set<String>.from(subscribedChannels);
    if (enabled) {
      updatedChannels.add(channel);
    } else {
      updatedChannels.remove(channel);
    }
    return copyWith(
      subscribedChannels: updatedChannels,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a copy with updated priority for a message type
  WebSocketPreferences withMessageTypePriority(WebSocketMessageType messageType, int priority) {
    final updatedPriorities = Map<WebSocketMessageType, int>.from(messagePriorities);
    updatedPriorities[messageType] = priority.clamp(1, 5);
    return copyWith(
      messagePriorities: updatedPriorities,
      lastUpdated: DateTime.now(),
    );
  }
}