import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:data/websocket/websocket.dart';

class MockAuthTokenProvider extends Mock {
  Future<String?> call() => super.noSuchMethod(
    Invocation.method(#call, []),
    returnValue: Future.value('test-token'),
    returnValueForMissingStub: Future.value('test-token'),
  );
}

class MockTokenRefresher extends Mock {
  Future<String?> call() => super.noSuchMethod(
    Invocation.method(#call, []),
    returnValue: Future.value('refreshed-token'),
    returnValueForMissingStub: Future.value('refreshed-token'),
  );
}

void main() {
  group('WebSocketManager', () {
    late WebSocketManager webSocketManager;
    late MockAuthTokenProvider mockAuthTokenProvider;
    late MockTokenRefresher mockTokenRefresher;
    late WebSocketConfig testConfig;

    setUp(() {
      // Reset singleton instance before each test
      WebSocketManager.resetInstance();
      
      webSocketManager = WebSocketManager.instance;
      mockAuthTokenProvider = MockAuthTokenProvider();
      mockTokenRefresher = MockTokenRefresher();
      
      testConfig = const WebSocketConfig(
        url: 'ws://localhost:3000',
        reconnectInterval: Duration(seconds: 1),
        maxReconnectAttempts: 3,
        heartbeatInterval: Duration(seconds: 10),
        autoReconnect: true,
      );
    });

    tearDown(() {
      webSocketManager.dispose();
    });

    group('Initialization', () {
      test('should be a singleton', () {
        final instance1 = WebSocketManager.instance;
        final instance2 = WebSocketManager.instance;
        
        expect(instance1, same(instance2));
      });

      test('should initialize with authentication callbacks', () {
        webSocketManager.initialize(
          config: testConfig,
          getAuthToken: mockAuthTokenProvider.call,
          refreshToken: mockTokenRefresher.call,
        );

        expect(webSocketManager.webSocketService, isNotNull);
        expect(webSocketManager.currentState, WebSocketConnectionState.disconnected);
      });

      test('should throw error when not initialized', () {
        expect(
          () => webSocketManager.connect(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Connection Management', () {
      setUp(() {
        webSocketManager.initialize(
          config: testConfig,
          getAuthToken: mockAuthTokenProvider.call,
          refreshToken: mockTokenRefresher.call,
        );
      });

      test('should forward connection state changes', () async {
        final stateChanges = <WebSocketConnectionState>[];
        final subscription = webSocketManager.connectionState.listen(stateChanges.add);

        // Attempt connection (will fail in test environment)
        unawaited(webSocketManager.connect());
        
        // Wait for state change
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateChanges, contains(WebSocketConnectionState.connecting));
        
        await subscription.cancel();
      });

      test('should handle disconnect properly', () async {
        await webSocketManager.disconnect();
        expect(webSocketManager.currentState, WebSocketConnectionState.disconnected);
      });

      test('should provide connection status helpers', () {
        expect(webSocketManager.isConnected, false);
        expect(webSocketManager.isConnecting, false);
        expect(webSocketManager.isReconnecting, false);
        expect(webSocketManager.hasError, false);
      });
    });

    group('Subscription Management', () {
      setUp(() {
        webSocketManager.initialize(
          config: testConfig,
          getAuthToken: mockAuthTokenProvider.call,
          refreshToken: mockTokenRefresher.call,
        );
      });

      test('should handle channel subscriptions', () {
        void testCallback(dynamic data) {
          // Callback implementation for testing
        }

        webSocketManager.subscribe('test-channel', testCallback);
        webSocketManager.unsubscribe('test-channel');

        // Should not throw and maintain state
        expect(webSocketManager.currentState, WebSocketConnectionState.disconnected);
      });

      test('should throw error when subscribing without initialization', () {
        WebSocketManager.resetInstance();
        final uninitializedManager = WebSocketManager.instance;

        expect(
          () => uninitializedManager.subscribe('test-channel', (data) {}),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('App Lifecycle Management', () {
      setUp(() {
        webSocketManager.initialize(
          config: testConfig,
          getAuthToken: mockAuthTokenProvider.call,
          refreshToken: mockTokenRefresher.call,
        );
      });

      test('should handle app lifecycle changes', () async {
        await webSocketManager.handleAppLifecycle(AppLifecycleState.paused);
        expect(webSocketManager.currentState, WebSocketConnectionState.disconnected);

        await webSocketManager.handleAppLifecycle(AppLifecycleState.resumed);
        // State may change based on subscriptions
      });

      test('should handle lifecycle changes when not initialized', () async {
        WebSocketManager.resetInstance();
        final uninitializedManager = WebSocketManager.instance;

        // Should not throw
        await uninitializedManager.handleAppLifecycle(AppLifecycleState.paused);
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () async {
        webSocketManager.initialize(
          config: testConfig,
          getAuthToken: () async => null, // No token
          refreshToken: mockTokenRefresher.call,
        );

        await webSocketManager.connect();
        expect(webSocketManager.currentState, WebSocketConnectionState.error);
      });
    });

    group('Disposal', () {
      test('should dispose properly', () {
        webSocketManager.initialize(
          config: testConfig,
          getAuthToken: mockAuthTokenProvider.call,
          refreshToken: mockTokenRefresher.call,
        );

        webSocketManager.dispose();
        
        // Should be able to get new instance after disposal
        final newInstance = WebSocketManager.instance;
        expect(newInstance, isNotNull);
      });

      test('should reset singleton instance', () {
        final instance1 = WebSocketManager.instance;
        WebSocketManager.resetInstance();
        final instance2 = WebSocketManager.instance;
        
        expect(instance1, isNot(same(instance2)));
      });
    });

    group('Integration', () {
      test('should work with real WebSocket service', () async {
        webSocketManager.initialize(
          config: testConfig,
          getAuthToken: mockAuthTokenProvider.call,
          refreshToken: mockTokenRefresher.call,
        );

        expect(webSocketManager.webSocketService, isA<WebSocketService>());
        expect(webSocketManager.currentState, WebSocketConnectionState.disconnected);

        // Test subscription
        webSocketManager.subscribe('test-channel', (data) {});
        
        // Test connection attempt
        unawaited(webSocketManager.connect());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have attempted authentication
        verify(mockAuthTokenProvider.call()).called(1);
      });
    });
  });
}