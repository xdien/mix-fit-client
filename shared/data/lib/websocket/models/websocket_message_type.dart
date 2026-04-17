/// Enum defining the types of WebSocket messages that can be received
enum WebSocketMessageType {
  customerUpdate('customer.updated'),
  inventoryUpdate('inventory.changed'),
  orderStatusUpdate('order.status.changed'),
  systemNotification('system.notification'),
  userSpecific('user.specific'),
  unknown('unknown');

  const WebSocketMessageType(this.value);
  
  final String value;

  /// Create WebSocketMessageType from string value
  static WebSocketMessageType fromString(String value) {
    for (final type in WebSocketMessageType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return WebSocketMessageType.unknown;
  }

  /// Check if this message type requires database synchronization
  bool get requiresDatabaseSync {
    switch (this) {
      case WebSocketMessageType.customerUpdate:
      case WebSocketMessageType.inventoryUpdate:
      case WebSocketMessageType.orderStatusUpdate:
        return true;
      case WebSocketMessageType.systemNotification:
      case WebSocketMessageType.userSpecific:
      case WebSocketMessageType.unknown:
        return false;
    }
  }

  /// Check if this message type should trigger UI updates
  bool get triggersUIUpdate {
    switch (this) {
      case WebSocketMessageType.customerUpdate:
      case WebSocketMessageType.inventoryUpdate:
      case WebSocketMessageType.orderStatusUpdate:
      case WebSocketMessageType.systemNotification:
        return true;
      case WebSocketMessageType.userSpecific:
      case WebSocketMessageType.unknown:
        return false;
    }
  }
}