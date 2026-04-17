import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'package:mockito/mockito.dart' as mockito;

import 'package:data/websocket/interfaces/i_websocket_service.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/stores/websocket_aware_store.dart';

import 'websocket_aware_store_test.mocks.dart';

@GenerateMocks([IWebSocketService])
void main() {
  group('WebSocketAwareStore', () {
    late MockIWebSocketService mockWebSocketService;
    late TestWebSocketAwareStore store;
    late StreamController<WebSocketConnectionState> connectionStateController;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
      
      mockito.when(mockWebSocketService.connectionState)
          .thenAnswer((_) => connectionStateController.stream);
      mockito.when(mockWebSocketService.currentState)
          .thenReturn(WebSocketConnectionState.disconnected);
      
      store = TestWebSocketAwareStore(mockWebSocketService);
    });

    tearDown(() {
      store.dispose();
      connectionStateController.close();
    });

    test('should initialize with correct subscribed channels', () {
      expect(store.subscribedChannels, equals(['test_channel_1', 'test_channel_2']));
    });

    test('should subscribe to channels when WebSocket connects', () async {
      // Simulate connection
      connectionStateController.add(WebSocketConnectionState.connected);
      
      // Wait for reaction to process
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Verify subscriptions were made
      mockito.verify(mockWebSocketService.subscribe('test_channel_1', mockito.any)).called(1);
      mockito.verify(mockWebSocketService.subscribe('test_channel_2', mockito.any)).called(1);
    });

    test('should handle WebSocket messages correctly', () {
      final testData = {'message': 'test_data', 'timestamp': DateTime.now().toIso8601String()};
      
      // Simulate connection and subscription
      connectionStateController.add(WebSocketConnectionState.connected);
      
      // Simulate receiving a message
      store.simulateMessage('test_channel_1', testData);
      
      expect(store.receivedMessages.length, equals(1));
      expect(store.receivedMessages.first['channel'], equals('test_channel_1'));
      expect(store.receivedMessages.first['data'], equals(testData));
    });

    test('should update connection state when WebSocket state changes', () {
      expect(store.connectionState, equals(WebSocketConnectionState.disconnected));
      expect(store.isConnected, isFalse);
      
      connectionStateController.add(WebSocketConnectionState.connecting);
      expect(store.connectionState, equals(WebSocketConnectionState.connecting));
      expect(store.isConnected, isFalse);
      
      connectionStateController.add(WebSocketConnectionState.connected);
      expect(store.connectionState, equals(WebSocketConnectionState.connected));
      expect(store.isConnected, isTrue);
    });

    test('should call onConnectionStateChanged when state changes', () {
      connectionStateController.add(WebSocketConnectionState.connecting);
      expect(store.connectionStateChanges.length, equals(1));
      expect(store.connectionStateChanges.first, equals(WebSocketConnectionState.connecting));
      
      connectionStateController.add(WebSocketConnectionState.connected);
      expect(store.connectionStateChanges.length, equals(2));
      expect(store.connectionStateChanges.last, equals(WebSocketConnectionState.connected));
    });

    test('should unsubscribe from all channels on dispose', () {
      // First, simulate connection to create subscriptions
      connectionStateController.add(WebSocketConnectionState.connected);
      
      // Now dispose
      store.dispose();
      
      // Verify unsubscriptions
      mockito.verify(mockWebSocketService.unsubscribe('test_channel_1')).called(1);
      mockito.verify(mockWebSocketService.unsubscribe('test_channel_2')).called(1);
    });

    test('should not subscribe to same channel multiple times', () async {
      // Simulate multiple connection events
      connectionStateController.add(WebSocketConnectionState.connected);
      await Future.delayed(const Duration(milliseconds: 10));
      
      connectionStateController.add(WebSocketConnectionState.connected);
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Should only subscribe once per channel
      mockito.verify(mockWebSocketService.subscribe('test_channel_1', mockito.any)).called(1);
      mockito.verify(mockWebSocketService.subscribe('test_channel_2', mockito.any)).called(1);
    });

    test('should handle connection errors gracefully', () {
      connectionStateController.add(WebSocketConnectionState.error);
      
      expect(store.connectionState, equals(WebSocketConnectionState.error));
      expect(store.isConnected, isFalse);
      
      // Should still be able to handle state changes
      connectionStateController.add(WebSocketConnectionState.reconnecting);
      expect(store.connectionState, equals(WebSocketConnectionState.reconnecting));
    });

    test('should call refreshDataAfterReconnection when implemented', () async {
      // This test verifies that the method can be overridden
      await store.refreshDataAfterReconnection();
      expect(store.refreshCalled, isTrue);
    });
  });
}

/// Test implementation of WebSocketAwareStore for testing purposes
class TestWebSocketAwareStore extends WebSocketAwareStore {
  final List<Map<String, dynamic>> receivedMessages = [];
  final List<WebSocketConnectionState> connectionStateChanges = [];
  bool refreshCalled = false;

  TestWebSocketAwareStore(super.webSocketService);

  @override
  List<String> get subscribedChannels => ['test_channel_1', 'test_channel_2'];

  @override
  void handleWebSocketMessage(String channel, dynamic data) {
    receivedMessages.add({
      'channel': channel,
      'data': data,
      'timestamp': DateTime.now(),
    });
  }

  @override
  void onConnectionStateChanged(WebSocketConnectionState state) {
    super.onConnectionStateChanged(state);
    connectionStateChanges.add(state);
  }

  @override
  Future<void> refreshDataAfterReconnection() async {
    refreshCalled = true;
  }

  /// Helper method to simulate receiving a message (for testing)
  void simulateMessage(String channel, dynamic data) {
    handleWebSocketMessage(channel, data);
  }
}