import 'dart:async';
import 'dart:convert';
import 'package:data/sharedpref/shared_preference_helper.dart';
import '../../domain/repository/websocket_preferences_repository.dart';
import '../../models/websocket_preferences.dart';
import '../../models/websocket_channel_config.dart';

class WebSocketPreferencesRepositoryImpl implements WebSocketPreferencesRepository {
  final SharedPreferenceHelper _sharedPrefsHelper;
  final StreamController<WebSocketPreferences> _preferencesController = 
      StreamController<WebSocketPreferences>.broadcast();

  WebSocketPreferences? _cachedPreferences;

  WebSocketPreferencesRepositoryImpl(this._sharedPrefsHelper);

  static const String _preferencesKey = 'websocket_preferences';

  @override
  Future<WebSocketPreferences> getPreferences() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    try {
      final prefsString = _sharedPrefsHelper.sharedPreferences.getString(_preferencesKey);
      if (prefsString != null) {
        final json = jsonDecode(prefsString) as Map<String, dynamic>;
        _cachedPreferences = WebSocketPreferences.fromJson(json);
      } else {
        _cachedPreferences = _getDefaultPreferences();
        await savePreferences(_cachedPreferences!);
      }
    } catch (e) {
      // If there's an error parsing preferences, use defaults
      _cachedPreferences = _getDefaultPreferences();
      await savePreferences(_cachedPreferences!);
    }

    return _cachedPreferences!;
  }

  @override
  Future<void> savePreferences(WebSocketPreferences preferences) async {
    _cachedPreferences = preferences;
    final json = preferences.toJson();
    final prefsString = jsonEncode(json);
    await _sharedPrefsHelper.sharedPreferences.setString(_preferencesKey, prefsString);
    _preferencesController.add(preferences);
  }

  @override
  List<WebSocketChannelConfig> getAvailableChannels() {
    return [
      const WebSocketChannelConfig(
        id: 'customer',
        name: 'Customer Updates',
        description: 'Real-time updates for customer information changes',
        type: WebSocketChannelType.customer,
        defaultPriority: NotificationPriority.normal,
      ),
      const WebSocketChannelConfig(
        id: 'inventory',
        name: 'Inventory Changes',
        description: 'Live inventory level changes and stock updates',
        type: WebSocketChannelType.inventory,
        defaultPriority: NotificationPriority.high,
      ),
      const WebSocketChannelConfig(
        id: 'order',
        name: 'Order Status',
        description: 'Order status changes and fulfillment updates',
        type: WebSocketChannelType.order,
        defaultPriority: NotificationPriority.high,
      ),
      const WebSocketChannelConfig(
        id: 'system',
        name: 'System Notifications',
        description: 'System-wide notifications and alerts',
        type: WebSocketChannelType.system,
        defaultPriority: NotificationPriority.critical,
        userConfigurable: false,
      ),
      const WebSocketChannelConfig(
        id: 'notification',
        name: 'General Notifications',
        description: 'General application notifications',
        type: WebSocketChannelType.notification,
        defaultPriority: NotificationPriority.normal,
      ),
    ];
  }

  @override
  Future<void> setChannelEnabled(String channelId, bool enabled) async {
    final currentPrefs = await getPreferences();
    final updatedChannelPrefs = Map<String, bool>.from(currentPrefs.channelPreferences);
    updatedChannelPrefs[channelId] = enabled;

    final updatedSubscribedChannels = Set<String>.from(currentPrefs.subscribedChannels);
    if (enabled) {
      updatedSubscribedChannels.add(channelId);
    } else {
      updatedSubscribedChannels.remove(channelId);
    }

    final updatedPrefs = currentPrefs.copyWith(
      channelPreferences: updatedChannelPrefs,
      subscribedChannels: updatedSubscribedChannels,
    );

    await savePreferences(updatedPrefs);
  }

  @override
  Future<void> setChannelPriority(String channelId, NotificationPriority priority) async {
    final currentPrefs = await getPreferences();
    final updatedPriorities = Map<String, NotificationPriority>.from(currentPrefs.notificationPriorities);
    updatedPriorities[channelId] = priority;

    final updatedPrefs = currentPrefs.copyWith(
      notificationPriorities: updatedPriorities,
    );

    await savePreferences(updatedPrefs);
  }

  @override
  Future<void> setRealTimeUpdatesEnabled(bool enabled) async {
    final currentPrefs = await getPreferences();
    final updatedPrefs = currentPrefs.copyWith(enableRealTimeUpdates: enabled);
    await savePreferences(updatedPrefs);
  }

  @override
  Future<void> setConnectionStatusEnabled(bool enabled) async {
    final currentPrefs = await getPreferences();
    final updatedPrefs = currentPrefs.copyWith(showConnectionStatus: enabled);
    await savePreferences(updatedPrefs);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    final currentPrefs = await getPreferences();
    final updatedPrefs = currentPrefs.copyWith(enableNotifications: enabled);
    await savePreferences(updatedPrefs);
  }

  @override
  Set<String> getSubscribedChannels() {
    if (_cachedPreferences == null) {
      return _getDefaultPreferences().subscribedChannels;
    }
    return _cachedPreferences!.subscribedChannels;
  }

  @override
  bool shouldShowNotification(String channelId, NotificationPriority priority) {
    if (_cachedPreferences == null) {
      return true;
    }

    final prefs = _cachedPreferences!;
    
    // Check if notifications are globally enabled
    if (!prefs.enableNotifications) {
      return false;
    }

    // Check if the channel is enabled
    final channelEnabled = prefs.channelPreferences[channelId] ?? true;
    if (!channelEnabled) {
      return false;
    }

    // Check priority threshold
    final channelPriority = prefs.notificationPriorities[channelId] ?? NotificationPriority.normal;
    return priority.value >= channelPriority.value;
  }

  @override
  Future<void> resetToDefaults() async {
    final defaultPrefs = _getDefaultPreferences();
    await savePreferences(defaultPrefs);
  }

  @override
  Stream<WebSocketPreferences> get preferencesStream => _preferencesController.stream;

  WebSocketPreferences _getDefaultPreferences() {
    final availableChannels = getAvailableChannels();
    final defaultChannelPrefs = <String, bool>{};
    final defaultPriorities = <String, NotificationPriority>{};
    final defaultSubscribedChannels = <String>{};

    for (final channel in availableChannels) {
      defaultChannelPrefs[channel.id] = channel.defaultEnabled;
      defaultPriorities[channel.id] = channel.defaultPriority;
      if (channel.defaultEnabled) {
        defaultSubscribedChannels.add(channel.id);
      }
    }

    return WebSocketPreferences(
      enableRealTimeUpdates: true,
      subscribedChannels: defaultSubscribedChannels,
      showConnectionStatus: true,
      enableNotifications: true,
      channelPreferences: defaultChannelPrefs,
      notificationPriorities: defaultPriorities,
    );
  }



  void dispose() {
    _preferencesController.close();
  }
}