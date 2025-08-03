import 'dart:math';
import '../models/websocket_connection_state.dart';

/// Reconnection strategy with exponential backoff and error-aware delays
class ReconnectionStrategy {
  static const List<Duration> defaultBackoffIntervals = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
  ];

  final List<Duration> _backoffIntervals;
  final double _jitterFactor;
  final Random _random = Random();
  final Duration _maxDelay;
  final Duration _minDelay;

  ReconnectionStrategy({
    List<Duration>? backoffIntervals,
    double jitterFactor = 0.1,
    Duration? maxDelay,
    Duration? minDelay,
  }) : _backoffIntervals = backoffIntervals ?? defaultBackoffIntervals,
       _jitterFactor = jitterFactor,
       _maxDelay = maxDelay ?? const Duration(minutes: 5),
       _minDelay = minDelay ?? const Duration(milliseconds: 500);

  /// Calculate the delay for the given attempt number
  Duration calculateDelay(int attemptNumber, {WebSocketError? lastError}) {
    if (attemptNumber <= 0) {
      return Duration.zero;
    }

    // Get base delay using predefined intervals or exponential backoff
    Duration baseDelay = _calculateBaseDelay(attemptNumber);

    // Adjust delay based on error type if provided
    if (lastError != null) {
      baseDelay = _adjustDelayForError(baseDelay, lastError);
    }

    // Ensure delay is within bounds
    baseDelay = Duration(
      milliseconds: max(
        _minDelay.inMilliseconds,
        min(baseDelay.inMilliseconds, _maxDelay.inMilliseconds),
      ),
    );

    // Add jitter to prevent thundering herd problem
    final jitterMs = (baseDelay.inMilliseconds * _jitterFactor * _random.nextDouble()).round();
    return Duration(milliseconds: baseDelay.inMilliseconds + jitterMs);
  }

  /// Calculate delay with error-specific adjustments
  Duration calculateDelayWithError(int attemptNumber, WebSocketError error) {
    return calculateDelay(attemptNumber, lastError: error);
  }

  /// Check if should attempt reconnection based on attempt number and max attempts
  bool shouldAttemptReconnection(int attemptNumber, int maxAttempts, {WebSocketError? lastError}) {
    if (attemptNumber <= 0 || maxAttempts <= 0 || attemptNumber > maxAttempts) {
      return false;
    }

    // Check if error type allows reconnection
    if (lastError != null && !lastError.isRecoverable) {
      return false;
    }

    return true;
  }

  /// Check if should attempt reconnection based on error
  bool shouldReconnectForError(WebSocketError error, int currentAttempts, int maxAttempts) {
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

  /// Get the maximum delay that can be returned
  Duration get maxDelay => _maxDelay;

  /// Get the minimum delay that can be returned
  Duration get minDelay => _minDelay;

  /// Get the configured backoff intervals
  List<Duration> get backoffIntervals => List.unmodifiable(_backoffIntervals);

  /// Reset strategy state (if needed for stateful implementations)
  void reset() {
    // Currently stateless, but can be extended for stateful strategies
  }

  Duration _calculateBaseDelay(int attemptNumber) {
    // Use predefined intervals if available, otherwise use exponential backoff
    if (attemptNumber <= _backoffIntervals.length) {
      return _backoffIntervals[attemptNumber - 1];
    } else {
      // Exponential backoff: 2^(attemptNumber-backoffIntervals.length) seconds
      final exponent = attemptNumber - _backoffIntervals.length;
      final exponentialSeconds = min(pow(2, exponent).toInt(), _maxDelay.inSeconds);
      return Duration(seconds: exponentialSeconds);
    }
  }

  Duration _adjustDelayForError(Duration baseDelay, WebSocketError error) {
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
      
      case WebSocketErrorType.heartbeatTimeout:
        // Shorter delay for heartbeat timeouts
        return Duration(milliseconds: (baseDelay.inMilliseconds * 0.7).round());
      
      default:
        return baseDelay;
    }
  }
}