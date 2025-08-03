import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/websocket.dart';

void main() {
  group('MissedUpdateSynchronizer - Basic Tests', () {
    late MissedUpdateSynchronizer synchronizer;
    late List<WebSocketMessage> mockUpdates;
    late List<List<WebSocketMessage>> processedBatches;
    late bool fullRefreshCalled;
    
    Future<List<WebSocketMessage>> mockFetchUpdates(DateTime from, DateTime to) async {
      await Future.delayed(const Duration(milliseconds: 50));
      return List.from(mockUpdates);
    }
    
    Future<void> mockProcessBatch(List<WebSocketMessage> batch) async {
      await Future.delayed(const Duration(milliseconds: 25));
      processedBatches.add(List.from(batch));
    }
    
    Future<void> mockFullRefresh() async {
      await Future.delayed(const Duration(milliseconds: 100));
      fullRefreshCalled = true;
    }

    setUp(() {
      mockUpdates = [];
      processedBatches = [];
      fullRefreshCalled = false;
      
      synchronizer = MissedUpdateSynchronizer(
        fetchMissedUpdates: mockFetchUpdates,
        processBatchUpdates: mockProcessBatch,
        performFullRefresh: mockFullRefresh,
      );
    });

    tearDown(() {
      synchronizer.dispose();
    });

    test('should successfully synchronize missed updates', () async {
      mockUpdates = [
        WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '1', 'name': 'John Doe'},
          timestamp: DateTime.now(),
          messageId: 'msg1',
        ),
        WebSocketMessage(
          type: 'inventory.changed',
          channel: 'inventory',
          data: {'id': '2', 'quantity': 10},
          timestamp: DateTime.now(),
          messageId: 'msg2',
        ),
      ];

      final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
      final resumeTime = DateTime.now();

      final result = await synchronizer.synchronizeMissedUpdates(
        backgroundTime: backgroundTime,
        resumeTime: resumeTime,
      );

      expect(result.isSuccess, isTrue);
      expect(result.type, SynchronizationResultType.success);
      expect(result.updatesProcessed, 2);
      expect(processedBatches, hasLength(1));
      expect(processedBatches.first, hasLength(2));
    });

    test('should handle empty updates list', () async {
      mockUpdates = [];

      final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
      final resumeTime = DateTime.now();

      final result = await synchronizer.synchronizeMissedUpdates(
        backgroundTime: backgroundTime,
        resumeTime: resumeTime,
      );

      expect(result.isSuccess, isTrue);
      expect(result.updatesProcessed, 0);
      expect(processedBatches, isEmpty);
    });

    test('should perform full refresh for long background duration', () async {
      final backgroundTime = DateTime.now().subtract(const Duration(hours: 1));
      final resumeTime = DateTime.now();

      final result = await synchronizer.synchronizeMissedUpdates(
        backgroundTime: backgroundTime,
        resumeTime: resumeTime,
      );

      expect(result.type, SynchronizationResultType.fullRefresh);
      expect(fullRefreshCalled, isTrue);
      expect(processedBatches, isEmpty);
    });

    test('should handle fetch errors', () async {
      synchronizer = MissedUpdateSynchronizer(
        fetchMissedUpdates: (from, to) => throw Exception('Network error'),
        processBatchUpdates: mockProcessBatch,
        performFullRefresh: mockFullRefresh,
      );

      final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
      final resumeTime = DateTime.now();

      final result = await synchronizer.synchronizeMissedUpdates(
        backgroundTime: backgroundTime,
        resumeTime: resumeTime,
      );

      expect(result.isError, isTrue);
      expect(result.type, SynchronizationResultType.error);
      expect(result.error, isA<Exception>());
    });

    test('should perform full data refresh successfully', () async {
      final result = await synchronizer.performFullDataRefresh();

      expect(result.type, SynchronizationResultType.fullRefresh);
      expect(result.isSuccess, isTrue);
      expect(fullRefreshCalled, isTrue);
    });

    test('should prevent concurrent synchronization', () async {
      mockUpdates = [
        WebSocketMessage(
          type: 'test.update',
          channel: 'test',
          data: {'id': '1'},
          timestamp: DateTime.now(),
        ),
      ];

      final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
      final resumeTime = DateTime.now();

      // Start first synchronization
      final future1 = synchronizer.synchronizeMissedUpdates(
        backgroundTime: backgroundTime,
        resumeTime: resumeTime,
      );

      // Try to start second synchronization immediately
      final result2 = await synchronizer.synchronizeMissedUpdates(
        backgroundTime: backgroundTime,
        resumeTime: resumeTime,
      );

      expect(result2.type, SynchronizationResultType.alreadyInProgress);

      // Wait for first to complete
      final result1 = await future1;
      expect(result1.isSuccess, isTrue);
    });

    test('should track synchronization state correctly', () {
      expect(synchronizer.isSynchronizing, isFalse);

      final future = synchronizer.performFullDataRefresh();
      expect(synchronizer.isSynchronizing, isTrue);

      return future.then((_) {
        expect(synchronizer.isSynchronizing, isFalse);
      });
    });
  });
}