import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/websocket.dart';

void main() {
  group('WebSocketErrorHandler', () {
    late WebSocketErrorHandler errorHandler;

    setUp(() {
      errorHandler = WebSocketErrorHandler();
    });

    tearDown(() {
      errorHandler.dispose();
    });

    group('Error Analysis', () {
      test('should analyze TimeoutException correctly', () {
        final error = TimeoutException('Connection timeout', const Duration(seconds: 10));
        
        final wsError = errorHandler.analyzeError(error, attemptNumber: 1);
        
        expect(wsError.type, WebSocketErrorType.connectionTimeout);
        expect(wsError.message, contains('Connection timeout'));
        expect(wsError.isRecoverable, isTrue);
        expect(wsError.attemptNumber, 1);
        expect(wsError.originalError, error);
      });

      test('should analyze SocketException correctly', () {
        final error = const SocketException('Connection refused');
        
        final wsError = errorHandler.analyzeError(error, attemptNumber: 2);
        
        expect(wsError.type, WebSocketErrorType.connectionTimeout);
        expect(wsError.message, contains('Connection refused'));
        expect(wsError.isRecoverable, isTrue);
        expect(wsError.attemptNumber, 2);
        expect(wsError.originalError, error);
      });

      test('should analyze network unreachable SocketException', () {
        final error = const SocketException('Network is unreachable');
        
        final wsError = errorHandler.analyzeError(error);
        
        expect(wsError.type, WebSocketErrorType.networkError);
        expect(wsError.message, contains('Network unreachable'));
        expect(wsError.isRecoverable, isTrue);
      });

      test('should analyze FormatException correctly', () {
        final error = const FormatException('Invalid JSON');
        
        final wsError = errorHandler.analyzeError(error);
        
        expect(wsError.type, WebSocketErrorType.invalidMessage);
        expect(wsError.message, contains('Invalid message format'));
        expect(wsError.isRecoverable, isFalse);
        expect(wsError.originalError, error);
      });

      test('should detect authentication errors', () {
        final authErrors = [
          'Authentication failed',
          'Unauthorized access',
          '401 error',
          'Invalid token provided',
        ];

        for (final errorMsg in authErrors) {
          final wsError = errorHandler.analyzeError(errorMsg);
          expect(wsError.type, WebSocketErrorType.authenticationFailed);
          expect(wsError.isRecoverable, isTrue);
        }
      });

      test('should detect token expiration errors', () {
        final tokenErrors = [
          'Token expired',
          'JWT expired',
          'Token invalid due to expiration',
        ];

        for (final errorMsg in tokenErrors) {
          final wsError = errorHandler.analyzeError(errorMsg);
          expect(wsError.type, WebSocketErrorType.tokenExpired);
          expect(wsError.isRecoverable, isTrue);
        }
      });

      test('should detect server errors', () {
        final serverErrors = [
          '500 Internal Server Error',
          '502 Bad Gateway',
          '503 Service Unavailable',
          'Internal server error occurred',
        ];

        for (final errorMsg in serverErrors) {
          final wsError = errorHandler.analyzeError(errorMsg);
          expect(wsError.type, WebSocketErrorType.serverError);
          expect(wsError.isRecoverable, isTrue);
        }
      });

      test('should default to network error for unknown errors', () {
        final wsError = errorHandler.analyzeError('Unknown error occurred');
        
        expect(wsError.type, WebSocketErrorType.networkError);
        expect(wsError.isRecoverable, isTrue);
        expect(wsError.message, contains('Network error'));
      });
    });

    group('Specific Error Creation', () {
      test('should create max attempts error', () {
        final wsError = errorHandler.createMaxAttemptsError(5);
        
        expect(wsError.type, WebSocketErrorType.maxReconnectAttemptsExceeded);
        expect(wsError.message, contains('Maximum reconnection attempts (5) exceeded'));
        expect(wsError.isRecoverable, isFalse);
        expect(wsError.attemptNumber, 5);
      });

      test('should create heartbeat timeout error', () {
        final wsError = errorHandler.createHeartbeatTimeoutError();
        
        expect(wsError.type, WebSocketErrorType.heartbeatTimeout);
        expect(wsError.message, contains('Heartbeat timeout'));
        expect(wsError.isRecoverable, isTrue);
      });

      test('should create token refresh error', () {
        final originalError = 'Network error during refresh';
        final wsError = errorHandler.createTokenRefreshError(originalError);
        
        expect(wsError.type, WebSocketErrorType.tokenRefreshFailed);
        expect(wsError.message, contains('Failed to refresh authentication token'));
        expect(wsError.isRecoverable, isFalse);
        expect(wsError.originalError, originalError);
      });

      test('should create unexpected disconnection error', () {
        final wsError = errorHandler.createUnexpectedDisconnectionError('Server shutdown');
        
        expect(wsError.type, WebSocketErrorType.unexpectedDisconnection);
        expect(wsError.message, contains('Unexpected disconnection: Server shutdown'));
        expect(wsError.isRecoverable, isTrue);
      });

      test('should create unexpected disconnection error without reason', () {
        final wsError = errorHandler.createUnexpectedDisconnectionError(null);
        
        expect(wsError.type, WebSocketErrorType.unexpectedDisconnection);
        expect(wsError.message, 'Unexpected disconnection');
        expect(wsError.isRecoverable, isTrue);
      });
    });

    group('Error Stream', () {
      test('should emit errors to stream', () async {
        final errors = <WebSocketError>[];
        final subscription = errorHandler.errorStream.listen(errors.add);

        final testError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        errorHandler.emitError(testError);
        
        // Wait for stream emission
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(errors, hasLength(1));
        expect(errors.first, testError);
        
        await subscription.cancel();
      });

      test('should handle multiple error emissions', () async {
        final errors = <WebSocketError>[];
        final subscription = errorHandler.errorStream.listen(errors.add);

        final error1 = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Error 1',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final error2 = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Error 2',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        errorHandler.emitError(error1);
        errorHandler.emitError(error2);
        
        // Wait for stream emissions
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(errors, hasLength(2));
        expect(errors[0], error1);
        expect(errors[1], error2);
        
        await subscription.cancel();
      });
    });

    group('Reconnection Decision', () {
      test('should allow reconnection for recoverable errors', () {
        final recoverableError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        expect(errorHandler.shouldReconnect(recoverableError, 0, 5), isTrue);
        expect(errorHandler.shouldReconnect(recoverableError, 2, 5), isTrue);
        expect(errorHandler.shouldReconnect(recoverableError, 4, 5), isTrue);
      });

      test('should not allow reconnection for non-recoverable errors', () {
        final nonRecoverableError = WebSocketError(
          type: WebSocketErrorType.invalidMessage,
          message: 'Invalid message',
          timestamp: DateTime.now(),
          isRecoverable: false,
        );

        expect(errorHandler.shouldReconnect(nonRecoverableError, 1, 5), isFalse);
      });

      test('should not allow reconnection when max attempts exceeded', () {
        final recoverableError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        expect(errorHandler.shouldReconnect(recoverableError, 5, 5), isFalse);
        expect(errorHandler.shouldReconnect(recoverableError, 10, 5), isFalse);
      });

      test('should not allow reconnection for specific error types', () {
        final errorTypes = [
          WebSocketErrorType.invalidMessage,
          WebSocketErrorType.maxReconnectAttemptsExceeded,
          WebSocketErrorType.tokenRefreshFailed,
        ];

        for (final errorType in errorTypes) {
          final error = WebSocketError(
            type: errorType,
            message: 'Test error',
            timestamp: DateTime.now(),
            isRecoverable: true, // Even if marked recoverable
          );

          expect(errorHandler.shouldReconnect(error, 0, 5), isFalse);
        }
      });
    });

    group('Retry Delay Calculation', () {
      test('should adjust delay for authentication errors', () {
        final authError = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Auth failed',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final baseDelay = const Duration(seconds: 10);
        final adjustedDelay = errorHandler.getRetryDelay(authError, baseDelay);
        
        expect(adjustedDelay.inMilliseconds, 5000); // 50% of base delay
      });

      test('should adjust delay for server errors', () {
        final serverError = WebSocketError(
          type: WebSocketErrorType.serverError,
          message: 'Server error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final baseDelay = const Duration(seconds: 10);
        final adjustedDelay = errorHandler.getRetryDelay(serverError, baseDelay);
        
        expect(adjustedDelay.inMilliseconds, 15000); // 150% of base delay
      });

      test('should use standard delay for timeout errors', () {
        final timeoutError = WebSocketError(
          type: WebSocketErrorType.connectionTimeout,
          message: 'Timeout',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final baseDelay = const Duration(seconds: 10);
        final adjustedDelay = errorHandler.getRetryDelay(timeoutError, baseDelay);
        
        expect(adjustedDelay, baseDelay);
      });

      test('should use standard delay for network errors', () {
        final networkError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final baseDelay = const Duration(seconds: 10);
        final adjustedDelay = errorHandler.getRetryDelay(networkError, baseDelay);
        
        expect(adjustedDelay, baseDelay);
      });
    });

    group('Error Equality and String Representation', () {
      test('should implement equality correctly', () {
        final timestamp = DateTime.now();
        
        final error1 = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: timestamp,
          attemptNumber: 1,
          isRecoverable: true,
        );

        final error2 = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: timestamp,
          attemptNumber: 1,
          isRecoverable: true,
        );

        final error3 = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Test error',
          timestamp: timestamp,
          attemptNumber: 1,
          isRecoverable: true,
        );

        expect(error1, equals(error2));
        expect(error1, isNot(equals(error3)));
      });

      test('should implement toString correctly', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          attemptNumber: 1,
          isRecoverable: true,
        );

        final errorString = error.toString();
        
        expect(errorString, contains('WebSocketError'));
        expect(errorString, contains('networkError'));
        expect(errorString, contains('Test error'));
        expect(errorString, contains('attemptNumber: 1'));
        expect(errorString, contains('isRecoverable: true'));
      });
    });

    group('Disposal', () {
      test('should dispose without errors', () {
        expect(() => errorHandler.dispose(), returnsNormally);
      });

      test('should not emit errors after disposal', () async {
        final errors = <WebSocketError>[];
        final subscription = errorHandler.errorStream.listen(errors.add);

        errorHandler.dispose();

        final testError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        // This should not cause an error or emit to stream
        expect(() => errorHandler.emitError(testError), returnsNormally);
        
        // Wait to ensure no emission
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(errors, isEmpty);
        
        await subscription.cancel();
      });
    });
  });
}