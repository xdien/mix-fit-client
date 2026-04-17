import 'dart:async';
import '../models/queued_message.dart';
import '../models/websocket_message.dart';

/// Interface for WebSocket message queue service
/// 
/// This service handles queuing of WebSocket messages during disconnection periods,
/// manages offline message storage, and processes queued messages on reconnection.
abstract class IMessageQueueService {
  /// Stream of queue processing results
  Stream<QueueProcessingResult> get processingResults;
  
  /// Stream of queue statistics updates
  Stream<MessageQueueStats> get queueStats;
  
  /// Whether the queue is currently processing messages
  bool get isProcessing;
  
  /// Current queue configuration
  MessageQueueConfig get config;
  
  /// Current queue statistics
  MessageQueueStats get stats;

  /// Queue a message for later processing
  /// 
  /// [message] - The WebSocket message to queue
  /// [priority] - Priority level for processing order
  /// [expiresAt] - Optional expiration time for the message
  /// 
  /// Returns the ID of the queued message
  Future<String> queueMessage(
    WebSocketMessage message, {
    QueuedMessagePriority priority = QueuedMessagePriority.normal,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  });

  /// Queue multiple messages in batch
  /// 
  /// [messages] - List of messages to queue
  /// [priority] - Default priority for all messages
  /// 
  /// Returns list of queued message IDs
  Future<List<String>> queueBatch(
    List<WebSocketMessage> messages, {
    QueuedMessagePriority priority = QueuedMessagePriority.normal,
    DateTime? expiresAt,
  });

  /// Start processing queued messages
  /// 
  /// [batchSize] - Number of messages to process in each batch
  /// 
  /// Returns a stream of processing results
  Stream<QueueProcessingResult> startProcessing({int? batchSize});

  /// Stop processing queued messages
  Future<void> stopProcessing();

  /// Process a specific queued message by ID
  /// 
  /// [messageId] - ID of the message to process
  /// 
  /// Returns the processing result
  Future<QueueProcessingResult> processMessage(String messageId);

  /// Get all queued messages with optional filtering
  /// 
  /// [status] - Filter by message status
  /// [priority] - Filter by message priority
  /// [limit] - Maximum number of messages to return
  /// 
  /// Returns list of queued messages
  Future<List<QueuedMessage>> getQueuedMessages({
    QueuedMessageStatus? status,
    QueuedMessagePriority? priority,
    int? limit,
  });

  /// Get a specific queued message by ID
  /// 
  /// [messageId] - ID of the message to retrieve
  /// 
  /// Returns the queued message or null if not found
  Future<QueuedMessage?> getQueuedMessage(String messageId);

  /// Remove a message from the queue
  /// 
  /// [messageId] - ID of the message to remove
  /// 
  /// Returns true if the message was removed
  Future<bool> removeMessage(String messageId);

  /// Clear all messages with specified status
  /// 
  /// [status] - Status of messages to clear
  /// 
  /// Returns number of messages cleared
  Future<int> clearMessages({QueuedMessageStatus? status});

  /// Clear expired messages from the queue
  /// 
  /// Returns number of expired messages cleared
  Future<int> clearExpiredMessages();

  /// Update queue configuration
  /// 
  /// [config] - New configuration to apply
  Future<void> updateConfig(MessageQueueConfig config);

  /// Get current queue size
  Future<int> getQueueSize();

  /// Check if queue is full
  Future<bool> isQueueFull();

  /// Retry failed messages
  /// 
  /// [maxRetries] - Maximum number of retry attempts
  /// 
  /// Returns number of messages retried
  Future<int> retryFailedMessages({int? maxRetries});

  /// Prioritize a message (move to front of queue)
  /// 
  /// [messageId] - ID of the message to prioritize
  /// [priority] - New priority level
  /// 
  /// Returns true if the message was prioritized
  Future<bool> prioritizeMessage(String messageId, QueuedMessagePriority priority);

  /// Get queue health status
  /// 
  /// Returns information about queue performance and health
  Future<Map<String, dynamic>> getQueueHealth();

  /// Dispose of the service and clean up resources
  void dispose();
}