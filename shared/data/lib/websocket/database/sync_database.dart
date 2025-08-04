import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'sync_database.g.dart';

/// Table for storing customer data
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text().unique()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

/// Table for storing inventory data
class Inventory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

/// Table for storing order data
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text().unique()();
  TextColumn get customerExternalId => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  TextColumn get notes => text().nullable()();
  TextColumn get deliveryAddress => text().nullable()();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

/// Table for storing synchronization operations
class SyncOperationEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId => text().unique()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get data => text()(); // JSON string
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// Table for storing queued WebSocket messages
class QueuedMessageEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  TextColumn get messageType => text()();
  TextColumn get channel => text()();
  TextColumn get messageData => text()(); // JSON string of WebSocket message
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get metadata => text().nullable()(); // JSON string
}

/// Database class for WebSocket synchronization
@DriftDatabase(tables: [Customers, Inventory, Orders, SyncOperationEntries, QueuedMessageEntries])
class SyncDatabase extends _$SyncDatabase {
  SyncDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add QueuedMessageEntries table in version 2
        await m.createTable(queuedMessageEntries);
      }
    },
  );

  // Customer operations
  Future<List<Customer>> getAllCustomers() => select(customers).get();
  
  Future<Customer?> getCustomerByExternalId(String externalId) =>
      (select(customers)..where((c) => c.externalId.equals(externalId))).getSingleOrNull();

  Future<int> insertCustomer(CustomersCompanion customer) =>
      into(customers).insert(customer);

  Future<bool> updateCustomer(String externalId, CustomersCompanion customer) async {
    final result = await (update(customers)..where((c) => c.externalId.equals(externalId))).write(customer);
    return result > 0;
  }

  Future<int> deleteCustomer(String externalId) =>
      (delete(customers)..where((c) => c.externalId.equals(externalId))).go();

  // Inventory operations
  Future<List<InventoryData>> getAllInventory() => select(inventory).get();
  
  Future<InventoryData?> getInventoryByExternalId(String externalId) =>
      (select(inventory)..where((i) => i.externalId.equals(externalId))).getSingleOrNull();

  Future<int> insertInventory(InventoryCompanion item) =>
      into(inventory).insert(item);

  Future<bool> updateInventory(String externalId, InventoryCompanion item) async {
    final result = await (update(inventory)..where((i) => i.externalId.equals(externalId))).write(item);
    return result > 0;
  }

  Future<int> deleteInventory(String externalId) =>
      (delete(inventory)..where((i) => i.externalId.equals(externalId))).go();

  // Order operations
  Future<List<Order>> getAllOrders() => select(orders).get();
  
  Future<Order?> getOrderByExternalId(String externalId) =>
      (select(orders)..where((o) => o.externalId.equals(externalId))).getSingleOrNull();

  Future<int> insertOrder(OrdersCompanion order) =>
      into(orders).insert(order);

  Future<bool> updateOrder(String externalId, OrdersCompanion order) async {
    final result = await (update(orders)..where((o) => o.externalId.equals(externalId))).write(order);
    return result > 0;
  }

  Future<int> deleteOrder(String externalId) =>
      (delete(orders)..where((o) => o.externalId.equals(externalId))).go();

  // Sync operations
  Future<List<SyncOperationEntry>> getPendingSyncOperations() =>
      (select(syncOperationEntries)..where((s) => s.status.equals('pending'))).get();

  Future<int> insertSyncOperation(SyncOperationEntriesCompanion operation) =>
      into(syncOperationEntries).insert(operation);

  Future<bool> updateSyncOperationStatus(String operationId, String status, {String? error}) async {
    final result = await (update(syncOperationEntries)..where((s) => s.operationId.equals(operationId))).write(
      SyncOperationEntriesCompanion(
        status: Value(status),
        error: Value(error),
        completedAt: status == 'completed' ? Value(DateTime.now()) : const Value.absent(),
      ),
    );
    return result > 0;
  }

  Future<int> clearCompletedSyncOperations() =>
      (delete(syncOperationEntries)..where((s) => s.status.equals('completed'))).go();

  // Queued message operations
  Future<List<QueuedMessageEntry>> getAllQueuedMessages() => select(queuedMessageEntries).get();
  
  Future<List<QueuedMessageEntry>> getQueuedMessagesByStatus(String status) =>
      (select(queuedMessageEntries)..where((q) => q.status.equals(status))).get();

  Future<List<QueuedMessageEntry>> getQueuedMessagesByPriority(String priority) =>
      (select(queuedMessageEntries)..where((q) => q.priority.equals(priority))).get();

  Future<List<QueuedMessageEntry>> getPendingQueuedMessages({int? limit}) {
    final query = select(queuedMessageEntries)
      ..where((q) => q.status.equals('pending'))
      ..orderBy([(q) => OrderingTerm(expression: q.priority, mode: OrderingMode.desc),
                 (q) => OrderingTerm(expression: q.queuedAt, mode: OrderingMode.asc)]);
    
    if (limit != null) {
      query.limit(limit);
    }
    
    return query.get();
  }

  Future<QueuedMessageEntry?> getQueuedMessageById(String messageId) =>
      (select(queuedMessageEntries)..where((q) => q.messageId.equals(messageId))).getSingleOrNull();

  Future<int> insertQueuedMessage(QueuedMessageEntriesCompanion message) =>
      into(queuedMessageEntries).insert(message);

  Future<bool> updateQueuedMessageStatus(String messageId, String status, {String? error, DateTime? processedAt}) async {
    final result = await (update(queuedMessageEntries)..where((q) => q.messageId.equals(messageId))).write(
      QueuedMessageEntriesCompanion(
        status: Value(status),
        error: Value(error),
        processedAt: Value(processedAt),
      ),
    );
    return result > 0;
  }

  Future<bool> updateQueuedMessagePriority(String messageId, String priority) async {
    final result = await (update(queuedMessageEntries)..where((q) => q.messageId.equals(messageId))).write(
      QueuedMessageEntriesCompanion(priority: Value(priority)),
    );
    return result > 0;
  }

  Future<bool> incrementRetryCount(String messageId) async {
    final message = await getQueuedMessageById(messageId);
    if (message == null) return false;
    
    final result = await (update(queuedMessageEntries)..where((q) => q.messageId.equals(messageId))).write(
      QueuedMessageEntriesCompanion(retryCount: Value(message.retryCount + 1)),
    );
    return result > 0;
  }

  Future<int> deleteQueuedMessage(String messageId) =>
      (delete(queuedMessageEntries)..where((q) => q.messageId.equals(messageId))).go();

  Future<int> clearQueuedMessagesByStatus(String status) =>
      (delete(queuedMessageEntries)..where((q) => q.status.equals(status))).go();

  Future<int> clearExpiredQueuedMessages() =>
      (delete(queuedMessageEntries)..where((q) => q.expiresAt.isSmallerThanValue(DateTime.now()))).go();

  Future<int> getQueuedMessageCount({String? status}) {
    final query = selectOnly(queuedMessageEntries)..addColumns([queuedMessageEntries.id.count()]);
    
    if (status != null) {
      query.where(queuedMessageEntries.status.equals(status));
    }
    
    return query.map((row) => row.read(queuedMessageEntries.id.count()) ?? 0).getSingle();
  }

  Future<List<QueuedMessageEntry>> getFailedQueuedMessages({int? maxRetries}) {
    final query = select(queuedMessageEntries)..where((q) => q.status.equals('failed'));
    
    if (maxRetries != null) {
      query.where((q) => q.retryCount.isSmallerThanValue(maxRetries));
    }
    
    return query.get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'sync_database.db'));
    return NativeDatabase(file);
  });
}