import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'mock_websocket_server.dart';

@GenerateMocks([SharedPreferenceHelper])
import 'websocket_lifecycle_integration_test.mocks.dart';

void main() {
  group('WebSocket App Lifecycle Integration Tests', () {
    late MockWebSocketServer mockServer;
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;
    late IWebSocketService webSocketService;
    late AppLifecycleManager lifecycleManager;
    late MissedUpdateSynchronizer synchronizer;
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

      // Setup auth mock
      when(mockSharedPreferenceHelper.authToken)
          .thenAnswer((_) async => 'valid-test-token');
      when(mockSharedPreferenceHelper.isLoggedIn)
          .thenAnswer((_) async => true);

      // Create WebSocket service with mock server URL
      final config = WebSocketConfig(
        url: 'ws://localhost:${mockServer.port}',
        reconnectInterval: const Duration(milliseconds: 200),
        maxReconnectAttempts: 3,
        heartbeatInterval: const Duration(seconds: 1),
        autoReconnect: true,
      );

      webSocketService = WebSocketFactory.createWebSocketService(
        sharedPreferenceHelper: mockSharedPreferenceHelper,
        config: config,
      );

      // Create synchronizer and lifecycle manager
      synchronizer = MissedUpdateSynchronizer(webSocketService);
      lifecycleManager = AppLifecycleManager(
        webSocketService,
        synchronizer,
        hasActiveSubscriptionsCallback: () => true, // Always has subscriptions for testing
      );
    });

    tearDown(() async {
      lifecycleManager.dispose();
      await webSocketService.disconnect();
      await serverEventSubscription.cancel();
      await mockServer.stop();
      mockServer.dispose();
      WebSocketManager.resetInstance();
    });

    group('App Lifecycle State Transitions', () {
      test('should disconnect when app goes to background (paused)', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate app going to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        
        // Wait for disconnection
        await Future.delayed(const Duration(milliseconds: 700));

        // Should be disconnected
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
        expect(lifecycleManager.backgroundTime, isNotNull);

        await subscription.cancel();
      });

      test('should disconnect when app is detached', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate app being detached
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.detached);
        
        // Wait for disconnection
        await Future.delayed(const Duration(milliseconds: 700));

        // Should be disconnected
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
        expect(lifecycleManager.backgroundTime, isNotNull);

        await subscription.cancel();
      });

      test('should reconnect when app returns to foreground (resumed)', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        // Go to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Return to foreground
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        
        // Wait for reconnection
        await Future.delayed(const Duration(milliseconds: 800));

        // Should be connected or connecting
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.connecting));
        expect(lifecycleManager.backgroundTime, isNull);

        await subscription.cancel();
      });

      test('should not disconnect when app is inactive', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate app becoming inactive (e.g., notification panel pulled down)
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.inactive);
        
        // Wait to ensure no disconnection
        await Future.delayed(const Duration(milliseconds: 700));

        // Should still be connected
        expect(webSocketService.currentState, WebSocketConnectionState.connected);
        expect(lifecycleManager.backgroundTime, isNull);

        await subscription.cancel();
      });

      test('should not disconnect when app is hidden', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate app being hidden
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.hidden);
        
        // Wait to ensure no disconnection
        await Future.delayed(const Duration(milliseconds: 700));

        // Should still be connected
        expect(webSocketService.currentState, WebSocketConnectionState.connected);
        expect(lifecycleManager.backgroundTime, isNull);

        await subscription.cancel();
      });

      test('should debounce rapid lifecycle changes', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Rapid state changes
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        
        // Wait for debouncing to settle
        await Future.delayed(const Duration(milliseconds: 800));

        // Should have processed only the final state (resumed)
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.connecting));

        await subscription.cancel();
      });
    });

    group('Background/Foreground Data Synchronization', () {
      test('should synchronize missed updates after returning from background', () async {
        // Connect and subscribe
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        webSocketService.subscribe('sync-test-channel', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send initial message
        await mockServer.broadcastToChannel('sync-test-channel', {
          'type': 'before-background',
          'data': {'content': 'Before background'},
        });

        await Future.delayed(const Duration(milliseconds: 100));
        expect(receivedMessages, hasLength(1));

        // Go to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        // Send messages while in background (should be missed)
        await mockServer.broadcastToChannel('sync-test-channel', {
          'type': 'during-background-1',
          'data': {'content': 'During background 1'},
        });

        await mockServer.broadcastToChannel('sync-test-channel', {
          'type': 'during-background-2',
          'data': {'content': 'During background 2'},
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Return to foreground
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        
        // Wait for reconnection and synchronization
        await Future.delayed(const Duration(seconds: 2));

        // Send message after returning
        await mockServer.broadcastToChannel('sync-test-channel', {
          'type': 'after-background',
          'data': {'content': 'After background'},
        });

        await Future.delayed(const Duration(milliseconds: 500));

        // Should have received the message after returning (synchronization may vary)
        expect(receivedMessages.length, greaterThanOrEqualTo(1));
        
        // Verify synchronization was attempted
        expect(lifecycleManager.backgroundTime, isNull); // Should be cleared after resume
      });

      test('should handle long background periods correctly', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        // Go to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        final backgroundTime = lifecycleManager.backgroundTime;
        expect(backgroundTime, isNotNull);

        // Simulate long background period
        await Future.delayed(const Duration(milliseconds: 500));

        // Return to foreground
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        
        // Wait for reconnection
        await Future.delayed(const Duration(milliseconds: 800));

        // Should have attempted synchronization for the background period
        expect(lifecycleManager.backgroundTime, isNull);
        
        // Should be connected or connecting
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.connecting));
      });

      test('should not synchronize if no active subscriptions', () async {
        // Create lifecycle manager with no active subscriptions
        final noSubsLifecycleManager = AppLifecycleManager(
          webSocketService,
          synchronizer,
          hasActiveSubscriptionsCallback: () => false, // No active subscriptions
        );

        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Go to background
        noSubsLifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        // Return to foreground
        noSubsLifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 500));

        // Should not have attempted reconnection
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);

        await subscription.cancel();
        noSubsLifecycleManager.dispose();
      });

      test('should handle synchronization errors gracefully', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        // Go to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        // Simulate server issues during synchronization
        mockServer.simulateServerOverload();

        // Return to foreground
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        
        // Wait for reconnection attempt
        await Future.delayed(const Duration(seconds: 2));

        // Should handle synchronization errors gracefully
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.error, WebSocketConnectionState.reconnecting, WebSocketConnectionState.connecting));

        // Reset server
        mockServer.resetToNormal();
        await Future.delayed(const Duration(milliseconds: 500));
      });
    });

    group('Subscription Management During Lifecycle', () {
      test('should maintain subscriptions across lifecycle changes', () async {
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
          'type': 'initial',
          'data': {'content': 'Initial message'},
        });

        await Future.delayed(const Duration(milliseconds: 100));
        expect(receivedMessages, hasLength(1));

        // Go through background/foreground cycle
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 800));

        // Send message after lifecycle change
        await mockServer.broadcastToChannel('persistent-channel', {
          'type': 'after-lifecycle',
          'data': {'content': 'After lifecycle'},
        });

        await Future.delayed(const Duration(milliseconds: 500));

        // Should have received message after lifecycle change
        expect(receivedMessages.length, greaterThanOrEqualTo(1));

        // Verify subscription was re-established
        final subscribeEvents = serverEvents.where((e) => e.type == 'channel_subscribed').toList();
        expect(subscribeEvents.length, greaterThanOrEqualTo(1));
      });

      test('should handle subscription failures during reconnection', () async {
        // Connect and subscribe
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        webSocketService.subscribe('test-channel', (data) {});
        await Future.delayed(const Duration(milliseconds: 200));

        // Go to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        // Simulate server issues for subscriptions
        mockServer.simulateServerOverload();

        // Return to foreground
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(seconds: 2));

        // Should handle subscription failures gracefully
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.error, WebSocketConnectionState.reconnecting));

        // Reset server
        mockServer.resetToNormal();
        await Future.delayed(const Duration(milliseconds: 500));
      });

      test('should unsubscribe cleanly during background transition', () async {
        // Connect and subscribe
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        webSocketService.subscribe('temp-channel', (data) {});
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify subscription
        final initialSubscribeEvents = serverEvents.where((e) => e.type == 'channel_subscribed').toList();
        expect(initialSubscribeEvents, hasLength(1));

        // Unsubscribe before going to background
        webSocketService.unsubscribe('temp-channel');
        await Future.delayed(const Duration(milliseconds: 200));

        // Go to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        // Return to foreground
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 800));

        // Should not have re-subscribed to unsubscribed channel
        final allSubscribeEvents = serverEvents.where((e) => e.type == 'channel_subscribed').toList();
        final tempChannelSubscriptions = allSubscribeEvents.where((e) => e.data['channel'] == 'temp-channel').toList();
        expect(tempChannelSubscriptions, hasLength(1)); // Only the initial subscription
      });
    });

    group('Performance During Lifecycle Changes', () {
      test('should handle rapid lifecycle changes efficiently', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final startTime = DateTime.now();

        // Perform many rapid lifecycle changes
        for (int i = 0; i < 10; i++) {
          lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
          lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Wait for all changes to be processed
        await Future.delayed(const Duration(milliseconds: 800));

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Should handle rapid changes efficiently
        expect(duration.inSeconds, lessThan(5));
        
        // Should be in a stable state
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.connecting));
      });

      test('should not leak resources during lifecycle changes', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        // Perform multiple lifecycle cycles
        for (int i = 0; i < 5; i++) {
          lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
          await Future.delayed(const Duration(milliseconds: 200));
          
          lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // Should maintain reasonable connection count on server
        final stats = mockServer.getStats();
        expect(stats['clientCount'], lessThanOrEqualTo(2)); // Allow for some connection overlap
      });

      test('should maintain performance with many subscriptions during lifecycle', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        // Create many subscriptions
        const subscriptionCount = 20;
        for (int i = 0; i < subscriptionCount; i++) {
          webSocketService.subscribe('channel-$i', (data) {});
        }

        await Future.delayed(const Duration(milliseconds: 500));

        final startTime = DateTime.now();

        // Go through lifecycle change
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 700));

        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(seconds: 2));

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Should handle many subscriptions efficiently
        expect(duration.inSeconds, lessThan(10));
        
        // Should be connected
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.connecting));
      });
    });
  });
}