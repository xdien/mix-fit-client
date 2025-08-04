import 'dart:async';
import '../../models/websocket_preferences.dart';
import '../../models/websocket_channel_config.dart';

abstract class WebSocketPreferencesRepository {
  /// Get current WebSocket preferences
  Future<WebSocketPreferences> getPreferences();

  /// Save WebSocket preferences
  Future<void> savePreferences(WebSocketPreferences preferences);

  /// Get available channel configurations
  List<WebSocketChannelConfig> getAvailableChannels();

  /// Enable/disable a specific channel
  Future<void> setChannelEnabled(String channelId, bool enabled);

  /// Set notification priority for a channel
  Future<void> setChannelPriority(String channelId, NotificationPriority priority);

  /// Enable/disable all real-time updates
  Future<void> setRealTimeUpdatesEnabled(bool enabled);

  /// Enable/disable connection status display
  Future<void> setConnectionStatusEnabled(bool enabled);

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled);

  /// Get subscribed channels based on preferences
  Set<String> getSubscribedChannels();

  /// Check if a channel should show notifications
  bool shouldShowNotification(String channelId, NotificationPriority priority);

  /// Reset preferences to default
  Future<void> resetToDefaults();

  /// Stream of preference changes
  Stream<WebSocketPreferences> get preferencesStream;
}