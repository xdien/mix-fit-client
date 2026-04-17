import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../interfaces/i_message_queue_service.dart';
import '../interfaces/i_websocket_data_synchronizer.dart';
import '../models/websocket_message.dart';
import '../database/sync_database.dart';
import '../models/queued_message.dart';

/// Implementation of WebSocket message queue service
/// 
/// This service handles queuing of WebSocket messages during disconnection periods,
/// manages offline message storage, and processes queued messages on reconnection.
class MessageQueueService implements IMessageQueueService {
  final SyncDatabase _database;
  final IWebSocketDataSynchronizer _dataSynchronizer;
  final Uuid _uuid = const Uuid();
  
  MessageQueueConfig _config;
  bool _isProcessing = false;
  Timer? _processingTimer;
  Timer? _cleanupTimer;
  
  final StreamController<QueueProcessingResult> _processingResultController =
      StreamController<QueueProcessingResult>.broadcast();
  final StreamController<MessageQueueStats> _statsController =
      StreamController<MessageQueueStats>.broadcast();

  MessageQueueService({
    required SyncDatabase database,
    required IWebSocketDataSynchronizer dataSynchronizer,
    MessageQueueConfig? config,
  }) : _database = database,
       _dataSynchronizer = dataSynchronizer,
       _config = config ?? const MessageQueueConfig() {
    _initializeService();
  }

  @override
  Stream<QueueProcessingResult> get processingResults => _processingResultController.stream;

  @override
  Stream<MessageQueueStats> get queueStats => _statsController.stream;

  @override
  bool get isProcessing => _isProcessing;

  @override
  MessageQueueConfig get config => _config;

  @override
  MessageQueueStats get stats => _currentStats;

  MessageQueueStats _currentStats = MessageQueueStats(
    totalQueued: 0,
    pending: 0,
    processing: 0,
    completed: 0,
    failed: 0,
    expired: 0,
    lastUpdated: DateTime.now(),
  );

  void _initializeService() {
    developer.log('Initializing MessageQueueService', name: 'MessageQueueService');
    
    // Start periodic cleanup of expired messages
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredMessages();
    });
    
    // Update stats periodically
    Timer.periodic(const Duration(seconds: 30), (_) {
      _updateStats();
    });
    
    // Initial stats update
    _updateStats();
  }

  @override
  Future<String> queueMessage(
    WebSocketMessage message, {
    QueuedMessagePriority priority = QueuedMessagePriority.normal,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    developer.log('Queuing message: ${message.type}', name: 'MessageQueueService');
    
    // Check if queue is full
    if (await isQueueFull()) {
      throw StateError('Message queue is full');
    }
    
    final messageId = _uuid.v4();
    final queuedMessage = QueuedMessageEntriesCompanion(
      messageId: Value(messageId),
      messageType: Value(message.type),
      channel: Value(message.channel),
      messageData: Value(jsonEncode(message.toJson())),
      status: Value(QueuedMessageStatus.pending.name),
      priority: Value(priority.name),
      queuedAt: Value(DateTime.now()),
      expiresAt: Value(expiresAt ?? DateTime.now().add(_config.messageExpiration)),
      metadata: Value(metadata != null ? jsonEncode(metadata) : null),
    );
    
    await _database.insertQueuedMessage(queuedMessage);
    
    developer.log('Message queued with ID: $messageId', name: 'MessageQueueService');
    _updateStats();
    
    return messageId;
  }

  @override
  Future<List<String>> queueBatch(
    List<WebSocketMessage> messages, {
    QueuedMessagePriority priority = QueuedMessagePriority.normal,
    DateTime? expiresAt,
  }) async {
    developer.log('Queuing batch of ${messages.length} messages', name: 'MessageQueueService');
    
    final messageIds = <String>[];
    
    for (final message in messages) {
      try {
        final messageId = await queueMessage(
          message,
          priority: priority,
          expiresAt: expiresAt,
        );
        messageIds.add(messageId);
      } catch (error) {
        developer.log('Error queuing message in batch: $error', name: 'MessageQueueService');
        // Continue with other messages
      }
    }
    
    developer.log('Queued ${messageIds.length}/${messages.length} messages in batch', name: 'MessageQueueService');
    return messageIds;
  }

  @override
  Stream<QueueProcessingResult> startProcessing({int? batchSize}) async* {
    if (_isProcessing) {
      developer.log('Processing already in progress', name: 'MessageQueueService');
      return;
    }
    
    _isProcessing = true;
    final effectiveBatchSize = batchSize ?? _config.batchSize;
    
    developer.log('Starting message queue processing with batch size: $effectiveBatchSize', name: 'MessageQueueService');
    
    try {
      while (_isProcessing) {
        final pendingMessages = await _database.getPendingQueuedMessages(limit: effectiveBatchSize);
        
        if (pendingMessages.isEmpty) {
          // No messages to process, wait a bit
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        developer.log('Processing batch of ${pendingMessages.length} messages', name: 'MessageQueueService');
        
        for (final queuedMessage in pendingMessages) {
          if (!_isProcessing) break;
          
          try {
            final result = await _processQueuedMessage(queuedMessage);
            yield result;
            _processingResultController.add(result);
          } catch (error) {
            developer.log('Error processing queued message ${queuedMessage.messageId}: $error', name: 'MessageQueueService');
            
            final result = QueueProcessingResult(
              messageId: queuedMessage.messageId,
              success: false,
              processingTime: Duration.zero,
              error: error.toString(),
            );
            
            yield result;
            _processingResultController.add(result);
          }
        }
        
        _updateStats();
        
        // Small delay between batches
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isProcessing = false;
      developer.log('Message queue processing stopped', name: 'MessageQueueService');
    }
  }

  @override
  Future<void> stopProcessing() async {
    developer.log('Stopping message queue processing', name: 'MessageQueueService');
    _isProcessing = false;
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  @override
  Future<QueueProcessingResult> processMessage(String messageId) async {
    developer.log('Processing specific message: $messageId', name: 'MessageQueueService');
    
    final queuedMessage = await _database.getQueuedMessageById(messageId);
    if (queuedMessage == null) {
      throw ArgumentError('Message not found: $messageId');
    }
    
    return await _processQueuedMessage(queuedMessage);
  }

  Future<QueueProcessingResult> _processQueuedMessage(QueuedMessageEntry queuedMessage) async {
    final startTime = DateTime.now();
    
    try {
      // Mark as processing
      await _database.updateQueuedMessageStatus(
        queuedMessage.messageId,
        QueuedMessageStatus.processing.name,
      );
      
      // Parse the WebSocket message
      final messageData = jsonDecode(queuedMessage.messageData) as Map<String, dynamic>;
      final websocketMessage = WebSocketMessage.fromJson(messageData);
      
      // Process the message through the data synchronizer
      final syncResult = await _dataSynchronizer.processMessage(websocketMessage)
          .timeout(_config.processingTimeout);
      
      final processingTime = DateTime.now().difference(startTime);
      
      if (syncResult.success) {
        // Mark as completed
        await _database.updateQueuedMessageStatus(
          queuedMessage.messageId,
          QueuedMessageStatus.completed.name,
          processedAt: DateTime.now(),
        );
        
        developer.log('Successfully processed queued message: ${queuedMessage.messageId}', name: 'MessageQueueService');
        
        return QueueProcessingResult(
          messageId: queuedMessage.messageId,
          success: true,
          processingTime: processingTime,
        );
      } else {
        // Handle failure
        return await _handleProcessingFailure(queuedMessage, syncResult.error, processingTime);
      }
      
    } catch (error) {
      final processingTime = DateTime.now().difference(startTime);
      return await _handleProcessingFailure(queuedMessage, error.toString(), processingTime);
    }
  }

  Future<QueueProcessingResult> _handleProcessingFailure(
    QueuedMessageEntry queuedMessage,
    String? error,
    Duration processingTime,
  ) async {
    developer.log('Processing failed for message ${queuedMessage.messageId}: $error', name: 'MessageQueueService');
    
    // Increment retry count
    await _database.incrementRetryCount(queuedMessage.messageId);
    
    final updatedMessage = await _database.getQueuedMessageById(queuedMessage.messageId);
    final retryCount = updatedMessage?.retryCount ?? 0;
    
    if (retryCount >= _config.maxRetryAttempts) {
      // Max retries reached, mark as failed
      await _database.updateQueuedMessageStatus(
        queuedMessage.messageId,
        QueuedMessageStatus.failed.name,
        error: error,
        processedAt: DateTime.now(),
      );
      
      developer.log('Message ${queuedMessage.messageId} failed after $retryCount retries', name: 'MessageQueueService');
    } else {
      // Reset to pending for retry
      await _database.updateQueuedMessageStatus(
        queuedMessage.messageId,
        QueuedMessageStatus.pending.name,
        error: error,
      );
      
      developer.log('Message ${queuedMessage.messageId} will be retried (attempt ${retryCount + 1})', name: 'MessageQueueService');
    }
    
    return QueueProcessingResult(
      messageId: queuedMessage.messageId,
      success: false,
      processingTime: processingTime,
      error: error,
    );
  }

  @override
  Future<List<QueuedMessage>> getQueuedMessages({
    QueuedMessageStatus? status,
    QueuedMessagePriority? priority,
    int? limit,
  }) async {
    final dbMessages = await _database.getAllQueuedMessages();
    
    var filteredMessages = dbMessages.where((msg) {
      if (status != null && msg.status != status.name) return false;
      if (priority != null && msg.priority != priority.name) return false;
      return true;
    }).toList();
    
    // Sort by priority and queue time
    filteredMessages.sort((a, b) {
      final priorityA = QueuedMessagePriority.values.firstWhere((p) => p.name == a.priority);
      final priorityB = QueuedMessagePriority.values.firstWhere((p) => p.name == b.priority);
      
      final priorityComparison = priorityB.value.compareTo(priorityA.value);
      if (priorityComparison != 0) return priorityComparison;
      
      return a.queuedAt.compareTo(b.queuedAt);
    });
    
    if (limit != null && filteredMessages.length > limit) {
      filteredMessages = filteredMessages.take(limit).toList();
    }
    
    return filteredMessages.map(_convertToQueuedMessage).toList();
  }

  @override
  Future<QueuedMessage?> getQueuedMessage(String messageId) async {
    final dbMessage = await _database.getQueuedMessageById(messageId);
    return dbMessage != null ? _convertToQueuedMessage(dbMessage) : null;
  }

  @override
  Future<bool> removeMessage(String messageId) async {
    final result = await _database.deleteQueuedMessage(messageId);
    if (result > 0) {
      _updateStats();
      return true;
    }
    return false;
  }

  @override
  Future<int> clearMessages({QueuedMessageStatus? status}) async {
    final result = status != null
        ? await _database.clearQueuedMessagesByStatus(status.name)
        : await _database.clearQueuedMessagesByStatus('completed');
    
    if (result > 0) {
      _updateStats();
    }
    
    return result;
  }

  @override
  Future<int> clearExpiredMessages() async {
    final result = await _database.clearExpiredQueuedMessages();
    if (result > 0) {
      developer.log('Cleared $result expired messages', name: 'MessageQueueService');
      _updateStats();
    }
    return result;
  }

  @override
  Future<void> updateConfig(MessageQueueConfig config) async {
    _config = config;
    developer.log('Updated message queue configuration', name: 'MessageQueueService');
  }

  @override
  Future<int> getQueueSize() async {
    return await _database.getQueuedMessageCount();
  }

  @override
  Future<bool> isQueueFull() async {
    final currentSize = await getQueueSize();
    return currentSize >= _config.maxQueueSize;
  }

  @override
  Future<int> retryFailedMessages({int? maxRetries}) async {
    final failedMessages = await _database.getFailedQueuedMessages(maxRetries: maxRetries);
    
    int retriedCount = 0;
    for (final message in failedMessages) {
      await _database.updateQueuedMessageStatus(
        message.messageId,
        QueuedMessageStatus.pending.name,
      );
      retriedCount++;
    }
    
    if (retriedCount > 0) {
      developer.log('Retried $retriedCount failed messages', name: 'MessageQueueService');
      _updateStats();
    }
    
    return retriedCount;
  }

  @override
  Future<bool> prioritizeMessage(String messageId, QueuedMessagePriority priority) async {
    final result = await _database.updateQueuedMessagePriority(messageId, priority.name);
    if (result) {
      developer.log('Prioritized message $messageId to ${priority.name}', name: 'MessageQueueService');
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> getQueueHealth() async {
    final stats = await _calculateStats();
    
    return {
      'isHealthy': stats.failed < (stats.totalQueued * 0.1), // Less than 10% failure rate
      'queueSize': stats.totalQueued,
      'processingRate': stats.messagesPerSecond ?? 0,
      'failureRate': stats.totalQueued > 0 ? (stats.failed / stats.totalQueued) : 0.0,
      'averageProcessingTime': stats.averageProcessingTime?.inMilliseconds ?? 0,
      'isProcessing': _isProcessing,
      'lastUpdated': stats.lastUpdated,
    };
  }

  Future<void> _cleanupExpiredMessages() async {
    try {
      await clearExpiredMessages();
    } catch (error) {
      developer.log('Error during cleanup: $error', name: 'MessageQueueService');
    }
  }

  Future<void> _updateStats() async {
    try {
      _currentStats = await _calculateStats();
      _statsController.add(_currentStats);
    } catch (error) {
      developer.log('Error updating stats: $error', name: 'MessageQueueService');
    }
  }

  Future<MessageQueueStats> _calculateStats() async {
    final totalQueued = await _database.getQueuedMessageCount();
    final pending = await _database.getQueuedMessageCount(status: QueuedMessageStatus.pending.name);
    final processing = await _database.getQueuedMessageCount(status: QueuedMessageStatus.processing.name);
    final completed = await _database.getQueuedMessageCount(status: QueuedMessageStatus.completed.name);
    final failed = await _database.getQueuedMessageCount(status: QueuedMessageStatus.failed.name);
    final expired = await _database.getQueuedMessageCount(status: QueuedMessageStatus.expired.name);
    
    return MessageQueueStats(
      totalQueued: totalQueued,
      pending: pending,
      processing: processing,
      completed: completed,
      failed: failed,
      expired: expired,
      lastUpdated: DateTime.now(),
    );
  }

  QueuedMessage _convertToQueuedMessage(QueuedMessageEntry dbMessage) {
    return QueuedMessage(
      id: dbMessage.messageId,
      message: WebSocketMessage.fromJson(jsonDecode(dbMessage.messageData)),
      queuedAt: dbMessage.queuedAt,
      status: QueuedMessageStatus.values.firstWhere((s) => s.name == dbMessage.status),
      priority: QueuedMessagePriority.values.firstWhere((p) => p.name == dbMessage.priority),
      processedAt: dbMessage.processedAt,
      expiresAt: dbMessage.expiresAt,
      error: dbMessage.error,
      retryCount: dbMessage.retryCount,
      metadata: dbMessage.metadata != null ? jsonDecode(dbMessage.metadata!) : null,
    );
  }

  @override
  void dispose() {
    developer.log('Disposing MessageQueueService', name: 'MessageQueueService');
    
    _isProcessing = false;
    _processingTimer?.cancel();
    _cleanupTimer?.cancel();
    
    _processingResultController.close();
    _statsController.close();
  }
}