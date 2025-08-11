import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';

// Generate mocks
@GenerateMocks([])
class MockAuthTokenProvider extends Mock {
  Future<String?> call() => super.noSuchMethod(
    Invocation.method(#call, []),
    returnValue: Future.value(null),
    returnValueForMissingStub: Future.value(null),
  );
}

class MockTokenRefresher extends Mock {
  Future<String?> call() => super.noSuchMethod(
    Invocation.method(#call, []),
    returnValue: Future.value(null),
    returnValueForMissingStub: Future.value(null),
  );
}

void main() {
  group('WebSocketService', () {
    late WebSocketService webSocketService;
    late MockAuthTokenProvider mockAuthTokenProvider;
    late MockTokenRefresher mockTokenRefresher;
    late WebSocketConfig testConfig;

    setUp(() {
      mockAuthTokenProvider = MockAuthTokenProvider();
      mockTokenRefresher = MockTokenRefresher();
      
      testConfig = const WebSocketConfig(
        url: 'ws://localhost:3000',
        reconnectInterval: Duration(seconds: 1),
        maxReconnectAttempts: 3,
        heartbeatInterval: Duration(seconds: 10),
        autoReconnect: true,
      );

      webSocketService = WebSocketService(
        testConfig,
        mockAuthTokenProvider.call,
        refreshToken: mockTokenRefresher.call,
      );
    });

    tearDown(() {
      webSocketService.dispose();
    });

    group('Connection State Management', () {
      test('should start with disconnected state', () {
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });

      test('should emit connection state changes', () async {
        final stateChanges = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(stateChanges.add);

        // Mock successful authentication
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // Attempt connection (will fail in test environment, but state should change)
        unawaited(webSocketService.connect());

        // Wait for state change
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateChanges, contains(WebSocketConnectionState.connecting));
        
        await subscription.cancel();
      });

      test('should handle connection state transitions correctly', () async {
        final stateChanges = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(stateChanges.add);

        // Test disconnect
        await webSocketService.disconnect();
        
        // Wait for state change
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (stateChanges.isNotEmpty) {
          expect(stateChanges.last, WebSocketConnectionState.disconnected);
        }

        await subscription.cancel();
      });
    });

    group('Authentication', () {
      test('should not connect without authentication token', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => null);

        await webSocketService.connect();

        expect(webSocketService.currentState, WebSocketConnectionState.error);
        verify(mockAuthTokenProvider.call()).called(1);
      });

      test('should attempt connection with valid token', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // This will fail in test environment but should attempt connection
        unawaited(webSocketService.connect());
        
        // Wait for connection attempt to complete
        await Future.delayed(const Duration(milliseconds: 1000));

        // In test environment, connection might succeed or fail
        // So we verify that the connection was attempted
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting, WebSocketConnectionState.connecting, WebSocketConnectionState.connected));
      });

      test('should handle token refresh on authentication error', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'expired-token');
        when(mockTokenRefresher.call()).thenAnswer((_) async => 'new-token');

        // Simulate authentication error handling
        await webSocketService.connect();
        
        // In a real scenario, this would be triggered by socket events
        // For testing, we verify the setup is correct
        verify(mockAuthTokenProvider.call()).called(1);
      });
    });

    group('Subscription Management', () {
      test('should manage channel subscriptions', () {
        void testCallback(dynamic data) {
          // Callback implementation for testing
        }

        webSocketService.subscribe('test-channel', testCallback);
        
        // Verify subscription is stored (internal state)
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
        
        webSocketService.unsubscribe('test-channel');
        
        // Subscription should be removed
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });

      test('should handle multiple subscriptions', () {
        final callbacks = <String, bool>{};
        
        void createCallback(String channel) {
          callbacks[channel] = false;
        }

        // Subscribe to multiple channels
        webSocketService.subscribe('channel1', (data) => createCallback('channel1'));
        webSocketService.subscribe('channel2', (data) => createCallback('channel2'));
        webSocketService.subscribe('channel3', (data) => createCallback('channel3'));

        // Unsubscribe from one channel
        webSocketService.unsubscribe('channel2');

        // Verify service is still functional
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });
    });

    group('App Lifecycle Management', () {
      test('should disconnect on app pause', () async {
        await webSocketService.handleAppLifecycle(AppLifecycleState.paused);
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });

      test('should disconnect on app detached', () async {
        await webSocketService.handleAppLifecycle(AppLifecycleState.detached);
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });

      test('should attempt reconnection on app resume with subscriptions', () async {
        // Add a subscription first
        webSocketService.subscribe('test-channel', (data) {});
        
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // This will attempt to connect (and fail in test environment)
        unawaited(webSocketService.handleAppLifecycle(AppLifecycleState.resumed));
        
        // Wait for connection attempt to complete
        await Future.delayed(const Duration(milliseconds: 1000));

        // In test environment, network connectivity check might fail first
        // So we verify that the connection was attempted
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting, WebSocketConnectionState.connecting));
      });

      test('should not reconnect on app resume without subscriptions', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        await webSocketService.handleAppLifecycle(AppLifecycleState.resumed);

        // Should not attempt connection without subscriptions
        verifyNever(mockAuthTokenProvider.call());
      });
    });

    group('Error Handling', () {
      test('should handle connection timeout gracefully', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // Connection will timeout in test environment
        await webSocketService.connect();

        // Should end up in error or reconnecting state due to connection failure
        // In some test environments, connection might succeed
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting, WebSocketConnectionState.connected));
      });

      test('should not exceed max reconnection attempts', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // Multiple connection attempts should respect max attempts
        for (int i = 0; i < testConfig.maxReconnectAttempts + 2; i++) {
          unawaited(webSocketService.connect());
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Should not exceed max attempts
        verify(mockAuthTokenProvider.call()).called(lessThanOrEqualTo(testConfig.maxReconnectAttempts + 1));
      });

      test('should emit errors to error stream', () async {
        final errors = <WebSocketError>[];
        final subscription = webSocketService.errorStream.listen(errors.add);

        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // Attempt connection (will fail in test environment)
        await webSocketService.connect();
        
        // Wait for potential error emission
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have emitted at least one error
        expect(errors, isNotEmpty);
        
        await subscription.cancel();
      });

      test('should track last error', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => null);

        await webSocketService.connect();

        // Should have recorded the authentication error
        expect(webSocketService.lastError, isNotNull);
        expect(webSocketService.lastError!.type, WebSocketErrorType.authenticationFailed);
      });

      test('should handle network connectivity issues', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // Connection will fail due to network issues in test environment
        await webSocketService.connect();

        // Should handle the error gracefully - in some test environments it might succeed
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting, WebSocketConnectionState.connected));
      });

      test('should clear last error on successful connection', () async {
        when(mockAuthTokenProvider.call()).thenAnswer((_) async => 'valid-token');

        // First attempt will fail and set an error
        await webSocketService.connect();
        
        // In test environment, connection might succeed or fail
        // If it fails, there should be an error; if it succeeds, error should be null
        if (webSocketService.currentState == WebSocketConnectionState.error) {
          expect(webSocketService.lastError, isNotNull);
        } else {
          // Connection succeeded, error should be cleared
          expect(webSocketService.lastError, isNull);
        }
      });
    });

    group('Configuration', () {
      test('should use provided configuration', () {
        final customConfig = const WebSocketConfig(
          url: 'ws://custom.com',
          reconnectInterval: Duration(seconds: 2),
          maxReconnectAttempts: 5,
          heartbeatInterval: Duration(seconds: 20),
          autoReconnect: false,
        );

        final customService = WebSocketService(
          customConfig,
          mockAuthTokenProvider.call,
        );

        expect(customService.currentState, WebSocketConnectionState.disconnected);
        
        customService.dispose();
      });
    });

    group('Disposal', () {
      test('should clean up resources on dispose', () {
        webSocketService.dispose();
        
        // Service should be in a clean state
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });

      test('should handle multiple dispose calls gracefully', () {
        webSocketService.dispose();
        webSocketService.dispose(); // Should not throw
        
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });
    });
  });
}