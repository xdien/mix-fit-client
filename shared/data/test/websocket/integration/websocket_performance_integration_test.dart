import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'mock_websocket_server.dart';

@GenerateMocks([SharedPreferenceHelper])
import 'websocket_performance_integration_test.mocks.dart';

void main() {
  group('WebSocket Performance Integration Tests', () {
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

      // Setup auth mock
      when(mockSharedPreferenceHelper.authToken)
          .thenAnswer((_) async => 'valid-test-token');
      when(mockSharedPreferenceHelper.isLoggedIn)
          .thenAnswer((_) async => true);

      // Create WebSocket service with mock server URL
      final config = WebSocketConfig(
        url: 'ws://localhost:${mockServer.port}',
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

    group('Message Processing Performance', () {
      test('should handle high-frequency message bursts efficiently', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final receivedMessages = <dynamic>[];
        final processingTimes = <Duration>[];
        
        webSocketService.subscribe('burst-test', (data) {
          final receiveTime = DateTime.now();
          final sentTime = DateTime.parse(data['timestamp'] as String);
          processingTimes.add(receiveTime.difference(sentTime));
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        const burstSize = 100;
        final startTime = DateTime.now();

        // Send burst of messages
        for (int i = 0; i < burstSize; i++) {
          await mockServer.broadcastToChannel('burst-test', {
            'type': 'burst-message',
            'messageId': i,
            'timestamp': DateTime.now().toIso8601String(),
            'data': {'content': 'Burst message $i'},
          });
        }

        // Wait for all messages to be processed
        await Future.delayed(const Duration(seconds: 3));

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);

        // Performance assertions
        expect(receivedMessages.length, greaterThan(burstSize * 0.9)); // Allow for some message loss
        expect(totalDuration.inSeconds, lessThan(5)); // Should process quickly

        // Calculate throughput
        final throughput = receivedMessages.length / totalDuration.inSeconds;
        expect(throughput, greaterThan(20)); // At least 20 messages per second

        // Check processing latency
        if (processingTimes.isNotEmpty) {
          final avgLatency = processingTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds) / processingTimes.length;
          expect(avgLatency, lessThan(100)); // Average latency should be less than 100ms
        }
      });

      test('should maintain performance with large message payloads', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        final startTime = DateTime.now();
        
        webSocketService.subscribe('large-payload-test', (data) {
          receivedMessages.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        const messageCount = 20;
        
        // Send messages with large payloads
        for (int i = 0; i < messageCount; i++) {
          // Create large payload (approximately 10KB)
          final largeData = List.generate(1000, (index) => 'data-item-$index-with-some-additional-content').join(',');
          
          await mockServer.broadcastToChannel('large-payload-test', {
            'type': 'large-message',
            'messageId': i,
            'timestamp': DateTime.now().toIso8601String(),
            'largePayload': largeData,
            'metadata': {
              'size': largeData.length,
              'created': DateTime.now().toIso8601String(),
            },
          });
          
          // Small delay to prevent overwhelming
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await Future.delayed(const Duration(seconds: 3));

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);

        // Should handle large messages efficiently
        expect(receivedMessages.length, greaterThan(messageCount * 0.8));
        expect(totalDuration.inSeconds, lessThan(10));

        // Verify message integrity
        for (final message in receivedMessages) {
          expect(message['largePayload'], isA<String>());
          expect(message['largePayload'].length, greaterThan(5000));
          expect(message['metadata']['size'], isA<int>());
        }
      });

      test('should handle concurrent message processing efficiently', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final channelMessages = <String, List<dynamic>>{};
        const channelCount = 10;
        const messagesPerChannel = 20;

        // Subscribe to multiple channels
        for (int i = 0; i < channelCount; i++) {
          final channelName = 'concurrent-channel-$i';
          channelMessages[channelName] = [];
          
          webSocketService.subscribe(channelName, (data) {
            channelMessages[channelName]!.add(data);
          });
        }

        await Future.delayed(const Duration(milliseconds: 500));

        final startTime = DateTime.now();

        // Send messages to all channels concurrently
        final futures = <Future>[];
        for (int channelIndex = 0; channelIndex < channelCount; channelIndex++) {
          final channelName = 'concurrent-channel-$channelIndex';
          
          futures.add(Future(() async {
            for (int msgIndex = 0; msgIndex < messagesPerChannel; msgIndex++) {
              await mockServer.broadcastToChannel(channelName, {
                'type': 'concurrent-message',
                'channelId': channelIndex,
                'messageId': msgIndex,
                'timestamp': DateTime.now().toIso8601String(),
                'data': {'content': 'Message $msgIndex for channel $channelIndex'},
              });
              
              // Small delay to simulate realistic timing
              await Future.delayed(const Duration(milliseconds: 10));
            }
          }));
        }

        await Future.wait(futures);
        await Future.delayed(const Duration(seconds: 2));

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);

        // Performance assertions
        final totalExpectedMessages = channelCount * messagesPerChannel;
        final totalReceivedMessages = channelMessages.values.fold<int>(0, (sum, messages) => sum + messages.length);
        
        expect(totalReceivedMessages, greaterThan(totalExpectedMessages * 0.8));
        expect(totalDuration.inSeconds, lessThan(15));

        // Verify each channel received messages
        for (int i = 0; i < channelCount; i++) {
          final channelName = 'concurrent-channel-$i';
          expect(channelMessages[channelName]!.length, greaterThan(messagesPerChannel * 0.7));
        }
      });

      test('should maintain performance under memory pressure', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        var memoryUsageApprox = 0;
        
        webSocketService.subscribe('memory-pressure-test', (data) {
          receivedMessages.add(data);
          // Approximate memory usage tracking
          memoryUsageApprox += (data.toString().length * 2); // Rough estimate
        });

        await Future.delayed(const Duration(milliseconds: 200));

        const messageCount = 100;
        final startTime = DateTime.now();

        // Send messages that accumulate in memory
        for (int i = 0; i < messageCount; i++) {
          // Create progressively larger payloads
          final payloadSize = 100 + (i * 10);
          final payload = List.generate(payloadSize, (index) => 'item-$index').join(',');
          
          await mockServer.broadcastToChannel('memory-pressure-test', {
            'type': 'memory-test',
            'messageId': i,
            'iteration': i,
            'payload': payload,
            'timestamp': DateTime.now().toIso8601String(),
          });
          
          await Future.delayed(const Duration(milliseconds: 20));
        }

        await Future.delayed(const Duration(seconds: 3));

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);

        // Should handle memory pressure gracefully
        expect(receivedMessages.length, greaterThan(messageCount * 0.8));
        expect(totalDuration.inSeconds, lessThan(10));

        // Memory usage should be reasonable (rough check)
        expect(memoryUsageApprox, lessThan(10 * 1024 * 1024)); // Less than 10MB

        // Verify message integrity under memory pressure
        for (int i = 0; i < min(10, receivedMessages.length); i++) {
          final message = receivedMessages[i];
          expect(message['messageId'], isA<int>());
          expect(message['payload'], isA<String>());
        }
      });
    });

    group('Connection Performance', () {
      test('should establish connections quickly', () async {
        final connectionTimes = <Duration>[];
        
        // Test multiple connection attempts
        for (int i = 0; i < 5; i++) {
          final startTime = DateTime.now();
          
          await webSocketService.connect();
          
          // Wait for connection to be established
          var attempts = 0;
          while (webSocketService.currentState != WebSocketConnectionState.connected && attempts < 50) {
            await Future.delayed(const Duration(milliseconds: 100));
            attempts++;
          }
          
          final endTime = DateTime.now();
          final connectionTime = endTime.difference(startTime);
          connectionTimes.add(connectionTime);
          
          await webSocketService.disconnect();
          await Future.delayed(const Duration(milliseconds: 200));
        }

        // Analyze connection performance
        final avgConnectionTime = connectionTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds) / connectionTimes.length;
        expect(avgConnectionTime, lessThan(2000)); // Average connection time should be less than 2 seconds

        // No connection should take more than 5 seconds
        for (final time in connectionTimes) {
          expect(time.inSeconds, lessThan(5));
        }
      });

      test('should handle rapid connect/disconnect cycles efficiently', () async {
        final startTime = DateTime.now();
        const cycleCount = 10;

        for (int i = 0; i < cycleCount; i++) {
          await webSocketService.connect();
          
          // Wait briefly for connection
          await Future.delayed(const Duration(milliseconds: 200));
          
          await webSocketService.disconnect();
          
          // Brief pause between cycles
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);

        // Should handle rapid cycles efficiently
        expect(totalDuration.inSeconds, lessThan(15));
        
        // Should end in disconnected state
        expect(webSocketService.currentState, WebSocketConnectionState.disconnected);
      });

      test('should maintain performance with many concurrent subscriptions', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        const subscriptionCount = 50;
        final subscriptionTimes = <Duration>[];
        final channelMessages = <String, List<dynamic>>{};

        // Create many subscriptions and measure time
        for (int i = 0; i < subscriptionCount; i++) {
          final channelName = 'perf-channel-$i';
          channelMessages[channelName] = [];
          
          final startTime = DateTime.now();
          
          webSocketService.subscribe(channelName, (data) {
            channelMessages[channelName]!.add(data);
          });
          
          final endTime = DateTime.now();
          subscriptionTimes.add(endTime.difference(startTime));
        }

        await Future.delayed(const Duration(milliseconds: 1000));

        // Test message delivery to all subscriptions
        final messageStartTime = DateTime.now();
        
        for (int i = 0; i < subscriptionCount; i++) {
          final channelName = 'perf-channel-$i';
          await mockServer.broadcastToChannel(channelName, {
            'type': 'performance-test',
            'channelId': i,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        await Future.delayed(const Duration(seconds: 2));
        
        final messageEndTime = DateTime.now();
        final messageDuration = messageEndTime.difference(messageStartTime);

        // Performance assertions
        final avgSubscriptionTime = subscriptionTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds) / subscriptionTimes.length;
        expect(avgSubscriptionTime, lessThan(50)); // Each subscription should be fast

        expect(messageDuration.inSeconds, lessThan(5)); // Message delivery should be fast

        // Verify all channels received messages
        var receivedCount = 0;
        for (int i = 0; i < subscriptionCount; i++) {
          final channelName = 'perf-channel-$i';
          if (channelMessages[channelName]!.isNotEmpty) {
            receivedCount++;
          }
        }
        
        expect(receivedCount, greaterThan(subscriptionCount * 0.9)); // Most channels should receive messages
      });

      test('should handle subscription/unsubscription performance', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        const operationCount = 100;
        final operationTimes = <Duration>[];

        // Test rapid subscription/unsubscription cycles
        for (int i = 0; i < operationCount; i++) {
          final channelName = 'temp-channel-$i';
          
          // Subscribe
          final subscribeStart = DateTime.now();
          webSocketService.subscribe(channelName, (data) {});
          final subscribeEnd = DateTime.now();
          operationTimes.add(subscribeEnd.difference(subscribeStart));
          
          // Small delay
          await Future.delayed(const Duration(milliseconds: 10));
          
          // Unsubscribe
          final unsubscribeStart = DateTime.now();
          webSocketService.unsubscribe(channelName);
          final unsubscribeEnd = DateTime.now();
          operationTimes.add(unsubscribeEnd.difference(unsubscribeStart));
        }

        // Performance assertions
        final avgOperationTime = operationTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds) / operationTimes.length;
        expect(avgOperationTime, lessThan(10)); // Each operation should be very fast

        // No single operation should take more than 100ms
        for (final time in operationTimes) {
          expect(time.inMilliseconds, lessThan(100));
        }
      });
    });

    group('Reconnection Performance', () {
      test('should reconnect efficiently after connection loss', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(webSocketService.currentState, WebSocketConnectionState.connected);

        final reconnectionTimes = <Duration>[];
        
        // Test multiple reconnection scenarios
        for (int i = 0; i < 3; i++) {
          // Force disconnection
          mockServer.simulateConnectionDrops();
          
          // Wait for disconnection detection
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Reset server and measure reconnection time
          mockServer.resetToNormal();
          
          final reconnectStart = DateTime.now();
          
          // Wait for reconnection
          var attempts = 0;
          while (webSocketService.currentState != WebSocketConnectionState.connected && attempts < 50) {
            await Future.delayed(const Duration(milliseconds: 100));
            attempts++;
          }
          
          final reconnectEnd = DateTime.now();
          
          if (webSocketService.currentState == WebSocketConnectionState.connected) {
            reconnectionTimes.add(reconnectEnd.difference(reconnectStart));
          }
          
          await Future.delayed(const Duration(milliseconds: 200));
        }

        // Analyze reconnection performance
        if (reconnectionTimes.isNotEmpty) {
          final avgReconnectionTime = reconnectionTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds) / reconnectionTimes.length;
          expect(avgReconnectionTime, lessThan(3000)); // Average reconnection should be less than 3 seconds
        }
      });

      test('should handle reconnection with many subscriptions efficiently', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        const subscriptionCount = 20;
        final channelMessages = <String, List<dynamic>>{};

        // Create many subscriptions
        for (int i = 0; i < subscriptionCount; i++) {
          final channelName = 'reconnect-channel-$i';
          channelMessages[channelName] = [];
          
          webSocketService.subscribe(channelName, (data) {
            channelMessages[channelName]!.add(data);
          });
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Force disconnection
        mockServer.simulateConnectionDrops();
        await Future.delayed(const Duration(milliseconds: 300));

        // Reset server and measure reconnection with re-subscription
        mockServer.resetToNormal();
        
        final reconnectStart = DateTime.now();
        
        // Wait for reconnection and re-subscription
        await Future.delayed(const Duration(seconds: 3));
        
        final reconnectEnd = DateTime.now();
        final reconnectionDuration = reconnectEnd.difference(reconnectStart);

        // Test message delivery after reconnection
        for (int i = 0; i < subscriptionCount; i++) {
          final channelName = 'reconnect-channel-$i';
          await mockServer.broadcastToChannel(channelName, {
            'type': 'after-reconnect',
            'channelId': i,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        await Future.delayed(const Duration(milliseconds: 1000));

        // Performance assertions
        expect(reconnectionDuration.inSeconds, lessThan(5));
        
        // Verify most subscriptions were restored
        var activeChannels = 0;
        for (int i = 0; i < subscriptionCount; i++) {
          final channelName = 'reconnect-channel-$i';
          if (channelMessages[channelName]!.isNotEmpty) {
            activeChannels++;
          }
        }
        
        expect(activeChannels, greaterThan(subscriptionCount * 0.7)); // Most channels should be active
      });
    });

    group('Resource Usage Performance', () {
      test('should not leak memory during extended operation', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedMessages = <dynamic>[];
        webSocketService.subscribe('memory-leak-test', (data) {
          receivedMessages.add(data);
          
          // Periodically clear old messages to simulate real app behavior
          if (receivedMessages.length > 100) {
            receivedMessages.removeRange(0, 50);
          }
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send many messages over time
        const totalMessages = 500;
        for (int i = 0; i < totalMessages; i++) {
          await mockServer.broadcastToChannel('memory-leak-test', {
            'type': 'memory-test',
            'messageId': i,
            'data': List.generate(50, (index) => 'data-$index').join(','),
            'timestamp': DateTime.now().toIso8601String(),
          });
          
          // Small delay to simulate real-time flow
          await Future.delayed(const Duration(milliseconds: 10));
          
          // Periodic cleanup simulation
          if (i % 100 == 0) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }

        await Future.delayed(const Duration(seconds: 1));

        // Memory usage should be reasonable (messages are being cleaned up)
        expect(receivedMessages.length, lessThan(150)); // Should not accumulate indefinitely
        
        // Connection should still be stable
        expect(webSocketService.currentState, WebSocketConnectionState.connected);
      });

      test('should handle CPU-intensive message processing efficiently', () async {
        // Connect first
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final processingTimes = <Duration>[];
        var totalProcessedMessages = 0;
        
        webSocketService.subscribe('cpu-intensive-test', (data) {
          final processStart = DateTime.now();
          
          // Simulate CPU-intensive processing
          final payload = data['complexData'] as List<dynamic>;
          var sum = 0;
          for (final item in payload) {
            sum += (item as Map<String, dynamic>)['value'] as int;
          }
          
          final processEnd = DateTime.now();
          processingTimes.add(processEnd.difference(processStart));
          totalProcessedMessages++;
        });

        await Future.delayed(const Duration(milliseconds: 200));

        const messageCount = 50;
        final startTime = DateTime.now();

        // Send messages with complex data
        for (int i = 0; i < messageCount; i++) {
          final complexData = List.generate(100, (index) => {
            'id': index,
            'value': Random().nextInt(1000),
            'metadata': {
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'category': 'test-$index',
            },
          });
          
          await mockServer.broadcastToChannel('cpu-intensive-test', {
            'type': 'complex-message',
            'messageId': i,
            'complexData': complexData,
            'timestamp': DateTime.now().toIso8601String(),
          });
          
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await Future.delayed(const Duration(seconds: 3));

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);

        // Performance assertions
        expect(totalProcessedMessages, greaterThan(messageCount * 0.8));
        expect(totalDuration.inSeconds, lessThan(15));

        // Processing time per message should be reasonable
        if (processingTimes.isNotEmpty) {
          final avgProcessingTime = processingTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds) / processingTimes.length;
          expect(avgProcessingTime, lessThan(100)); // Each message should process in less than 100ms
        }
      });
    });
  });
}