import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/services/websocket_data_synchronizer.dart';
import 'package:data/websocket/interfaces/i_message_router.dart';
import 'package:data/websocket/interfaces/i_conflict_resolver.dart';
import 'package:data/websocket/database/sync_database.dart';
import 'package:data/websocket/models/websocket_message.dart';
import 'package:data/websocket/models/sync_operation.dart';

@GenerateMocks([SyncDatabase, IMessageRouter, IConflictResolver])
import 'websocket_data_synchronizer_test.mocks.dart';

void main() {
  group('WebSocketDataSynchronizer', () {
    late WebSocketDataSynchronizer synchronizer;
    late MockSyncDatabase mockDatabase;
    late MockIMessageRouter mockMessageRouter;
    late MockIConflictResolver mockConflictResolver;

    setUp(() {
      mockDatabase = MockSyncDatabase();
      mockMessageRouter = MockIMessageRouter();
      mockConflictResolver = MockIConflictResolver();
      
      synchronizer = WebSocketDataSynchronizer(
        database: mockDatabase,
        messageRouter: mockMessageRouter,
        conflictResolver: mockConflictResolver,
      );
    });

    tearDown(() {
      synchronizer.dispose();
    });

    test('should process message successfully', () async {
      // Arrange
      final message = WebSocketMessage(
        type: 'customer.updated',
        channel: 'customers',
        data: {'id': '123', 'name': 'Test Customer'},
        timestamp: DateTime.now(),
        messageId: 'msg-123',
      );

      when(mockMessageRouter.routeMessage(any)).thenAnswer((_) async {});

      // Act
      final result = await synchronizer.processMessage(message);

      // Assert
      expect(result.success, isTrue);
      expect(result.operationId, equals('msg-123'));
      verify(mockMessageRouter.routeMessage(message)).called(1);
    });

    test('should handle message processing error', () async {
      // Arrange
      final message = WebSocketMessage(
        type: 'customer.updated',
        channel: 'customers',
        data: {'id': '123', 'name': 'Test Customer'},
        timestamp: DateTime.now(),
        messageId: 'msg-123',
      );

      when(mockMessageRouter.routeMessage(any))
          .thenThrow(Exception('Routing error'));

      // Act
      final result = await synchronizer.processMessage(message);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('Routing error'));
      expect(result.operationId, equals('msg-123'));
    });

    test('should process batch of messages', () async {
      // Arrange
      final messages = [
        WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '123'},
          timestamp: DateTime.now(),
          messageId: 'msg-1',
        ),
        WebSocketMessage(
          type: 'inventory.changed',
          channel: 'inventory',
          data: {'id': '456'},
          timestamp: DateTime.now(),
          messageId: 'msg-2',
        ),
      ];

      when(mockMessageRouter.routeMessage(any)).thenAnswer((_) async {});

      // Act
      final results = await synchronizer.processBatch(messages);

      // Assert
      expect(results.length, equals(2));
      expect(results[0].success, isTrue);
      expect(results[1].success, isTrue);
      verify(mockMessageRouter.routeMessage(any)).called(2);
    });

    test('should resolve conflict successfully', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name'},
        remoteData: {'name': 'Remote Name'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      final resolvedData = {'name': 'Resolved Name'};

      when(mockConflictResolver.resolveConflict(any, any))
          .thenAnswer((_) async => resolvedData);
      when(mockDatabase.updateCustomer(any, any))
          .thenAnswer((_) async => true);

      // Act
      final result = await synchronizer.resolveConflict(conflict, 'useRemote');

      // Assert
      expect(result.success, isTrue);
      verify(mockConflictResolver.resolveConflict(conflict, any)).called(1);
      verify(mockDatabase.updateCustomer('123', any)).called(1);
    });

    test('should handle conflict resolution error', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name'},
        remoteData: {'name': 'Remote Name'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      when(mockConflictResolver.resolveConflict(any, any))
          .thenThrow(Exception('Resolution error'));

      // Act
      final result = await synchronizer.resolveConflict(conflict, 'useRemote');

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('Resolution error'));
    });

    test('should get pending operations', () async {
      // Arrange
      final dbOperations = [
        SyncOperationEntry(
          id: 1,
          operationId: 'op-1',
          operationType: 'update',
          entityType: 'customer',
          entityId: '123',
          data: '{"name": "Test"}',
          priority: 'normal',
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      ];

      when(mockDatabase.getPendingSyncOperations())
          .thenAnswer((_) async => dbOperations);

      // Act
      final operations = await synchronizer.getPendingOperations();

      // Assert
      expect(operations.length, equals(1));
      expect(operations[0].id, equals('op-1'));
      expect(operations[0].entityType, equals('customer'));
    });

    test('should clear completed operations', () async {
      // Arrange
      when(mockDatabase.clearCompletedSyncOperations())
          .thenAnswer((_) async => 5);

      // Act
      await synchronizer.clearCompletedOperations();

      // Assert
      verify(mockDatabase.clearCompletedSyncOperations()).called(1);
    });

    test('should emit sync results through stream', () async {
      // Arrange
      final message = WebSocketMessage(
        type: 'customer.updated',
        channel: 'customers',
        data: {'id': '123'},
        timestamp: DateTime.now(),
        messageId: 'msg-123',
      );

      when(mockMessageRouter.routeMessage(any)).thenAnswer((_) async {});

      SyncResult? emittedResult;
      synchronizer.syncResultStream.listen((result) {
        emittedResult = result;
      });

      // Act
      await synchronizer.processMessage(message);

      // Wait for stream emission
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(emittedResult, isNotNull);
      expect(emittedResult!.success, isTrue);
      expect(emittedResult!.operationId, equals('msg-123'));
    });

    test('should emit conflicts through stream', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name'},
        remoteData: {'name': 'Remote Name'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      DataConflict? emittedConflict;
      synchronizer.conflictStream.listen((conflict) {
        emittedConflict = conflict;
      });

      // Act
      synchronizer.conflictController.add(conflict);

      // Wait for stream emission
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(emittedConflict, isNotNull);
      expect(emittedConflict!.entityType, equals('customer'));
      expect(emittedConflict!.entityId, equals('123'));
    });
  });
}