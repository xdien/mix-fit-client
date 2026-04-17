import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/models/websocket_message_type.dart';

void main() {
  group('WebSocketMessageType', () {
    test('should create from string value correctly', () {
      // Act & Assert
      expect(
        WebSocketMessageType.fromString('customer.updated'),
        equals(WebSocketMessageType.customerUpdate),
      );
      expect(
        WebSocketMessageType.fromString('inventory.changed'),
        equals(WebSocketMessageType.inventoryUpdate),
      );
      expect(
        WebSocketMessageType.fromString('order.status.changed'),
        equals(WebSocketMessageType.orderStatusUpdate),
      );
      expect(
        WebSocketMessageType.fromString('system.notification'),
        equals(WebSocketMessageType.systemNotification),
      );
      expect(
        WebSocketMessageType.fromString('user.specific'),
        equals(WebSocketMessageType.userSpecific),
      );
      expect(
        WebSocketMessageType.fromString('unknown.type'),
        equals(WebSocketMessageType.unknown),
      );
    });

    test('should return correct value strings', () {
      // Act & Assert
      expect(WebSocketMessageType.customerUpdate.value, equals('customer.updated'));
      expect(WebSocketMessageType.inventoryUpdate.value, equals('inventory.changed'));
      expect(WebSocketMessageType.orderStatusUpdate.value, equals('order.status.changed'));
      expect(WebSocketMessageType.systemNotification.value, equals('system.notification'));
      expect(WebSocketMessageType.userSpecific.value, equals('user.specific'));
      expect(WebSocketMessageType.unknown.value, equals('unknown'));
    });

    test('should correctly identify messages requiring database sync', () {
      // Act & Assert
      expect(WebSocketMessageType.customerUpdate.requiresDatabaseSync, isTrue);
      expect(WebSocketMessageType.inventoryUpdate.requiresDatabaseSync, isTrue);
      expect(WebSocketMessageType.orderStatusUpdate.requiresDatabaseSync, isTrue);
      expect(WebSocketMessageType.systemNotification.requiresDatabaseSync, isFalse);
      expect(WebSocketMessageType.userSpecific.requiresDatabaseSync, isFalse);
      expect(WebSocketMessageType.unknown.requiresDatabaseSync, isFalse);
    });

    test('should correctly identify messages triggering UI updates', () {
      // Act & Assert
      expect(WebSocketMessageType.customerUpdate.triggersUIUpdate, isTrue);
      expect(WebSocketMessageType.inventoryUpdate.triggersUIUpdate, isTrue);
      expect(WebSocketMessageType.orderStatusUpdate.triggersUIUpdate, isTrue);
      expect(WebSocketMessageType.systemNotification.triggersUIUpdate, isTrue);
      expect(WebSocketMessageType.userSpecific.triggersUIUpdate, isFalse);
      expect(WebSocketMessageType.unknown.triggersUIUpdate, isFalse);
    });
  });
}