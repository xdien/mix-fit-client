import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/services/message_router.dart';
import 'package:data/websocket/models/websocket_message.dart';
import 'package:data/websocket/models/websocket_message_type.dart';

void main() {
  group('MessageRouter', () {
    late MessageRouter messageRouter;

    setUp(() {
      messageRouter = MessageRouter();
    });

    tearDown(() {
      messageRouter.dispose();
    });

    test('should register and unregister handlers', () {
      // Arrange
      bool handlerCalled = false;
      Future<void> testHandler(message) async {
        handlerCalled = true;
      }

      // Act
      messageRouter.registerHandler(WebSocketMessageType.customerUpdate, testHandler);

      // Assert
      expect(messageRouter.hasHandler(WebSocketMessageType.customerUpdate), isTrue);
      expect(messageRouter.getRegisteredTypes(), contains(WebSocketMessageType.customerUpdate));

      // Act - unregister
      messageRouter.unregisterHandler(WebSocketMessageType.customerUpdate);

      // Assert
      expect(messageRouter.hasHandler(WebSocketMessageType.customerUpdate), isFalse);
      expect(messageRouter.getRegisteredTypes(), isNot(contains(WebSocketMessageType.customerUpdate)));
    });

    test('should route message to correct handler', () async {
      // Arrange
      bool customerHandlerCalled = false;
      bool inventoryHandlerCalled = false;

      Future<void> customerHandler(message) async {
        customerHandlerCalled = true;
      }

      Future<void> inventoryHandler(message) async {
        inventoryHandlerCalled = true;
      }

      messageRouter.registerHandler(WebSocketMessageType.customerUpdate, customerHandler);
      messageRouter.registerHandler(WebSocketMessageType.inventoryUpdate, inventoryHandler);

      final message = WebSocketMessage(
        type: 'customer.updated',
        channel: 'customers',
        data: {'id': '123', 'name': 'Test Customer'},
        timestamp: DateTime.now(),
      );

      // Act
      await messageRouter.routeMessage(message);

      // Assert
      expect(customerHandlerCalled, isTrue);
      expect(inventoryHandlerCalled, isFalse);
    });

    test('should emit error when no handler is registered', () async {
      // Arrange
      final message = WebSocketMessage(
        type: 'unknown.type',
        channel: 'test',
        data: {},
        timestamp: DateTime.now(),
      );

      String? errorMessage;
      messageRouter.errorStream.listen((error) {
        errorMessage = error;
      });

      // Act
      await messageRouter.routeMessage(message);

      // Wait for error to be emitted
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(errorMessage, contains('No handler registered for message type: unknown.type'));
    });

    test('should clear all handlers', () {
      // Arrange
      Future<void> testHandler(message) async {}
      
      messageRouter.registerHandler(WebSocketMessageType.customerUpdate, testHandler);
      messageRouter.registerHandler(WebSocketMessageType.inventoryUpdate, testHandler);

      expect(messageRouter.getRegisteredTypes().length, equals(2));

      // Act
      messageRouter.clearHandlers();

      // Assert
      expect(messageRouter.getRegisteredTypes().isEmpty, isTrue);
    });

    test('should handle handler exceptions gracefully', () async {
      // Arrange
      Future<void> faultyHandler(message) async {
        throw Exception('Handler error');
      }

      messageRouter.registerHandler(WebSocketMessageType.customerUpdate, faultyHandler);

      final message = WebSocketMessage(
        type: 'customer.updated',
        channel: 'customers',
        data: {'id': '123'},
        timestamp: DateTime.now(),
      );

      String? errorMessage;
      messageRouter.errorStream.listen((error) {
        errorMessage = error;
      });

      // Act
      await messageRouter.routeMessage(message);

      // Wait for error to be emitted
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(errorMessage, contains('Error routing message customer.updated'));
    });
  });
}