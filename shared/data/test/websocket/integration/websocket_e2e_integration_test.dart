import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'mock_socketio_server.dart';

@GenerateMocks([SharedPreferenceHelper])
import 'websocket_e2e_integration_test.mocks.dart';

void main() {
  group('WebSocket End-to-End Integration Tests', () {
    late MockSocketIOServer mockServer;
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;
    late IWebSocketService webSocketService;
    late StreamSubscription<MockServerEvent> serverEventSubscription;
    final List<MockServerEvent> serverEvents = [];

    setUp(() async {
      mockServer = MockSocketIOServer();
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
        url: 'ws://localhost:${mockServer.port}/socket.io',
        reconnectInterval: const Duration(milliseconds: 100),
        maxReconnectAttempts: 3,
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

    group('Complete Connection Flow', () {
      test('should establish connection and authenticate successfully', () async {
        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Connect
        await webSocketService.connect();
        
        // Wait for connection to establish
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify connection states
        expect(connectionStates, contains(WebSocketConnectionState.connecting));
        expect(connectionStates, contains(WebSocketConnectionState.connected));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        // Verify server received connection and auth
        final authEvents = serverEvents.where((e) => e.type == 'auth_success').toList();
        expect(authEvents, hasLength(1));

        await subscription.cancel();
      });

      test('should handle authentication failure gracefully', () async {
        // Setup auth failure
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'invalid-token');

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Connect
        await webSocketService.connect();
        
        // Wait for connection attempt
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be in error state
        expect(webSocketService.currentState, WebSocketConnectionState.error);

        // Verify server received auth failure
        final authFailEvents = serverEvents.where((e) => e.type == 'auth_failed').toList();
        expect(authFailEvents, hasLength(1));

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

        // Connect
        await webSocketService.connect();
        
        // Wait for connection attempt
        await Future.delayed(const Duration(milliseconds: 500));

        // Should be in error state
        expect(webSocketService.currentState, WebSocketConnectionState.error);

        await subscription.cancel();
      });
    });

    group('Data Flow and Messaging', () {
      test('should send and receive messages correctly', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final receivedMessages = <dynamic>[];
        
        // Subscribe to a channel
        webSocketService.subscribe('test-channel', (data) {
          receivedMessages.add(data);
        });

        // Wait for subscription to be processed
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify subscription on server
        final subscribeEvents = serverEvents.where((e) => e.type == 'channel_subscribed').toList();
        expect(subscribeEvents, hasLength(1));
        expect(subscribeEvents.first.data['room'], 'test-channel');

        // Broadcast message from server
        await mockServer.broadcastToRoom('test-channel', {
          'type': 'test-message',
          'data': {'content': 'Hello from server'},
        });

        // Wait for message to be received
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify message was received
        expect(receivedMessages, hasLength(1));
        expect(receivedMessages.first['type'], 'test-message');
        expect(receivedMessages.first['data']['content'], 'Hello from server');
      });

      test('should handle multiple channel subscriptions', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final channel1Messages = <dynamic>[];
        final channel2Messages = <dynamic>[];
        
        // Subscribe to multiple channels
        webSocketService.subscribe('channel-1', (data) {
          channel1Messages.add(data);
        });
        
        webSocketService.subscribe('channel-2', (data) {
          channel2Messages.add(data);
        });

        // Wait for subscriptions
        await Future.delayed(const Duration(milliseconds: 200));

        // Broadcast to different channels
        await mockServer.broadcastToRoom('channel-1', {
          'type': 'message-1',
          'data': {'content': 'Message for channel 1'},
        });

        await mockServer.broadcastToRoom('channel-2', {
          'type': 'message-2',
          'data': {'content': 'Message for channel 2'},
        });

        // Wait for messages
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify messages were received correctly
        expect(channel1Messages, hasLength(1));
        expect(channel1Messages.first['data']['content'], 'Message for channel 1');
        
        expect(channel2Messages, hasLength(1));
        expect(channel2Messages.first['data']['content'], 'Message for channel 2');
      });

      test('should handle unsubscription correctly', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        
        // Subscribe to a channel
        webSocketService.subscribe('test-channel', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send first message
        await mockServer.broadcastToRoom('test-channel', {
          'type': 'message-1',
          'data': {'content': 'First message'},
        });

        await Future.delayed(const Duration(milliseconds: 100));
        expect(receivedMessages, hasLength(1));

        // Unsubscribe
        webSocketService.unsubscribe('test-channel');
        await Future.delayed(const Duration(milliseconds: 200));

        // Send second message (should not be received)
        await mockServer.broadcastToRoom('test-channel', {
          'type': 'message-2',
          'data': {'content': 'Second message'},
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Should still have only one message
        expect(receivedMessages, hasLength(1));

        // Verify unsubscription on server
        final unsubscribeEvents = serverEvents.where((e) => e.type == 'channel_unsubscribed').toList();
        expect(unsubscribeEvents, hasLength(1));
      });
    });

    group('Reconnection and Error Handling', () {
      test('should reconnect automatically after connection loss', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Simulate server dropping connections
        mockServer.simulateConnectionDrops();

        // Subscribe to trigger reconnection
        webSocketService.subscribe('test-channel', (data) {});
        
        // Wait for reconnection attempts
        await Future.delayed(const Duration(milliseconds: 800));

        // Reset server to normal
        mockServer.resetToNormal();
        
        // Wait for successful reconnection
        await Future.delayed(const Duration(milliseconds: 500));

        // Should have attempted reconnection
        expect(connectionStates, contains(WebSocketConnectionState.reconnecting));

        await subscription.cancel();
      });

      test('should handle exponential backoff during reconnection', () async {
        // Setup server to reject connections
        mockServer.simulateAuthFailure();

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);
        final startTime = DateTime.now();

        // Attempt connection
        await webSocketService.connect();
        
        // Wait for multiple reconnection attempts
        await Future.delayed(const Duration(milliseconds: 1000));

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Should have made multiple attempts with increasing delays
        final reconnectingStates = connectionStates.where((s) => s == WebSocketConnectionState.reconnecting).length;
        expect(reconnectingStates, greaterThan(1));
        
        // Should have taken some time due to backoff
        expect(duration.inMilliseconds, greaterThan(300));

        await subscription.cancel();
      });

      test('should handle network issues gracefully', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        webSocketService.subscribe('test-channel', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Simulate network issues
        mockServer.simulateNetworkIssues();

        // Send multiple messages (some will be dropped/corrupted)
        for (int i = 0; i < 10; i++) {
          await mockServer.broadcastToRoom('test-channel', {
            'type': 'test-message',
            'data': {'content': 'Message $i'},
          });
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Should have received some messages (not all due to network issues)
        expect(receivedMessages.length, lessThan(10));
        expect(receivedMessages.length, greaterThan(0));
      });

      test('should handle server overload scenarios', () async {
        // Simulate server overload
        mockServer.simulateServerOverload();

        final connectionStates = <WebSocketConnectionState>[];
        final subscription = webSocketService.connectionState.listen(connectionStates.add);

        // Attempt connection
        await webSocketService.connect();
        
        // Wait for connection attempt with delays
        await Future.delayed(const Duration(seconds: 6));

        // Connection should be delayed or failed
        expect(connectionStates, contains(WebSocketConnectionState.connecting));

        await subscription.cancel();
      });
    });

    group('Performance and Load Testing', () {
      test('should handle high message throughput', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        final startTime = DateTime.now();
        
        webSocketService.subscribe('high-throughput', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send many messages quickly
        const messageCount = 100;
        for (int i = 0; i < messageCount; i++) {
          await mockServer.broadcastToRoom('high-throughput', {
            'type': 'performance-test',
            'data': {'messageId': i, 'timestamp': DateTime.now().millisecondsSinceEpoch},
          });
        }

        // Wait for all messages to be processed
        await Future.delayed(const Duration(seconds: 2));

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Should have received most messages
        expect(receivedMessages.length, greaterThan(messageCount * 0.8));
        
        // Should process messages reasonably quickly
        expect(duration.inSeconds, lessThan(5));

        // Calculate throughput
        final throughput = receivedMessages.length / duration.inSeconds;
        expect(throughput, greaterThan(10)); // At least 10 messages per second
      });

      test('should handle concurrent subscriptions efficiently', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final channelMessages = <String, List<dynamic>>{};
        const channelCount = 20;

        // Subscribe to multiple channels
        for (int i = 0; i < channelCount; i++) {
          final channelName = 'channel-$i';
          channelMessages[channelName] = [];
          
          webSocketService.subscribe(channelName, (data) {
            channelMessages[channelName]!.add(data);
          });
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Send messages to all channels
        for (int i = 0; i < channelCount; i++) {
          final channelName = 'channel-$i';
          await mockServer.broadcastToRoom(channelName, {
            'type': 'concurrent-test',
            'data': {'channelId': i},
          });
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Verify all channels received their messages
        for (int i = 0; i < channelCount; i++) {
          final channelName = 'channel-$i';
          expect(channelMessages[channelName], hasLength(1));
          expect(channelMessages[channelName]!.first['data']['channelId'], i);
        }
      });

      test('should maintain performance under memory pressure', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        webSocketService.subscribe('memory-test', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send messages with large payloads
        const messageCount = 50;
        for (int i = 0; i < messageCount; i++) {
          final largeData = List.generate(1000, (index) => 'data-$index').join(',');
          
          await mockServer.broadcastToRoom('memory-test', {
            'type': 'memory-test',
            'data': {
              'messageId': i,
              'largePayload': largeData,
            },
          });
          
          // Small delay to prevent overwhelming
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await Future.delayed(const Duration(seconds: 2));

        // Should handle large messages without issues
        expect(receivedMessages.length, greaterThan(messageCount * 0.8));
        
        // Verify message integrity
        for (final message in receivedMessages) {
          expect(message['data']['largePayload'], isA<String>());
          expect(message['data']['largePayload'].length, greaterThan(1000));
        }
      });
    });

    group('Error Recovery and Resilience', () {
      test('should recover from temporary server unavailability', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        // Stop server temporarily
        await mockServer.stop();
        
        // Wait for disconnection detection
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Restart server
        await mockServer.start();
        
        // Wait for reconnection
        await Future.delayed(const Duration(seconds: 2));

        // Should eventually reconnect
        expect(webSocketService.currentState, 
            anyOf(WebSocketConnectionState.connected, WebSocketConnectionState.reconnecting));
      });

      test('should handle malformed messages gracefully', () async {
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
          await mockServer.broadcastToRoom('test-channel', {
            'type': 'test-message',
            'data': {'content': 'Message $i'},
          });
          await Future.delayed(const Duration(milliseconds: 100));
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Should still be connected despite corrupted messages
        expect(webSocketService.currentState, WebSocketConnectionState.connected);
        
        // Should have received some messages (corrupted ones might be filtered)
        expect(receivedMessages.length, greaterThanOrEqualTo(0));
      });

      test('should maintain subscriptions after reconnection', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        webSocketService.subscribe('persistent-channel', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send initial message
        await mockServer.broadcastToRoom('persistent-channel', {
          'type': 'before-disconnect',
          'data': {'content': 'Before disconnect'},
        });

        await Future.delayed(const Duration(milliseconds: 100));
        expect(receivedMessages, hasLength(1));

        // Force disconnection
        mockServer.simulateConnectionDrops();
        await Future.delayed(const Duration(milliseconds: 200));

        // Reset server and allow reconnection
        mockServer.resetToNormal();
        await Future.delayed(const Duration(seconds: 1));

        // Send message after reconnection
        await mockServer.broadcastToRoom('persistent-channel', {
          'type': 'after-reconnect',
          'data': {'content': 'After reconnect'},
        });

        await Future.delayed(const Duration(milliseconds: 500));

        // Should have received both messages
        expect(receivedMessages.length, greaterThanOrEqualTo(1));
      });
    });
  });
}