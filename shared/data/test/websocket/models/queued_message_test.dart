import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/models/queued_message.dart';
import 'package:data/websocket/models/websocket_message.dart';

void main() {
  group('QueuedMessage', () {
    late WebSocketMessage testMessage;
    late DateTime testTime;

    setUp(() {
      testTime = DateTime.now();
      testMessage = WebSocketMessage(
        type: 'customer.updated',
        channel: 'customers',
        data: {'id': '123', 'name': 'Test Customer'},
        timestamp: testTime,
        messageId: 'msg-123',
      );
    });

    group('creation', () {
      test('should create QueuedMessage with required fields', () {
        // Act
        final queuedMessage = QueuedMessage(
          id: 'queued-123',
          message: testMessage,
          queuedAt: testTime,
          status: QueuedMessageStatus.pending,
        );

        // Assert
        expect(queuedMessage.id, equals('queued-123'));
        expect(queuedMessage.message, equals(testMessage));
        expect(queuedMessage.queuedAt, equals(testTime));
        expect(queuedMessage.status, equals(QueuedMessageStatus.pending));
        expect(queuedMessage.priority, equals(QueuedMessagePriority.normal)); // Default
        expect(queuedMessage.processedAt, isNull);
        expect(queuedMessage.expiresAt, isNull);
        expect(queuedMessage.error, isNull);
        expect(queuedMessage.retryCount, isNull);
        expect(queuedMessage.metadata, isNull);
      });

      test('should create QueuedMessage with all fields', () {
        // Arrange
        final processedTime = testTime.add(const Duration(minutes: 1));
        final expiresTime = testTime.add(const Duration(hours: 1));
        final metadata = {'source': 'test', 'priority': 'high'};

        // Act
        final queuedMessage = QueuedMessage(
          id: 'queued-123',
          message: testMessage,
          queuedAt: testTime,
          status: QueuedMessageStatus.completed,
          priority: QueuedMessagePriority.high,
          processedAt: processedTime,
          expiresAt: expiresTime,
          error: 'Test error',
          retryCount: 2,
          metadata: metadata,
        );

        // Assert
        expect(queuedMessage.id, equals('queued-123'));
        expect(queuedMessage.message, equals(testMessage));
        expect(queuedMessage.queuedAt, equals(testTime));
        expect(queuedMessage.status, equals(QueuedMessageStatus.completed));
        expect(queuedMessage.priority, equals(QueuedMessagePriority.high));
        expect(queuedMessage.processedAt, equals(processedTime));
        expect(queuedMessage.expiresAt, equals(expiresTime));
        expect(queuedMessage.error, equals('Test error'));
        expect(queuedMessage.retryCount, equals(2));
        expect(queuedMessage.metadata, equals(metadata));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final queuedMessage = QueuedMessage(
          id: 'queued-123',
          message: testMessage,
          queuedAt: testTime,
          status: QueuedMessageStatus.pending,
          priority: QueuedMessagePriority.high,
        );

        // Act
        final json = queuedMessage.toJson();

        // Assert
        expect(json['id'], equals('queued-123'));
        expect(json['message'], isA<Map<String, dynamic>>());
        expect(json['message']['type'], equals('customer.updated'));
        expect(json['message']['channel'], equals('customers'));
        expect(json['queuedAt'], equals(testTime.toIso8601String()));
        expect(json['status'], equals('pending'));
        expect(json['priority'], equals('high'));
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'queued-123',
          'message': testMessage.toJson(),
          'queuedAt': testTime.toIso8601String(),
          'status': 'pending',
          'priority': 'high',
        };

        // Act
        final queuedMessage = QueuedMessage.fromJson(json);

        // Assert
        expect(queuedMessage.id, equals('queued-123'));
        expect(queuedMessage.message.type, equals(testMessage.type));
        expect(queuedMessage.message.channel, equals(testMessage.channel));
        expect(queuedMessage.queuedAt, equals(testTime));
        expect(queuedMessage.status, equals(QueuedMessageStatus.pending));
        expect(queuedMessage.priority, equals(QueuedMessagePriority.high));
      });

      test('should handle null optional fields in JSON', () {
        // Arrange
        final json = {
          'id': 'queued-123',
          'message': testMessage.toJson(),
          'queuedAt': testTime.toIso8601String(),
          'status': 'pending',
          'priority': 'normal',
          'processedAt': null,
          'expiresAt': null,
          'error': null,
          'retryCount': null,
          'metadata': null,
        };

        // Act
        final queuedMessage = QueuedMessage.fromJson(json);

        // Assert
        expect(queuedMessage.processedAt, isNull);
        expect(queuedMessage.expiresAt, isNull);
        expect(queuedMessage.error, isNull);
        expect(queuedMessage.retryCount, isNull);
        expect(queuedMessage.metadata, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = QueuedMessage(
          id: 'queued-123',
          message: testMessage,
          queuedAt: testTime,
          status: QueuedMessageStatus.pending,
          priority: QueuedMessagePriority.normal,
        );

        final processedTime = testTime.add(const Duration(minutes: 1));

        // Act
        final updated = original.copyWith(
          status: QueuedMessageStatus.completed,
          processedAt: processedTime,
          error: 'Test error',
        );

        // Assert
        expect(updated.id, equals(original.id));
        expect(updated.message, equals(original.message));
        expect(updated.queuedAt, equals(original.queuedAt));
        expect(updated.priority, equals(original.priority));
        expect(updated.status, equals(QueuedMessageStatus.completed));
        expect(updated.processedAt, equals(processedTime));
        expect(updated.error, equals('Test error'));
      });
    });
  });

  group('QueuedMessageStatus', () {
    group('extensions', () {
      test('should return correct display names', () {
        expect(QueuedMessageStatus.pending.displayName, equals('Pending'));
        expect(QueuedMessageStatus.processing.displayName, equals('Processing'));
        expect(QueuedMessageStatus.completed.displayName, equals('Completed'));
        expect(QueuedMessageStatus.failed.displayName, equals('Failed'));
        expect(QueuedMessageStatus.expired.displayName, equals('Expired'));
      });

      test('should identify active statuses correctly', () {
        expect(QueuedMessageStatus.pending.isActive, isTrue);
        expect(QueuedMessageStatus.processing.isActive, isTrue);
        expect(QueuedMessageStatus.completed.isActive, isFalse);
        expect(QueuedMessageStatus.failed.isActive, isFalse);
        expect(QueuedMessageStatus.expired.isActive, isFalse);
      });

      test('should identify completed status correctly', () {
        expect(QueuedMessageStatus.pending.isCompleted, isFalse);
        expect(QueuedMessageStatus.processing.isCompleted, isFalse);
        expect(QueuedMessageStatus.completed.isCompleted, isTrue);
        expect(QueuedMessageStatus.failed.isCompleted, isFalse);
        expect(QueuedMessageStatus.expired.isCompleted, isFalse);
      });

      test('should identify failed statuses correctly', () {
        expect(QueuedMessageStatus.pending.isFailed, isFalse);
        expect(QueuedMessageStatus.processing.isFailed, isFalse);
        expect(QueuedMessageStatus.completed.isFailed, isFalse);
        expect(QueuedMessageStatus.failed.isFailed, isTrue);
        expect(QueuedMessageStatus.expired.isFailed, isTrue);
      });
    });
  });

  group('QueuedMessagePriority', () {
    group('extensions', () {
      test('should return correct display names', () {
        expect(QueuedMessagePriority.low.displayName, equals('Low'));
        expect(QueuedMessagePriority.normal.displayName, equals('Normal'));
        expect(QueuedMessagePriority.high.displayName, equals('High'));
        expect(QueuedMessagePriority.critical.displayName, equals('Critical'));
      });

      test('should return correct priority values', () {
        expect(QueuedMessagePriority.low.value, equals(1));
        expect(QueuedMessagePriority.normal.value, equals(2));
        expect(QueuedMessagePriority.high.value, equals(3));
        expect(QueuedMessagePriority.critical.value, equals(4));
      });

      test('should maintain priority ordering', () {
        final priorities = [
          QueuedMessagePriority.critical,
          QueuedMessagePriority.low,
          QueuedMessagePriority.high,
          QueuedMessagePriority.normal,
        ];

        priorities.sort((a, b) => b.value.compareTo(a.value));

        expect(priorities[0], equals(QueuedMessagePriority.critical));
        expect(priorities[1], equals(QueuedMessagePriority.high));
        expect(priorities[2], equals(QueuedMessagePriority.normal));
        expect(priorities[3], equals(QueuedMessagePriority.low));
      });
    });
  });

  group('MessageQueueConfig', () {
    test('should create with default values', () {
      // Act
      const config = MessageQueueConfig();

      // Assert
      expect(config.maxQueueSize, equals(1000));
      expect(config.messageExpiration, equals(Duration(hours: 24)));
      expect(config.maxRetryAttempts, equals(3));
      expect(config.retryDelay, equals(Duration(seconds: 30)));
      expect(config.processingTimeout, equals(Duration(minutes: 5)));
      expect(config.enablePriorityProcessing, isTrue);
      expect(config.batchSize, equals(100));
    });

    test('should create with custom values', () {
      // Act
      const config = MessageQueueConfig(
        maxQueueSize: 500,
        messageExpiration: Duration(hours: 12),
        maxRetryAttempts: 5,
        retryDelay: Duration(minutes: 1),
        processingTimeout: Duration(minutes: 10),
        enablePriorityProcessing: false,
        batchSize: 50,
      );

      // Assert
      expect(config.maxQueueSize, equals(500));
      expect(config.messageExpiration, equals(Duration(hours: 12)));
      expect(config.maxRetryAttempts, equals(5));
      expect(config.retryDelay, equals(Duration(minutes: 1)));
      expect(config.processingTimeout, equals(Duration(minutes: 10)));
      expect(config.enablePriorityProcessing, isFalse);
      expect(config.batchSize, equals(50));
    });

    test('should serialize and deserialize correctly', () {
      // Arrange
      const original = MessageQueueConfig(
        maxQueueSize: 500,
        messageExpiration: Duration(hours: 12),
        maxRetryAttempts: 5,
      );

      // Act
      final json = original.toJson();
      final deserialized = MessageQueueConfig.fromJson(json);

      // Assert
      expect(deserialized.maxQueueSize, equals(original.maxQueueSize));
      expect(deserialized.messageExpiration, equals(original.messageExpiration));
      expect(deserialized.maxRetryAttempts, equals(original.maxRetryAttempts));
    });
  });

  group('MessageQueueStats', () {
    test('should create with required fields', () {
      // Arrange
      final lastUpdated = DateTime.now();

      // Act
      final stats = MessageQueueStats(
        totalQueued: 100,
        pending: 20,
        processing: 5,
        completed: 70,
        failed: 3,
        expired: 2,
        lastUpdated: lastUpdated,
      );

      // Assert
      expect(stats.totalQueued, equals(100));
      expect(stats.pending, equals(20));
      expect(stats.processing, equals(5));
      expect(stats.completed, equals(70));
      expect(stats.failed, equals(3));
      expect(stats.expired, equals(2));
      expect(stats.lastUpdated, equals(lastUpdated));
      expect(stats.averageProcessingTime, isNull);
      expect(stats.messagesPerSecond, isNull);
    });

    test('should create with optional performance metrics', () {
      // Arrange
      final lastUpdated = DateTime.now();
      const avgProcessingTime = Duration(milliseconds: 150);

      // Act
      final stats = MessageQueueStats(
        totalQueued: 100,
        pending: 20,
        processing: 5,
        completed: 70,
        failed: 3,
        expired: 2,
        lastUpdated: lastUpdated,
        averageProcessingTime: avgProcessingTime,
        messagesPerSecond: 10,
      );

      // Assert
      expect(stats.averageProcessingTime, equals(avgProcessingTime));
      expect(stats.messagesPerSecond, equals(10));
    });

    test('should serialize and deserialize correctly', () {
      // Arrange
      final lastUpdated = DateTime.now();
      final original = MessageQueueStats(
        totalQueued: 100,
        pending: 20,
        processing: 5,
        completed: 70,
        failed: 3,
        expired: 2,
        lastUpdated: lastUpdated,
        averageProcessingTime: const Duration(milliseconds: 150),
        messagesPerSecond: 10,
      );

      // Act
      final json = original.toJson();
      final deserialized = MessageQueueStats.fromJson(json);

      // Assert
      expect(deserialized.totalQueued, equals(original.totalQueued));
      expect(deserialized.pending, equals(original.pending));
      expect(deserialized.processing, equals(original.processing));
      expect(deserialized.completed, equals(original.completed));
      expect(deserialized.failed, equals(original.failed));
      expect(deserialized.expired, equals(original.expired));
      expect(deserialized.lastUpdated, equals(original.lastUpdated));
      expect(deserialized.averageProcessingTime, equals(original.averageProcessingTime));
      expect(deserialized.messagesPerSecond, equals(original.messagesPerSecond));
    });
  });

  group('QueueProcessingResult', () {
    test('should create successful result', () {
      // Act
      const result = QueueProcessingResult(
        messageId: 'msg-123',
        success: true,
        processingTime: Duration(milliseconds: 100),
      );

      // Assert
      expect(result.messageId, equals('msg-123'));
      expect(result.success, isTrue);
      expect(result.processingTime, equals(Duration(milliseconds: 100)));
      expect(result.error, isNull);
      expect(result.metadata, isNull);
    });

    test('should create failed result with error', () {
      // Act
      const result = QueueProcessingResult(
        messageId: 'msg-123',
        success: false,
        processingTime: Duration(milliseconds: 50),
        error: 'Processing failed',
        metadata: {'retryCount': 2},
      );

      // Assert
      expect(result.messageId, equals('msg-123'));
      expect(result.success, isFalse);
      expect(result.processingTime, equals(Duration(milliseconds: 50)));
      expect(result.error, equals('Processing failed'));
      expect(result.metadata, equals({'retryCount': 2}));
    });

    test('should serialize and deserialize correctly', () {
      // Arrange
      const original = QueueProcessingResult(
        messageId: 'msg-123',
        success: false,
        processingTime: Duration(milliseconds: 50),
        error: 'Processing failed',
        metadata: {'retryCount': 2},
      );

      // Act
      final json = original.toJson();
      final deserialized = QueueProcessingResult.fromJson(json);

      // Assert
      expect(deserialized.messageId, equals(original.messageId));
      expect(deserialized.success, equals(original.success));
      expect(deserialized.processingTime, equals(original.processingTime));
      expect(deserialized.error, equals(original.error));
      expect(deserialized.metadata, equals(original.metadata));
    });
  });
}