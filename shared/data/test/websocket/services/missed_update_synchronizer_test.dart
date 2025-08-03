import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/websocket.dart';

void main() {
  group('MissedUpdateSynchronizer', () {
    late MissedUpdateSynchronizer synchronizer;
    late List<WebSocketMessage> mockUpdates;
    late List<List<WebSocketMessage>> processedBatches;
    late bool fullRefreshCalled;
    
    Future<List<WebSocketMessage>> mockFetchUpdates(DateTime from, DateTime to) async {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return List.from(mockUpdates);
    }
    
    Future<void> mockProcessBatch(List<WebSocketMessage> batch) async {
      await Future.delayed(const Duration(milliseconds: 50)); // Simulate processing delay
      processedBatches.add(List.from(batch));
    }
    
    Future<void> mockFullRefresh() async {
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate refresh delay
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

    group('Synchronization', () {
      test('should successfully synchronize missed updates', () async {
        // Setup mock data
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
        expect(result.backgroundDuration, isNotNull);
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

      test('should process updates in batches', () async {
        // Create more updates than batch size
        mockUpdates = List.generate(250, (index) => WebSocketMessage(
          type: 'test.update',
          channel: 'test',
          data: {'index': index},
          timestamp: DateTime.now(),
          messageId: 'msg$index',
        ));

        final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
        final resumeTime = DateTime.now();

        final result = await synchronizer.synchronizeMissedUpdates(
          backgroundTime: backgroundTime,
          resumeTime: resumeTime,
        );

        expect(result.isSuccess, isTrue);
        expect(result.updatesProcessed, 250);
        expect(processedBatches.length, 3); // 100, 100, 50
        expect(processedBatches[0], hasLength(100));
        expect(processedBatches[1], hasLength(100));
        expect(processedBatches[2], hasLength(50));
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

      test('should emit synchronization events', () async {
        final events = <SynchronizationEvent>[];
        synchronizer.synchronizationEvents.listen(events.add);

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

        await synchronizer.synchronizeMissedUpdates(
          backgroundTime: backgroundTime,
          resumeTime: resumeTime,
        );

        expect(events.length, greaterThanOrEqualTo(2)); // started, completed (batchProcessing might not be emitted for single item)
        expect(events.first.type, SynchronizationEventType.started);
        expect(events.last.type, SynchronizationEventType.completed);
      });
    });

    group('Error Handling', () {
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

      test('should handle processing errors', () async {
        mockUpdates = [
          WebSocketMessage(
            type: 'test.update',
            channel: 'test',
            data: {'id': '1'},
            timestamp: DateTime.now(),
          ),
        ];

        synchronizer = MissedUpdateSynchronizer(
          fetchMissedUpdates: mockFetchUpdates,
          processBatchUpdates: (batch) => throw Exception('Processing error'),
          performFullRefresh: mockFullRefresh,
        );

        final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
        final resumeTime = DateTime.now();

        final result = await synchronizer.synchronizeMissedUpdates(
          backgroundTime: backgroundTime,
          resumeTime: resumeTime,
        );

        expect(result.isError, isTrue);
        expect(result.error, isA<Exception>());
      });

      test('should handle timeout errors', () async {
        synchronizer = MissedUpdateSynchronizer(
          fetchMissedUpdates: (from, to) async {
            await Future.delayed(const Duration(seconds: 6)); // Longer than timeout (5 minutes in real, but we'll make it shorter for test)
            return [];
          },
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
        expect(result.error, isA<TimeoutException>());
      }, timeout: const Timeout(Duration(seconds: 10)));

      test('should emit error events', () async {
        synchronizer = MissedUpdateSynchronizer(
          fetchMissedUpdates: (from, to) => throw Exception('Test error'),
          processBatchUpdates: mockProcessBatch,
          performFullRefresh: mockFullRefresh,
        );

        final events = <SynchronizationEvent>[];
        synchronizer.synchronizationEvents.listen(events.add);

        final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
        final resumeTime = DateTime.now();

        await synchronizer.synchronizeMissedUpdates(
          backgroundTime: backgroundTime,
          resumeTime: resumeTime,
        );

        expect(events.any((e) => e.type == SynchronizationEventType.failed), isTrue);
      });
    });

    group('Full Data Refresh', () {
      test('should perform full data refresh successfully', () async {
        final result = await synchronizer.performFullDataRefresh();

        expect(result.type, SynchronizationResultType.fullRefresh);
        expect(result.isSuccess, isTrue);
        expect(fullRefreshCalled, isTrue);
      });

      test('should handle full refresh errors', () async {
        synchronizer = MissedUpdateSynchronizer(
          fetchMissedUpdates: mockFetchUpdates,
          processBatchUpdates: mockProcessBatch,
          performFullRefresh: () => throw Exception('Refresh error'),
        );

        final result = await synchronizer.performFullDataRefresh();

        expect(result.isError, isTrue);
        expect(result.error, isA<Exception>());
      });

      test('should emit full refresh events', () async {
        final events = <SynchronizationEvent>[];
        synchronizer.synchronizationEvents.listen(events.add);

        await synchronizer.performFullDataRefresh();

        // Wait a bit for events to be processed
        await Future.delayed(const Duration(milliseconds: 50));

        expect(events.any((e) => e.type == SynchronizationEventType.fullRefreshStarted), isTrue);
        expect(events.any((e) => e.type == SynchronizationEventType.completed), isTrue);
      });
    });

    group('Concurrent Operations', () {
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

      test('should prevent concurrent full refresh', () async {
        // Start first refresh
        final future1 = synchronizer.performFullDataRefresh();

        // Try to start second refresh immediately
        final result2 = await synchronizer.performFullDataRefresh();

        expect(result2.type, SynchronizationResultType.alreadyInProgress);

        // Wait for first to complete
        final result1 = await future1;
        expect(result1.isSuccess, isTrue);
      });
    });

    group('State Management', () {
      test('should track synchronization state correctly', () {
        expect(synchronizer.isSynchronizing, isFalse);

        final future = synchronizer.performFullDataRefresh();
        expect(synchronizer.isSynchronizing, isTrue);

        return future.then((_) {
          expect(synchronizer.isSynchronizing, isFalse);
        });
      });
    });

    group('Disposal', () {
      test('should close streams on disposal', () async {
        bool streamClosed = false;
        synchronizer.synchronizationEvents.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        synchronizer.dispose();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(streamClosed, isTrue);
      });
    });
  });
}