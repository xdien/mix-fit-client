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
  group('CMS Modules WebSocket Integration Tests', () {
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

    group('Customer Management Module Integration', () {
      test('should handle customer created events', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedEvents = <dynamic>[];
        webSocketService.subscribe('customers', (data) {
          receivedEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Simulate customer created event from backend
        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.created',
          'timestamp': DateTime.now().toIso8601String(),
          'customerId': 'KH001',
          'customerData': {
            'khid': 'KH001',
            'ten': 'Nguyen Van A',
            'dienThoai': '0123456789',
            'diaChi': 'Ha Noi',
          },
          'userId': 'user123',
          'channel': 'customers',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first['eventType'], 'customer.created');
        expect(receivedEvents.first['customerId'], 'KH001');
        expect(receivedEvents.first['customerData']['ten'], 'Nguyen Van A');
      });

      test('should handle customer updated events with conflict resolution', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedEvents = <dynamic>[];
        webSocketService.subscribe('customers', (data) {
          receivedEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Simulate customer updated event
        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.updated',
          'timestamp': DateTime.now().toIso8601String(),
          'customerId': 'KH001',
          'customerData': {
            'khid': 'KH001',
            'ten': 'Nguyen Van B', // Updated name
            'dienThoai': '0987654321', // Updated phone
            'diaChi': 'Ho Chi Minh',
          },
          'previousData': {
            'khid': 'KH001',
            'ten': 'Nguyen Van A',
            'dienThoai': '0123456789',
            'diaChi': 'Ha Noi',
          },
          'userId': 'user456',
          'channel': 'customers',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first['eventType'], 'customer.updated');
        expect(receivedEvents.first['customerData']['ten'], 'Nguyen Van B');
        expect(receivedEvents.first['previousData']['ten'], 'Nguyen Van A');
      });

      test('should handle customer deleted events', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedEvents = <dynamic>[];
        webSocketService.subscribe('customers', (data) {
          receivedEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.deleted',
          'timestamp': DateTime.now().toIso8601String(),
          'customerId': 'KH001',
          'customerData': {
            'khid': 'KH001',
            'ten': 'Nguyen Van A',
          },
          'userId': 'admin',
          'channel': 'customers',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first['eventType'], 'customer.deleted');
        expect(receivedEvents.first['customerId'], 'KH001');
      });
    });

    group('Sales Dashboard Module Integration', () {
      test('should handle order created events', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final orderEvents = <dynamic>[];
        final salesEvents = <dynamic>[];

        webSocketService.subscribe('orders', (data) {
          orderEvents.add(data);
        });

        webSocketService.subscribe('sales', (data) {
          salesEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('orders', {
          'eventType': 'order.created',
          'timestamp': DateTime.now().toIso8601String(),
          'orderId': 'HD001',
          'customerId': 'KH001',
          'status': 'PENDING',
          'totalAmount': 1500000,
          'orderData': {
            'denghigiabanid': 'HD001',
            'tenKhachHang': 'Nguyen Van A',
            'tong': 1500000,
          },
          'userId': 'sales_user',
          'channel': 'orders',
        });

        await mockServer.broadcastToRoom('sales', {
          'eventType': 'order.created',
          'timestamp': DateTime.now().toIso8601String(),
          'orderId': 'HD001',
          'customerId': 'KH001',
          'status': 'PENDING',
          'totalAmount': 1500000,
          'orderData': {
            'denghigiabanid': 'HD001',
            'tenKhachHang': 'Nguyen Van A',
            'tong': 1500000,
          },
          'userId': 'sales_user',
          'channel': 'sales',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(orderEvents, hasLength(1));
        expect(salesEvents, hasLength(1));
        expect(orderEvents.first['orderId'], 'HD001');
        expect(orderEvents.first['status'], 'PENDING');
        expect(salesEvents.first['orderId'], 'HD001');
      });

      test('should handle order status changes', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final receivedEvents = <dynamic>[];
        webSocketService.subscribe('orders', (data) {
          receivedEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('orders', {
          'eventType': 'order.status.changed',
          'timestamp': DateTime.now().toIso8601String(),
          'orderId': 'HD001',
          'customerId': 'KH001',
          'status': 'CONFIRMED',
          'previousStatus': 'PENDING',
          'totalAmount': 1500000,
          'orderData': {
            'denghigiabanid': 'HD001',
            'tenKhachHang': 'Nguyen Van A',
            'tong': 1500000,
          },
          'userId': 'sales_manager',
          'channel': 'orders',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first['eventType'], 'order.status.changed');
        expect(receivedEvents.first['status'], 'CONFIRMED');
        expect(receivedEvents.first['previousStatus'], 'PENDING');
      });
    });

    group('Inventory Management Integration', () {
      test('should handle inventory updates', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final inventoryEvents = <dynamic>[];
        final warehouseEvents = <dynamic>[];

        webSocketService.subscribe('inventory', (data) {
          inventoryEvents.add(data);
        });

        webSocketService.subscribe('warehouse.1', (data) {
          warehouseEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('inventory', {
          'eventType': 'inventory.updated',
          'timestamp': DateTime.now().toIso8601String(),
          'itemId': 'VTPT001',
          'warehouseId': 1,
          'currentStock': 50,
          'previousStock': 75,
          'minThreshold': 10,
          'itemData': {
            'vtptid': 'VTPT001',
            'ten': 'Phu tung A',
            'donGia': 100000,
          },
          'userId': 'warehouse_user',
          'channel': 'inventory',
        });

        await mockServer.broadcastToRoom('warehouse.1', {
          'eventType': 'inventory.updated',
          'timestamp': DateTime.now().toIso8601String(),
          'itemId': 'VTPT001',
          'warehouseId': 1,
          'currentStock': 50,
          'previousStock': 75,
          'minThreshold': 10,
          'itemData': {
            'vtptid': 'VTPT001',
            'ten': 'Phu tung A',
            'donGia': 100000,
          },
          'userId': 'warehouse_user',
          'channel': 'warehouse.1',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(inventoryEvents, hasLength(1));
        expect(warehouseEvents, hasLength(1));
        expect(inventoryEvents.first['itemId'], 'VTPT001');
        expect(inventoryEvents.first['currentStock'], 50);
        expect(inventoryEvents.first['previousStock'], 75);
      });

      test('should handle low stock alerts', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final alertEvents = <dynamic>[];
        webSocketService.subscribe('inventory', (data) {
          if (data['eventType'] == 'inventory.low_stock') {
            alertEvents.add(data);
          }
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('inventory', {
          'eventType': 'inventory.low_stock',
          'timestamp': DateTime.now().toIso8601String(),
          'itemId': 'VTPT002',
          'warehouseId': 1,
          'currentStock': 5,
          'minThreshold': 10,
          'itemData': {
            'vtptid': 'VTPT002',
            'ten': 'Phu tung B',
            'donGia': 200000,
          },
          'userId': 'system',
          'channel': 'inventory',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(alertEvents, hasLength(1));
        expect(alertEvents.first['eventType'], 'inventory.low_stock');
        expect(alertEvents.first['currentStock'], 5);
        expect(alertEvents.first['minThreshold'], 10);
      });

      test('should handle out of stock alerts', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final alertEvents = <dynamic>[];
        webSocketService.subscribe('inventory', (data) {
          if (data['eventType'] == 'inventory.out_of_stock') {
            alertEvents.add(data);
          }
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('inventory', {
          'eventType': 'inventory.out_of_stock',
          'timestamp': DateTime.now().toIso8601String(),
          'itemId': 'VTPT003',
          'warehouseId': 1,
          'currentStock': 0,
          'minThreshold': 10,
          'itemData': {
            'vtptid': 'VTPT003',
            'ten': 'Phu tung C',
            'donGia': 150000,
          },
          'userId': 'system',
          'channel': 'inventory',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(alertEvents, hasLength(1));
        expect(alertEvents.first['eventType'], 'inventory.out_of_stock');
        expect(alertEvents.first['currentStock'], 0);
      });
    });

    group('Vehicle Repair Entry Module Integration', () {
      test('should handle repair quote events', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final repairEvents = <dynamic>[];
        webSocketService.subscribe('orders', (data) {
          if (data['orderData']?['type'] == 'repair_quote') {
            repairEvents.add(data);
          }
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('orders', {
          'eventType': 'order.created',
          'timestamp': DateTime.now().toIso8601String(),
          'orderId': 'RQ001',
          'customerId': 'KH001',
          'status': 'PENDING',
          'totalAmount': 2500000,
          'orderData': {
            'type': 'repair_quote',
            'vehicleId': 'VH001',
            'repairItems': [
              {'item': 'Engine oil change', 'cost': 500000},
              {'item': 'Brake pad replacement', 'cost': 2000000},
            ],
          },
          'userId': 'mechanic_user',
          'channel': 'orders',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(repairEvents, hasLength(1));
        expect(repairEvents.first['orderId'], 'RQ001');
        expect(repairEvents.first['orderData']['type'], 'repair_quote');
        expect(repairEvents.first['orderData']['vehicleId'], 'VH001');
      });

      test('should handle repair status updates', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final statusEvents = <dynamic>[];
        webSocketService.subscribe('orders', (data) {
          if (data['eventType'] == 'order.status.changed' && 
              data['orderData']?['type'] == 'repair_quote') {
            statusEvents.add(data);
          }
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('orders', {
          'eventType': 'order.status.changed',
          'timestamp': DateTime.now().toIso8601String(),
          'orderId': 'RQ001',
          'customerId': 'KH001',
          'status': 'IN_PROGRESS',
          'previousStatus': 'CONFIRMED',
          'totalAmount': 2500000,
          'orderData': {
            'type': 'repair_quote',
            'vehicleId': 'VH001',
            'progress': 'Started brake pad replacement',
          },
          'userId': 'mechanic_user',
          'channel': 'orders',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(statusEvents, hasLength(1));
        expect(statusEvents.first['status'], 'IN_PROGRESS');
        expect(statusEvents.first['previousStatus'], 'CONFIRMED');
      });
    });

    group('System Notifications Integration', () {
      test('should handle system-wide notifications', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final systemEvents = <dynamic>[];
        webSocketService.subscribe('system', (data) {
          systemEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('system', {
          'eventType': 'system.notification',
          'timestamp': DateTime.now().toIso8601String(),
          'title': 'System Maintenance',
          'message': 'System will be under maintenance from 2:00 AM to 4:00 AM',
          'type': 'INFO',
          'userId': 'admin',
          'channel': 'system',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(systemEvents, hasLength(1));
        expect(systemEvents.first['eventType'], 'system.notification');
        expect(systemEvents.first['title'], 'System Maintenance');
        expect(systemEvents.first['type'], 'INFO');
      });

      test('should handle user-specific notifications', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final userEvents = <dynamic>[];
        webSocketService.subscribe('user.user123', (data) {
          userEvents.add(data);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await mockServer.broadcastToRoom('user.user123', {
          'eventType': 'user.notification',
          'timestamp': DateTime.now().toIso8601String(),
          'targetUserId': 'user123',
          'title': 'New Order Assigned',
          'message': 'You have been assigned order HD001',
          'type': 'INFO',
          'relatedEntityId': 'HD001',
          'relatedEntityType': 'order',
          'userId': 'manager',
          'channel': 'user.user123',
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(userEvents, hasLength(1));
        expect(userEvents.first['eventType'], 'user.notification');
        expect(userEvents.first['targetUserId'], 'user123');
        expect(userEvents.first['relatedEntityId'], 'HD001');
      });
    });

    group('Multi-Module Integration Scenarios', () {
      test('should handle cascading events across modules', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final allEvents = <dynamic>[];
        
        // Subscribe to multiple channels
        webSocketService.subscribe('customers', (data) => allEvents.add(data));
        webSocketService.subscribe('orders', (data) => allEvents.add(data));
        webSocketService.subscribe('inventory', (data) => allEvents.add(data));

        await Future.delayed(const Duration(milliseconds: 200));

        // Simulate a customer placing an order that affects inventory
        
        // 1. Customer updated (address change)
        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.updated',
          'customerId': 'KH001',
          'customerData': {'diaChi': 'New Address'},
          'timestamp': DateTime.now().toIso8601String(),
        });

        await Future.delayed(const Duration(milliseconds: 100));

        // 2. Order created for that customer
        await mockServer.broadcastToRoom('orders', {
          'eventType': 'order.created',
          'orderId': 'HD002',
          'customerId': 'KH001',
          'status': 'PENDING',
          'totalAmount': 500000,
          'timestamp': DateTime.now().toIso8601String(),
        });

        await Future.delayed(const Duration(milliseconds: 100));

        // 3. Inventory updated due to order
        await mockServer.broadcastToRoom('inventory', {
          'eventType': 'inventory.updated',
          'itemId': 'VTPT004',
          'warehouseId': 1,
          'currentStock': 45,
          'previousStock': 50,
          'timestamp': DateTime.now().toIso8601String(),
        });

        await Future.delayed(const Duration(milliseconds: 200));

        expect(allEvents, hasLength(3));
        expect(allEvents[0]['eventType'], 'customer.updated');
        expect(allEvents[1]['eventType'], 'order.created');
        expect(allEvents[2]['eventType'], 'inventory.updated');
        
        // Verify the cascade relationship
        expect(allEvents[1]['customerId'], allEvents[0]['customerId']);
      });

      test('should handle concurrent events from multiple modules', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final concurrentEvents = <dynamic>[];
        
        webSocketService.subscribe('customers', (data) => concurrentEvents.add(data));
        webSocketService.subscribe('orders', (data) => concurrentEvents.add(data));
        webSocketService.subscribe('inventory', (data) => concurrentEvents.add(data));
        webSocketService.subscribe('system', (data) => concurrentEvents.add(data));

        await Future.delayed(const Duration(milliseconds: 200));

        // Send multiple events simultaneously
        final futures = <Future>[];
        
        futures.add(mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.created',
          'customerId': 'KH002',
          'timestamp': DateTime.now().toIso8601String(),
        }));

        futures.add(mockServer.broadcastToRoom('orders', {
          'eventType': 'order.status.changed',
          'orderId': 'HD003',
          'status': 'COMPLETED',
          'timestamp': DateTime.now().toIso8601String(),
        }));

        futures.add(mockServer.broadcastToRoom('inventory', {
          'eventType': 'inventory.low_stock',
          'itemId': 'VTPT005',
          'currentStock': 3,
          'timestamp': DateTime.now().toIso8601String(),
        }));

        futures.add(mockServer.broadcastToRoom('system', {
          'eventType': 'system.notification',
          'title': 'Concurrent Test',
          'message': 'Testing concurrent events',
          'timestamp': DateTime.now().toIso8601String(),
        }));

        await Future.wait(futures);
        await Future.delayed(const Duration(milliseconds: 300));

        expect(concurrentEvents, hasLength(4));
        
        // Verify all event types are present
        final eventTypes = concurrentEvents.map((e) => e['eventType']).toSet();
        expect(eventTypes, contains('customer.created'));
        expect(eventTypes, contains('order.status.changed'));
        expect(eventTypes, contains('inventory.low_stock'));
        expect(eventTypes, contains('system.notification'));
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle malformed CMS events gracefully', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final validEvents = <dynamic>[];
        webSocketService.subscribe('customers', (data) {
          // Only add valid events
          if (data is Map && data.containsKey('eventType')) {
            validEvents.add(data);
          }
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Send valid event
        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.created',
          'customerId': 'KH003',
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Send malformed event
        await mockServer.broadcastToRoom('customers', {
          'invalid': 'data',
          'missing': 'eventType',
        });

        // Send another valid event
        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.updated',
          'customerId': 'KH003',
          'timestamp': DateTime.now().toIso8601String(),
        });

        await Future.delayed(const Duration(milliseconds: 300));

        // Should only receive valid events
        expect(validEvents, hasLength(2));
        expect(validEvents[0]['eventType'], 'customer.created');
        expect(validEvents[1]['eventType'], 'customer.updated');
      });

      test('should maintain module subscriptions after reconnection', () async {
        await webSocketService.connect();
        await Future.delayed(const Duration(milliseconds: 300));

        final reconnectionEvents = <dynamic>[];
        
        // Subscribe to multiple CMS channels
        webSocketService.subscribe('customers', (data) => reconnectionEvents.add(data));
        webSocketService.subscribe('orders', (data) => reconnectionEvents.add(data));
        webSocketService.subscribe('inventory', (data) => reconnectionEvents.add(data));

        await Future.delayed(const Duration(milliseconds: 200));

        // Send initial events
        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.created',
          'customerId': 'KH004',
          'timestamp': DateTime.now().toIso8601String(),
        });

        await Future.delayed(const Duration(milliseconds: 100));
        expect(reconnectionEvents, hasLength(1));

        // Force disconnection
        mockServer.simulateConnectionDrops();
        await Future.delayed(const Duration(milliseconds: 200));

        // Reset server and allow reconnection
        mockServer.resetToNormal();
        await Future.delayed(const Duration(seconds: 1));

        // Send events after reconnection
        await mockServer.broadcastToRoom('customers', {
          'eventType': 'customer.updated',
          'customerId': 'KH004',
          'timestamp': DateTime.now().toIso8601String(),
        });

        await mockServer.broadcastToRoom('orders', {
          'eventType': 'order.created',
          'orderId': 'HD004',
          'timestamp': DateTime.now().toIso8601String(),
        });

        await Future.delayed(const Duration(milliseconds: 300));

        // Should have received events after reconnection
        expect(reconnectionEvents.length, greaterThan(1));
        
        final eventTypes = reconnectionEvents.map((e) => e['eventType']).toList();
        expect(eventTypes, contains('customer.created'));
        expect(eventTypes, contains('customer.updated'));
        expect(eventTypes, contains('order.created'));
      });
    });
  });
}