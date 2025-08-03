import 'dart:async';
import 'dart:developer' as developer;
import 'package:mobx/mobx.dart';
import '../models/websocket_preferences.dart';
import '../models/websocket_message_type.dart';
import '../services/websocket_preferences_service.dart';

part 'websocket_preferences_store.g.dart';

/// MobX store for managing WebSocket preferences in the UI
class WebSocketPreferencesStore = _WebSocketPreferencesStore with _$WebSocketPreferencesStore;

abstract class _WebSocketPreferencesStore with Store {
  final WebSocketPreferencesService _preferencesService;
  StreamSubscription<WebSocketPreferences>? _preferencesSubscription;

  _WebSocketPreferencesStore(this._preferencesService) {
    _initializeStore();
  }

  // Observable state
  @observable
  WebSocketPreferences preferences = WebSocketPreferencesExtension.createDefault();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  // Computed values
  @computed
  bool get isRealTimeEnabled => preferences.enableRealTimeUpdates;

  @computed
  bool get isConnectionStatusVisible => preferences.showConnectionStatus;

  @computed
  bool get areNotificationsEnabled => preferences.enableNotifications;

  @computed
  bool get areSoundNotificationsEnabled => preferences.enableSoundNotifications;

  @computed
  bool get areVibrationNotificationsEnabled => preferences.enableVibrationNotifications;

  @computed
  bool get areForegroundNotificationsEnabled => preferences.showForegroundNotifications;

  @computed
  bool get isOfflineQueueEnabled => preferences.enableOfflineMessageQueue;

  @computed
  bool get isAutoReconnectEnabled => preferences.enableAutoReconnect;

  @computed
  int get maxQueuedMessages => preferences.maxQueuedMessages;

  @computed
  int get heartbeatInterval => preferences.heartbeatIntervalSeconds;

  @computed
  Set<WebSocketMessageType> get enabledMessageTypes => preferences.subscribedMessageTypes;

  @computed
  Set<String> get enabledChannels => preferences.subscribedChannels;

  @computed
  Map<WebSocketMessageType, int> get messagePriorities => preferences.messagePriorities;

  // Actions
  @action
  Future<void> _initializeStore() async {
    developer.log('Initializing WebSocket preferences store', name: 'WebSocketPreferencesStore');
    
    isLoading = true;
    errorMessage = null;

    try {
      // Load current preferences
      preferences = _preferencesService.currentPreferences;
      
      // Listen to preference changes
      _preferencesSubscription = _preferencesService.preferencesStream.listen(
        (newPreferences) {
          runInAction(() {
            preferences = newPreferences;
          });
        },
        onError: (error) {
          runInAction(() {
            errorMessage = 'Error loading preferences: $error';
          });
        },
      );
      
      developer.log('WebSocket preferences store initialized', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error initializing preferences store: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to initialize preferences: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setRealTimeEnabled(bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setRealTimeUpdatesEnabled(enabled);
      developer.log('Real-time updates ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting real-time enabled: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update real-time setting: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setConnectionStatusVisible(bool visible) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setConnectionStatusEnabled(visible);
      developer.log('Connection status visibility ${visible ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting connection status visibility: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update connection status setting: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setNotificationsEnabled(enabled);
      developer.log('Notifications ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting notifications enabled: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update notifications setting: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setSoundNotificationsEnabled(bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setSoundNotificationsEnabled(enabled);
      developer.log('Sound notifications ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting sound notifications: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update sound notifications: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setVibrationNotificationsEnabled(bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setVibrationNotificationsEnabled(enabled);
      developer.log('Vibration notifications ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting vibration notifications: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update vibration notifications: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setForegroundNotificationsEnabled(bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setForegroundNotificationsEnabled(enabled);
      developer.log('Foreground notifications ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting foreground notifications: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update foreground notifications: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setMessageTypeEnabled(WebSocketMessageType messageType, bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setMessageTypeEnabled(messageType, enabled);
      developer.log('Message type $messageType ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting message type enabled: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update message type setting: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setChannelEnabled(String channel, bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setChannelEnabled(channel, enabled);
      developer.log('Channel $channel ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting channel enabled: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update channel setting: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setMessageTypePriority(WebSocketMessageType messageType, int priority) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setMessageTypePriority(messageType, priority);
      developer.log('Message type $messageType priority set to $priority', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting message type priority: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update message priority: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setOfflineQueueEnabled(bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setOfflineMessageQueueEnabled(enabled);
      developer.log('Offline queue ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting offline queue: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update offline queue setting: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setMaxQueuedMessages(int maxMessages) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setMaxQueuedMessages(maxMessages);
      developer.log('Max queued messages set to $maxMessages', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting max queued messages: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update max queued messages: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setAutoReconnectEnabled(bool enabled) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setAutoReconnectEnabled(enabled);
      developer.log('Auto-reconnect ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting auto-reconnect: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update auto-reconnect setting: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> setHeartbeatInterval(int intervalSeconds) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.setHeartbeatInterval(intervalSeconds);
      developer.log('Heartbeat interval set to $intervalSeconds seconds', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error setting heartbeat interval: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to update heartbeat interval: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  Future<void> resetToDefaults() async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;

    try {
      await _preferencesService.resetToDefaults();
      developer.log('Preferences reset to defaults', name: 'WebSocketPreferencesStore');
    } catch (error) {
      developer.log('Error resetting preferences: $error', name: 'WebSocketPreferencesStore');
      runInAction(() {
        errorMessage = 'Failed to reset preferences: $error';
      });
    } finally {
      runInAction(() {
        isLoading = false;
      });
    }
  }

  @action
  void clearError() {
    errorMessage = null;
  }

  // Helper methods
  bool isMessageTypeEnabled(WebSocketMessageType messageType) {
    return preferences.isMessageTypeEnabled(messageType);
  }

  bool isChannelEnabled(String channel) {
    return preferences.isChannelEnabled(channel);
  }

  int getMessageTypePriority(WebSocketMessageType messageType) {
    return preferences.getPriorityForMessageType(messageType);
  }

  void dispose() {
    developer.log('Disposing WebSocket preferences store', name: 'WebSocketPreferencesStore');
    _preferencesSubscription?.cancel();
  }
}