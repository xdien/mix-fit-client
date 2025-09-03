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
  group('Debug CMS WebSocket Integration', () {
    late MockSocketIOServer mockServer;
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;
    late IWebSocketService webSocketService;
    late StreamSubscription<MockServerEvent> serverEventSubscription;
    final List<MockServerEvent> serverEvents = [];

    setUp(() async {
      mockServer = MockSocketIOServer();
      mockSharedPreferenceHelper = MockSharedPreferenceHelper();
      serverEvents.clear();

      await mockServer.start();
      serverEventSubscription = mockServer.events.listen(serverEvents.add);

      when(mockSharedPreferenceHelper.authToken)
          .thenAnswer((_) async => 'valid-cms-token');
      when(mockSharedPreferenceHelper.isLoggedIn)
          .thenAnswer((_) async => true);

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

    test('should connect and receive basic messages', () async {
      print('Starting connection test...');
      
      // Connect
      await webSocketService.connect();
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('Connection state: ${webSocketService.currentState}');
      expect(webSocketService.currentState, WebSocketConnectionState.connected);

      final receivedMessages = <dynamic>[];
      
      // Subscribe to a test channel
      print('Subscribing to test channel...');
      webSocketService.subscribe('test', (data) {
        print('Received message: $data');
        receivedMessages.add(data);
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // Check if subscription was registered on server
      final subscribeEvents = serverEvents.where((e) => e.type == 'channel_subscribed').toList();
      print('Subscribe events: ${subscribeEvents.length}');
      for (final event in subscribeEvents) {
        print('Subscribe event: ${event.data}');
      }

      // Send a test message
      print('Broadcasting test message...');
      await mockServer.broadcastToRoom('test', {
        'type': 'test-message',
        'content': 'Hello World',
      });

      await Future.delayed(const Duration(milliseconds: 300));

      print('Received messages count: ${receivedMessages.length}');
      for (int i = 0; i < receivedMessages.length; i++) {
        print('Message $i: ${receivedMessages[i]}');
      }

      expect(receivedMessages, hasLength(1));
    });

    test('should handle customer events specifically', () async {
      print('Starting customer event test...');
      
      await webSocketService.connect();
      await Future.delayed(const Duration(milliseconds: 300));
      
      final receivedEvents = <dynamic>[];
      webSocketService.subscribe('customers', (data) {
        print('Received customer event: $data');
        receivedEvents.add(data);
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // Send customer created event
      print('Broadcasting customer created event...');
      await mockServer.broadcastToRoom('customers', {
        'eventType': 'customer.created',
        'timestamp': DateTime.now().toIso8601String(),
        'customerId': 'KH001',
        'customerData': {
          'khid': 'KH001',
          'ten': 'Test Customer',
        },
      });

      await Future.delayed(const Duration(milliseconds: 300));

      print('Customer events received: ${receivedEvents.length}');
      for (int i = 0; i < receivedEvents.length; i++) {
        print('Customer event $i: ${receivedEvents[i]}');
      }

      expect(receivedEvents, hasLength(1));
      if (receivedEvents.isNotEmpty) {
        expect(receivedEvents.first['eventType'], 'customer.created');
      }
    });
  });
}