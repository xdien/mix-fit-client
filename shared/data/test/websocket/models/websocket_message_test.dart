import 'package:flutter_test/flutter_test.dart';
import 'package:data/data.dart';

void main() {
  group('WebSocketMessage', () {
    test('should create WebSocketMessage with required fields', () {
      final timestamp = DateTime.now();
      final message = WebSocketMessage(
        type: 'customer.updated',
        channel: 'customer',
        data: {'id': '123', 'name': 'John Doe'},
        timestamp: timestamp,
      );

      expect(message.type, equals('customer.updated'));
      expect(message.channel, equals('customer'));
      expect(message.data, equals({'id': '123', 'name': 'John Doe'}));
      expect(message.timestamp, equals(timestamp));
      expect(message.messageId, isNull);
    });

    test('should create WebSocketMessage with optional messageId', () {
      final timestamp = DateTime.now();
      final message = WebSocketMessage(
        type: 'inventory.changed',
        channel: 'inventory',
        data: {'productId': '456', 'quantity': 10},
        timestamp: timestamp,
        messageId: 'msg-123',
      );

      expect(message.type, equals('inventory.changed'));
      expect(message.channel, equals('inventory'));
      expect(message.data, equals({'productId': '456', 'quantity': 10}));
      expect(message.timestamp, equals(timestamp));
      expect(message.messageId, equals('msg-123'));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.parse('2024-01-01T10:00:00.000Z');
      final message = WebSocketMessage(
        type: 'order.status.changed',
        channel: 'orders',
        data: {'orderId': '789', 'status': 'completed'},
        timestamp: timestamp,
        messageId: 'msg-456',
      );

      final json = message.toJson();

      expect(json['type'], equals('order.status.changed'));
      expect(json['channel'], equals('orders'));
      expect(json['data'], equals({'orderId': '789', 'status': 'completed'}));
      expect(json['timestamp'], equals('2024-01-01T10:00:00.000Z'));
      expect(json['messageId'], equals('msg-456'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'system.notification',
        'channel': 'system',
        'data': {'message': 'System maintenance scheduled'},
        'timestamp': '2024-01-01T10:00:00.000Z',
        'messageId': 'msg-789',
      };

      final message = WebSocketMessage.fromJson(json);

      expect(message.type, equals('system.notification'));
      expect(message.channel, equals('system'));
      expect(message.data, equals({'message': 'System maintenance scheduled'}));
      expect(message.timestamp, equals(DateTime.parse('2024-01-01T10:00:00.000Z')));
      expect(message.messageId, equals('msg-789'));
    });

    test('should deserialize from JSON without messageId', () {
      final json = {
        'type': 'customer.updated',
        'channel': 'customer',
        'data': {'id': '123'},
        'timestamp': '2024-01-01T10:00:00.000Z',
      };

      final message = WebSocketMessage.fromJson(json);

      expect(message.type, equals('customer.updated'));
      expect(message.channel, equals('customer'));
      expect(message.data, equals({'id': '123'}));
      expect(message.timestamp, equals(DateTime.parse('2024-01-01T10:00:00.000Z')));
      expect(message.messageId, isNull);
    });

    test('should support equality comparison', () {
      final timestamp = DateTime.now();
      final message1 = WebSocketMessage(
        type: 'test',
        channel: 'test',
        data: {'key': 'value'},
        timestamp: timestamp,
        messageId: 'msg-1',
      );

      final message2 = WebSocketMessage(
        type: 'test',
        channel: 'test',
        data: {'key': 'value'},
        timestamp: timestamp,
        messageId: 'msg-1',
      );

      final message3 = WebSocketMessage(
        type: 'test',
        channel: 'test',
        data: {'key': 'different'},
        timestamp: timestamp,
        messageId: 'msg-1',
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    test('should support copyWith functionality', () {
      final timestamp = DateTime.now();
      final originalMessage = WebSocketMessage(
        type: 'original',
        channel: 'original',
        data: {'key': 'original'},
        timestamp: timestamp,
      );

      final copiedMessage = originalMessage.copyWith(
        type: 'updated',
        messageId: 'new-id',
      );

      expect(copiedMessage.type, equals('updated'));
      expect(copiedMessage.channel, equals('original'));
      expect(copiedMessage.data, equals({'key': 'original'}));
      expect(copiedMessage.timestamp, equals(timestamp));
      expect(copiedMessage.messageId, equals('new-id'));
    });
  });
}