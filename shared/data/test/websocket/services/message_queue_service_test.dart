import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:matcher/matcher.dart' as matcher;

import 'package:data/websocket/interfaces/i_websocket_data_synchronizer.dart';
import 'package:data/websocket/models/queued_message.dart';
import 'package:data/websocket/models/websocket_message.dart';
import 'package:data/websocket/models/sync_operation.dart';
import 'package:data/websocket/database/sync_database.dart';
import 'package:data/websocket/services/message_queue_service.dart';

import 'message_queue_service_test.mocks.dart';

@GenerateMocks([IWebSocketDataSynchronizer])
void main() {
  group('MessageQueueService', () {
    late SyncDatabase database;
    late MockIWebSocketDataSynchronizer mockDataSynchronizer;
    late MessageQueueService messageQueueService;

    setUp(() async {
      // Create in-memory database for testing
      database = TestSyncDatabase(NativeDatabase.memory());
      mockDataSynchronizer = MockIWebSocketDataSynchronizer();
      
      messageQueueService = MessageQueueService(
        database: database,
        dataSynchronizer: mockDataSynchronizer,
        config: const MessageQueueConfig(
          maxQueueSize: 100,
          messageExpiration: Duration(hours: 1),
          maxRetryAttempts: 3,
          batchSize: 10,
        ),
      );
    });

    tearDown(() async {
      messageQueueService.dispose();
      await database.close();
    });

    group('queueMessage', () {
      test('should queue a message successfully', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '123', 'name': 'Test Customer'},
          timestamp: DateTime.now(),
          messageId: 'msg-123',
        );

        // Act
        final messageId = await messageQueueService.queueMessage(
          message,
          priority: QueuedMessagePriority.high,
        );

        // Assert
        expect(messageId, isNotEmpty);
        
        final queuedMessage = await messageQueueService.getQueuedMessage(messageId);
        expect(queuedMessage, matcher.isNotNull);
        expect(queuedMessage!.message.type, equals('customer.updated'));
        expect(queuedMessage.priority, equals(QueuedMessagePriority.high));
        expect(queuedMessage.status, equals(QueuedMessageStatus.pending));
      });

      test('should throw error when queue is full', () async {
        // Arrange
        final config = MessageQueueConfig(maxQueueSize: 1);
        await messageQueueService.updateConfig(config);
        
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );

        // Queue first message
        await messageQueueService.queueMessage(message);

        // Act & Assert
        expect(
          () => messageQueueService.queueMessage(message),
          throwsA(isA<StateError>()),
        );
      });

      test('should set expiration time correctly', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        final customExpiration = DateTime.now().add(const Duration(hours: 2));

        // Act
        final messageId = await messageQueueService.queueMessage(
          message,
          expiresAt: customExpiration,
        );

        // Assert
        final queuedMessage = await messageQueueService.getQueuedMessage(messageId);
        expect(queuedMessage!.expiresAt, matcher.isNotNull);
        expect(
          queuedMessage.expiresAt!.difference(customExpiration).abs(),
          lessThan(const Duration(seconds: 1)),
        );
      });
    });

    group('queueBatch', () {
      test('should queue multiple messages', () async {
        // Arrange
        final messages = List.generate(5, (index) => WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {'index': index},
          timestamp: DateTime.now(),
        ));

        // Act
        final messageIds = await messageQueueService.queueBatch(
          messages,
          priority: QueuedMessagePriority.normal,
        );

        // Assert
        expect(messageIds, hasLength(5));
        
        final queuedMessages = await messageQueueService.getQueuedMessages();
        expect(queuedMessages, hasLength(5));
        
        for (int i = 0; i < 5; i++) {
          expect(queuedMessages[i].message.data['index'], equals(i));
          expect(queuedMessages[i].priority, equals(QueuedMessagePriority.normal));
        }
      });
    });

    group('processMessage', () {
      test('should process message successfully', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'customer.updated',
          channel: 'customers',
          data: {'id': '123'},
          timestamp: DateTime.now(),
        );
        
        final messageId = await messageQueueService.queueMessage(message);
        
        when(mockDataSynchronizer.processMessage(any))
            .thenAnswer((_) async => const SyncResult(
              operationId: 'test-op',
              success: true,
            ));

        // Act
        final result = await messageQueueService.processMessage(messageId);

        // Assert
        expect(result.success, isTrue);
        expect(result.messageId, equals(messageId));
        
        final queuedMessage = await messageQueueService.getQueuedMessage(messageId);
        expect(queuedMessage!.status, equals(QueuedMessageStatus.completed));
        expect(queuedMessage.processedAt, matcher.isNotNull);
        
        verify(mockDataSynchronizer.processMessage(any)).called(1);
      });

      test('should handle processing failure with retries', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        final messageId = await messageQueueService.queueMessage(message);
        
        when(mockDataSynchronizer.processMessage(any))
            .thenAnswer((_) async => const SyncResult(
              operationId: 'test-op',
              success: false,
              error: 'Processing failed',
            ));

        // Act
        final result = await messageQueueService.processMessage(messageId);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Processing failed'));
        
        final queuedMessage = await messageQueueService.getQueuedMessage(messageId);
        expect(queuedMessage!.status, equals(QueuedMessageStatus.pending)); // Reset for retry
        expect(queuedMessage.retryCount, equals(1));
        expect(queuedMessage.error, contains('Processing failed'));
      });

      test('should mark as failed after max retries', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        final messageId = await messageQueueService.queueMessage(message);
        
        when(mockDataSynchronizer.processMessage(any))
            .thenAnswer((_) async => const SyncResult(
              operationId: 'test-op',
              success: false,
              error: 'Processing failed',
            ));

        // Act - Process multiple times to exceed retry limit
        for (int i = 0; i < 4; i++) {
          await messageQueueService.processMessage(messageId);
        }

        // Assert
        final queuedMessage = await messageQueueService.getQueuedMessage(messageId);
        expect(queuedMessage!.status, equals(QueuedMessageStatus.failed));
        expect(queuedMessage.retryCount, equals(3)); // Max retries reached
      });

      test('should throw error for non-existent message', () async {
        // Act & Assert
        expect(
          () => messageQueueService.processMessage('non-existent'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('startProcessing', () {
      test('should process pending messages in batches', () async {
        // Arrange
        final messages = List.generate(15, (index) => WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {'index': index},
          timestamp: DateTime.now(),
        ));
        
        await messageQueueService.queueBatch(messages);
        
        when(mockDataSynchronizer.processMessage(any))
            .thenAnswer((_) async => const SyncResult(
              operationId: 'test-op',
              success: true,
            ));

        // Act
        final results = <QueueProcessingResult>[];
        final subscription = messageQueueService.startProcessing(batchSize: 5)
            .listen(results.add);
        
        // Wait for processing to complete
        await Future.delayed(const Duration(milliseconds: 500));
        await messageQueueService.stopProcessing();
        await subscription.cancel();

        // Assert
        expect(results, hasLength(15));
        expect(results.every((r) => r.success), isTrue);
        
        final queuedMessages = await messageQueueService.getQueuedMessages(
          status: QueuedMessageStatus.completed,
        );
        expect(queuedMessages, hasLength(15));
      });

      test('should handle processing errors gracefully', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        await messageQueueService.queueMessage(message);
        
        when(mockDataSynchronizer.processMessage(any))
            .thenThrow(Exception('Processing error'));

        // Act
        final results = <QueueProcessingResult>[];
        final subscription = messageQueueService.startProcessing()
            .listen(results.add);
        
        await Future.delayed(const Duration(milliseconds: 200));
        await messageQueueService.stopProcessing();
        await subscription.cancel();

        // Assert
        expect(results, hasLength(1));
        expect(results.first.success, isFalse);
        expect(results.first.error, contains('Processing error'));
      });

      test('should not start processing if already in progress', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        await messageQueueService.queueMessage(message);

        // Act
        final stream1 = messageQueueService.startProcessing();
        final stream2 = messageQueueService.startProcessing();

        // Assert
        expect(messageQueueService.isProcessing, isTrue);
        
        // Second stream should be empty since processing is already in progress
        final results2 = await stream2.toList();
        expect(results2, isEmpty);
        
        await messageQueueService.stopProcessing();
      });
    });

    group('getQueuedMessages', () {
      test('should filter messages by status', () async {
        // Arrange
        final messages = List.generate(3, (index) => WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {'index': index},
          timestamp: DateTime.now(),
        ));
        
        final messageIds = await messageQueueService.queueBatch(messages);
        
        // Mark one as completed
        await database.updateQueuedMessageStatus(
          messageIds[0],
          QueuedMessageStatus.completed.name,
          processedAt: DateTime.now(),
        );

        // Act
        final pendingMessages = await messageQueueService.getQueuedMessages(
          status: QueuedMessageStatus.pending,
        );
        final completedMessages = await messageQueueService.getQueuedMessages(
          status: QueuedMessageStatus.completed,
        );

        // Assert
        expect(pendingMessages, hasLength(2));
        expect(completedMessages, hasLength(1));
        expect(completedMessages.first.status, equals(QueuedMessageStatus.completed));
      });

      test('should filter messages by priority', () async {
        // Arrange
        final highPriorityMessage = WebSocketMessage(
          type: 'urgent',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        final normalPriorityMessage = WebSocketMessage(
          type: 'normal',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        await messageQueueService.queueMessage(
          highPriorityMessage,
          priority: QueuedMessagePriority.high,
        );
        await messageQueueService.queueMessage(
          normalPriorityMessage,
          priority: QueuedMessagePriority.normal,
        );

        // Act
        final highPriorityMessages = await messageQueueService.getQueuedMessages(
          priority: QueuedMessagePriority.high,
        );
        final normalPriorityMessages = await messageQueueService.getQueuedMessages(
          priority: QueuedMessagePriority.normal,
        );

        // Assert
        expect(highPriorityMessages, hasLength(1));
        expect(normalPriorityMessages, hasLength(1));
        expect(highPriorityMessages.first.message.type, equals('urgent'));
        expect(normalPriorityMessages.first.message.type, equals('normal'));
      });

      test('should limit number of returned messages', () async {
        // Arrange
        final messages = List.generate(10, (index) => WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {'index': index},
          timestamp: DateTime.now(),
        ));
        
        await messageQueueService.queueBatch(messages);

        // Act
        final limitedMessages = await messageQueueService.getQueuedMessages(limit: 5);

        // Assert
        expect(limitedMessages, hasLength(5));
      });

      test('should sort messages by priority and queue time', () async {
        // Arrange
        await Future.delayed(const Duration(milliseconds: 10));
        
        await messageQueueService.queueMessage(
          WebSocketMessage(type: 'low', channel: 'test', data: {}, timestamp: DateTime.now()),
          priority: QueuedMessagePriority.low,
        );
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        await messageQueueService.queueMessage(
          WebSocketMessage(type: 'high', channel: 'test', data: {}, timestamp: DateTime.now()),
          priority: QueuedMessagePriority.high,
        );
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        await messageQueueService.queueMessage(
          WebSocketMessage(type: 'critical', channel: 'test', data: {}, timestamp: DateTime.now()),
          priority: QueuedMessagePriority.critical,
        );

        // Act
        final sortedMessages = await messageQueueService.getQueuedMessages();

        // Assert
        expect(sortedMessages, hasLength(3));
        expect(sortedMessages[0].message.type, equals('critical')); // Highest priority first
        expect(sortedMessages[1].message.type, equals('high'));
        expect(sortedMessages[2].message.type, equals('low'));
      });
    });

    group('clearMessages', () {
      test('should clear completed messages', () async {
        // Arrange
        final messages = List.generate(3, (index) => WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {'index': index},
          timestamp: DateTime.now(),
        ));
        
        final messageIds = await messageQueueService.queueBatch(messages);
        
        // Mark some as completed
        await database.updateQueuedMessageStatus(
          messageIds[0],
          QueuedMessageStatus.completed.name,
          processedAt: DateTime.now(),
        );
        await database.updateQueuedMessageStatus(
          messageIds[1],
          QueuedMessageStatus.completed.name,
          processedAt: DateTime.now(),
        );

        // Act
        final clearedCount = await messageQueueService.clearMessages(
          status: QueuedMessageStatus.completed,
        );

        // Assert
        expect(clearedCount, equals(2));
        
        final remainingMessages = await messageQueueService.getQueuedMessages();
        expect(remainingMessages, hasLength(1));
        expect(remainingMessages.first.status, equals(QueuedMessageStatus.pending));
      });
    });

    group('clearExpiredMessages', () {
      test('should clear expired messages', () async {
        // Arrange
        final expiredMessage = WebSocketMessage(
          type: 'expired',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        final validMessage = WebSocketMessage(
          type: 'valid',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        // Queue expired message
        await messageQueueService.queueMessage(
          expiredMessage,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        
        // Queue valid message
        await messageQueueService.queueMessage(
          validMessage,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        // Act
        final clearedCount = await messageQueueService.clearExpiredMessages();

        // Assert
        expect(clearedCount, equals(1));
        
        final remainingMessages = await messageQueueService.getQueuedMessages();
        expect(remainingMessages, hasLength(1));
        expect(remainingMessages.first.message.type, equals('valid'));
      });
    });

    group('retryFailedMessages', () {
      test('should retry failed messages', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        final messageId = await messageQueueService.queueMessage(message);
        
        // Mark as failed
        await database.updateQueuedMessageStatus(
          messageId,
          QueuedMessageStatus.failed.name,
          error: 'Test failure',
        );

        // Act
        final retriedCount = await messageQueueService.retryFailedMessages();

        // Assert
        expect(retriedCount, equals(1));
        
        final queuedMessage = await messageQueueService.getQueuedMessage(messageId);
        expect(queuedMessage!.status, equals(QueuedMessageStatus.pending));
      });
    });

    group('prioritizeMessage', () {
      test('should update message priority', () async {
        // Arrange
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        final messageId = await messageQueueService.queueMessage(
          message,
          priority: QueuedMessagePriority.normal,
        );

        // Act
        final result = await messageQueueService.prioritizeMessage(
          messageId,
          QueuedMessagePriority.critical,
        );

        // Assert
        expect(result, isTrue);
        
        final queuedMessage = await messageQueueService.getQueuedMessage(messageId);
        expect(queuedMessage!.priority, equals(QueuedMessagePriority.critical));
      });
    });

    group('getQueueHealth', () {
      test('should return queue health information', () async {
        // Arrange
        final messages = List.generate(10, (index) => WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {'index': index},
          timestamp: DateTime.now(),
        ));
        
        await messageQueueService.queueBatch(messages);

        // Act
        final health = await messageQueueService.getQueueHealth();

        // Assert
        expect(health['queueSize'], equals(10));
        expect(health['isHealthy'], isA<bool>());
        expect(health['processingRate'], isA<num>());
        expect(health['failureRate'], isA<num>());
        expect(health['isProcessing'], equals(messageQueueService.isProcessing));
        expect(health['lastUpdated'], isA<DateTime>());
      });
    });

    group('queue size management', () {
      test('should track queue size correctly', () async {
        // Arrange
        expect(await messageQueueService.getQueueSize(), equals(0));
        expect(await messageQueueService.isQueueFull(), isFalse);

        // Act
        final message = WebSocketMessage(
          type: 'test',
          channel: 'test',
          data: {},
          timestamp: DateTime.now(),
        );
        
        await messageQueueService.queueMessage(message);

        // Assert
        expect(await messageQueueService.getQueueSize(), equals(1));
        expect(await messageQueueService.isQueueFull(), isFalse);
      });
    });

    group('configuration management', () {
      test('should update configuration', () async {
        // Arrange
        final newConfig = MessageQueueConfig(
          maxQueueSize: 200,
          messageExpiration: const Duration(hours: 2),
          maxRetryAttempts: 5,
        );

        // Act
        await messageQueueService.updateConfig(newConfig);

        // Assert
        expect(messageQueueService.config.maxQueueSize, equals(200));
        expect(messageQueueService.config.messageExpiration, equals(const Duration(hours: 2)));
        expect(messageQueueService.config.maxRetryAttempts, equals(5));
      });
    });
  });
}

extension SyncDatabaseTesting on SyncDatabase {
  static SyncDatabase forTesting(QueryExecutor executor) {
    return TestSyncDatabase(executor);
  }
}

class TestSyncDatabase extends _$SyncDatabase {
  TestSyncDatabase(QueryExecutor executor) : super(executor);
  
  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );
}