enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

enum WebSocketErrorType {
  authenticationFailed,
  connectionTimeout,
  networkError,
  serverError,
  invalidMessage,
  subscriptionFailed,
  tokenExpired,
  tokenRefreshFailed,
  maxReconnectAttemptsExceeded,
  heartbeatTimeout,
  unexpectedDisconnection
}

/// Represents a WebSocket error with detailed information
class WebSocketError {
  final WebSocketErrorType type;
  final String message;
  final dynamic originalError;
  final DateTime timestamp;
  final int? attemptNumber;
  final bool isRecoverable;

  const WebSocketError({
    required this.type,
    required this.message,
    this.originalError,
    required this.timestamp,
    this.attemptNumber,
    required this.isRecoverable,
  });

  @override
  String toString() {
    return 'WebSocketError(type: $type, message: $message, timestamp: $timestamp, attemptNumber: $attemptNumber, isRecoverable: $isRecoverable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketError &&
        other.type == type &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.attemptNumber == attemptNumber &&
        other.isRecoverable == isRecoverable;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        message.hashCode ^
        timestamp.hashCode ^
        attemptNumber.hashCode ^
        isRecoverable.hashCode;
  }
}