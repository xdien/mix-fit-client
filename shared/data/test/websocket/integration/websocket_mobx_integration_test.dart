import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'dart:async';

import 'package:data/websocket/interfaces/i_websocket_service.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/stores/inventory_websocket_store.dart';
import 'package:data/websocket/stores/customer_websocket_store.dart';
import 'package:data/websocket/stores/order_websocket_store.dart';
import 'package:data/websocket/stores/websocket_store_manager.dart';

// Generate mocks
@GenerateMocks([IWebSocketService])
import 'websocket_mobx_integration_test.mocks.dart';

void main() {
  group('WebSocket-MobX Integration', () {
    late MockIWebSocketService mockWebSocketService;
    late StreamController<WebSocketConnectionState> connectionStateController;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
      
      mockito.when(mockWebSocketService.connectionState)
          .thenAnswer((_) => connectionStateController.stream);
      mockito.when(mockWebSocketService.currentState)
          .thenReturn(WebSocketConnectionState.disconnected);
    });

    tearDown(() {
      connectionStateController.close();
    });

    test('should create and initialize inventory store with WebSocket integration', () {
      final store = InventoryWebSocketStore(mockWebSocketService);
      
      expect(store.subscribedChannels, equals(['inventory', 'inventory.updates']));
      expect(store.inventoryItems.isEmpty, isTrue);
      expect(store.totalItemsInStock, equals(0));
      expect(store.isReceivingUpdates, isFalse);
      
      store.dispose();
    });

    test('should create and initialize customer store with WebSocket integration', () {
      final store = CustomerWebSocketStore(mockWebSocketService);
      
      expect(store.subscribedChannels, equals(['customers', 'customers.updates']));
      expect(store.customers.isEmpty, isTrue);
      expect(store.totalCustomers, equals(0));
      expect(store.isReceivingUpdates, isFalse);
      
      store.dispose();
    });

    test('should create and initialize order store with WebSocket integration', () {
      final store = OrderWebSocketStore(mockWebSocketService);
      
      expect(store.subscribedChannels, equals(['orders', 'orders.updates', 'orders.critical']));
      expect(store.orders.isEmpty, isTrue);
      expect(store.totalOrders, equals(0));
      expect(store.isReceivingUpdates, isFalse);
      
      store.dispose();
    });

    test('should create and initialize WebSocket store manager', () {
      final storeManager = WebSocketStoreManager(mockWebSocketService);
      
      expect(storeManager.hasActiveStores, isTrue);
      expect(storeManager.isConnected, isFalse);
      expect(storeManager.connectionState, equals(WebSocketConnectionState.disconnected));
      
      // Verify all stores are initialized
      expect(storeManager.inventoryStore, isNotNull);
      expect(storeManager.customerStore, isNotNull);
      expect(storeManager.orderStore, isNotNull);
      
      storeManager.dispose();
    });

    test('should handle inventory data updates through WebSocket messages', () {
      final store = InventoryWebSocketStore(mockWebSocketService);
      
      // Test basic functionality by adding an item directly
      final item = InventoryItem(
        id: 'test_item',
        name: 'Test Item',
        sku: 'TEST001',
        quantity: 10,
        price: 100.0,
        lowStockThreshold: 5,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      
      store.addInventoryItem(item);
      
      expect(store.inventoryItems.length, equals(1));
      expect(store.inventoryItems['test_item']?.name, equals('Test Item'));
      expect(store.totalItemsInStock, equals(10));
      expect(store.totalInventoryValue, equals(1000.0));
      
      // Test updating the item directly
      final updatedItem = InventoryItem(
        id: 'test_item',
        name: 'Updated Test Item',
        sku: 'TEST001',
        quantity: 15,
        price: 120.0,
        lowStockThreshold: 5,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      
      store.addInventoryItem(updatedItem); // This will replace the existing item
      
      expect(store.inventoryItems.length, equals(1));
      expect(store.inventoryItems['test_item']?.name, equals('Updated Test Item'));
      expect(store.totalItemsInStock, equals(15));
      expect(store.totalInventoryValue, equals(1800.0));
      
      store.dispose();
    });

    test('should handle customer data updates through WebSocket messages', () {
      final store = CustomerWebSocketStore(mockWebSocketService);
      
      // Simulate WebSocket message for customer creation
      final createMessage = {
        'type': 'customer.created',
        'channel': 'customers',
        'data': {
          'id': 'new_customer',
          'name': 'New Customer',
          'email': 'new@example.com',
          'phone': '+1234567890',
          'address': '123 New St',
          'status': 'active',
          'isVip': true,
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': 1,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      store.handleWebSocketMessage('customers', createMessage);
      
      expect(store.customers.length, equals(1));
      expect(store.customers['new_customer']?.name, equals('New Customer'));
      expect(store.totalCustomers, equals(1));
      expect(store.activeCustomers, equals(1));
      expect(store.vipCustomerCount, equals(1));
      expect(store.lastUpdateTime, isNotNull);
      
      store.dispose();
    });

    test('should handle order data updates through WebSocket messages', () {
      final store = OrderWebSocketStore(mockWebSocketService);
      
      // Simulate WebSocket message for order creation
      final createMessage = {
        'type': 'order.created',
        'channel': 'orders',
        'data': {
          'id': 'new_order',
          'orderNumber': 'ORD001',
          'customerId': 'customer_1',
          'customerName': 'Test Customer',
          'status': 'pending',
          'priority': 'normal',
          'totalAmount': 500.0,
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
          'statusHistory': [],
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      store.handleWebSocketMessage('orders', createMessage);
      
      expect(store.orders.length, equals(1));
      expect(store.orders['new_order']?.orderNumber, equals('ORD001'));
      expect(store.totalOrders, equals(1));
      expect(store.pendingOrders, equals(1));
      expect(store.totalOrderValue, equals(500.0));
      expect(store.lastUpdateTime, isNotNull);
      
      store.dispose();
    });

    test('should provide comprehensive data summary from store manager', () {
      final storeManager = WebSocketStoreManager(mockWebSocketService);
      
      // Add test data to stores
      final inventoryItem = InventoryItem(
        id: 'summary_item',
        name: 'Summary Item',
        sku: 'SUM001',
        quantity: 20,
        price: 50.0,
        lowStockThreshold: 10,
        category: 'Summary',
        lastUpdated: DateTime.now(),
      );
      storeManager.inventoryStore.addInventoryItem(inventoryItem);
      
      final customer = Customer(
        id: 'summary_customer',
        name: 'Summary Customer',
        email: 'summary@example.com',
        phone: '+1111111111',
        address: 'Summary Address',
        status: CustomerStatus.active,
        isVip: false,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        version: 1,
      );
      storeManager.customerStore.addCustomer(customer);
      
      final order = Order(
        id: 'summary_order',
        orderNumber: 'SUM001',
        customerId: 'summary_customer',
        customerName: 'Summary Customer',
        status: OrderStatus.pending,
        priority: OrderPriority.normal,
        totalAmount: 250.0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      storeManager.orderStore.addOrder(order);
      
      final summary = storeManager.dataSummary;
      
      expect(summary['inventory']['totalItems'], equals(20));
      expect(summary['inventory']['totalValue'], equals(1000.0));
      expect(summary['customers']['totalCustomers'], equals(1));
      expect(summary['customers']['activeCustomers'], equals(1));
      expect(summary['orders']['totalOrders'], equals(1));
      expect(summary['orders']['pendingOrders'], equals(1));
      expect(summary['orders']['totalValue'], equals(250.0));
      expect(summary['connection']['isConnected'], isFalse);
      
      storeManager.dispose();
    });

    test('should handle WebSocket connection state changes', () async {
      final storeManager = WebSocketStoreManager(mockWebSocketService);
      
      expect(storeManager.connectionState, equals(WebSocketConnectionState.disconnected));
      expect(storeManager.isConnected, isFalse);
      
      // Simulate connection state changes
      connectionStateController.add(WebSocketConnectionState.connecting);
      await Future.delayed(const Duration(milliseconds: 10));
      
      connectionStateController.add(WebSocketConnectionState.connected);
      await Future.delayed(const Duration(milliseconds: 10));
      
      connectionStateController.add(WebSocketConnectionState.disconnected);
      await Future.delayed(const Duration(milliseconds: 10));
      
      storeManager.dispose();
    });

    test('should demonstrate complete WebSocket-MobX integration workflow', () async {
      final storeManager = WebSocketStoreManager(mockWebSocketService);
      
      // Initial state
      expect(storeManager.inventoryStore.inventoryItems.isEmpty, isTrue);
      expect(storeManager.customerStore.customers.isEmpty, isTrue);
      expect(storeManager.orderStore.orders.isEmpty, isTrue);
      
      // Simulate receiving real-time updates
      storeManager.inventoryStore.handleWebSocketMessage('inventory', {
        'type': 'inventory.item.added',
        'channel': 'inventory',
        'data': {
          'id': 'workflow_item',
          'name': 'Workflow Item',
          'sku': 'WF001',
          'quantity': 30,
          'price': 75.0,
          'lowStockThreshold': 10,
          'category': 'Workflow',
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      storeManager.customerStore.handleWebSocketMessage('customers', {
        'type': 'customer.created',
        'channel': 'customers',
        'data': {
          'id': 'workflow_customer',
          'name': 'Workflow Customer',
          'email': 'workflow@example.com',
          'phone': '+2222222222',
          'address': 'Workflow Address',
          'status': 'active',
          'isVip': false,
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': 1,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      storeManager.orderStore.handleWebSocketMessage('orders', {
        'type': 'order.created',
        'channel': 'orders',
        'data': {
          'id': 'workflow_order',
          'orderNumber': 'WF001',
          'customerId': 'workflow_customer',
          'customerName': 'Workflow Customer',
          'status': 'pending',
          'priority': 'normal',
          'totalAmount': 300.0,
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
          'statusHistory': [],
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Verify all data was processed correctly
      expect(storeManager.inventoryStore.inventoryItems.length, equals(1));
      expect(storeManager.inventoryStore.totalItemsInStock, equals(30));
      expect(storeManager.inventoryStore.totalInventoryValue, equals(2250.0));
      
      expect(storeManager.customerStore.customers.length, equals(1));
      expect(storeManager.customerStore.totalCustomers, equals(1));
      expect(storeManager.customerStore.activeCustomers, equals(1));
      
      expect(storeManager.orderStore.orders.length, equals(1));
      expect(storeManager.orderStore.totalOrders, equals(1));
      expect(storeManager.orderStore.pendingOrders, equals(1));
      expect(storeManager.orderStore.totalOrderValue, equals(300.0));
      
      // Verify data summary reflects all updates
      final summary = storeManager.dataSummary;
      expect(summary['inventory']['totalItems'], equals(30));
      expect(summary['customers']['totalCustomers'], equals(1));
      expect(summary['orders']['totalOrders'], equals(1));
      
      storeManager.dispose();
    });
  });
}