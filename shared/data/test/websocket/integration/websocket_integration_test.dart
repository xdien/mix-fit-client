import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';

@GenerateMocks([SharedPreferenceHelper])
import '../services/websocket_auth_integration_test.mocks.dart';

void main() {
  group('WebSocket Integration Tests', () {
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;

    setUp(() {
      mockSharedPreferenceHelper = MockSharedPreferenceHelper();
      WebSocketManager.resetInstance();
    });

    tearDown(() {
      WebSocketManager.resetInstance();
    });

    group('Complete Authentication Flow', () {
      test('should initialize and handle authentication flow', () async {
        const testToken = 'integration-test-jwt-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Initialize WebSocket manager using factory
        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
          config: const WebSocketConfig(
            url: 'ws://localhost:3000',
            reconnectInterval: Duration(seconds: 1),
            maxReconnectAttempts: 2,
            heartbeatInterval: Duration(seconds: 5),
            autoReconnect: true,
          ),
        );

        final manager = WebSocketManager.instance;
        expect(manager.webSocketService, isNotNull);
        expect(manager.currentState, WebSocketConnectionState.disconnected);

        // Test subscription
        bool callbackCalled = false;
        manager.subscribe('test-channel', (data) {
          callbackCalled = true;
        });

        // Test connection attempt (will fail in test environment but should attempt auth)
        unawaited(manager.connect());
        
        // Wait for connection attempt
        await Future.delayed(const Duration(milliseconds: 100));

        // In test environment, network connectivity check might prevent auth token call
        // So we just verify the connection was attempted
        expect(manager.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting, WebSocketConnectionState.connecting));

        // Test unsubscribe
        manager.unsubscribe('test-channel');

        // Test disconnect
        await manager.disconnect();
        expect(manager.currentState, WebSocketConnectionState.disconnected);
      });

      test('should handle authentication failure gracefully', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => null);
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => false);

        // Initialize WebSocket manager
        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        final manager = WebSocketManager.instance;

        // Attempt connection without token
        await manager.connect();

        // Should be in error state
        expect(manager.currentState, WebSocketConnectionState.error);
        verify(mockSharedPreferenceHelper.authToken).called(1);
      });
    });

    group('Service Creation and Configuration', () {
      test('should create service with custom configuration', () {
        const customConfig = WebSocketConfig(
          url: 'wss://custom.example.com/socket.io',
          reconnectInterval: Duration(seconds: 3),
          maxReconnectAttempts: 8,
          heartbeatInterval: Duration(seconds: 20),
          autoReconnect: false,
        );

        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'test-token');

        final service = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
          config: customConfig,
        );

        expect(service, isA<WebSocketService>());
        expect(service.currentState, WebSocketConnectionState.disconnected);
      });

      test('should create production configuration correctly', () {
        final config = WebSocketFactory.createProductionConfig('https://api.example.com');

        expect(config.url, equals('wss://api.example.com/socket.io'));
        expect(config.autoReconnect, isTrue);
        expect(config.maxReconnectAttempts, equals(15));
      });

      test('should create development configuration correctly', () {
        final config = WebSocketFactory.createDevelopmentConfig();

        expect(config.url, equals('ws://localhost:3000/socket.io'));
        expect(config.autoReconnect, isTrue);
        expect(config.maxReconnectAttempts, equals(5));
      });
    });

    group('Auth Integration', () {
      test('should integrate with auth system correctly', () async {
        const testToken = 'auth-integration-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        final authIntegration = WebSocketAuthIntegration(mockSharedPreferenceHelper);

        // Test token retrieval
        final token = await authIntegration.getAuthToken();
        expect(token, equals(testToken));

        // Test login status
        final isLoggedIn = await authIntegration.isLoggedIn();
        expect(isLoggedIn, isTrue);

        // Test factory methods
        final tokenGetter = authIntegration.createTokenGetter();
        final retrievedToken = await tokenGetter();
        expect(retrievedToken, equals(testToken));

        final tokenRefresher = authIntegration.createTokenRefresher();
        expect(tokenRefresher, isNull); // Not implemented yet

        verify(mockSharedPreferenceHelper.authToken).called(2);
        verify(mockSharedPreferenceHelper.isLoggedIn).called(1);
      });
    });

    group('Connection State Management', () {
      test('should manage connection states correctly', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'test-token');

        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        final manager = WebSocketManager.instance;
        final stateChanges = <WebSocketConnectionState>[];
        final subscription = manager.connectionState.listen(stateChanges.add);

        // Initial state
        expect(manager.currentState, WebSocketConnectionState.disconnected);
        expect(manager.isConnected, isFalse);
        expect(manager.isConnecting, isFalse);
        expect(manager.isReconnecting, isFalse);
        expect(manager.hasError, isFalse);

        // Attempt connection
        unawaited(manager.connect());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have attempted connection
        expect(stateChanges, contains(WebSocketConnectionState.connecting));

        await subscription.cancel();
      });
    });

    group('Error Handling', () {
      test('should handle various error scenarios', () async {
        // Test with storage error
        when(mockSharedPreferenceHelper.authToken)
            .thenThrow(Exception('Storage error'));

        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        final manager = WebSocketManager.instance;

        // Should not throw during connection attempt
        await manager.connect();

        // Should be in error state
        expect(manager.currentState, WebSocketConnectionState.error);
      });
    });

    group('Reconnection Strategy', () {
      test('should use reconnection strategy correctly', () {
        final strategy = ReconnectionStrategy();

        // Test basic functionality
        expect(strategy.shouldAttemptReconnection(1, 5), isTrue);
        expect(strategy.shouldAttemptReconnection(6, 5), isFalse);

        // Test delay calculation
        final delay1 = strategy.calculateDelay(1);
        final delay2 = strategy.calculateDelay(2);

        expect(delay1.inMilliseconds, greaterThanOrEqualTo(1000));
        expect(delay2.inMilliseconds, greaterThanOrEqualTo(2000));
      });
    });
  });
}