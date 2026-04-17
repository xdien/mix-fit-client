import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'dart:async';
import 'package:mockito/mockito.dart' as mockito;

import 'package:data/websocket/interfaces/i_websocket_service.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/stores/websocket_store_manager.dart';
import 'package:data/websocket/stores/inventory_websocket_store.dart';
import 'package:data/websocket/stores/customer_websocket_store.dart';
import 'package:data/websocket/stores/order_websocket_store.dart';

import 'websocket_aware_store_test.mocks.dart';

@GenerateMocks([IWebSocketService])
void main() {
  group('WebSocketStoreManager', () {
    late MockIWebSocketService mockWebSocketService;
    late WebSocketStoreManager storeManager;
    late StreamController<WebSocketConnectionState> connectionStateController;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
      
      mockito.when(mockWebSocketService.connectionState)
          .thenAnswer((_) => connectionStateController.stream);
      mockito.when(mockWebSocketService.currentState)
          .thenReturn(WebSocketConnectionState.disconnected);
      
      storeManager = WebSocketStoreManager(mockWebSocketService);
    });

    tearDown(() {
      storeManager.dispose();
      connectionStateController.close();
    });

    test('should initialize with correct default state', () {
      expect(storeManager.connectionState, equals(WebSocketConnectionState.disconnected));
      expect(storeManager.isConnected, isFalse);
      expect(storeManager.lastConnectionTime, isNull);
      expect(storeManager.reconnectAttempts, equals(0));
      expect(storeManager.lastError, isNull);
      expect(storeManager.hasActiveStores, isTrue);
    });

    test('should initialize all stores correctly', () {
      expect(storeManager.inventoryStore, isNotNull);
      expect(storeManager.customerStore, isNotNull);
      expect(storeManager.orderStore, isNotNull);
    });

    test('should update connection state when WebSocket state changes', () {
      expect(storeManager.connectionState, equals(WebSocketConnectionState.disconnected));
      expect(storeManager.isConnected, isFalse);

      connectionStateController.add(WebSocketConnectionState.connecting);
      expect(storeManager.connectionState, equals(WebSocketConnectionState.connecting));
      expect(storeManager.isConnected, isFalse);

      connectionStateController.add(WebSocketConnectionState.connected);
      expect(storeManager.connectionState, equals(WebSocketConnectionState.connected));
      expect(storeManager.isConnected, isTrue);
      expect(storeManager.lastConnectionTime, isNotNull);
      expect(storeManager.reconnectAttempts, equals(0));
      expect(storeManager.lastError, isNull);
    });

    test('should track reconnection attempts correctly', () {
      connectionStateController.add(WebSocketConnectionState.reconnecting);
      expect(storeManager.reconnectAttempts, equals(1));

      connectionStateController.add(WebSocketConnectionState.reconnecting);
      expect(storeManager.reconnectAttempts, equals(2));

      // Reset when connected
      connectionStateController.add(WebSocketConnectionState.connected);
      expect(storeManager.reconnectAttempts, equals(0));
    });

    test('should provide correct connection status text', () {
      expect(storeManager.connectionStatusText, equals('Disconnected - Using cached data'));

      connectionStateController.add(WebSocketConnectionState.connecting);
      expect(storeManager.connectionStatusText, equals('Connecting...'));

      connectionStateController.add(WebSocketConnectionState.connected);
      expect(storeManager.connectionStatusText, equals('Connected - Receiving real-time updates'));

      connectionStateController.add(WebSocketConnectionState.reconnecting);
      expect(storeManager.connectionStatusText, contains('Reconnecting... (Attempt 1)'));

      connectionStateController.add(WebSocketConnectionState.error);
      expect(storeManager.connectionStatusText, contains('Connection error'));
    });

    test('should show connection indicator when not connected', () {
      expect(storeManager.shouldShowConnectionIndicator, isTrue);

      connectionStateController.add(WebSocketConnectionState.connecting);
      expect(storeManager.shouldShowConnectionIndicator, isTrue);

      connectionStateController.add(WebSocketConnectionState.connected);
      expect(storeManager.shouldShowConnectionIndicator, isFalse);

      connectionStateController.add(WebSocketConnectionState.error);
      expect(storeManager.shouldShowConnectionIndicator, isTrue);
    });

    test('should connect to WebSocket service', () async {
      mockito.when(mockWebSocketService.connect()).thenAnswer((_) async {});

      await storeManager.connect();

      mockito.verify(mockWebSocketService.connect()).called(1);
    });

    test('should handle connection errors', () async {
      final error = Exception('Connection failed');
      mockito.when(mockWebSocketService.connect()).thenThrow(error);

      await storeManager.connect();

      expect(storeManager.lastError, equals(error.toString()));
    });

    test('should disconnect from WebSocket service', () async {
      mockito.when(mockWebSocketService.disconnect()).thenAnswer((_) async {});

      await storeManager.disconnect();

      mockito.verify(mockWebSocketService.disconnect()).called(1);
    });

    test('should provide data summary from all stores', () {
      // Add some test data to stores
      final testInventoryItem = InventoryItem(
        id: 'test_item',
        name: 'Test Item',
        sku: 'TEST001',
        quantity: 10,
        price: 100.0,
        lowStockThreshold: 5,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      storeManager.inventoryStore.addInventoryItem(testInventoryItem);

      final testCustomer = Customer(
        id: 'test_customer',
        name: 'Test Customer',
        email: 'test@example.com',
        phone: '+1234567890',
        address: 'Test Address',
        status: CustomerStatus.active,
        isVip: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        version: 1,
      );
      storeManager.customerStore.addCustomer(testCustomer);

      final testOrder = Order(
        id: 'test_order',
        orderNumber: 'ORD001',
        customerId: 'test_customer',
        customerName: 'Test Customer',
        status: OrderStatus.pending,
        priority: OrderPriority.normal,
        totalAmount: 500.0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      storeManager.orderStore.addOrder(testOrder);

      final summary = storeManager.dataSummary;

      expect(summary['inventory']['totalItems'], equals(10));
      expect(summary['inventory']['totalValue'], equals(1000.0));
      expect(summary['customers']['totalCustomers'], equals(1));
      expect(summary['customers']['vipCustomers'], equals(1));
      expect(summary['orders']['totalOrders'], equals(1));
      expect(summary['orders']['pendingOrders'], equals(1));
      expect(summary['orders']['totalValue'], equals(500.0));
      expect(summary['connection']['state'], equals('disconnected'));
      expect(summary['connection']['isConnected'], isFalse);
    });

    test('should collect critical alerts from all stores', () {
      // Add low stock item
      final lowStockItem = InventoryItem(
        id: 'low_stock',
        name: 'Low Stock Item',
        sku: 'LOW001',
        quantity: 2,
        price: 50.0,
        lowStockThreshold: 5,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      storeManager.inventoryStore.addInventoryItem(lowStockItem);

      // Add out of stock item
      final outOfStockItem = InventoryItem(
        id: 'out_of_stock',
        name: 'Out of Stock Item',
        sku: 'OUT001',
        quantity: 0,
        price: 75.0,
        lowStockThreshold: 3,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      storeManager.inventoryStore.addInventoryItem(outOfStockItem);

      // Add urgent order
      final urgentOrder = Order(
        id: 'urgent_order',
        orderNumber: 'URG001',
        customerId: 'test_customer',
        customerName: 'Test Customer',
        status: OrderStatus.pending,
        priority: OrderPriority.urgent,
        totalAmount: 1000.0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      storeManager.orderStore.addOrder(urgentOrder);

      final alerts = storeManager.allCriticalAlerts;

      expect(alerts.length, greaterThan(0));
      expect(alerts.any((alert) => alert.contains('out of stock')), isTrue);
      expect(alerts.any((alert) => alert.contains('low in stock')), isTrue);
      expect(alerts.any((alert) => alert.contains('urgent orders')), isTrue);
    });

    test('should clear all alerts', () {
      // Set up some alerts
      storeManager.customerStore.handleWebSocketMessage('customers', {
        'type': 'customer.conflict',
        'channel': 'customers',
        'data': {
          'customerId': 'test',
          'conflictType': 'test',
          'serverVersion': {
            'id': 'test',
            'name': 'Test',
            'email': 'test@example.com',
            'phone': '+1111111111',
            'address': 'Test Address',
            'status': 'active',
            'isVip': false,
            'createdAt': DateTime.now().toIso8601String(),
            'lastUpdated': DateTime.now().toIso8601String(),
            'version': 1,
          },
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      expect(storeManager.customerStore.conflictResolutionMessage, isNotNull);

      storeManager.clearAllAlerts();

      expect(storeManager.customerStore.conflictResolutionMessage, isNull);
    });

    test('should handle app lifecycle changes', () async {
      mockito.when(mockWebSocketService.handleAppLifecycle(mockito.any)).thenAnswer((_) async {});

      await storeManager.handleAppLifecycleChange(AppLifecycleState.paused);
      mockito.verify(mockWebSocketService.handleAppLifecycle(AppLifecycleState.paused)).called(1);

      // Test resume with connected state
      connectionStateController.add(WebSocketConnectionState.connected);
      await storeManager.handleAppLifecycleChange(AppLifecycleState.resumed);
      mockito.verify(mockWebSocketService.handleAppLifecycle(AppLifecycleState.resumed)).called(1);
    });

    test('should provide connection health status', () {
      var health = storeManager.connectionHealth;
      expect(health['isHealthy'], isFalse);
      expect(health['connectionState'], equals('disconnected'));
      expect(health['hasErrors'], isFalse);

      // Connect
      connectionStateController.add(WebSocketConnectionState.connected);
      health = storeManager.connectionHealth;
      expect(health['isHealthy'], isTrue);
      expect(health['connectionState'], equals('connected'));

      // Set error
      storeManager.lastError = 'Test error';
      health = storeManager.connectionHealth;
      expect(health['hasErrors'], isTrue);
      expect(health['lastError'], equals('Test error'));
    });

    test('should refresh all stores', () async {
      // This test verifies that refreshAllStores calls the refresh method on all stores
      // Since the stores are real instances, we can't easily mock them, but we can
      // verify the method completes without error
      await expectLater(storeManager.refreshAllStores(), completes);
    });

    test('should dispose all resources correctly', () {
      // Add some test data to verify stores are working
      final testItem = InventoryItem(
        id: 'dispose_test',
        name: 'Dispose Test',
        sku: 'DISPOSE001',
        quantity: 5,
        price: 25.0,
        lowStockThreshold: 2,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      storeManager.inventoryStore.addInventoryItem(testItem);

      expect(storeManager.inventoryStore.inventoryItems.length, equals(1));

      // Dispose should not throw
      expect(() => storeManager.dispose(), returnsNormally);
    });
  });
}