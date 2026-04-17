import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:data/websocket/interfaces/i_message_queue_service.dart';
import 'package:data/websocket/interfaces/i_websocket_data_synchronizer.dart';
import 'package:data/websocket/models/queued_message.dart';
import 'package:data/websocket/models/websocket_message.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/models/sync_operation.dart';
import 'package:data/websocket/services/offline_sync_service.dart';
import 'package:data/websocket/services/missed_update_synchronizer.dart';

import 'offline_sync_service_test.mocks.dart';

@GenerateMocks([
  IMessageQueueService,
  IWebSocketDataSynchronizer,
  MissedUpdateSynchronizer,
])
void main() {
  group('OfflineSyncService', () {
    late MockIMessageQueueService mockMessageQueueService;
    late MockIWebSocketDataSynchronizer mockDataSynchronizer;
    late MockMissedUpdateSynchronizer mockMissedUpdateSynchronizer;
    late OfflineSyncService offlineSyncService;
    late StreamController<QueueProcessingResult> processingResultController;

    setUp(() {
      mockMessageQueueService = MockIMessageQueueService();
      mockDataSynchronizer = MockIWebSocketDataSynchronizer();
      mockMissedUpdateSynchronizer = MockMissedUpdateSynchronizer();
      processingResultController = StreamController<QueueProcessingResult>.broadcast();

      // Setup default mock behaviors
      when(mockMessageQueueService.processingResults)
          .thenAnswer((_) => processingResultController.stream);
      when(mockMessageQueueService.stats)
          .thenReturn(const MessageQueueStats(
            totalQueued: 0,
            pending: 0,
            processing: 0,
            completed: 0,
            failed: 0,
            expired: 0,
            lastUpdated: null,
          ));

      offlineSyncService = OfflineSyncService(
        messageQueueService: mockMessageQueueService,
        dataSynchronizer: mockDataSynchronizer,
        missedUpdateSynchronizer: mockMissedUpdateSynchronizer,
      );
    });

    tearDown(() {
      processingResultController.close();
      offlineSyncService.dispose();
    });

    group('connection state handling', () {
      test('should handle online transition', () async {
        // Arrange
        final syncEvents = <OfflineSyncEvent>[];
        final subscription = offlineSyncService.syncEvents.listen(syncEvents.add);

        when(mockMissedUpdateSynchronizer.synchronizeMissedUpdates(
          backgroundTime: any,
          resumeTime: any,
        )).thenAnswer((_) async => SynchronizationResult.success(
          updatesProcessed: 5,
          duration: const Duration(seconds: 1),
          backgroundDuration: const Duration(minutes: 5),
        ));

        when(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending))
            .thenAnswer((_) async => []);

        // Act
        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.disconnected);
        await Future.delayed(const Duration(milliseconds: 10));
        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.connected);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(offlineSyncService.isOnline, isTrue);
        expect(offlineSyncService.offlineStartTime, isNull);
        
        final offlineEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.offlineTransition);
        final onlineEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.onlineTransition);
        
        expect(offlineEvents, hasLength(1));
        expect(onlineEvents, hasLength(1));

        await subscription.cancel();
      });

      test('should handle offline transition', () async {
        // Arrange
        final syncEvents = <OfflineSyncEvent>[];
        final subscription = offlineSyncService.syncEvents.listen(syncEvents.add);

        when(mockMessageQueueService.stopProcessing())
            .thenAnswer((_) async {});

        // Act
        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.disconnected);

        // Assert
        expect(offlineSyncService.isOnline, isFalse);
        expect(offlineSyncService.offlineStartTime, isNotNull);
        expect(offlineSyncService.offlineDuration, isNotNull);

        final offlineEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.offlineTransition);
        expect(offlineEvents, hasLength(1));

        verify(mockMessageQueueService.stopProcessing()).called(1);

        await subscription.cancel();
      });

      test('should calculate offline duration correctly', () async {
        // Arrange
        when(mockMessageQueueService.stopProcessing())
            .thenAnswer((_) async {});

        // Act
        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.disconnected);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final duration = offlineSyncService.offlineDuration;
        expect(duration, isNotNull);
        expect(duration!.inMilliseconds, greaterThanOrEqualTo(100));
      });
    });

    group('message queuing', () {
      test('should process message immediately when online', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '123'},
          timestamp: DateTime.now(),
        );

        when(mockDataSynchronizer.processMessage(any))
            .thenAnswer((_) async => const SyncResult(
              operationId: 'test-op',
              success: true,
            ));

        // Act
        final messageId = await offlineSyncService.queueMessageForOfflineProcessing(message);

        // Assert
        expect(messageId, startsWith('immediate_'));
        verify(mockDataSynchronizer.processMessage(any)).called(1);
        verifyNever(mockMessageQueueService.queueMessage(any));
      });

      test('should queue message when processing fails while online', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '123'},
          timestamp: DateTime.now(),
        );

        when(mockDataSynchronizer.processMessage(any))
            .thenAnswer((_) async => const SyncResult(
              operationId: 'test-op',
              success: false,
              error: 'Processing failed',
            ));

        when(mockMessageQueueService.queueMessage(
          any,
          priority: anyNamed('priority'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => 'queued-123');

        // Act
        final messageId = await offlineSyncService.queueMessageForOfflineProcessing(message);

        // Assert
        expect(messageId, equals('queued-123'));
        verify(mockDataSynchronizer.processMessage(any)).called(1);
        verify(mockMessageQueueService.queueMessage(
          any,
          priority: anyNamed('priority'),
          metadata: anyNamed('metadata'),
        )).called(1);
      });

      test('should queue message when offline', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '123'},
          timestamp: DateTime.now(),
        );

        when(mockMessageQueueService.stopProcessing())
            .thenAnswer((_) async {});
        when(mockMessageQueueService.queueMessage(
          any,
          priority: anyNamed('priority'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => 'queued-123');

        // Go offline first
        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.disconnected);

        // Act
        final messageId = await offlineSyncService.queueMessageForOfflineProcessing(message);

        // Assert
        expect(messageId, equals('queued-123'));
        verifyNever(mockDataSynchronizer.processMessage(any));
        verify(mockMessageQueueService.queueMessage(
          any,
          priority: anyNamed('priority'),
          metadata: anyNamed('metadata'),
        )).called(1);
      });

      test('should emit message queued event', () async {
        // Arrange
        final syncEvents = <OfflineSyncEvent>[];
        final subscription = offlineSyncService.syncEvents.listen(syncEvents.add);

        final message = WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '123'},
          timestamp: DateTime.now(),
        );

        when(mockDataSynchronizer.processMessage(any))
            .thenAnswer((_) async => const SyncResult(
              operationId: 'test-op',
              success: false,
            ));

        when(mockMessageQueueService.queueMessage(
          any,
          priority: anyNamed('priority'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => 'queued-123');

        // Act
        await offlineSyncService.queueMessageForOfflineProcessing(message);

        // Assert
        final queuedEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.messageQueued);
        expect(queuedEvents, hasLength(1));
        expect(queuedEvents.first.data['messageId'], equals('queued-123'));
        expect(queuedEvents.first.data['messageType'], equals('customer.updated'));

        await subscription.cancel();
      });
    });

    group('queue processing', () {
      test('should process queued messages successfully', () async {
        // Arrange
        final pendingMessages = [
          QueuedMessage(
            id: 'msg-1',
            message: WebSocketMessage(
              type: 'test',
              channel: 'test',
              data: {},
              timestamp: DateTime.now(),
            ),
            queuedAt: DateTime.now(),
            status: QueuedMessageStatus.pending,
          ),
          QueuedMessage(
            id: 'msg-2',
            message: WebSocketMessage(
              type: 'test',
              channel: 'test',
              data: {},
              timestamp: DateTime.now(),
            ),
            queuedAt: DateTime.now(),
            status: QueuedMessageStatus.pending,
          ),
        ];

        when(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending))
            .thenAnswer((_) async => pendingMessages);

        final processingResults = [
          QueueProcessingResult(
            messageId: 'msg-1',
            success: true,
            processingTime: const Duration(milliseconds: 100),
          ),
          QueueProcessingResult(
            messageId: 'msg-2',
            success: true,
            processingTime: const Duration(milliseconds: 150),
          ),
        ];

        when(mockMessageQueueService.startProcessing())
            .thenAnswer((_) => Stream.fromIterable(processingResults));

        // Act
        final result = await offlineSyncService.processQueuedMessages();

        // Assert
        expect(result.success, isTrue);
        expect(result.messagesProcessed, equals(2));
        expect(result.failureCount, equals(0));

        verify(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending)).called(1);
        verify(mockMessageQueueService.startProcessing()).called(1);
      });

      test('should handle processing failures', () async {
        // Arrange
        final pendingMessages = [
          QueuedMessage(
            id: 'msg-1',
            message: WebSocketMessage(
              type: 'test',
              channel: 'test',
              data: {},
              timestamp: DateTime.now(),
            ),
            queuedAt: DateTime.now(),
            status: QueuedMessageStatus.pending,
          ),
        ];

        when(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending))
            .thenAnswer((_) async => pendingMessages);

        final processingResults = [
          QueueProcessingResult(
            messageId: 'msg-1',
            success: false,
            processingTime: const Duration(milliseconds: 100),
            error: 'Processing failed',
          ),
        ];

        when(mockMessageQueueService.startProcessing())
            .thenAnswer((_) => Stream.fromIterable(processingResults));

        // Act
        final result = await offlineSyncService.processQueuedMessages();

        // Assert
        expect(result.success, isTrue); // Overall success even with failures
        expect(result.messagesProcessed, equals(0));
        expect(result.failureCount, equals(1));
        expect(result.errors, contains('Processing failed'));
      });

      test('should handle empty queue', () async {
        // Arrange
        when(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending))
            .thenAnswer((_) async => []);

        // Act
        final result = await offlineSyncService.processQueuedMessages();

        // Assert
        expect(result.success, isTrue);
        expect(result.messagesProcessed, equals(0));
        expect(result.failureCount, isNull);

        verify(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending)).called(1);
        verifyNever(mockMessageQueueService.startProcessing());
      });

      test('should emit processing events', () async {
        // Arrange
        final syncEvents = <OfflineSyncEvent>[];
        final subscription = offlineSyncService.syncEvents.listen(syncEvents.add);

        when(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending))
            .thenAnswer((_) async => []);

        // Act
        await offlineSyncService.processQueuedMessages();

        // Assert
        final startedEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.queueProcessingStarted);
        final completedEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.queueProcessingCompleted);

        expect(startedEvents, hasLength(1));
        expect(completedEvents, hasLength(1));

        await subscription.cancel();
      });
    });

    group('comprehensive sync', () {
      test('should perform comprehensive sync successfully', () async {
        // Arrange
        when(mockMessageQueueService.stopProcessing())
            .thenAnswer((_) async {});

        // Go offline first
        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.disconnected);
        await Future.delayed(const Duration(milliseconds: 10));

        // Setup mocks for comprehensive sync
        when(mockMissedUpdateSynchronizer.synchronizeMissedUpdates(
          backgroundTime: any,
          resumeTime: any,
        )).thenAnswer((_) async => SynchronizationResult.success(
          updatesProcessed: 3,
          duration: const Duration(seconds: 1),
          backgroundDuration: const Duration(minutes: 2),
        ));

        when(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending))
            .thenAnswer((_) async => []);

        // Act
        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.connected);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(offlineSyncService.isOnline, isTrue);
        verify(mockMissedUpdateSynchronizer.synchronizeMissedUpdates(
          backgroundTime: any,
          resumeTime: any,
        )).called(1);
      });

      test('should throw error when performing comprehensive sync while offline', () async {
        // Arrange
        when(mockMessageQueueService.stopProcessing())
            .thenAnswer((_) async {});

        await offlineSyncService.handleConnectionStateChange(WebSocketConnectionState.disconnected);

        // Act & Assert
        expect(
          () => offlineSyncService.performComprehensiveSync(),
          throwsA(isA<StateError>()),
        );
      });

      test('should emit comprehensive sync events', () async {
        // Arrange
        final syncEvents = <OfflineSyncEvent>[];
        final subscription = offlineSyncService.syncEvents.listen(syncEvents.add);

        when(mockMissedUpdateSynchronizer.synchronizeMissedUpdates(
          backgroundTime: any,
          resumeTime: any,
        )).thenAnswer((_) async => SynchronizationResult.success(
          updatesProcessed: 0,
          duration: const Duration(seconds: 1),
          backgroundDuration: const Duration(minutes: 1),
        ));

        when(mockMessageQueueService.getQueuedMessages(status: QueuedMessageStatus.pending))
            .thenAnswer((_) async => []);

        // Act
        await offlineSyncService.performComprehensiveSync();

        // Assert
        final startedEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.comprehensiveSyncStarted);
        final completedEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.comprehensiveSyncCompleted);

        expect(startedEvents, hasLength(1));
        expect(completedEvents, hasLength(1));

        await subscription.cancel();
      });
    });

    group('utility methods', () {
      test('should clear completed messages', () async {
        // Arrange
        when(mockMessageQueueService.clearMessages(status: QueuedMessageStatus.completed))
            .thenAnswer((_) async => 5);

        // Act
        final clearedCount = await offlineSyncService.clearCompletedMessages();

        // Assert
        expect(clearedCount, equals(5));
        verify(mockMessageQueueService.clearMessages(status: QueuedMessageStatus.completed)).called(1);
      });

      test('should get queue stats', () async {
        // Arrange
        const expectedStats = MessageQueueStats(
          totalQueued: 10,
          pending: 3,
          processing: 1,
          completed: 5,
          failed: 1,
          expired: 0,
          lastUpdated: null,
        );

        when(mockMessageQueueService.stats).thenReturn(expectedStats);

        // Act
        final stats = await offlineSyncService.getQueueStats();

        // Assert
        expect(stats, equals(expectedStats));
      });

      test('should retry failed messages', () async {
        // Arrange
        when(mockMessageQueueService.retryFailedMessages())
            .thenAnswer((_) async => 3);

        // Act
        final retriedCount = await offlineSyncService.retryFailedMessages();

        // Assert
        expect(retriedCount, equals(3));
        verify(mockMessageQueueService.retryFailedMessages()).called(1);
      });
    });

    group('event handling', () {
      test('should handle queue processing results', () async {
        // Arrange
        final syncEvents = <OfflineSyncEvent>[];
        final subscription = offlineSyncService.syncEvents.listen(syncEvents.add);

        // Act
        processingResultController.add(QueueProcessingResult(
          messageId: 'test-msg',
          success: true,
          processingTime: const Duration(milliseconds: 100),
        ));

        processingResultController.add(QueueProcessingResult(
          messageId: 'test-msg-2',
          success: false,
          processingTime: const Duration(milliseconds: 50),
          error: 'Processing failed',
        ));

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - Events are handled internally, no specific events emitted for individual results
        // But we can verify the service is listening to the stream
        expect(syncEvents, isNotEmpty);

        await subscription.cancel();
      });

      test('should handle queue processing errors', () async {
        // Arrange
        final syncEvents = <OfflineSyncEvent>[];
        final subscription = offlineSyncService.syncEvents.listen(syncEvents.add);

        // Act
        processingResultController.addError('Queue processing error');
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        final errorEvents = syncEvents.where((e) => e.type == OfflineSyncEventType.error);
        expect(errorEvents, hasLength(1));
        expect(errorEvents.first.data['error'], contains('Queue processing error'));

        await subscription.cancel();
      });
    });
  });
}