import 'package:flutter_test/flutter_test.dart';
import 'package:websocket_service/models/websocket_channel_config.dart';
import 'package:websocket_service/models/websocket_preferences.dart';

void main() {
  group('WebSocketChannelConfig', () {
    test('should create with required values', () {
      const config = WebSocketChannelConfig(
        id: 'customer',
        name: 'Customer Updates',
        description: 'Real-time customer updates',
        type: WebSocketChannelType.customer,
      );

      expect(config.id, 'customer');
      expect(config.name, 'Customer Updates');
      expect(config.description, 'Real-time customer updates');
      expect(config.type, WebSocketChannelType.customer);
      expect(config.userConfigurable, true);
      expect(config.defaultPriority, NotificationPriority.normal);
      expect(config.defaultEnabled, true);
    });

    test('should create with custom values', () {
      const config = WebSocketChannelConfig(
        id: 'system',
        name: 'System Notifications',
        description: 'System-wide notifications',
        type: WebSocketChannelType.system,
        userConfigurable: false,
        defaultPriority: NotificationPriority.critical,
        defaultEnabled: false,
      );

      expect(config.userConfigurable, false);
      expect(config.defaultPriority, NotificationPriority.critical);
      expect(config.defaultEnabled, false);
    });

    test('should serialize to and from JSON', () {
      const originalConfig = WebSocketChannelConfig(
        id: 'inventory',
        name: 'Inventory Changes',
        description: 'Live inventory updates',
        type: WebSocketChannelType.inventory,
        userConfigurable: false,
        defaultPriority: NotificationPriority.high,
        defaultEnabled: false,
      );

      final json = originalConfig.toJson();
      final deserializedConfig = WebSocketChannelConfig.fromJson(json);

      expect(deserializedConfig.id, originalConfig.id);
      expect(deserializedConfig.name, originalConfig.name);
      expect(deserializedConfig.description, originalConfig.description);
      expect(deserializedConfig.type, originalConfig.type);
      expect(deserializedConfig.userConfigurable, originalConfig.userConfigurable);
      expect(deserializedConfig.defaultPriority, originalConfig.defaultPriority);
      expect(deserializedConfig.defaultEnabled, originalConfig.defaultEnabled);
    });
  });

  group('WebSocketChannelType', () {
    test('should have correct display names', () {
      expect(WebSocketChannelType.customer.displayName, 'Customer Updates');
      expect(WebSocketChannelType.inventory.displayName, 'Inventory Changes');
      expect(WebSocketChannelType.order.displayName, 'Order Status');
      expect(WebSocketChannelType.system.displayName, 'System Notifications');
      expect(WebSocketChannelType.notification.displayName, 'General Notifications');
    });

    test('should have correct descriptions', () {
      expect(WebSocketChannelType.customer.description, 'Real-time updates for customer information changes');
      expect(WebSocketChannelType.inventory.description, 'Live inventory level changes and stock updates');
      expect(WebSocketChannelType.order.description, 'Order status changes and fulfillment updates');
      expect(WebSocketChannelType.system.description, 'System-wide notifications and alerts');
      expect(WebSocketChannelType.notification.description, 'General application notifications');
    });
  });
}