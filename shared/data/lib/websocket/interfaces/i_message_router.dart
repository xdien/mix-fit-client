import '../models/websocket_message.dart';
import '../models/websocket_message_type.dart';

/// Callback function for handling routed messages
typedef MessageHandler = Future<void> Function(WebSocketMessage message);

/// Interface for routing WebSocket messages to appropriate handlers
abstract class IMessageRouter {
  /// Register a handler for a specific message type
  void registerHandler(WebSocketMessageType type, MessageHandler handler);

  /// Unregister a handler for a specific message type
  void unregisterHandler(WebSocketMessageType type);

  /// Route a message to the appropriate handler
  Future<void> routeMessage(WebSocketMessage message);

  /// Get all registered message types
  Set<WebSocketMessageType> getRegisteredTypes();

  /// Check if a handler is registered for a message type
  bool hasHandler(WebSocketMessageType type);

  /// Clear all registered handlers
  void clearHandlers();
}