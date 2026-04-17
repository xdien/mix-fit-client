import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'package:mockito/mockito.dart' as mockito;

import 'package:data/websocket/interfaces/i_websocket_service.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/stores/inventory_websocket_store.dart';

import 'websocket_aware_store_test.mocks.dart';

@GenerateMocks([IWebSocketService])
void main() {
  group('InventoryWebSocketStore', () {
    late MockIWebSocketService mockWebSocketService;
    late InventoryWebSocketStore store;
    late StreamController<WebSocketConnectionState> connectionStateController;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
      
      mockito.when(mockWebSocketService.connectionState)
          .thenAnswer((_) => connectionStateController.stream);
      mockito.when(mockWebSocketService.currentState)
          .thenReturn(WebSocketConnectionState.disconnected);
      
      store = InventoryWebSocketStore(mockWebSocketService);
    });

    tearDown(() {
      store.dispose();
      connectionStateController.close();
    });

    test('should initialize with correct subscribed channels', () {
      expect(store.subscribedChannels, equals(['inventory', 'inventory.updates']));
    });

    test('should initialize with empty inventory', () {
      expect(store.inventoryItems.isEmpty, isTrue);
      expect(store.totalItemsInStock, equals(0));
      expect(store.totalInventoryValue, equals(0.0));
      expect(store.lowStockCount, equals(0));
      expect(store.outOfStockCount, equals(0));
    });

    test('should handle inventory item update message', () {
      final itemData = {
        'id': 'item_1',
        'name': 'Test Item',
        'sku': 'TEST001',
        'quantity': 50,
        'price': 100.0,
        'lowStockThreshold': 10,
        'category': 'Electronics',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final message = {
        'type': 'inventory.item.updated',
        'channel': 'inventory',
        'data': itemData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('inventory', message);

      expect(store.inventoryItems.length, equals(1));
      expect(store.inventoryItems['item_1']?.name, equals('Test Item'));
      expect(store.totalItemsInStock, equals(50));
      expect(store.totalInventoryValue, equals(5000.0));
    });

    test('should handle inventory item added message', () {
      final itemData = {
        'id': 'item_2',
        'name': 'New Item',
        'sku': 'NEW001',
        'quantity': 25,
        'price': 200.0,
        'lowStockThreshold': 5,
        'category': 'Tools',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final message = {
        'type': 'inventory.item.added',
        'channel': 'inventory',
        'data': itemData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('inventory', message);

      expect(store.inventoryItems.length, equals(1));
      expect(store.inventoryItems['item_2']?.name, equals('New Item'));
      expect(store.totalItemsInStock, equals(25));
      expect(store.totalInventoryValue, equals(5000.0));
    });

    test('should handle inventory item removed message', () {
      // First add an item
      final item = InventoryItem(
        id: 'item_to_remove',
        name: 'Remove Me',
        sku: 'REMOVE001',
        quantity: 10,
        price: 50.0,
        lowStockThreshold: 5,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      store.addInventoryItem(item);

      expect(store.inventoryItems.length, equals(1));

      // Now remove it via WebSocket message
      final message = {
        'type': 'inventory.item.removed',
        'channel': 'inventory',
        'data': {'id': 'item_to_remove'},
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('inventory', message);

      expect(store.inventoryItems.length, equals(0));
      expect(store.totalItemsInStock, equals(0));
      expect(store.totalInventoryValue, equals(0.0));
    });

    test('should handle bulk inventory update message', () {
      final items = [
        {
          'id': 'bulk_1',
          'name': 'Bulk Item 1',
          'sku': 'BULK001',
          'quantity': 30,
          'price': 75.0,
          'lowStockThreshold': 10,
          'category': 'Bulk',
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        {
          'id': 'bulk_2',
          'name': 'Bulk Item 2',
          'sku': 'BULK002',
          'quantity': 20,
          'price': 125.0,
          'lowStockThreshold': 5,
          'category': 'Bulk',
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      ];

      final message = {
        'type': 'inventory.bulk.update',
        'channel': 'inventory',
        'data': {'items': items},
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('inventory', message);

      expect(store.inventoryItems.length, equals(2));
      expect(store.totalItemsInStock, equals(50));
      expect(store.totalInventoryValue, equals(4750.0)); // (30*75) + (20*125)
    });

    test('should handle low stock alert message', () {
      // First add an item with normal stock
      final item = InventoryItem(
        id: 'low_stock_item',
        name: 'Low Stock Item',
        sku: 'LOW001',
        quantity: 20,
        price: 100.0,
        lowStockThreshold: 15,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      store.addInventoryItem(item);

      expect(store.lowStockCount, equals(1)); // Already low stock

      // Now receive low stock alert
      final message = {
        'type': 'inventory.low.stock.alert',
        'channel': 'inventory',
        'data': {
          'itemId': 'low_stock_item',
          'currentQuantity': 5,
          'threshold': 10,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('inventory', message);

      final updatedItem = store.inventoryItems['low_stock_item'];
      expect(updatedItem?.quantity, equals(5));
      expect(updatedItem?.lowStockThreshold, equals(10));
      expect(store.lowStockCount, equals(1));
    });

    test('should calculate low stock and out of stock items correctly', () {
      final items = [
        InventoryItem(
          id: 'normal_stock',
          name: 'Normal Stock',
          sku: 'NORMAL001',
          quantity: 50,
          price: 100.0,
          lowStockThreshold: 10,
          category: 'Test',
          lastUpdated: DateTime.now(),
        ),
        InventoryItem(
          id: 'low_stock',
          name: 'Low Stock',
          sku: 'LOW001',
          quantity: 5,
          price: 100.0,
          lowStockThreshold: 10,
          category: 'Test',
          lastUpdated: DateTime.now(),
        ),
        InventoryItem(
          id: 'out_of_stock',
          name: 'Out of Stock',
          sku: 'OUT001',
          quantity: 0,
          price: 100.0,
          lowStockThreshold: 5,
          category: 'Test',
          lastUpdated: DateTime.now(),
        ),
      ];

      store.updateInventoryItems(items);

      expect(store.lowStockCount, equals(1));
      expect(store.outOfStockCount, equals(1));
      expect(store.lowStockItems.length, equals(1));
      expect(store.outOfStockItems.length, equals(1));
      expect(store.lowStockItems.first.id, equals('low_stock'));
      expect(store.outOfStockItems.first.id, equals('out_of_stock'));
    });

    test('should update connection state correctly', () {
      expect(store.isReceivingUpdates, isFalse);

      connectionStateController.add(WebSocketConnectionState.connected);
      expect(store.isReceivingUpdates, isTrue);

      connectionStateController.add(WebSocketConnectionState.disconnected);
      expect(store.isReceivingUpdates, isFalse);
    });

    test('should search items correctly', () {
      final items = [
        InventoryItem(
          id: 'search_1',
          name: 'Apple iPhone',
          sku: 'APPLE001',
          quantity: 10,
          price: 999.0,
          lowStockThreshold: 5,
          category: 'Electronics',
          lastUpdated: DateTime.now(),
        ),
        InventoryItem(
          id: 'search_2',
          name: 'Samsung Galaxy',
          sku: 'SAMSUNG001',
          quantity: 15,
          price: 799.0,
          lowStockThreshold: 5,
          category: 'Electronics',
          lastUpdated: DateTime.now(),
        ),
      ];

      store.updateInventoryItems(items);

      // Search by name
      var results = store.searchItems('apple');
      expect(results.length, equals(1));
      expect(results.first.name, equals('Apple iPhone'));

      // Search by SKU
      results = store.searchItems('SAMSUNG');
      expect(results.length, equals(1));
      expect(results.first.sku, equals('SAMSUNG001'));

      // Search with empty query should return all items
      results = store.searchItems('');
      expect(results.length, equals(2));
    });

    test('should handle invalid WebSocket messages gracefully', () {
      // Test with invalid JSON structure
      expect(() => store.handleWebSocketMessage('inventory', 'invalid_json'), 
             returnsNormally);

      // Test with unknown message type
      final message = {
        'type': 'unknown.message.type',
        'channel': 'inventory',
        'data': {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => store.handleWebSocketMessage('inventory', message), 
             returnsNormally);
    });

    test('should update last update time when processing messages', () {
      expect(store.lastUpdateTime, isNull);

      final message = {
        'type': 'inventory.item.updated',
        'channel': 'inventory',
        'data': {
          'id': 'test_item',
          'name': 'Test Item',
          'sku': 'TEST001',
          'quantity': 10,
          'price': 50.0,
          'lowStockThreshold': 5,
          'category': 'Test',
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('inventory', message);

      expect(store.lastUpdateTime, isNotNull);
      expect(store.lastUpdateTime!.isBefore(DateTime.now().add(const Duration(seconds: 1))), 
             isTrue);
    });
  });
}