import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'package:mockito/mockito.dart' as mockito;

import 'package:data/websocket/interfaces/i_websocket_service.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/stores/customer_websocket_store.dart';

import 'websocket_aware_store_test.mocks.dart';

@GenerateMocks([IWebSocketService])
void main() {
  group('CustomerWebSocketStore', () {
    late MockIWebSocketService mockWebSocketService;
    late CustomerWebSocketStore store;
    late StreamController<WebSocketConnectionState> connectionStateController;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
      
      mockito.when(mockWebSocketService.connectionState)
          .thenAnswer((_) => connectionStateController.stream);
      mockito.when(mockWebSocketService.currentState)
          .thenReturn(WebSocketConnectionState.disconnected);
      
      store = CustomerWebSocketStore(mockWebSocketService);
    });

    tearDown(() {
      store.dispose();
      connectionStateController.close();
    });

    test('should initialize with correct subscribed channels', () {
      expect(store.subscribedChannels, equals(['customers', 'customers.updates']));
    });

    test('should initialize with empty customer data', () {
      expect(store.customers.isEmpty, isTrue);
      expect(store.totalCustomers, equals(0));
      expect(store.activeCustomers, equals(0));
      expect(store.vipCustomerCount, equals(0));
      expect(store.conflictResolutionMessage, isNull);
    });

    test('should handle customer updated message', () {
      final customerData = {
        'id': 'customer_1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'address': '123 Main St',
        'status': 'active',
        'isVip': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': 1,
      };

      final message = {
        'type': 'customer.updated',
        'channel': 'customers',
        'data': customerData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('customers', message);

      expect(store.customers.length, equals(1));
      expect(store.customers['customer_1']?.name, equals('John Doe'));
      expect(store.totalCustomers, equals(1));
      expect(store.activeCustomers, equals(1));
    });

    test('should handle customer created message', () {
      final customerData = {
        'id': 'new_customer',
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'phone': '+0987654321',
        'address': '456 Oak Ave',
        'status': 'active',
        'isVip': true,
        'createdAt': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': 1,
      };

      final message = {
        'type': 'customer.created',
        'channel': 'customers',
        'data': customerData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('customers', message);

      expect(store.customers.length, equals(1));
      expect(store.customers['new_customer']?.name, equals('Jane Smith'));
      expect(store.customers['new_customer']?.isVip, isTrue);
      expect(store.vipCustomerCount, equals(1));
    });

    test('should handle customer deleted message', () {
      // First add a customer
      final customer = Customer(
        id: 'customer_to_delete',
        name: 'Delete Me',
        email: 'delete@example.com',
        phone: '+1111111111',
        address: '789 Delete St',
        status: CustomerStatus.active,
        isVip: false,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lastUpdated: DateTime.now(),
        version: 1,
      );
      store.addCustomer(customer);

      expect(store.customers.length, equals(1));

      // Now delete it via WebSocket message
      final message = {
        'type': 'customer.deleted',
        'channel': 'customers',
        'data': {'id': 'customer_to_delete'},
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('customers', message);

      expect(store.customers.length, equals(0));
      expect(store.totalCustomers, equals(0));
    });

    test('should handle customer status changed message', () {
      // First add a customer
      final customer = Customer(
        id: 'status_change_customer',
        name: 'Status Change',
        email: 'status@example.com',
        phone: '+2222222222',
        address: '321 Status St',
        status: CustomerStatus.active,
        isVip: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
        version: 1,
      );
      store.addCustomer(customer);

      expect(store.customers['status_change_customer']?.status, equals(CustomerStatus.active));

      // Change status via WebSocket message
      final message = {
        'type': 'customer.status.changed',
        'channel': 'customers',
        'data': {
          'id': 'status_change_customer',
          'status': 'suspended',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('customers', message);

      expect(store.customers['status_change_customer']?.status, equals(CustomerStatus.suspended));
      expect(store.activeCustomers, equals(0)); // Should decrease active count
    });

    test('should handle customer conflict message', () {
      final serverCustomerData = {
        'id': 'conflict_customer',
        'name': 'Conflict Customer Server',
        'email': 'conflict@example.com',
        'phone': '+3333333333',
        'address': '654 Conflict Ave',
        'status': 'active',
        'isVip': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': 2,
      };

      final message = {
        'type': 'customer.conflict',
        'channel': 'customers',
        'data': {
          'customerId': 'conflict_customer',
          'conflictType': 'version_mismatch',
          'serverVersion': serverCustomerData,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('customers', message);

      expect(store.conflictResolutionMessage, isNotNull);
      expect(store.conflictResolutionMessage, contains('conflict_customer'));
      expect(store.customers['conflict_customer']?.name, equals('Conflict Customer Server'));
    });

    test('should calculate recently updated customers correctly', () {
      final now = DateTime.now();
      final customers = [
        Customer(
          id: 'recent_1',
          name: 'Recent Customer 1',
          email: 'recent1@example.com',
          phone: '+1111111111',
          address: '111 Recent St',
          status: CustomerStatus.active,
          isVip: false,
          createdAt: now.subtract(const Duration(days: 10)),
          lastUpdated: now.subtract(const Duration(hours: 2)), // Recent
          version: 1,
        ),
        Customer(
          id: 'old_1',
          name: 'Old Customer 1',
          email: 'old1@example.com',
          phone: '+2222222222',
          address: '222 Old St',
          status: CustomerStatus.active,
          isVip: false,
          createdAt: now.subtract(const Duration(days: 30)),
          lastUpdated: now.subtract(const Duration(days: 2)), // Old
          version: 1,
        ),
        Customer(
          id: 'recent_2',
          name: 'Recent Customer 2',
          email: 'recent2@example.com',
          phone: '+3333333333',
          address: '333 Recent Ave',
          status: CustomerStatus.active,
          isVip: true,
          createdAt: now.subtract(const Duration(days: 5)),
          lastUpdated: now.subtract(const Duration(minutes: 30)), // Recent
          version: 1,
        ),
      ];

      store.updateCustomers(customers);

      expect(store.recentlyUpdatedCustomers.length, equals(2));
      expect(store.recentlyUpdatedCustomers.first.id, equals('recent_2')); // Most recent first
      expect(store.recentlyUpdatedCustomers.last.id, equals('recent_1'));
    });

    test('should calculate VIP customers correctly', () {
      final customers = [
        Customer(
          id: 'regular_1',
          name: 'Regular Customer',
          email: 'regular@example.com',
          phone: '+1111111111',
          address: '111 Regular St',
          status: CustomerStatus.active,
          isVip: false,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          lastUpdated: DateTime.now(),
          version: 1,
        ),
        Customer(
          id: 'vip_1',
          name: 'VIP Customer 1',
          email: 'vip1@example.com',
          phone: '+2222222222',
          address: '222 VIP Ave',
          status: CustomerStatus.active,
          isVip: true,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          lastUpdated: DateTime.now(),
          version: 1,
        ),
        Customer(
          id: 'vip_2',
          name: 'VIP Customer 2',
          email: 'vip2@example.com',
          phone: '+3333333333',
          address: '333 VIP Blvd',
          status: CustomerStatus.suspended,
          isVip: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          lastUpdated: DateTime.now(),
          version: 1,
        ),
      ];

      store.updateCustomers(customers);

      expect(store.vipCustomers.length, equals(2));
      expect(store.vipCustomerCount, equals(2));
      expect(store.activeCustomers, equals(2)); // Only active customers
    });

    test('should search customers correctly', () {
      final customers = [
        Customer(
          id: 'search_1',
          name: 'John Smith',
          email: 'john.smith@example.com',
          phone: '+1234567890',
          address: '123 Main St',
          status: CustomerStatus.active,
          isVip: false,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          lastUpdated: DateTime.now(),
          version: 1,
        ),
        Customer(
          id: 'search_2',
          name: 'Jane Doe',
          email: 'jane.doe@example.com',
          phone: '+0987654321',
          address: '456 Oak Ave',
          status: CustomerStatus.active,
          isVip: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          lastUpdated: DateTime.now(),
          version: 1,
        ),
      ];

      store.updateCustomers(customers);

      // Search by name
      var results = store.searchCustomers('john');
      expect(results.length, equals(1));
      expect(results.first.name, equals('John Smith'));

      // Search by email
      results = store.searchCustomers('jane.doe');
      expect(results.length, equals(1));
      expect(results.first.email, equals('jane.doe@example.com'));

      // Search by phone
      results = store.searchCustomers('1234567890');
      expect(results.length, equals(1));
      expect(results.first.phone, equals('+1234567890'));

      // Search with empty query should return all customers
      results = store.searchCustomers('');
      expect(results.length, equals(2));
    });

    test('should update connection state correctly', () {
      expect(store.isReceivingUpdates, isFalse);
      expect(store.conflictResolutionMessage, isNull);

      connectionStateController.add(WebSocketConnectionState.connected);
      expect(store.isReceivingUpdates, isTrue);

      // Set a conflict message
      store.handleWebSocketMessage('customers', {
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

      expect(store.conflictResolutionMessage, isNotNull);

      connectionStateController.add(WebSocketConnectionState.disconnected);
      expect(store.isReceivingUpdates, isFalse);
      expect(store.conflictResolutionMessage, isNull); // Should clear on disconnect
    });

    test('should handle conflict resolution actions', () {
      // Set up a conflict
      store.handleWebSocketMessage('customers', {
        'type': 'customer.conflict',
        'channel': 'customers',
        'data': {
          'customerId': 'conflict_test',
          'conflictType': 'version_mismatch',
          'serverVersion': {
            'id': 'conflict_test',
            'name': 'Server Version',
            'email': 'server@example.com',
            'phone': '+1111111111',
            'address': 'Server Address',
            'status': 'active',
            'isVip': false,
            'createdAt': DateTime.now().toIso8601String(),
            'lastUpdated': DateTime.now().toIso8601String(),
            'version': 2,
          },
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      expect(store.conflictResolutionMessage, isNotNull);

      // Accept server version
      store.acceptServerVersion('conflict_test');
      expect(store.conflictResolutionMessage, isNull);

      // Set up another conflict
      store.handleWebSocketMessage('customers', {
        'type': 'customer.conflict',
        'channel': 'customers',
        'data': {
          'customerId': 'conflict_test_2',
          'conflictType': 'version_mismatch',
          'serverVersion': {
            'id': 'conflict_test_2',
            'name': 'Server Version 2',
            'email': 'server2@example.com',
            'phone': '+2222222222',
            'address': 'Server Address 2',
            'status': 'active',
            'isVip': false,
            'createdAt': DateTime.now().toIso8601String(),
            'lastUpdated': DateTime.now().toIso8601String(),
            'version': 2,
          },
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      expect(store.conflictResolutionMessage, isNotNull);

      // Keep local version
      store.keepLocalVersion('conflict_test_2');
      expect(store.conflictResolutionMessage, isNull);
    });

    test('should handle invalid WebSocket messages gracefully', () {
      // Test with invalid JSON structure
      expect(() => store.handleWebSocketMessage('customers', 'invalid_json'), 
             returnsNormally);

      // Test with unknown message type
      final message = {
        'type': 'unknown.message.type',
        'channel': 'customers',
        'data': {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => store.handleWebSocketMessage('customers', message), 
             returnsNormally);
    });

    test('should update last update time when processing messages', () {
      expect(store.lastUpdateTime, isNull);

      final message = {
        'type': 'customer.updated',
        'channel': 'customers',
        'data': {
          'id': 'test_customer',
          'name': 'Test Customer',
          'email': 'test@example.com',
          'phone': '+1111111111',
          'address': 'Test Address',
          'status': 'active',
          'isVip': false,
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': 1,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      store.handleWebSocketMessage('customers', message);

      expect(store.lastUpdateTime, isNotNull);
      expect(store.lastUpdateTime!.isBefore(DateTime.now().add(const Duration(seconds: 1))), 
             isTrue);
    });
  });
}