import 'package:flutter_test/flutter_test.dart';
import 'package:websocket_service/models/websocket_preferences.dart';

void main() {
  group('WebSocketPreferences', () {
    test('should create with default values', () {
      const preferences = WebSocketPreferences();

      expect(preferences.enableRealTimeUpdates, true);
      expect(preferences.subscribedChannels, isEmpty);
      expect(preferences.showConnectionStatus, true);
      expect(preferences.enableNotifications, true);
      expect(preferences.channelPreferences, isEmpty);
      expect(preferences.notificationPriorities, isEmpty);
    });

    test('should create with custom values', () {
      const preferences = WebSocketPreferences(
        enableRealTimeUpdates: false,
        subscribedChannels: {'customer', 'inventory'},
        showConnectionStatus: false,
        enableNotifications: false,
        channelPreferences: {'customer': true, 'inventory': false},
        notificationPriorities: {'customer': NotificationPriority.high},
      );

      expect(preferences.enableRealTimeUpdates, false);
      expect(preferences.subscribedChannels, {'customer', 'inventory'});
      expect(preferences.showConnectionStatus, false);
      expect(preferences.enableNotifications, false);
      expect(preferences.channelPreferences['customer'], true);
      expect(preferences.channelPreferences['inventory'], false);
      expect(preferences.notificationPriorities['customer'], NotificationPriority.high);
    });

    test('should serialize to and from JSON', () {
      const originalPreferences = WebSocketPreferences(
        enableRealTimeUpdates: false,
        subscribedChannels: {'customer', 'inventory'},
        showConnectionStatus: false,
        enableNotifications: true,
        channelPreferences: {'customer': true, 'inventory': false},
        notificationPriorities: {'customer': NotificationPriority.high},
      );

      final json = originalPreferences.toJson();
      final deserializedPreferences = WebSocketPreferences.fromJson(json);

      expect(deserializedPreferences.enableRealTimeUpdates, originalPreferences.enableRealTimeUpdates);
      expect(deserializedPreferences.subscribedChannels, originalPreferences.subscribedChannels);
      expect(deserializedPreferences.showConnectionStatus, originalPreferences.showConnectionStatus);
      expect(deserializedPreferences.enableNotifications, originalPreferences.enableNotifications);
      expect(deserializedPreferences.channelPreferences, originalPreferences.channelPreferences);
      expect(deserializedPreferences.notificationPriorities, originalPreferences.notificationPriorities);
    });

    test('should support copyWith', () {
      const originalPreferences = WebSocketPreferences(
        enableRealTimeUpdates: true,
        subscribedChannels: {'customer'},
      );

      final updatedPreferences = originalPreferences.copyWith(
        enableRealTimeUpdates: false,
        subscribedChannels: {'customer', 'inventory'},
      );

      expect(updatedPreferences.enableRealTimeUpdates, false);
      expect(updatedPreferences.subscribedChannels, {'customer', 'inventory'});
      expect(updatedPreferences.showConnectionStatus, originalPreferences.showConnectionStatus);
    });
  });

  group('NotificationPriority', () {
    test('should have correct display names', () {
      expect(NotificationPriority.low.displayName, 'Low');
      expect(NotificationPriority.normal.displayName, 'Normal');
      expect(NotificationPriority.high.displayName, 'High');
      expect(NotificationPriority.critical.displayName, 'Critical');
    });

    test('should have correct values', () {
      expect(NotificationPriority.low.value, 1);
      expect(NotificationPriority.normal.value, 2);
      expect(NotificationPriority.high.value, 3);
      expect(NotificationPriority.critical.value, 4);
    });

    test('should maintain priority order', () {
      expect(NotificationPriority.low.value < NotificationPriority.normal.value, true);
      expect(NotificationPriority.normal.value < NotificationPriority.high.value, true);
      expect(NotificationPriority.high.value < NotificationPriority.critical.value, true);
    });
  });

  group('WebSocketChannelPreference', () {
    test('should create with required values', () {
      const preference = WebSocketChannelPreference(
        channelId: 'customer',
        displayName: 'Customer Updates',
        description: 'Real-time customer updates',
      );

      expect(preference.channelId, 'customer');
      expect(preference.displayName, 'Customer Updates');
      expect(preference.description, 'Real-time customer updates');
      expect(preference.enabled, true);
      expect(preference.priority, NotificationPriority.normal);
      expect(preference.showInUI, true);
    });

    test('should serialize to and from JSON', () {
      const originalPreference = WebSocketChannelPreference(
        channelId: 'customer',
        displayName: 'Customer Updates',
        description: 'Real-time customer updates',
        enabled: false,
        priority: NotificationPriority.high,
        showInUI: false,
      );

      final json = originalPreference.toJson();
      final deserializedPreference = WebSocketChannelPreference.fromJson(json);

      expect(deserializedPreference.channelId, originalPreference.channelId);
      expect(deserializedPreference.displayName, originalPreference.displayName);
      expect(deserializedPreference.description, originalPreference.description);
      expect(deserializedPreference.enabled, originalPreference.enabled);
      expect(deserializedPreference.priority, originalPreference.priority);
      expect(deserializedPreference.showInUI, originalPreference.showInUI);
    });
  });
}