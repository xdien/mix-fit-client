import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/i_websocket_data_synchronizer.dart';
import '../interfaces/i_message_router.dart';
import '../interfaces/i_conflict_resolver.dart';
import '../models/websocket_message.dart';
import '../models/websocket_message_type.dart';
import '../models/sync_operation.dart';
import '../database/sync_database.dart';
import 'message_router.dart';
import 'conflict_resolver.dart';

/// Implementation of WebSocket data synchronizer
class WebSocketDataSynchronizer implements IWebSocketDataSynchronizer {
  final SyncDatabase _database;
  final IMessageRouter _messageRouter;
  final IConflictResolver _conflictResolver;
  
  final StreamController<SyncResult> _syncResultController = 
      StreamController<SyncResult>.broadcast();
  final StreamController<DataConflict> _conflictController = 
      StreamController<DataConflict>.broadcast();

  WebSocketDataSynchronizer({
    required SyncDatabase database,
    IMessageRouter? messageRouter,
    IConflictResolver? conflictResolver,
  }) : _database = database,
       _messageRouter = messageRouter ?? MessageRouter(),
       _conflictResolver = conflictResolver ?? ConflictResolver() {
    _setupMessageHandlers();
  }

  @override
  Stream<SyncResult> get syncResultStream => _syncResultController.stream;

  @override
  Stream<DataConflict> get conflictStream => _conflictController.stream;

  /// Expose conflict controller for testing
  @visibleForTesting
  StreamController<DataConflict> get conflictController => _conflictController;

  void _setupMessageHandlers() {
    // Register handlers for different message types
    _messageRouter.registerHandler(
      WebSocketMessageType.customerUpdate,
      _handleCustomerUpdate,
    );
    
    _messageRouter.registerHandler(
      WebSocketMessageType.inventoryUpdate,
      _handleInventoryUpdate,
    );
    
    _messageRouter.registerHandler(
      WebSocketMessageType.orderStatusUpdate,
      _handleOrderUpdate,
    );
    
    _messageRouter.registerHandler(
      WebSocketMessageType.systemNotification,
      _handleSystemNotification,
    );
  }

  @override
  Future<SyncResult> processMessage(WebSocketMessage message) async {
    developer.log(
      'Processing WebSocket message: ${message.type} for channel: ${message.channel}',
      name: 'WebSocketDataSynchronizer',
    );

    try {
      // Route the message to appropriate handler
      await _messageRouter.routeMessage(message);
      
      final result = SyncResult(
        operationId: message.messageId ?? 'unknown',
        success: true,
        completedAt: DateTime.now(),
      );
      
      _syncResultController.add(result);
      return result;
      
    } catch (error, stackTrace) {
      developer.log(
        'Error processing message: $error',
        error: error,
        stackTrace: stackTrace,
        name: 'WebSocketDataSynchronizer',
      );
      
      final result = SyncResult(
        operationId: message.messageId ?? 'unknown',
        success: false,
        error: error.toString(),
        completedAt: DateTime.now(),
      );
      
      _syncResultController.add(result);
      return result;
    }
  }

  @override
  Future<List<SyncResult>> processBatch(List<WebSocketMessage> messages) async {
    developer.log(
      'Processing batch of ${messages.length} messages',
      name: 'WebSocketDataSynchronizer',
    );

    final results = <SyncResult>[];
    
    // Process messages in order to maintain consistency
    for (final message in messages) {
      final result = await processMessage(message);
      results.add(result);
    }
    
    return results;
  }

  @override
  Future<SyncResult> resolveConflict(DataConflict conflict, String strategy) async {
    developer.log(
      'Resolving conflict for ${conflict.entityType}:${conflict.entityId} with strategy: $strategy',
      name: 'WebSocketDataSynchronizer',
    );

    try {
      final strategyEnum = _parseConflictStrategy(strategy);
      final resolvedData = await _conflictResolver.resolveConflict(conflict, strategyEnum);
      
      // Apply the resolved data to the database
      await _applyResolvedData(conflict.entityType, conflict.entityId, resolvedData);
      
      final result = SyncResult(
        operationId: '${conflict.entityType}_${conflict.entityId}_conflict',
        success: true,
        completedAt: DateTime.now(),
      );
      
      _syncResultController.add(result);
      return result;
      
    } catch (error, stackTrace) {
      developer.log(
        'Error resolving conflict: $error',
        error: error,
        stackTrace: stackTrace,
        name: 'WebSocketDataSynchronizer',
      );
      
      final result = SyncResult(
        operationId: '${conflict.entityType}_${conflict.entityId}_conflict',
        success: false,
        error: error.toString(),
        completedAt: DateTime.now(),
      );
      
      _syncResultController.add(result);
      return result;
    }
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async {
    final dbOperations = await _database.getPendingSyncOperations();
    return dbOperations.map((op) => SyncOperation(
      id: op.operationId,
      type: _parseSyncOperationType(op.operationType),
      entityType: op.entityType,
      entityId: op.entityId,
      data: jsonDecode(op.data),
      timestamp: op.createdAt,
      priority: _parseSyncPriority(op.priority),
    )).toList();
  }

  @override
  Future<void> clearCompletedOperations() async {
    await _database.clearCompletedSyncOperations();
    developer.log('Cleared completed sync operations', name: 'WebSocketDataSynchronizer');
  }

  Future<void> _handleCustomerUpdate(WebSocketMessage message) async {
    developer.log('Handling customer update', name: 'WebSocketDataSynchronizer');
    
    final customerData = message.data;
    final externalId = customerData['id']?.toString();
    
    if (externalId == null) {
      throw ArgumentError('Customer update missing ID');
    }

    // Check if customer exists locally
    final existingCustomer = await _database.getCustomerByExternalId(externalId);
    
    if (existingCustomer != null) {
      // Check for conflicts
      final conflict = await _detectCustomerConflict(existingCustomer, customerData, message.timestamp);
      
      if (conflict != null) {
        if (_conflictResolver.canAutoResolve(conflict)) {
          final strategy = _conflictResolver.getDefaultStrategy('customer');
          await resolveConflict(conflict, strategy.name);
        } else {
          _conflictController.add(conflict);
        }
      } else {
        // No conflict, update directly
        await _updateCustomer(externalId, customerData, message.timestamp);
      }
    } else {
      // New customer, insert
      await _insertCustomer(customerData, message.timestamp);
    }
  }

  Future<void> _handleInventoryUpdate(WebSocketMessage message) async {
    developer.log('Handling inventory update', name: 'WebSocketDataSynchronizer');
    
    final inventoryData = message.data;
    final externalId = inventoryData['id']?.toString();
    
    if (externalId == null) {
      throw ArgumentError('Inventory update missing ID');
    }

    // Check if inventory item exists locally
    final existingItem = await _database.getInventoryByExternalId(externalId);
    
    if (existingItem != null) {
      // Check for conflicts
      final conflict = await _detectInventoryConflict(existingItem, inventoryData, message.timestamp);
      
      if (conflict != null) {
        if (_conflictResolver.canAutoResolve(conflict)) {
          final strategy = _conflictResolver.getDefaultStrategy('inventory');
          await resolveConflict(conflict, strategy.name);
        } else {
          _conflictController.add(conflict);
        }
      } else {
        // No conflict, update directly
        await _updateInventory(externalId, inventoryData, message.timestamp);
      }
    } else {
      // New inventory item, insert
      await _insertInventory(inventoryData, message.timestamp);
    }
  }

  Future<void> _handleOrderUpdate(WebSocketMessage message) async {
    developer.log('Handling order update', name: 'WebSocketDataSynchronizer');
    
    final orderData = message.data;
    final externalId = orderData['id']?.toString();
    
    if (externalId == null) {
      throw ArgumentError('Order update missing ID');
    }

    // Check if order exists locally
    final existingOrder = await _database.getOrderByExternalId(externalId);
    
    if (existingOrder != null) {
      // Check for conflicts
      final conflict = await _detectOrderConflict(existingOrder, orderData, message.timestamp);
      
      if (conflict != null) {
        if (_conflictResolver.canAutoResolve(conflict)) {
          final strategy = _conflictResolver.getDefaultStrategy('order');
          await resolveConflict(conflict, strategy.name);
        } else {
          _conflictController.add(conflict);
        }
      } else {
        // No conflict, update directly
        await _updateOrder(externalId, orderData, message.timestamp);
      }
    } else {
      // New order, insert
      await _insertOrder(orderData, message.timestamp);
    }
  }

  Future<void> _handleSystemNotification(WebSocketMessage message) async {
    developer.log('Handling system notification', name: 'WebSocketDataSynchronizer');
    // System notifications don't require database sync, just log
    developer.log('System notification: ${message.data}', name: 'WebSocketDataSynchronizer');
  }

  Future<DataConflict?> _detectCustomerConflict(
    Customer existing,
    Map<String, dynamic> remoteData,
    DateTime remoteTimestamp,
  ) async {
    // Check if local data was modified after last sync
    if (existing.lastSyncAt != null && existing.updatedAt.isAfter(existing.lastSyncAt!)) {
      return DataConflict(
        entityType: 'customer',
        entityId: existing.externalId,
        localData: _customerToMap(existing),
        remoteData: remoteData,
        localTimestamp: existing.updatedAt,
        remoteTimestamp: remoteTimestamp,
      );
    }
    return null;
  }

  Future<DataConflict?> _detectInventoryConflict(
    InventoryData existing,
    Map<String, dynamic> remoteData,
    DateTime remoteTimestamp,
  ) async {
    // Check if local data was modified after last sync
    if (existing.lastSyncAt != null && existing.updatedAt.isAfter(existing.lastSyncAt!)) {
      return DataConflict(
        entityType: 'inventory',
        entityId: existing.externalId,
        localData: _inventoryToMap(existing),
        remoteData: remoteData,
        localTimestamp: existing.updatedAt,
        remoteTimestamp: remoteTimestamp,
      );
    }
    return null;
  }

  Future<DataConflict?> _detectOrderConflict(
    Order existing,
    Map<String, dynamic> remoteData,
    DateTime remoteTimestamp,
  ) async {
    // Check if local data was modified after last sync
    if (existing.lastSyncAt != null && existing.updatedAt.isAfter(existing.lastSyncAt!)) {
      return DataConflict(
        entityType: 'order',
        entityId: existing.externalId,
        localData: _orderToMap(existing),
        remoteData: remoteData,
        localTimestamp: existing.updatedAt,
        remoteTimestamp: remoteTimestamp,
      );
    }
    return null;
  }

  Future<void> _insertCustomer(Map<String, dynamic> data, DateTime syncTime) async {
    final customer = CustomersCompanion(
      externalId: Value(data['id']?.toString() ?? ''),
      name: Value(data['name']?.toString() ?? ''),
      email: Value(data['email']?.toString()),
      phone: Value(data['phone']?.toString()),
      address: Value(data['address']?.toString()),
      balance: Value(data['balance']?.toDouble() ?? 0.0),
      creditLimit: Value(data['credit_limit']?.toDouble() ?? 0.0),
      status: Value(data['status']?.toString() ?? 'active'),
      lastSyncAt: Value(syncTime),
    );
    
    await _database.insertCustomer(customer);
  }

  Future<void> _updateCustomer(String externalId, Map<String, dynamic> data, DateTime syncTime) async {
    final customer = CustomersCompanion(
      name: Value(data['name']?.toString() ?? ''),
      email: Value(data['email']?.toString()),
      phone: Value(data['phone']?.toString()),
      address: Value(data['address']?.toString()),
      balance: Value(data['balance']?.toDouble() ?? 0.0),
      creditLimit: Value(data['credit_limit']?.toDouble() ?? 0.0),
      status: Value(data['status']?.toString() ?? 'active'),
      updatedAt: Value(DateTime.now()),
      lastSyncAt: Value(syncTime),
    );
    
    await _database.updateCustomer(externalId, customer);
  }

  Future<void> _insertInventory(Map<String, dynamic> data, DateTime syncTime) async {
    final inventory = InventoryCompanion(
      externalId: Value(data['id']?.toString() ?? ''),
      name: Value(data['name']?.toString() ?? ''),
      description: Value(data['description']?.toString()),
      category: Value(data['category']?.toString()),
      quantity: Value(data['quantity']?.toInt() ?? 0),
      price: Value(data['price']?.toDouble() ?? 0.0),
      unit: Value(data['unit']?.toString()),
      status: Value(data['status']?.toString() ?? 'active'),
      lastSyncAt: Value(syncTime),
    );
    
    await _database.insertInventory(inventory);
  }

  Future<void> _updateInventory(String externalId, Map<String, dynamic> data, DateTime syncTime) async {
    final inventory = InventoryCompanion(
      name: Value(data['name']?.toString() ?? ''),
      description: Value(data['description']?.toString()),
      category: Value(data['category']?.toString()),
      quantity: Value(data['quantity']?.toInt() ?? 0),
      price: Value(data['price']?.toDouble() ?? 0.0),
      unit: Value(data['unit']?.toString()),
      status: Value(data['status']?.toString() ?? 'active'),
      updatedAt: Value(DateTime.now()),
      lastSyncAt: Value(syncTime),
    );
    
    await _database.updateInventory(externalId, inventory);
  }

  Future<void> _insertOrder(Map<String, dynamic> data, DateTime syncTime) async {
    final order = OrdersCompanion(
      externalId: Value(data['id']?.toString() ?? ''),
      customerExternalId: Value(data['customer_id']?.toString() ?? ''),
      status: Value(data['status']?.toString() ?? 'pending'),
      totalAmount: Value(data['total_amount']?.toDouble() ?? 0.0),
      paymentStatus: Value(data['payment_status']?.toString() ?? 'pending'),
      notes: Value(data['notes']?.toString()),
      deliveryAddress: Value(data['delivery_address']?.toString()),
      orderDate: Value(DateTime.tryParse(data['order_date']?.toString() ?? '') ?? DateTime.now()),
      lastSyncAt: Value(syncTime),
    );
    
    await _database.insertOrder(order);
  }

  Future<void> _updateOrder(String externalId, Map<String, dynamic> data, DateTime syncTime) async {
    final order = OrdersCompanion(
      customerExternalId: Value(data['customer_id']?.toString() ?? ''),
      status: Value(data['status']?.toString() ?? 'pending'),
      totalAmount: Value(data['total_amount']?.toDouble() ?? 0.0),
      paymentStatus: Value(data['payment_status']?.toString() ?? 'pending'),
      notes: Value(data['notes']?.toString()),
      deliveryAddress: Value(data['delivery_address']?.toString()),
      orderDate: Value(DateTime.tryParse(data['order_date']?.toString() ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
      lastSyncAt: Value(syncTime),
    );
    
    await _database.updateOrder(externalId, order);
  }

  Future<void> _applyResolvedData(String entityType, String entityId, Map<String, dynamic> data) async {
    switch (entityType) {
      case 'customer':
        await _updateCustomer(entityId, data, DateTime.now());
        break;
      case 'inventory':
        await _updateInventory(entityId, data, DateTime.now());
        break;
      case 'order':
        await _updateOrder(entityId, data, DateTime.now());
        break;
      default:
        throw ArgumentError('Unknown entity type: $entityType');
    }
  }

  Map<String, dynamic> _customerToMap(Customer customer) {
    return {
      'id': customer.externalId,
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'address': customer.address,
      'balance': customer.balance,
      'credit_limit': customer.creditLimit,
      'status': customer.status,
    };
  }

  Map<String, dynamic> _inventoryToMap(InventoryData inventory) {
    return {
      'id': inventory.externalId,
      'name': inventory.name,
      'description': inventory.description,
      'category': inventory.category,
      'quantity': inventory.quantity,
      'price': inventory.price,
      'unit': inventory.unit,
      'status': inventory.status,
    };
  }

  Map<String, dynamic> _orderToMap(Order order) {
    return {
      'id': order.externalId,
      'customer_id': order.customerExternalId,
      'status': order.status,
      'total_amount': order.totalAmount,
      'payment_status': order.paymentStatus,
      'notes': order.notes,
      'delivery_address': order.deliveryAddress,
      'order_date': order.orderDate.toIso8601String(),
    };
  }

  ConflictResolutionStrategy _parseConflictStrategy(String strategy) {
    switch (strategy.toLowerCase()) {
      case 'useremote':
        return ConflictResolutionStrategy.useRemote;
      case 'uselocal':
        return ConflictResolutionStrategy.useLocal;
      case 'merge':
        return ConflictResolutionStrategy.merge;
      case 'uselatest':
        return ConflictResolutionStrategy.useLatest;
      case 'manual':
        return ConflictResolutionStrategy.manual;
      default:
        return ConflictResolutionStrategy.useLatest;
    }
  }

  SyncOperationType _parseSyncOperationType(String type) {
    switch (type.toLowerCase()) {
      case 'create':
        return SyncOperationType.create;
      case 'update':
        return SyncOperationType.update;
      case 'delete':
        return SyncOperationType.delete;
      case 'merge':
        return SyncOperationType.merge;
      default:
        return SyncOperationType.update;
    }
  }

  SyncPriority _parseSyncPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return SyncPriority.low;
      case 'normal':
        return SyncPriority.normal;
      case 'high':
        return SyncPriority.high;
      case 'critical':
        return SyncPriority.critical;
      default:
        return SyncPriority.normal;
    }
  }

  @override
  void dispose() {
    developer.log('Disposing WebSocketDataSynchronizer', name: 'WebSocketDataSynchronizer');
    _syncResultController.close();
    _conflictController.close();
    if (_messageRouter is MessageRouter) {
      (_messageRouter as MessageRouter).dispose();
    }
  }
}