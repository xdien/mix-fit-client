import 'dart:async';
import 'dart:developer' as developer;
import '../interfaces/i_message_router.dart';
import '../models/websocket_message.dart';
import '../models/websocket_message_type.dart';

/// Implementation of message router for WebSocket messages
class MessageRouter implements IMessageRouter {
  final Map<WebSocketMessageType, MessageHandler> _handlers = {};
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  /// Stream of routing errors
  Stream<String> get errorStream => _errorController.stream;

  @override
  void registerHandler(WebSocketMessageType type, MessageHandler handler) {
    developer.log('Registering handler for message type: ${type.value}', name: 'MessageRouter');
    _handlers[type] = handler;
  }

  @override
  void unregisterHandler(WebSocketMessageType type) {
    developer.log('Unregistering handler for message type: ${type.value}', name: 'MessageRouter');
    _handlers.remove(type);
  }

  @override
  Future<void> routeMessage(WebSocketMessage message) async {
    try {
      final messageType = WebSocketMessageType.fromString(message.type);
      
      developer.log(
        'Routing message: ${message.type} to channel: ${message.channel}',
        name: 'MessageRouter',
      );

      final handler = _handlers[messageType];
      if (handler != null) {
        await handler(message);
        developer.log('Message routed successfully: ${message.type}', name: 'MessageRouter');
      } else {
        final errorMsg = 'No handler registered for message type: ${message.type}';
        developer.log(errorMsg, name: 'MessageRouter');
        _errorController.add(errorMsg);
      }
    } catch (error, stackTrace) {
      final errorMsg = 'Error routing message ${message.type}: $error';
      developer.log(errorMsg, error: error, stackTrace: stackTrace, name: 'MessageRouter');
      _errorController.add(errorMsg);
    }
  }

  @override
  Set<WebSocketMessageType> getRegisteredTypes() {
    return _handlers.keys.toSet();
  }

  @override
  bool hasHandler(WebSocketMessageType type) {
    return _handlers.containsKey(type);
  }

  @override
  void clearHandlers() {
    developer.log('Clearing all message handlers', name: 'MessageRouter');
    _handlers.clear();
  }

  /// Dispose resources
  void dispose() {
    developer.log('Disposing MessageRouter', name: 'MessageRouter');
    clearHandlers();
    _errorController.close();
  }
}