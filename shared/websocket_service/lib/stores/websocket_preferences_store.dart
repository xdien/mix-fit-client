import 'package:mobx/mobx.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/utils/error_migration_helper.dart';
import '../domain/repository/websocket_preferences_repository.dart';
import '../models/websocket_preferences.dart';
import '../models/websocket_channel_config.dart';

part 'websocket_preferences_store.g.dart';

class WebSocketPreferencesStore = _WebSocketPreferencesStore with _$WebSocketPreferencesStore;

abstract class _WebSocketPreferencesStore with Store {
  final String TAG = "_WebSocketPreferencesStore";

  // repository instance
  final WebSocketPreferencesRepository _repository;

  // error migration helper for shared error system
  final ErrorMigrationHelper _errorMigrationHelper;

  // store variables:-----------------------------------------------------------
  @observable
  WebSocketPreferences? _preferences;

  @observable
  List<WebSocketChannelConfig> _availableChannels = [];

  @observable
  bool _isLoading = false;

  // getters:-------------------------------------------------------------------
  WebSocketPreferences? get preferences => _preferences;
  List<WebSocketChannelConfig> get availableChannels => _availableChannels;
  bool get isLoading => _isLoading;

  bool get enableRealTimeUpdates => _preferences?.enableRealTimeUpdates ?? true;
  bool get showConnectionStatus => _preferences?.showConnectionStatus ?? true;
  bool get enableNotifications => _preferences?.enableNotifications ?? true;
  Set<String> get subscribedChannels => _preferences?.subscribedChannels ?? {};

  // constructor:---------------------------------------------------------------
  _WebSocketPreferencesStore(this._repository, IErrorService errorService) 
      : _errorMigrationHelper = ErrorMigrationHelper(errorService) {
    init();
  }

  // actions:-------------------------------------------------------------------
  @action
  Future<void> init() async {
    try {
      _isLoading = true;
      _availableChannels = _repository.getAvailableChannels();
      _preferences = await _repository.getPreferences();
      
      // Listen to preference changes
      _repository.preferencesStream.listen((prefs) {
        runInAction(() {
          _preferences = prefs;
        });
      });
    } catch (e) {
      _errorMigrationHelper.migrateWebSocketError(
        'Failed to load WebSocket preferences: $e',
        operation: 'init',
      );
    } finally {
      _isLoading = false;
    }
  }

  @action
  Future<void> setRealTimeUpdatesEnabled(bool enabled) async {
    try {
      await _repository.setRealTimeUpdatesEnabled(enabled);
    } catch (e) {
      _errorMigrationHelper.migrateWebSocketError(
        'Failed to update real-time settings: $e',
        operation: 'setRealTimeUpdatesEnabled',
        metadata: {'enabled': enabled},
      );
    }
  }

  @action
  Future<void> setConnectionStatusEnabled(bool enabled) async {
    try {
      await _repository.setConnectionStatusEnabled(enabled);
    } catch (e) {
      _errorMigrationHelper.migrateWebSocketError(
        'Failed to update connection status settings: $e',
        operation: 'setConnectionStatusEnabled',
        metadata: {'enabled': enabled},
      );
    }
  }

  @action
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _repository.setNotificationsEnabled(enabled);
    } catch (e) {
      _errorMigrationHelper.migrateWebSocketError(
        'Failed to update notification settings: $e',
        operation: 'setNotificationsEnabled',
        metadata: {'enabled': enabled},
      );
    }
  }

  @action
  Future<void> setChannelEnabled(String channelId, bool enabled) async {
    try {
      await _repository.setChannelEnabled(channelId, enabled);
    } catch (e) {
      _errorMigrationHelper.migrateWebSocketError(
        'Failed to update channel settings: $e',
        operation: 'setChannelEnabled',
        channel: channelId,
        metadata: {'enabled': enabled},
      );
    }
  }

  @action
  Future<void> setChannelPriority(String channelId, NotificationPriority priority) async {
    try {
      await _repository.setChannelPriority(channelId, priority);
    } catch (e) {
      _errorMigrationHelper.migrateWebSocketError(
        'Failed to update channel priority: $e',
        operation: 'setChannelPriority',
        channel: channelId,
        metadata: {'priority': priority.toString()},
      );
    }
  }

  @action
  Future<void> resetToDefaults() async {
    try {
      _isLoading = true;
      await _repository.resetToDefaults();
    } catch (e) {
      _errorMigrationHelper.migrateWebSocketError(
        'Failed to reset preferences: $e',
        operation: 'resetToDefaults',
      );
    } finally {
      _isLoading = false;
    }
  }

  // computed:------------------------------------------------------------------
  bool isChannelEnabled(String channelId) {
    return _preferences?.channelPreferences[channelId] ?? true;
  }

  NotificationPriority getChannelPriority(String channelId) {
    return _preferences?.notificationPriorities[channelId] ?? NotificationPriority.normal;
  }

  bool shouldShowNotification(String channelId, NotificationPriority priority) {
    return _repository.shouldShowNotification(channelId, priority);
  }

  @computed
  Set<String> get activeSubscribedChannels {
    if (_preferences == null || !_preferences!.enableRealTimeUpdates) {
      return {};
    }
    return _preferences!.subscribedChannels;
  }

  // general methods:-----------------------------------------------------------
  WebSocketChannelConfig? getChannelConfig(String channelId) {
    try {
      return _availableChannels.firstWhere((channel) => channel.id == channelId);
    } catch (e) {
      return null;
    }
  }

  bool isChannelUserConfigurable(String channelId) {
    final config = getChannelConfig(channelId);
    return config?.userConfigurable ?? true;
  }

  // dispose:-------------------------------------------------------------------
  void dispose() {}
}