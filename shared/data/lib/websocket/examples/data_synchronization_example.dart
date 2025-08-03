import 'dart:async';
import 'dart:developer' as developer;
import '../services/websocket_data_synchronizer.dart';
import '../services/websocket_service.dart';
import '../database/sync_database.dart';
import '../models/websocket_message.dart';
import '../models/sync_operation.dart';

/// Example demonstrating how to use the WebSocket data synchronization system
class DataSynchronizationExample {
  late final SyncDatabase _database;
  late final WebSocketService _webSocketService;
  late final WebSocketDataSynchronizer _dataSynchronizer;
  
  StreamSubscription<SyncResult>? _syncResultSubscription;
  StreamSubscription<DataConflict>? _conflictSubscription;

  /// Initialize the data synchronization system
  Future<void> initialize() async {
    developer.log('Initializing data synchronization system', name: 'DataSyncExample');
    
    // Initialize database
    _database = SyncDatabase();
    
    // Initialize WebSocket service (you would provide real auth callbacks)
    _webSocketService = WebSocketService(
      // Your WebSocket config here
      WebSocketConfig(
        url: 'ws://localhost:3000',
        reconnectInterval: const Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: const Duration(seconds: 30),
      ),
      () async => 'your-jwt-token', // Auth token callback
      refreshToken: () async => 'refreshed-jwt-token', // Token refresh callback
    );
    
    // Initialize data synchronizer
    _dataSynchronizer = WebSocketDataSynchronizer(database: _database);
    
    // Set up listeners
    _setupListeners();
    
    developer.log('Data synchronization system initialized', name: 'DataSyncExample');
  }

  /// Set up listeners for synchronization events
  void _setupListeners() {
    // Listen to sync results
    _syncResultSubscription = _dataSynchronizer.syncResultStream.listen(
      (result) {
        if (result.success) {
          developer.log('Sync operation completed: ${result.operationId}', name: 'DataSyncExample');
        } else {
          developer.log('Sync operation failed: ${result.operationId} - ${result.error}', name: 'DataSyncExample');
        }
      },
    );
    
    // Listen to conflicts that need manual resolution
    _conflictSubscription = _dataSynchronizer.conflictStream.listen(
      (conflict) {
        developer.log(
          'Data conflict detected for ${conflict.entityType}:${conflict.entityId}',
          name: 'DataSyncExample',
        );
        _handleConflict(conflict);
      },
    );
    
    // Set up WebSocket message handling
    _webSocketService.subscribe('customers', (data) async {
      final message = WebSocketMessage.fromJson(data);
      await _dataSynchronizer.processMessage(message);
    });
    
    _webSocketService.subscribe('inventory', (data) async {
      final message = WebSocketMessage.fromJson(data);
      await _dataSynchronizer.processMessage(message);
    });
    
    _webSocketService.subscribe('orders', (data) async {
      final message = WebSocketMessage.fromJson(data);
      await _dataSynchronizer.processMessage(message);
    });
  }

  /// Handle data conflicts
  Future<void> _handleConflict(DataConflict conflict) async {
    developer.log('Handling conflict for ${conflict.entityType}:${conflict.entityId}', name: 'DataSyncExample');
    
    // Example: Auto-resolve using latest timestamp strategy
    try {
      final result = await _dataSynchronizer.resolveConflict(conflict, 'useLatest');
      if (result.success) {
        developer.log('Conflict resolved successfully', name: 'DataSyncExample');
      } else {
        developer.log('Failed to resolve conflict: ${result.error}', name: 'DataSyncExample');
      }
    } catch (error) {
      developer.log('Error resolving conflict: $error', name: 'DataSyncExample');
    }
  }

  /// Connect to WebSocket and start synchronization
  Future<void> connect() async {
    developer.log('Connecting to WebSocket', name: 'DataSyncExample');
    await _webSocketService.connect();
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    developer.log('Disconnecting from WebSocket', name: 'DataSyncExample');
    await _webSocketService.disconnect();
  }

  /// Get pending synchronization operations
  Future<List<SyncOperation>> getPendingOperations() async {
    return await _dataSynchronizer.getPendingOperations();
  }

  /// Clear completed synchronization operations
  Future<void> clearCompletedOperations() async {
    await _dataSynchronizer.clearCompletedOperations();
    developer.log('Cleared completed sync operations', name: 'DataSyncExample');
  }

  /// Process a batch of messages
  Future<void> processBatch(List<Map<String, dynamic>> messageData) async {
    final messages = messageData.map((data) => WebSocketMessage.fromJson(data)).toList();
    final results = await _dataSynchronizer.processBatch(messages);
    
    final successCount = results.where((r) => r.success).length;
    final failureCount = results.where((r) => !r.success).length;
    
    developer.log(
      'Batch processing completed: $successCount successful, $failureCount failed',
      name: 'DataSyncExample',
    );
  }

  /// Get all customers from local database
  Future<List<Customer>> getCustomers() async {
    return await _database.getAllCustomers();
  }

  /// Get all inventory items from local database
  Future<List<InventoryData>> getInventory() async {
    return await _database.getAllInventory();
  }

  /// Get all orders from local database
  Future<List<Order>> getOrders() async {
    return await _database.getAllOrders();
  }

  /// Dispose resources
  Future<void> dispose() async {
    developer.log('Disposing data synchronization system', name: 'DataSyncExample');
    
    await _syncResultSubscription?.cancel();
    await _conflictSubscription?.cancel();
    
    _dataSynchronizer.dispose();
    _webSocketService.dispose();
    
    developer.log('Data synchronization system disposed', name: 'DataSyncExample');
  }
}

/// Example usage
void main() async {
  final example = DataSynchronizationExample();
  
  try {
    // Initialize the system
    await example.initialize();
    
    // Connect to WebSocket
    await example.connect();
    
    // Example: Process some messages
    await example.processBatch([
      {
        'type': 'customer.updated',
        'channel': 'customers',
        'data': {'id': '123', 'name': 'Updated Customer'},
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'type': 'inventory.changed',
        'channel': 'inventory',
        'data': {'id': '456', 'quantity': 100},
        'timestamp': DateTime.now().toIso8601String(),
      },
    ]);
    
    // Get data from local database
    final customers = await example.getCustomers();
    final inventory = await example.getInventory();
    final orders = await example.getOrders();
    
    developer.log('Local data: ${customers.length} customers, ${inventory.length} inventory items, ${orders.length} orders');
    
    // Clean up
    await example.clearCompletedOperations();
    
  } catch (error) {
    developer.log('Error in example: $error');
  } finally {
    // Always dispose resources
    await example.dispose();
  }
}