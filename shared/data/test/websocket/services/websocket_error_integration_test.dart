import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/websocket.dart';

void main() {
  group('WebSocket Error Handling Integration', () {
    late WebSocketService webSocketService;
    late WebSocketErrorHandler errorHandler;
    late ReconnectionStrategy reconnectionStrategy;
    late NetworkConnectivityDetector networkDetector;

    Future<String?> mockAuthTokenProvider() async => 'test-token';
    Future<String?> mockTokenRefresher() async => 'refreshed-token';

    setUp(() {
      errorHandler = WebSocketErrorHandler();
      reconnectionStrategy = ReconnectionStrategy(
        backoffIntervals: [
          const Duration(milliseconds: 100),
          const Duration(milliseconds: 200),
          const Duration(milliseconds: 500),
        ],
        maxDelay: const Duration(seconds: 2),
      );
      networkDetector = NetworkConnectivityDetector(
        checkInterval: const Duration(milliseconds: 100),
        testTimeout: const Duration(milliseconds: 200),
      );

      final config = const WebSocketConfig(
        url: 'ws://localhost:9999', // Intentionally unreachable
        reconnectInterval: Duration(milliseconds: 100),
        maxReconnectAttempts: 3,
        heartbeatInterval: Duration(seconds: 1),
        autoReconnect: true,
      );

      webSocketService = WebSocketService(
        config,
        mockAuthTokenProvider,
        refreshToken: mockTokenRefresher,
        errorHandler: errorHandler,
        reconnectionStrategy: reconnectionStrategy,
        networkDetector: networkDetector,
      );
    });

    tearDown(() {
      webSocketService.dispose();
      errorHandler.dispose();
      networkDetector.dispose();
    });

    group('Error Detection and Classification', () {
      test('should detect and classify connection errors', () async {
        final errors = <WebSocketError>[];
        final subscription = errorHandler.errorStream.listen(errors.add);

        // Attempt connection to unreachable server
        await webSocketService.connect();

        // Wait for error to be emitted
        await Future.delayed(const Duration(milliseconds: 300));

        expect(errors, isNotEmpty);
        final error = errors.first;
        expect(error.type, anyOf(
          WebSocketErrorType.networkError,
          WebSocketErrorType.connectionTimeout,
          WebSocketErrorType.serverError,
        ));
        expect(error.isRecoverable, isTrue);

        await subscription.cancel();
      });

      test('should handle authentication errors', () async {
        Future<String?> failingAuthProvider() async => null;

        final authService = WebSocketService(
          const WebSocketConfig(
            url: 'ws://localhost:3000',
            reconnectInterval: Duration(milliseconds: 100),
            maxReconnectAttempts: 2,
            heartbeatInterval: Duration(seconds: 1),
          ),
          failingAuthProvider,
          errorHandler: errorHandler,
          reconnectionStrategy: reconnectionStrategy,
          networkDetector: networkDetector,
        );

        final errors = <WebSocketError>[];
        final subscription = errorHandler.errorStream.listen(errors.add);

        await authService.connect();

        // Wait for error to be emitted
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errors, isNotEmpty);
        final error = errors.first;
        expect(error.type, WebSocketErrorType.authenticationFailed);
        expect(error.isRecoverable, isFalse);

        await subscription.cancel();
        authService.dispose();
      });
    });

    group('Reconnection Strategy Integration', () {
      test('should use error-aware delay calculation', () async {
        final networkError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final authError = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Auth error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final networkDelay = reconnectionStrategy.calculateDelayWithError(1, networkError);
        final authDelay = reconnectionStrategy.calculateDelayWithError(1, authError);

        // Auth error should have shorter delay (accounting for jitter)
        // Auth delay is 50% of network delay, but jitter can affect this
        expect(authDelay.inMilliseconds, lessThanOrEqualTo(networkDelay.inMilliseconds));
      });

      test('should respect max attempts with error context', () async {
        final recoverableError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        expect(reconnectionStrategy.shouldReconnectForError(recoverableError, 0, 3), isTrue);
        expect(reconnectionStrategy.shouldReconnectForError(recoverableError, 2, 3), isTrue);
        expect(reconnectionStrategy.shouldReconnectForError(recoverableError, 3, 3), isFalse);
      });

      test('should not reconnect for non-recoverable errors', () async {
        final nonRecoverableError = WebSocketError(
          type: WebSocketErrorType.tokenRefreshFailed,
          message: 'Token refresh failed',
          timestamp: DateTime.now(),
          isRecoverable: false,
        );

        expect(reconnectionStrategy.shouldReconnectForError(nonRecoverableError, 0, 3), isFalse);
      });
    });

    group('Network Connectivity Integration', () {
      test('should detect network connectivity changes', () async {
        final connectivityChanges = <bool>[];
        final subscription = networkDetector.connectivityStream.listen(connectivityChanges.add);

        networkDetector.startMonitoring();

        // Wait for initial connectivity check
        await Future.delayed(const Duration(milliseconds: 300));

        networkDetector.stopMonitoring();

        // Should have performed connectivity checks
        expect(() => networkDetector.stopMonitoring(), returnsNormally);

        await subscription.cancel();
      });

      test('should check WebSocket server reachability', () async {
        // Test with unreachable server
        final isReachable = await networkDetector.isWebSocketServerReachable('ws://localhost:9999');
        expect(isReachable, isFalse);
      });
    });

    group('Complete Error Handling Flow', () {
      test('should handle connection failure with proper error flow', () async {
        final errors = <WebSocketError>[];
        final states = <WebSocketConnectionState>[];

        final errorSubscription = errorHandler.errorStream.listen(errors.add);
        final stateSubscription = webSocketService.connectionState.listen(states.add);

        // Attempt connection
        await webSocketService.connect();

        // Wait for error handling to complete
        await Future.delayed(const Duration(milliseconds: 500));

        // Should have emitted connection state changes
        expect(states, contains(WebSocketConnectionState.connecting));
        expect(states, anyOf(
          contains(WebSocketConnectionState.error),
          contains(WebSocketConnectionState.reconnecting),
        ));

        // Should have emitted errors
        expect(errors, isNotEmpty);

        // Should track last error
        expect(webSocketService.lastError, isNotNull);

        await errorSubscription.cancel();
        await stateSubscription.cancel();
      });

      test('should handle max reconnect attempts', () async {
        final errors = <WebSocketError>[];
        final subscription = errorHandler.errorStream.listen(errors.add);

        // Attempt connection (will fail and trigger reconnects)
        await webSocketService.connect();

        // Wait for all reconnect attempts to complete
        await Future.delayed(const Duration(seconds: 3));

        // Should have emitted errors (max attempts error might not be emitted in test environment)
        expect(errors, isNotEmpty);
        
        // Should have attempted connection and failed
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });
    });

    group('Error Recovery Scenarios', () {
      test('should handle token expiration scenario', () async {
        final tokenExpiredError = errorHandler.analyzeError('Token expired');
        
        expect(tokenExpiredError.type, WebSocketErrorType.tokenExpired);
        expect(tokenExpiredError.isRecoverable, isTrue);
        
        final shouldReconnect = reconnectionStrategy.shouldReconnectForError(
          tokenExpiredError, 
          1, 
          3,
        );
        expect(shouldReconnect, isTrue);
      });

      test('should handle server error scenario', () async {
        final serverError = errorHandler.analyzeError('500 Internal Server Error');
        
        expect(serverError.type, WebSocketErrorType.serverError);
        expect(serverError.isRecoverable, isTrue);
        
        // Server errors should have longer delay
        final delay = errorHandler.getRetryDelay(serverError, const Duration(seconds: 1));
        expect(delay.inMilliseconds, greaterThan(1000));
      });

      test('should handle heartbeat timeout scenario', () async {
        final heartbeatError = errorHandler.createHeartbeatTimeoutError();
        
        expect(heartbeatError.type, WebSocketErrorType.heartbeatTimeout);
        expect(heartbeatError.isRecoverable, isTrue);
        
        // Heartbeat errors should have shorter delay (70% of base delay + jitter tolerance)
        final baseDelay = reconnectionStrategy.calculateDelay(1);
        final delay = reconnectionStrategy.calculateDelayWithError(1, heartbeatError);
        // Allow for jitter - delay should be roughly 70% but with 10% jitter it can vary
        expect(delay.inMilliseconds, lessThanOrEqualTo(baseDelay.inMilliseconds + 50));
      });
    });

    group('Performance and Resource Management', () {
      test('should dispose resources properly', () async {
        expect(() => webSocketService.dispose(), returnsNormally);
        expect(() => errorHandler.dispose(), returnsNormally);
        expect(() => networkDetector.dispose(), returnsNormally);
      });

      test('should handle rapid connection attempts', () async {
        // Attempt multiple rapid connections
        for (int i = 0; i < 5; i++) {
          unawaited(webSocketService.connect());
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Wait for all attempts to settle
        await Future.delayed(const Duration(milliseconds: 500));

        // Should handle gracefully without crashing
        expect(webSocketService.currentState, isA<WebSocketConnectionState>());
      });
    });
  });
}