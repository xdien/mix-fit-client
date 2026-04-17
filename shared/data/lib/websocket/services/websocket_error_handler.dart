import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import '../models/websocket_connection_state.dart';

/// Handles WebSocket errors and determines recovery strategies
class WebSocketErrorHandler {
  final StreamController<WebSocketError> _errorController = 
      StreamController<WebSocketError>.broadcast();

  /// Stream of WebSocket errors
  Stream<WebSocketError> get errorStream => _errorController.stream;

  /// Analyzes an error and creates a WebSocketError with recovery information
  WebSocketError analyzeError(
    dynamic error, {
    int? attemptNumber,
    String? context,
  }) {
    final timestamp = DateTime.now();
    
    // Determine error type and recovery strategy
    if (error is TimeoutException) {
      return WebSocketError(
        type: WebSocketErrorType.connectionTimeout,
        message: 'Connection timeout: ${error.message ?? 'Unknown timeout'}',
        originalError: error,
        timestamp: timestamp,
        attemptNumber: attemptNumber,
        isRecoverable: true,
      );
    }
    
    if (error is SocketException) {
      return _handleSocketException(error, timestamp, attemptNumber);
    }
    
    if (error is FormatException) {
      return WebSocketError(
        type: WebSocketErrorType.invalidMessage,
        message: 'Invalid message format: ${error.message}',
        originalError: error,
        timestamp: timestamp,
        attemptNumber: attemptNumber,
        isRecoverable: false,
      );
    }
    
    // Check for authentication-related errors
    final errorString = error.toString().toLowerCase();
    if (_isAuthenticationError(errorString)) {
      return WebSocketError(
        type: WebSocketErrorType.authenticationFailed,
        message: 'Authentication failed: $error',
        originalError: error,
        timestamp: timestamp,
        attemptNumber: attemptNumber,
        isRecoverable: true,
      );
    }
    
    if (_isTokenExpiredError(errorString)) {
      return WebSocketError(
        type: WebSocketErrorType.tokenExpired,
        message: 'Token expired: $error',
        originalError: error,
        timestamp: timestamp,
        attemptNumber: attemptNumber,
        isRecoverable: true,
      );
    }
    
    if (_isServerError(errorString)) {
      return WebSocketError(
        type: WebSocketErrorType.serverError,
        message: 'Server error: $error',
        originalError: error,
        timestamp: timestamp,
        attemptNumber: attemptNumber,
        isRecoverable: true,
      );
    }
    
    // Default to network error for unknown errors
    return WebSocketError(
      type: WebSocketErrorType.networkError,
      message: 'Network error: $error',
      originalError: error,
      timestamp: timestamp,
      attemptNumber: attemptNumber,
      isRecoverable: true,
    );
  }

  /// Creates an error for max reconnect attempts exceeded
  WebSocketError createMaxAttemptsError(int maxAttempts) {
    return WebSocketError(
      type: WebSocketErrorType.maxReconnectAttemptsExceeded,
      message: 'Maximum reconnection attempts ($maxAttempts) exceeded',
      timestamp: DateTime.now(),
      attemptNumber: maxAttempts,
      isRecoverable: false,
    );
  }

  /// Creates an error for heartbeat timeout
  WebSocketError createHeartbeatTimeoutError() {
    return WebSocketError(
      type: WebSocketErrorType.heartbeatTimeout,
      message: 'Heartbeat timeout - connection may be lost',
      timestamp: DateTime.now(),
      isRecoverable: true,
    );
  }

  /// Creates an error for token refresh failure
  WebSocketError createTokenRefreshError(dynamic originalError) {
    return WebSocketError(
      type: WebSocketErrorType.tokenRefreshFailed,
      message: 'Failed to refresh authentication token: $originalError',
      originalError: originalError,
      timestamp: DateTime.now(),
      isRecoverable: false,
    );
  }

  /// Creates an error for unexpected disconnection
  WebSocketError createUnexpectedDisconnectionError(String? reason) {
    return WebSocketError(
      type: WebSocketErrorType.unexpectedDisconnection,
      message: 'Unexpected disconnection${reason != null ? ': $reason' : ''}',
      timestamp: DateTime.now(),
      isRecoverable: true,
    );
  }

  /// Emits an error to the error stream
  void emitError(WebSocketError error) {
    developer.log(
      'WebSocket error: ${error.type} - ${error.message}',
      name: 'WebSocketErrorHandler',
      error: error.originalError,
    );
    
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
  }

  /// Determines if an error should trigger reconnection
  bool shouldReconnect(WebSocketError error, int currentAttempts, int maxAttempts) {
    // Don't reconnect if not recoverable
    if (!error.isRecoverable) {
      return false;
    }
    
    // Don't reconnect if max attempts exceeded
    if (currentAttempts >= maxAttempts) {
      return false;
    }
    
    // Don't reconnect for certain error types
    switch (error.type) {
      case WebSocketErrorType.invalidMessage:
      case WebSocketErrorType.maxReconnectAttemptsExceeded:
      case WebSocketErrorType.tokenRefreshFailed:
        return false;
      default:
        return true;
    }
  }

  /// Gets the recommended delay before retry based on error type
  Duration getRetryDelay(WebSocketError error, Duration baseDelay) {
    switch (error.type) {
      case WebSocketErrorType.authenticationFailed:
      case WebSocketErrorType.tokenExpired:
        // Shorter delay for auth errors as they might be quickly resolved
        return Duration(milliseconds: (baseDelay.inMilliseconds * 0.5).round());
      
      case WebSocketErrorType.serverError:
        // Longer delay for server errors
        return Duration(milliseconds: (baseDelay.inMilliseconds * 1.5).round());
      
      case WebSocketErrorType.connectionTimeout:
        // Standard delay for timeout errors
        return baseDelay;
      
      case WebSocketErrorType.networkError:
        // Standard delay for network errors
        return baseDelay;
      
      default:
        return baseDelay;
    }
  }

  WebSocketError _handleSocketException(
    SocketException error, 
    DateTime timestamp, 
    int? attemptNumber,
  ) {
    final message = error.message.toLowerCase();
    
    if (message.contains('network is unreachable') || 
        message.contains('no route to host')) {
      return WebSocketError(
        type: WebSocketErrorType.networkError,
        message: 'Network unreachable: ${error.message}',
        originalError: error,
        timestamp: timestamp,
        attemptNumber: attemptNumber,
        isRecoverable: true,
      );
    }
    
    if (message.contains('connection refused') || 
        message.contains('connection reset')) {
      return WebSocketError(
        type: WebSocketErrorType.connectionTimeout,
        message: 'Connection refused: ${error.message}',
        originalError: error,
        timestamp: timestamp,
        attemptNumber: attemptNumber,
        isRecoverable: true,
      );
    }
    
    return WebSocketError(
      type: WebSocketErrorType.networkError,
      message: 'Socket error: ${error.message}',
      originalError: error,
      timestamp: timestamp,
      attemptNumber: attemptNumber,
      isRecoverable: true,
    );
  }

  bool _isAuthenticationError(String errorString) {
    return errorString.contains('authentication') ||
           errorString.contains('unauthorized') ||
           errorString.contains('401') ||
           errorString.contains('auth') ||
           errorString.contains('invalid token');
  }

  bool _isTokenExpiredError(String errorString) {
    return errorString.contains('token expired') ||
           errorString.contains('token invalid') ||
           errorString.contains('jwt expired') ||
           errorString.contains('expired');
  }

  bool _isServerError(String errorString) {
    return errorString.contains('500') ||
           errorString.contains('502') ||
           errorString.contains('503') ||
           errorString.contains('504') ||
           errorString.contains('internal server error') ||
           errorString.contains('bad gateway') ||
           errorString.contains('service unavailable');
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}