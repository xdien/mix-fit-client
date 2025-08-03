import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/websocket_preferences.dart';
import '../models/websocket_message_type.dart';
import '../interfaces/i_websocket_service.dart';

/// Service for managing WebSocket user preferences and subscription controls
class WebSocketPreferencesService {
  static const String _preferencesKey = 'websocket_preferences';
  
  final SharedPreferences _sharedPreferences;
  final IWebSocketService? _webSocketService;
  
  final StreamController<WebSocketPreferences> _preferencesController =
      StreamController<WebSocketPreferences>.broadcast();
  
  WebSocketPreferences _currentPreferences = WebSocketPreferencesExtension.createDefault();
  
  WebSocketPreferencesService(
    this._sharedPreferences, {
    IWebSocketService? webSocketService,
  }) : _webSocketService = webSocketService;

  /// Stream of preference changes
  Stream<WebSocketPreferences> get preferencesStream => _preferencesController.stream;

  /// Current preferences
  WebSocketPreferences get currentPreferences => _currentPreferences;

  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    developer.log('Initializing WebSocket preferences service', name: 'WebSocketPreferencesService');
    
    try {
      await _loadPreferences();
      await _applyPreferencesToWebSocket();
      developer.log('WebSocket preferences initialized successfully', name: 'WebSocketPreferencesService');
    } catch (error) {
      developer.log('Error initializing WebSocket preferences: $error', name: 'WebSocketPreferencesService');
      // Use default preferences if loading fails
      _currentPreferences = WebSocketPreferencesExtension.createDefault();
      await _savePreferences();
    }
  }

  /// Load preferences from shared preferences
  Future<void> _loadPreferences() async {
    final preferencesJson = _sharedPreferences.getString(_preferencesKey);
    
    if (preferencesJson != null) {
      try {
        final preferencesMap = jsonDecode(preferencesJson) as Map<String, dynamic>;
        _currentPreferences = WebSocketPreferences.fromJson(preferencesMap);
        developer.log('Loaded WebSocket preferences from storage', name: 'WebSocketPreferencesService');
      } catch (error) {
        developer.log('Error parsing saved preferences: $error', name: 'WebSocketPreferencesService');
        _currentPreferences = WebSocketPreferencesExtension.createDefault();
      }
    } else {
      developer.log('No saved preferences found, using defaults', name: 'WebSocketPreferencesService');
      _currentPreferences = WebSocketPreferencesExtension.createDefault();
    }
    
    _emitPreferences();
  }

  /// Save preferences to shared preferences
  Future<void> _savePreferences() async {
    try {
      final preferencesJson = jsonEncode(_currentPreferences.toJson());
      await _sharedPreferences.setString(_preferencesKey, preferencesJson);
      developer.log('Saved WebSocket preferences to storage', name: 'WebSocketPreferencesService');
    } catch (error) {
      developer.log('Error saving preferences: $error', name: 'WebSocketPreferencesService');
      rethrow;
    }
  }

  /// Apply current preferences to the WebSocket service
  Future<void> _applyPreferencesToWebSocket() async {
    if (_webSocketService == null) {
      developer.log('No WebSocket service available to apply preferences', name: 'WebSocketPreferencesService');
      return;
    }

    try {
      // Unsubscribe from all channels first
      await _unsubscribeFromAllChannels();
      
      // Subscribe to enabled channels based on preferences
      if (_currentPreferences.enableRealTimeUpdates) {
        for (final channel in _currentPreferences.subscribedChannels) {
          _webSocketService!.subscribe(channel, _createChannelCallback(channel));
          developer.log('Subscribed to channel: $channel', name: 'WebSocketPreferencesService');
        }
      }
      
      developer.log('Applied preferences to WebSocket service', name: 'WebSocketPreferencesService');
    } catch (error) {
      developer.log('Error applying preferences to WebSocket: $error', name: 'WebSocketPreferencesService');
    }
  }

  /// Create a callback function for a specific channel
  Function(dynamic) _createChannelCallback(String channel) {
    return (dynamic data) {
      developer.log('Received message on channel $channel: $data', name: 'WebSocketPreferencesService');
      
      // Extract message type from data if available
      WebSocketMessageType? messageType;
      if (data is Map<String, dynamic> && data.containsKey('type')) {
        messageType = WebSocketMessageType.fromString(data['type'] as String);
      }
      
      // Check if this message type should be processed
      if (messageType != null && !_currentPreferences.isMessageTypeEnabled(messageType)) {
        developer.log('Message type $messageType is disabled, ignoring', name: 'WebSocketPreferencesService');
        return;
      }
      
      // Process the message based on preferences
      _processChannelMessage(channel, data, messageType);
    };
  }

  /// Process a message received on a channel
  void _processChannelMessage(String channel, dynamic data, WebSocketMessageType? messageType) {
    developer.log('Processing message on channel $channel with type $messageType', name: 'WebSocketPreferencesService');
    
    // Here you would typically:
    // 1. Check notification preferences
    // 2. Filter based on priority
    // 3. Show notifications if appropriate
    // 4. Update local data stores
    
    // For now, just log the processing
    if (messageType != null) {
      final priority = _currentPreferences.getPriorityForMessageType(messageType);
      developer.log('Message priority: $priority', name: 'WebSocketPreferencesService');
      
      // Check if notification should be shown
      final shouldNotify = _currentPreferences.shouldShowNotification(messageType, true); // Assuming foreground for now
      if (shouldNotify) {
        developer.log('Should show notification for message type $messageType', name: 'WebSocketPreferencesService');
      }
    }
  }

  /// Unsubscribe from all currently subscribed channels
  Future<void> _unsubscribeFromAllChannels() async {
    if (_webSocketService == null) return;
    
    // Get all possible channels that might be subscribed
    final allChannels = {
      'inventory',
      'customers', 
      'orders',
      'system',
      ...WebSocketMessageType.values.map((type) => type.value),
    };
    
    for (final channel in allChannels) {
      _webSocketService!.unsubscribe(channel);
    }
    
    developer.log('Unsubscribed from all channels', name: 'WebSocketPreferencesService');
  }

  /// Update preferences and apply changes
  Future<void> updatePreferences(WebSocketPreferences newPreferences) async {
    developer.log('Updating WebSocket preferences', name: 'WebSocketPreferencesService');
    
    final oldPreferences = _currentPreferences;
    _currentPreferences = newPreferences.withUpdatedTimestamp();
    
    try {
      await _savePreferences();
      await _applyPreferencesToWebSocket();
      _emitPreferences();
      
      developer.log('WebSocket preferences updated successfully', name: 'WebSocketPreferencesService');
    } catch (error) {
      developer.log('Error updating preferences: $error', name: 'WebSocketPreferencesService');
      // Revert to old preferences on error
      _currentPreferences = oldPreferences;
      _emitPreferences();
      rethrow;
    }
  }

  /// Enable or disable real-time updates globally
  Future<void> setRealTimeUpdatesEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      enableRealTimeUpdates: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable a specific message type
  Future<void> setMessageTypeEnabled(WebSocketMessageType messageType, bool enabled) async {
    final updatedPreferences = _currentPreferences.withMessageTypeEnabled(messageType, enabled);
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable a specific channel
  Future<void> setChannelEnabled(String channel, bool enabled) async {
    final updatedPreferences = _currentPreferences.withChannelEnabled(channel, enabled);
    await updatePreferences(updatedPreferences);
  }

  /// Set priority for a message type
  Future<void> setMessageTypePriority(WebSocketMessageType messageType, int priority) async {
    final updatedPreferences = _currentPreferences.withMessageTypePriority(messageType, priority);
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable connection status display
  Future<void> setConnectionStatusEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      showConnectionStatus: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      enableNotifications: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable sound notifications
  Future<void> setSoundNotificationsEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      enableSoundNotifications: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable vibration notifications
  Future<void> setVibrationNotificationsEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      enableVibrationNotifications: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable foreground notifications
  Future<void> setForegroundNotificationsEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      showForegroundNotifications: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable offline message queue
  Future<void> setOfflineMessageQueueEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      enableOfflineMessageQueue: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Set maximum number of queued messages
  Future<void> setMaxQueuedMessages(int maxMessages) async {
    final updatedPreferences = _currentPreferences.copyWith(
      maxQueuedMessages: maxMessages.clamp(10, 1000),
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Enable or disable auto-reconnect
  Future<void> setAutoReconnectEnabled(bool enabled) async {
    final updatedPreferences = _currentPreferences.copyWith(
      enableAutoReconnect: enabled,
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Set heartbeat interval in seconds
  Future<void> setHeartbeatInterval(int intervalSeconds) async {
    final updatedPreferences = _currentPreferences.copyWith(
      heartbeatIntervalSeconds: intervalSeconds.clamp(10, 300),
      lastUpdated: DateTime.now(),
    );
    await updatePreferences(updatedPreferences);
  }

  /// Reset preferences to default values
  Future<void> resetToDefaults() async {
    developer.log('Resetting WebSocket preferences to defaults', name: 'WebSocketPreferencesService');
    final defaultPreferences = WebSocketPreferencesExtension.createDefault();
    await updatePreferences(defaultPreferences);
  }

  /// Check if a message should be filtered based on preferences
  bool shouldFilterMessage(WebSocketMessageType messageType, String channel, int priority) {
    // Check if real-time updates are enabled
    if (!_currentPreferences.enableRealTimeUpdates) {
      return true;
    }
    
    // Check if message type is enabled
    if (!_currentPreferences.isMessageTypeEnabled(messageType)) {
      return true;
    }
    
    // Check if channel is enabled
    if (!_currentPreferences.isChannelEnabled(channel)) {
      return true;
    }
    
    // Check priority threshold (could be configurable in the future)
    final messagePriority = _currentPreferences.getPriorityForMessageType(messageType);
    if (priority > 0 && messagePriority < priority) {
      return true;
    }
    
    return false;
  }

  /// Get notification settings for a message type
  NotificationSettings getNotificationSettings(WebSocketMessageType messageType, bool isAppInForeground) {
    return NotificationSettings(
      shouldShow: _currentPreferences.shouldShowNotification(messageType, isAppInForeground),
      shouldPlaySound: _currentPreferences.shouldPlaySound(messageType),
      shouldVibrate: _currentPreferences.shouldVibrate(messageType),
      priority: _currentPreferences.getPriorityForMessageType(messageType),
    );
  }

  /// Emit current preferences to listeners
  void _emitPreferences() {
    if (!_preferencesController.isClosed) {
      _preferencesController.add(_currentPreferences);
    }
  }

  /// Dispose of the service
  void dispose() {
    developer.log('Disposing WebSocket preferences service', name: 'WebSocketPreferencesService');
    _preferencesController.close();
  }
}

/// Helper class for notification settings
class NotificationSettings {
  final bool shouldShow;
  final bool shouldPlaySound;
  final bool shouldVibrate;
  final int priority;

  const NotificationSettings({
    required this.shouldShow,
    required this.shouldPlaySound,
    required this.shouldVibrate,
    required this.priority,
  });

  @override
  String toString() {
    return 'NotificationSettings(shouldShow: $shouldShow, shouldPlaySound: $shouldPlaySound, shouldVibrate: $shouldVibrate, priority: $priority)';
  }
}