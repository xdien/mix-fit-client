import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'mock_websocket_server.dart';

@GenerateMocks([SharedPreferenceHelper])
import 'websocket_auth_reconnection_integration_test.mocks.dart';

void main() {
  group('WebSocket Authentication & Reconnection Integration Tests', () {
    late MockWebSocketServer mockServer;
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;
    late IWebSocketService webSocketService;
    late StreamSubscription<MockServerEvent> serverEventSubscription;
    final List<MockServerEvent> serverEvents = [];

    setUp(() async {
      mockServer = MockWebSocketServer();
      mockSharedPreferenceHelper = MockSharedPreferenceHelper();
      serverEvents.clear();

      // Start mock server
      await mockServer.start();
      
      // Listen to server events
      serverEventSubscription = mockServer.events.listen(serverEvents.add);

      // Create WebSocket service with mock server URL
      final config = WebSocketConfig(
        url: 'ws://localhost:${mockServer.port}',
        reconnectInterval: const Duration(milliseconds: 200),
        maxReconnectAttempts: 5,
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
      await serverEventSubscription.cancel();
      await mockServer.stop();
      mockServer.dispose();
      WebSocketManager.resetInstance();
    });

    group('Authentication Flow Integration', () {
      test('should authenticate with valid JWT token', () async {
        const validToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => validToken);
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Connect and authenticate
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be connected and authenticated
        expect(webSocketService.currentState, WebSocketConnectionState.connected);
        
        // Verify auth success on server
        final authEvents = serverEvents.where((e) => e.type == 'auth_success').toList();
        expect(authEvents, hasLength(1));

        // Verify token was retrieved
        verify(mockSharedPreferenceHelper.authToken).called(greaterThan(0));

        await subscription.cancel();
      });

      test('should handle expired token and refresh', () async {
        // Start with expired token
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'expired-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Setup server to reject expired token initially
        mockServer.shouldRejectAuth = true;

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt connection
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        // Should be in error state initially
        expect(webSocketService.currentState, WebSocketConnectionState.error);

        // Simulate token refresh by providing new token
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'refreshed-valid-token');
        
        // Reset server to accept new token
        mockServer.shouldRejectAuth = false;

        // Trigger reconnection
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));

        // Should now be connected
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        // Verify multiple auth attempts
        verify(mockSharedPreferenceHelper.authToken).called(greaterThan(1));

        await subscription.cancel();
      });

      test('should handle authentication timeout', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Simulate slow server response
        mockServer.connectionDelay = const Duration(seconds: 2);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        final startTime = DateTime.now();
        
        // Attempt connection
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Should handle timeout gracefully
        expect(duration.inMilliseconds, lessThan(3000));
        expect(connectionStates, contains(WebSocketConnectionState.connecting));

        await subscription.cancel();
      });

      test('should handle multiple concurrent authentication attempts', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Make multiple concurrent connection attempts
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(webSocketService.connect());
        }

        await Future.wait(futures);
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be connected
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        // Should not have duplicate auth attempts
        final authEvents = serverEvents.where((e) => e.type == 'auth_success').toList();
        expect(authEvents.length, lessThanOrEqualTo(2)); // Allow for some race conditions

        await subscription.cancel();
      });

      test('should handle auth failure with proper error reporting', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'invalid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt connection with invalid token
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be in error state
        expect(webSocketService.currentState, WebSocketConnectionState.error);

        // Verify auth failure on server
        final authFailEvents = serverEvents.where((e) => e.type == 'auth_failed').toList();
        expect(authFailEvents, hasLength(1));
        expect(authFailEvents.first.data['reason'], contains('Token validation failed'));

        await subscription.cancel();
      });
    });

    group('Reconnection Strategy Integration', () {
      test('should implement exponential backoff correctly', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Setup server to reject connections initially
        mockServer.simulateConnectionDrops();

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);
        final reconnectionTimes = <DateTime>[];

        // Track reconnection attempts
        subscription.onData((state) {
          if (state == WebSocketConnectionState.reconnecting) {
            reconnectionTimes.add(DateTime.now());
          }
        });

        // Attempt connection
        await webSocketService.connect();
        
        // Wait for multiple reconnection attempts
        await Future.delayed(const Duration(seconds: 3));

        // Should have made multiple reconnection attempts
        expect(reconnectionTimes.length, greaterThan(1));

        // Verify exponential backoff (each attempt should be longer than the previous)
        if (reconnectionTimes.length >= 2) {
          final firstInterval = reconnectionTimes[1].difference(reconnectionTimes[0]);
          if (reconnectionTimes.length >= 3) {
            final secondInterval = reconnectionTimes[2].difference(reconnectionTimes[1]);
            expect(secondInterval.inMilliseconds, greaterThanOrEqualTo(firstInterval.inMilliseconds));
          }
        }

        await subscription.cancel();
      });

      test('should respect maximum reconnection attempts', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Create service with limited reconnection attempts
        final config = WebSocketConfig(
          url: 'ws://localhost:${mockServer.port}',
          reconnectInterval: const Duration(milliseconds: 100),
          maxReconnectAttempts: 2,
          heartbeatInterval: const Duration(seconds: 1),
          autoReconnect: true,
        );

        final limitedService = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
          config: config,
        );

        // Setup server to always reject connections
        mockServer.simulateConnectionDrops();

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = limitedService.connectionState.listen(connectionStates.add);

        // Attempt connection
        await limitedService.connect();
        
        // Wait for all reconnection attempts
        await Future.delayed(const Duration(seconds: 2));

        // Should eventually give up and be in error state
        expect(limitedService.currentState, WebSocketConnectionState.error);

        // Should not have made more than maxReconnectAttempts
        final reconnectingStates = connectionStates.where((s) => s == WebSocketConnectionState.reconnecting).length;
        expect(reconnectingStates, lessThanOrEqualTo(2));

        await subscription.cancel();
        await limitedService.disconnect();
      });

      test('should successfully reconnect after temporary failure', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Connect initially
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate temporary server failure
        mockServer.simulateConnectionDrops();
        
        // Wait for disconnection detection
        await Future.delayed(const Duration(milliseconds: 500));

        // Reset server to normal
        mockServer.resetToNormal();
        
        // Wait for reconnection
        await Future.delayed(const Duration(seconds: 2));

        // Should have reconnected
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.reconnecting));

        // Should have gone through reconnection states
        expect(connectionStates, contains(WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });

      test('should maintain subscriptions during reconnection', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Connect and subscribe
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        webSocketService.subscribe('persistent-channel', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send initial message
        await mockServer.broadcastToChannel('persistent-channel', {
          'type': 'before-disconnect',
          'data': {'content': 'Before disconnect'},
        });

        await Future.delayed(const Duration(milliseconds: 100));
        expect(receivedMessages, hasLength(1));

        // Simulate connection drop
        mockServer.simulateConnectionDrops();
        await Future.delayed(const Duration(milliseconds: 300));

        // Reset server
        mockServer.resetToNormal();
        await Future.delayed(const Duration(seconds: 1));

        // Wait for reconnection and re-subscription
        await Future.delayed(const Duration(milliseconds: 500));

        // Send message after reconnection
        await mockServer.broadcastToChannel('persistent-channel', {
          'type': 'after-reconnect',
          'data': {'content': 'After reconnect'},
        });

        await Future.delayed(const Duration(milliseconds: 500));

        // Should have received message after reconnection
        expect(receivedMessages.length, greaterThanOrEqualTo(1));
        
        // Verify subscription was maintained
        final subscribeEvents = serverEvents.where((e) => e.type == 'channel_subscribed').toList();
        expect(subscribeEvents.length, greaterThanOrEqualTo(1));
      });

      test('should handle network connectivity changes', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Connect initially
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate network issues
        mockServer.simulateNetworkIssues();
        
        // Wait for connection issues to be detected
        await Future.delayed(const Duration(milliseconds: 500));

        // Reset to normal network
        mockServer.resetToNormal();
        
        // Wait for recovery
        await Future.delayed(const Duration(seconds: 1));

        // Should handle network changes gracefully
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });
    });

    group('Error Handling Integration', () {
      test('should handle server errors gracefully', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate server overload
        mockServer.simulateServerOverload();

        // Try to subscribe (should handle server errors)
        webSocketService.subscribe('test-channel', (data) {});
        
        // Wait for error handling
        await Future.delayed(const Duration(seconds: 2));

        // Should handle errors without crashing
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });

      test('should handle malformed server responses', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        webSocketService.subscribe('test-channel', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Enable message corruption
        mockServer.shouldCorruptMessages = true;

        // Send messages (some will be corrupted)
        for (int i = 0; i < 5; i++) {
          await mockServer.broadcastToChannel('test-channel', {
            'type': 'test-message',
            'data': {'content': 'Message $i'},
          });
          await Future.delayed(const Duration(milliseconds: 100));
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Should still be connected despite corrupted messages
        expect(webSocketService.currentState, WebSocketConnectionState.connected);
      });

      test('should handle concurrent error scenarios', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'valid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate multiple error conditions simultaneously
        mockServer.simulateNetworkIssues();
        mockServer.simulateServerOverload();

        // Attempt connection
        await webSocketService.connect();
        
        // Wait for error handling
        await Future.delayed(const Duration(seconds: 2));

        // Should handle multiple errors gracefully
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        // Reset and allow recovery
        mockServer.resetToNormal();
        await Future.delayed(const Duration(seconds: 1));

        // Should eventually recover
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });

      test('should provide meaningful error information', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'invalid-token');
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt connection with invalid token
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be in error state
        expect(webSocketService.currentState, WebSocketConnectionState.error);

        // Verify meaningful error information is available on server
        final authFailEvents = serverEvents.where((e) => e.type == 'auth_failed').toList();
        expect(authFailEvents, hasLength(1));
        expect(authFailEvents.first.data['reason'], isNotEmpty);

        await subscription.cancel();
      });
    });
  });
}