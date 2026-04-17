import 'package:flutter_test/flutter_test.dart';
import 'package:data/data.dart';

void main() {
  group('WebSocketConnectionState', () {
    test('should have all expected connection states', () {
      const states = WebSocketConnectionState.values;
      
      expect(states, contains(WebSocketConnectionState.disconnected));
      expect(states, contains(WebSocketConnectionState.connecting));
      expect(states, contains(WebSocketConnectionState.connected));
      expect(states, contains(WebSocketConnectionState.reconnecting));
      expect(states, contains(WebSocketConnectionState.error));
      expect(states.length, equals(5));
    });

    test('should support equality comparison', () {
      expect(WebSocketConnectionState.disconnected, equals(WebSocketConnectionState.disconnected));
      expect(WebSocketConnectionState.connected, equals(WebSocketConnectionState.connected));
      expect(WebSocketConnectionState.connecting, isNot(equals(WebSocketConnectionState.connected)));
    });

    test('should have proper string representation', () {
      expect(WebSocketConnectionState.disconnected.toString(), 
             equals('WebSocketConnectionState.disconnected'));
      expect(WebSocketConnectionState.connecting.toString(), 
             equals('WebSocketConnectionState.connecting'));
      expect(WebSocketConnectionState.connected.toString(), 
             equals('WebSocketConnectionState.connected'));
      expect(WebSocketConnectionState.reconnecting.toString(), 
             equals('WebSocketConnectionState.reconnecting'));
      expect(WebSocketConnectionState.error.toString(), 
             equals('WebSocketConnectionState.error'));
    });

    test('should support switch statements', () {
      String getStateDescription(WebSocketConnectionState state) {
        switch (state) {
          case WebSocketConnectionState.disconnected:
            return 'Not connected';
          case WebSocketConnectionState.connecting:
            return 'Establishing connection';
          case WebSocketConnectionState.connected:
            return 'Connected and ready';
          case WebSocketConnectionState.reconnecting:
            return 'Attempting to reconnect';
          case WebSocketConnectionState.error:
            return 'Connection error occurred';
        }
      }

      expect(getStateDescription(WebSocketConnectionState.disconnected), 
             equals('Not connected'));
      expect(getStateDescription(WebSocketConnectionState.connecting), 
             equals('Establishing connection'));
      expect(getStateDescription(WebSocketConnectionState.connected), 
             equals('Connected and ready'));
      expect(getStateDescription(WebSocketConnectionState.reconnecting), 
             equals('Attempting to reconnect'));
      expect(getStateDescription(WebSocketConnectionState.error), 
             equals('Connection error occurred'));
    });

    test('should support state transition validation', () {
      bool isValidTransition(WebSocketConnectionState from, WebSocketConnectionState to) {
        switch (from) {
          case WebSocketConnectionState.disconnected:
            return to == WebSocketConnectionState.connecting;
          case WebSocketConnectionState.connecting:
            return to == WebSocketConnectionState.connected || 
                   to == WebSocketConnectionState.error ||
                   to == WebSocketConnectionState.disconnected;
          case WebSocketConnectionState.connected:
            return to == WebSocketConnectionState.disconnected ||
                   to == WebSocketConnectionState.reconnecting ||
                   to == WebSocketConnectionState.error;
          case WebSocketConnectionState.reconnecting:
            return to == WebSocketConnectionState.connected ||
                   to == WebSocketConnectionState.error ||
                   to == WebSocketConnectionState.disconnected;
          case WebSocketConnectionState.error:
            return to == WebSocketConnectionState.disconnected ||
                   to == WebSocketConnectionState.reconnecting;
        }
      }

      // Valid transitions
      expect(isValidTransition(WebSocketConnectionState.disconnected, 
                              WebSocketConnectionState.connecting), isTrue);
      expect(isValidTransition(WebSocketConnectionState.connecting, 
                              WebSocketConnectionState.connected), isTrue);
      expect(isValidTransition(WebSocketConnectionState.connected, 
                              WebSocketConnectionState.disconnected), isTrue);
      expect(isValidTransition(WebSocketConnectionState.connected, 
                              WebSocketConnectionState.reconnecting), isTrue);
      expect(isValidTransition(WebSocketConnectionState.reconnecting, 
                              WebSocketConnectionState.connected), isTrue);
      expect(isValidTransition(WebSocketConnectionState.error, 
                              WebSocketConnectionState.disconnected), isTrue);

      // Invalid transitions
      expect(isValidTransition(WebSocketConnectionState.disconnected, 
                              WebSocketConnectionState.connected), isFalse);
      expect(isValidTransition(WebSocketConnectionState.connected, 
                              WebSocketConnectionState.connecting), isFalse);
    });
  });

  group('WebSocketErrorType', () {
    test('should have all expected error types', () {
      const errorTypes = WebSocketErrorType.values;
      
      expect(errorTypes, contains(WebSocketErrorType.authenticationFailed));
      expect(errorTypes, contains(WebSocketErrorType.connectionTimeout));
      expect(errorTypes, contains(WebSocketErrorType.networkError));
      expect(errorTypes, contains(WebSocketErrorType.serverError));
      expect(errorTypes, contains(WebSocketErrorType.invalidMessage));
      expect(errorTypes, contains(WebSocketErrorType.subscriptionFailed));
      expect(errorTypes, contains(WebSocketErrorType.tokenExpired));
      expect(errorTypes, contains(WebSocketErrorType.tokenRefreshFailed));
      expect(errorTypes, contains(WebSocketErrorType.maxReconnectAttemptsExceeded));
      expect(errorTypes, contains(WebSocketErrorType.heartbeatTimeout));
      expect(errorTypes, contains(WebSocketErrorType.unexpectedDisconnection));
      expect(errorTypes.length, equals(11));
    });

    test('should support equality comparison', () {
      expect(WebSocketErrorType.authenticationFailed, 
             equals(WebSocketErrorType.authenticationFailed));
      expect(WebSocketErrorType.networkError, 
             equals(WebSocketErrorType.networkError));
      expect(WebSocketErrorType.authenticationFailed, 
             isNot(equals(WebSocketErrorType.networkError)));
    });

    test('should have proper string representation', () {
      expect(WebSocketErrorType.authenticationFailed.toString(), 
             equals('WebSocketErrorType.authenticationFailed'));
      expect(WebSocketErrorType.connectionTimeout.toString(), 
             equals('WebSocketErrorType.connectionTimeout'));
      expect(WebSocketErrorType.networkError.toString(), 
             equals('WebSocketErrorType.networkError'));
      expect(WebSocketErrorType.serverError.toString(), 
             equals('WebSocketErrorType.serverError'));
      expect(WebSocketErrorType.invalidMessage.toString(), 
             equals('WebSocketErrorType.invalidMessage'));
      expect(WebSocketErrorType.subscriptionFailed.toString(), 
             equals('WebSocketErrorType.subscriptionFailed'));
    });

    test('should support error categorization', () {
      bool isRecoverableError(WebSocketErrorType errorType) {
        switch (errorType) {
          case WebSocketErrorType.networkError:
          case WebSocketErrorType.connectionTimeout:
          case WebSocketErrorType.serverError:
          case WebSocketErrorType.tokenExpired:
          case WebSocketErrorType.heartbeatTimeout:
          case WebSocketErrorType.unexpectedDisconnection:
            return true;
          case WebSocketErrorType.authenticationFailed:
          case WebSocketErrorType.invalidMessage:
          case WebSocketErrorType.subscriptionFailed:
          case WebSocketErrorType.tokenRefreshFailed:
          case WebSocketErrorType.maxReconnectAttemptsExceeded:
            return false;
        }
      }

      // Recoverable errors
      expect(isRecoverableError(WebSocketErrorType.networkError), isTrue);
      expect(isRecoverableError(WebSocketErrorType.connectionTimeout), isTrue);
      expect(isRecoverableError(WebSocketErrorType.serverError), isTrue);
      expect(isRecoverableError(WebSocketErrorType.tokenExpired), isTrue);
      expect(isRecoverableError(WebSocketErrorType.heartbeatTimeout), isTrue);
      expect(isRecoverableError(WebSocketErrorType.unexpectedDisconnection), isTrue);

      // Non-recoverable errors
      expect(isRecoverableError(WebSocketErrorType.authenticationFailed), isFalse);
      expect(isRecoverableError(WebSocketErrorType.invalidMessage), isFalse);
      expect(isRecoverableError(WebSocketErrorType.subscriptionFailed), isFalse);
      expect(isRecoverableError(WebSocketErrorType.tokenRefreshFailed), isFalse);
      expect(isRecoverableError(WebSocketErrorType.maxReconnectAttemptsExceeded), isFalse);
    });

    test('should support error severity classification', () {
      int getErrorSeverity(WebSocketErrorType errorType) {
        switch (errorType) {
          case WebSocketErrorType.authenticationFailed:
          case WebSocketErrorType.tokenRefreshFailed:
          case WebSocketErrorType.maxReconnectAttemptsExceeded:
            return 3; // Critical
          case WebSocketErrorType.serverError:
          case WebSocketErrorType.tokenExpired:
            return 2; // High
          case WebSocketErrorType.connectionTimeout:
          case WebSocketErrorType.networkError:
          case WebSocketErrorType.heartbeatTimeout:
          case WebSocketErrorType.unexpectedDisconnection:
            return 1; // Medium
          case WebSocketErrorType.invalidMessage:
          case WebSocketErrorType.subscriptionFailed:
            return 0; // Low
        }
      }

      expect(getErrorSeverity(WebSocketErrorType.authenticationFailed), equals(3));
      expect(getErrorSeverity(WebSocketErrorType.serverError), equals(2));
      expect(getErrorSeverity(WebSocketErrorType.connectionTimeout), equals(1));
      expect(getErrorSeverity(WebSocketErrorType.networkError), equals(1));
      expect(getErrorSeverity(WebSocketErrorType.invalidMessage), equals(0));
      expect(getErrorSeverity(WebSocketErrorType.subscriptionFailed), equals(0));
    });
  });
}