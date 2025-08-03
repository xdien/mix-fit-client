import 'package:flutter_test/flutter_test.dart';
import 'package:data/data.dart';

void main() {
  group('WebSocket Exports', () {
    test('should export all WebSocket models and interfaces', () {
      // Test that all WebSocket classes are accessible through the main export
      
      // Test WebSocketMessage
      final message = WebSocketMessage(
        type: 'test',
        channel: 'test',
        data: {'key': 'value'},
        timestamp: DateTime.now(),
      );
      expect(message, isA<WebSocketMessage>());
      
      // Test WebSocketConfig
      const config = WebSocketConfig(
        url: 'ws://test.com',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
      );
      expect(config, isA<WebSocketConfig>());
      
      // Test WebSocketSubscription
      final subscription = WebSocketSubscription(
        channel: 'test',
        callback: (data) {},
        subscribedAt: DateTime.now(),
      );
      expect(subscription, isA<WebSocketSubscription>());
      
      // Test WebSocketConnectionState enum
      expect(WebSocketConnectionState.connected, isA<WebSocketConnectionState>());
      expect(WebSocketConnectionState.disconnected, isA<WebSocketConnectionState>());
      expect(WebSocketConnectionState.connecting, isA<WebSocketConnectionState>());
      expect(WebSocketConnectionState.reconnecting, isA<WebSocketConnectionState>());
      expect(WebSocketConnectionState.error, isA<WebSocketConnectionState>());
      
      // Test WebSocketErrorType enum
      expect(WebSocketErrorType.authenticationFailed, isA<WebSocketErrorType>());
      expect(WebSocketErrorType.connectionTimeout, isA<WebSocketErrorType>());
      expect(WebSocketErrorType.networkError, isA<WebSocketErrorType>());
      expect(WebSocketErrorType.serverError, isA<WebSocketErrorType>());
      expect(WebSocketErrorType.invalidMessage, isA<WebSocketErrorType>());
      expect(WebSocketErrorType.subscriptionFailed, isA<WebSocketErrorType>());
      
      // Test IWebSocketService interface (through type checking)
      expect(IWebSocketService, isA<Type>());
    });
    
    test('should support JSON serialization for serializable models', () {
      // Test WebSocketMessage JSON serialization
      final message = WebSocketMessage(
        type: 'test',
        channel: 'test',
        data: {'key': 'value'},
        timestamp: DateTime.parse('2024-01-01T10:00:00.000Z'),
        messageId: 'msg-123',
      );
      
      final messageJson = message.toJson();
      final messageFromJson = WebSocketMessage.fromJson(messageJson);
      expect(messageFromJson, equals(message));
      
      // Test WebSocketConfig JSON serialization
      const config = WebSocketConfig(
        url: 'ws://test.com',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      );
      
      final configJson = config.toJson();
      final configFromJson = WebSocketConfig.fromJson(configJson);
      expect(configFromJson, equals(config));
    });
    
    test('should support copyWith functionality for all models', () {
      // Test WebSocketMessage copyWith
      final originalMessage = WebSocketMessage(
        type: 'original',
        channel: 'original',
        data: {'key': 'original'},
        timestamp: DateTime.now(),
      );
      
      final copiedMessage = originalMessage.copyWith(type: 'updated');
      expect(copiedMessage.type, equals('updated'));
      expect(copiedMessage.channel, equals('original'));
      
      // Test WebSocketConfig copyWith
      const originalConfig = WebSocketConfig(
        url: 'ws://original.com',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
      );
      
      final copiedConfig = originalConfig.copyWith(url: 'ws://updated.com');
      expect(copiedConfig.url, equals('ws://updated.com'));
      expect(copiedConfig.reconnectInterval, equals(const Duration(seconds: 5)));
      
      // Test WebSocketSubscription copyWith
      final originalSubscription = WebSocketSubscription(
        channel: 'original',
        callback: (data) {},
        subscribedAt: DateTime.now(),
      );
      
      final copiedSubscription = originalSubscription.copyWith(channel: 'updated');
      expect(copiedSubscription.channel, equals('updated'));
      expect(copiedSubscription.isActive, isTrue);
    });
  });
}