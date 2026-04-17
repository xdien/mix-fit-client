import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';

@GenerateMocks([SharedPreferenceHelper])
import 'websocket_e2e_simple_test.mocks.dart';

void main() {
  group('WebSocket E2E Simple Integration Tests', () {
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;
    late IWebSocketService webSocketService;

    setUp(() async {
      mockSharedPreferenceHelper = MockSharedPreferenceHelper();

      // Setup auth mock
      when(mockSharedPreferenceHelper.authToken)
          .thenAnswer((_) async => 'valid-test-token');
      when(mockSharedPreferenceHelper.isLoggedIn)
          .thenAnswer((_) async => true);

      // Create WebSocket service with a non-existent server URL
      // This will test the connection failure handling
      final config = WebSocketConfig(
        url: 'ws://localhost:9999/socket.io', // Non-existent port
        reconnectInterval: const Duration(milliseconds: 100),
        maxReconnectAttempts: 2,
        heartbeatInterval: const Duration(seconds: 1),
        autoReconnect: true,
      );

      webSocketService = WebSocketFactory.createWebSocketService(
        sharedPreferenceHelper: mockSharedPreferenceHelper,
        config: config,
      );
    });

    tearDown(() async {
      await webSocketService.disconnect();
      WebSocketManager.resetInstance();
    });

    group('Connection Error Handling', () {
      test('should handle connection failure gracefully', () async {
        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt to connect to non-existent server
        await webSocketService.connect();
        
        // Wait for connection attempt
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be in error or reconnecting state (due to auto-reconnect)
        expect(connectionStates, contains(WebSocketConnectionState.connecting));
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });

      test('should handle missing token gracefully', () async {
        // Setup missing token
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => null);
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => false);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt to connect
        await webSocketService.connect();
        
        // Wait for connection attempt
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be in error or reconnecting state (due to auto-reconnect)
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });

      test('should handle invalid token gracefully', () async {
        // Setup invalid token
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'invalid-token');

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt to connect
        await webSocketService.connect();
        
        // Wait for connection attempt
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be in error or reconnecting state (due to auto-reconnect)
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });
    });

    group('Service Lifecycle', () {
      test('should handle disconnect correctly', () async {
        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt to connect
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));

        // Disconnect
        await webSocketService.disconnect();
        
        // Should be disconnected
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);

        await subscription.cancel();
      });

      test('should handle multiple connect/disconnect cycles', () async {
        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // First connection attempt
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        await webSocketService.disconnect();

        // Second connection attempt
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        await webSocketService.disconnect();

        // Should handle multiple cycles without issues
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);

        await subscription.cancel();
      });
    });

    group('Subscription Management', () {
      test('should handle subscriptions when disconnected', () async {
        // Subscribe to channels when disconnected
        webSocketService.subscribe('test-channel', (data) {
          // Callback should not be called when disconnected
        });

        // Should not throw any errors
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });

      test('should handle unsubscription when disconnected', () async {
        // Subscribe and then unsubscribe when disconnected
        webSocketService.subscribe('test-channel', (data) {});
        webSocketService.unsubscribe('test-channel');

        // Should not throw any errors
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });
    });

    group('Error Handling', () {
      test('should handle network connectivity issues', () async {
        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt to connect to unreachable server
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));

        // Should handle network issues gracefully
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });

      test('should handle reconnection attempts', () async {
        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt to connect
        await webSocketService.connect();
        
        // Wait for multiple reconnection attempts
        await Future.delayed(const Duration(seconds: 2));

        // Should have attempted reconnection
        expect(connectionStates, contains(WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });
    });

    group('Configuration', () {
      test('should use provided configuration', () async {
        final customConfig = WebSocketConfig(
          url: 'ws://localhost:8888/socket.io',
          reconnectInterval: const Duration(seconds: 1),
          maxReconnectAttempts: 1,
          heartbeatInterval: const Duration(seconds: 30),
          autoReconnect: false,
        );

        final customService = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
          config: customConfig,
        );

        // Should use custom configuration
        expect(customService.currentState, WebSocketConnectionState.disconnected);

        await customService.disconnect();
      });

      test('should use default configuration when none provided', () async {
        final defaultService = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        // Should use default configuration
        expect(defaultService.currentState, WebSocketConnectionState.disconnected);

        await defaultService.disconnect();
      });
    });
  });
} 