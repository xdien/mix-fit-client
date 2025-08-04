import 'dart:async';
import 'dart:developer' as developer;

import '../interfaces/i_message_queue_service.dart';
import '../interfaces/i_websocket_data_synchronizer.dart';
import '../models/queued_message.dart';
import '../models/websocket_message.dart';
import '../models/websocket_connection_state.dart';
import '../models/sync_operation.dart';
import 'missed_update_synchronizer.dart';

/// Service that handles offline synchronization and message queuing
/// 
/// This service coordinates between the message queue, data synchronizer,
/// and missed update synchronizer to provide seamless offline support.
class OfflineSyncService {
  final IMessageQueueService _messageQueueService;
  final IWebSocketDataSynchronizer _dataSynchronizer;
  final MissedUpdateSynchronizer _missedUpdateSynchronizer;
  
  final StreamController<OfflineSyncEvent> _syncEventController =
      StreamController<OfflineSyncEvent>.broadcast();
  
  bool _isOnline = true;
  DateTime? _lastOnlineTime;
  DateTime? _offlineStartTime;
  
  StreamSubscription<QueueProcessingResult>? _queueProcessingSubscription;

  OfflineSyncService({
    required IMessageQueueService messageQueueService,
    required IWebSocketDataSynchronizer dataSynchronizer,
    required MissedUpdateSynchronizer missedUpdateSynchronizer,
  }) : _messageQueueService = messageQueueService,
       _dataSynchronizer = dataSynchronizer,
       _missedUpdateSynchronizer = missedUpdateSynchronizer {
    _initializeService();
  }

  /// Stream of offline synchronization events
  Stream<OfflineSyncEvent> get syncEvents => _syncEventController.stream;

  /// Whether the service is currently online
  bool get isOnline => _isOnline;

  /// Time when the service went offline (null if currently online)
  DateTime? get offlineStartTime => _offlineStartTime;

  /// Duration the service has been offline (null if currently online)
  Duration? get offlineDuration => _offlineStartTime != null 
      ? DateTime.now().difference(_offlineStartTime!)
      : null;

  void _initializeService() {
    developer.log('Initializing OfflineSyncService', name: 'OfflineSyncService');
    
    // Listen to queue processing results
    _queueProcessingSubscription = _messageQueueService.processingResults.listen(
      _handleQueueProcessingResult,
      onError: (error) {
        developer.log('Error in queue processing: $error', name: 'OfflineSyncService');
        _emitSyncEvent(OfflineSyncEvent.error('Queue processing error: $error'));
      },
    );
  }

  /// Handle connection state changes
  Future<void> handleConnectionStateChange(WebSocketConnectionState state) async {
    developer.log('Connection state changed to: $state', name: 'OfflineSyncService');
    
    switch (state) {
      case WebSocketConnectionState.connected:
        await _handleOnlineTransition();
        break;
      case WebSocketConnectionState.disconnected:
      case WebSocketConnectionState.error:
        await _handleOfflineTransition();
        break;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        // No action needed for transitional states
        break;
    }
  }

  /// Queue a message for offline processing
  Future<String> queueMessageForOfflineProcessing(
    WebSocketMessage message, {
    QueuedMessagePriority priority = QueuedMessagePriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    developer.log('Queuing message for offline processing: ${message.type}', name: 'OfflineSyncService');
    
    if (_isOnline) {
      // If we're online, try to process immediately
      try {
        final syncResult = await _dataSynchronizer.processMessage(message);
        if (syncResult.success) {
          developer.log('Message processed immediately while online', name: 'OfflineSyncService');
          return 'immediate_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          // Failed to process, queue it
          developer.log('Failed to process message while online, queuing', name: 'OfflineSyncService');
        }
      } catch (error) {
        developer.log('Error processing message while online, queuing: $error', name: 'OfflineSyncService');
      }
    }
    
    // Queue the message
    final messageId = await _messageQueueService.queueMessage(
      message,
      priority: priority,
      metadata: {
        ...?metadata,
        'queuedWhileOffline': !_isOnline,
        'queuedAt': DateTime.now().toIso8601String(),
      },
    );
    
    _emitSyncEvent(OfflineSyncEvent.messageQueued(messageId, message.type));
    return messageId;
  }

  /// Process all queued messages
  Future<OfflineSyncResult> processQueuedMessages() async {
    developer.log('Starting to process queued messages', name: 'OfflineSyncService');
    
    _emitSyncEvent(OfflineSyncEvent.queueProcessingStarted());
    
    final startTime = DateTime.now();
    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];
    
    try {
      // Get all pending messages
      final pendingMessages = await _messageQueueService.getQueuedMessages(
        status: QueuedMessageStatus.pending,
      );
      
      if (pendingMessages.isEmpty) {
        developer.log('No queued messages to process', name: 'OfflineSyncService');
        final result = OfflineSyncResult.success(
          messagesProcessed: 0,
          duration: DateTime.now().difference(startTime),
        );
        _emitSyncEvent(OfflineSyncEvent.queueProcessingCompleted(result));
        return result;
      }
      
      developer.log('Processing ${pendingMessages.length} queued messages', name: 'OfflineSyncService');
      
      // Start processing and listen to results
      final processingStream = _messageQueueService.startProcessing();
      
      await for (final result in processingStream) {
        if (result.success) {
          successCount++;
          _emitSyncEvent(OfflineSyncEvent.messageProcessed(result.messageId, true));
        } else {
          failureCount++;
          if (result.error != null) {
            errors.add(result.error!);
          }
          _emitSyncEvent(OfflineSyncEvent.messageProcessed(result.messageId, false, result.error));
        }
        
        // Check if we've processed all messages
        if (successCount + failureCount >= pendingMessages.length) {
          break;
        }
      }
      
      final result = OfflineSyncResult.success(
        messagesProcessed: successCount,
        duration: DateTime.now().difference(startTime),
        failureCount: failureCount,
        errors: errors.isNotEmpty ? errors : null,
      );
      
      developer.log('Completed processing queued messages: $successCount success, $failureCount failures', name: 'OfflineSyncService');
      _emitSyncEvent(OfflineSyncEvent.queueProcessingCompleted(result));
      
      return result;
      
    } catch (error) {
      developer.log('Error processing queued messages: $error', name: 'OfflineSyncService');
      
      final result = OfflineSyncResult.error(
        error: error,
        duration: DateTime.now().difference(startTime),
        messagesProcessed: successCount,
      );
      
      _emitSyncEvent(OfflineSyncEvent.queueProcessingCompleted(result));
      return result;
    }
  }

  /// Synchronize missed updates and process queued messages
  Future<ComprehensiveSyncResult> performComprehensiveSync() async {
    if (!_isOnline) {
      throw StateError('Cannot perform comprehensive sync while offline');
    }
    
    developer.log('Starting comprehensive sync', name: 'OfflineSyncService');
    _emitSyncEvent(OfflineSyncEvent.comprehensiveSyncStarted());
    
    final startTime = DateTime.now();
    
    try {
      // Step 1: Synchronize missed updates if we were offline
      SynchronizationResult? missedUpdateResult;
      if (_lastOnlineTime != null && _offlineStartTime != null) {
        developer.log('Synchronizing missed updates from ${_offlineStartTime!} to ${DateTime.now()}', name: 'OfflineSyncService');
        
        missedUpdateResult = await _missedUpdateSynchronizer.synchronizeMissedUpdates(
          backgroundTime: _offlineStartTime!,
          resumeTime: DateTime.now(),
        );
        
        if (!missedUpdateResult.isSuccess) {
          developer.log('Missed update sync failed: ${missedUpdateResult.error}', name: 'OfflineSyncService');
        }
      }
      
      // Step 2: Process queued messages
      final queueResult = await processQueuedMessages();
      
      // Step 3: Handle conflicts between missed updates and queued messages
      final conflictResolutionResult = await _resolveUpdateConflicts();
      
      final result = ComprehensiveSyncResult(
        success: queueResult.success && (missedUpdateResult?.isSuccess ?? true),
        duration: DateTime.now().difference(startTime),
        missedUpdateResult: missedUpdateResult,
        queueProcessingResult: queueResult,
        conflictsResolved: conflictResolutionResult,
      );
      
      developer.log('Comprehensive sync completed: ${result.success ? 'success' : 'failure'}', name: 'OfflineSyncService');
      _emitSyncEvent(OfflineSyncEvent.comprehensiveSyncCompleted(result));
      
      return result;
      
    } catch (error) {
      developer.log('Error during comprehensive sync: $error', name: 'OfflineSyncService');
      
      final result = ComprehensiveSyncResult(
        success: false,
        duration: DateTime.now().difference(startTime),
        error: error.toString(),
      );
      
      _emitSyncEvent(OfflineSyncEvent.comprehensiveSyncCompleted(result));
      return result;
    }
  }

  /// Clear completed messages from the queue
  Future<int> clearCompletedMessages() async {
    return await _messageQueueService.clearMessages(status: QueuedMessageStatus.completed);
  }

  /// Get queue statistics
  Future<MessageQueueStats> getQueueStats() async {
    return _messageQueueService.stats;
  }

  /// Retry failed messages
  Future<int> retryFailedMessages() async {
    return await _messageQueueService.retryFailedMessages();
  }

  Future<void> _handleOnlineTransition() async {
    if (_isOnline) return; // Already online
    
    developer.log('Transitioning to online state', name: 'OfflineSyncService');
    
    _isOnline = true;
    _lastOnlineTime = DateTime.now();
    
    _emitSyncEvent(OfflineSyncEvent.onlineTransition(_lastOnlineTime!));
    
    // Start comprehensive sync
    try {
      await performComprehensiveSync();
    } catch (error) {
      developer.log('Error during online transition sync: $error', name: 'OfflineSyncService');
      _emitSyncEvent(OfflineSyncEvent.error('Online transition sync failed: $error'));
    } finally {
      _offlineStartTime = null;
    }
  }

  Future<void> _handleOfflineTransition() async {
    if (!_isOnline) return; // Already offline
    
    developer.log('Transitioning to offline state', name: 'OfflineSyncService');
    
    _isOnline = false;
    _offlineStartTime = DateTime.now();
    
    _emitSyncEvent(OfflineSyncEvent.offlineTransition(_offlineStartTime!));
    
    // Stop any ongoing queue processing
    await _messageQueueService.stopProcessing();
  }

  Future<int> _resolveUpdateConflicts() async {
    // This is a placeholder for conflict resolution logic
    // In a real implementation, you would:
    // 1. Identify conflicts between missed updates and queued messages
    // 2. Apply conflict resolution strategies
    // 3. Update local data accordingly
    
    developer.log('Resolving update conflicts (placeholder)', name: 'OfflineSyncService');
    return 0; // Number of conflicts resolved
  }

  void _handleQueueProcessingResult(QueueProcessingResult result) {
    if (result.success) {
      developer.log('Queue message processed successfully: ${result.messageId}', name: 'OfflineSyncService');
    } else {
      developer.log('Queue message processing failed: ${result.messageId} - ${result.error}', name: 'OfflineSyncService');
    }
  }

  void _emitSyncEvent(OfflineSyncEvent event) {
    if (!_syncEventController.isClosed) {
      _syncEventController.add(event);
    }
  }

  void dispose() {
    developer.log('Disposing OfflineSyncService', name: 'OfflineSyncService');
    
    _queueProcessingSubscription?.cancel();
    _syncEventController.close();
    _messageQueueService.dispose();
  }
}

/// Events emitted by the offline sync service
class OfflineSyncEvent {
  final OfflineSyncEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const OfflineSyncEvent._({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory OfflineSyncEvent.onlineTransition(DateTime timestamp) {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.onlineTransition,
      timestamp: timestamp,
      data: {},
    );
  }

  factory OfflineSyncEvent.offlineTransition(DateTime timestamp) {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.offlineTransition,
      timestamp: timestamp,
      data: {},
    );
  }

  factory OfflineSyncEvent.messageQueued(String messageId, String messageType) {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.messageQueued,
      timestamp: DateTime.now(),
      data: {'messageId': messageId, 'messageType': messageType},
    );
  }

  factory OfflineSyncEvent.messageProcessed(String messageId, bool success, [String? error]) {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.messageProcessed,
      timestamp: DateTime.now(),
      data: {'messageId': messageId, 'success': success, 'error': error},
    );
  }

  factory OfflineSyncEvent.queueProcessingStarted() {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.queueProcessingStarted,
      timestamp: DateTime.now(),
      data: {},
    );
  }

  factory OfflineSyncEvent.queueProcessingCompleted(OfflineSyncResult result) {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.queueProcessingCompleted,
      timestamp: DateTime.now(),
      data: {'result': result},
    );
  }

  factory OfflineSyncEvent.comprehensiveSyncStarted() {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.comprehensiveSyncStarted,
      timestamp: DateTime.now(),
      data: {},
    );
  }

  factory OfflineSyncEvent.comprehensiveSyncCompleted(ComprehensiveSyncResult result) {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.comprehensiveSyncCompleted,
      timestamp: DateTime.now(),
      data: {'result': result},
    );
  }

  factory OfflineSyncEvent.error(String error) {
    return OfflineSyncEvent._(
      type: OfflineSyncEventType.error,
      timestamp: DateTime.now(),
      data: {'error': error},
    );
  }

  @override
  String toString() {
    return 'OfflineSyncEvent(type: $type, timestamp: $timestamp, data: $data)';
  }
}

enum OfflineSyncEventType {
  onlineTransition,
  offlineTransition,
  messageQueued,
  messageProcessed,
  queueProcessingStarted,
  queueProcessingCompleted,
  comprehensiveSyncStarted,
  comprehensiveSyncCompleted,
  error,
}

/// Result of offline sync operations
class OfflineSyncResult {
  final bool success;
  final int messagesProcessed;
  final Duration duration;
  final int? failureCount;
  final List<String>? errors;
  final dynamic error;

  const OfflineSyncResult._({
    required this.success,
    required this.messagesProcessed,
    required this.duration,
    this.failureCount,
    this.errors,
    this.error,
  });

  factory OfflineSyncResult.success({
    required int messagesProcessed,
    required Duration duration,
    int? failureCount,
    List<String>? errors,
  }) {
    return OfflineSyncResult._(
      success: true,
      messagesProcessed: messagesProcessed,
      duration: duration,
      failureCount: failureCount,
      errors: errors,
    );
  }

  factory OfflineSyncResult.error({
    required dynamic error,
    required Duration duration,
    int messagesProcessed = 0,
  }) {
    return OfflineSyncResult._(
      success: false,
      messagesProcessed: messagesProcessed,
      duration: duration,
      error: error,
    );
  }

  @override
  String toString() {
    return 'OfflineSyncResult(success: $success, messagesProcessed: $messagesProcessed, duration: $duration, error: $error)';
  }
}

/// Result of comprehensive synchronization
class ComprehensiveSyncResult {
  final bool success;
  final Duration duration;
  final SynchronizationResult? missedUpdateResult;
  final OfflineSyncResult? queueProcessingResult;
  final int? conflictsResolved;
  final String? error;

  const ComprehensiveSyncResult({
    required this.success,
    required this.duration,
    this.missedUpdateResult,
    this.queueProcessingResult,
    this.conflictsResolved,
    this.error,
  });

  @override
  String toString() {
    return 'ComprehensiveSyncResult(success: $success, duration: $duration, conflictsResolved: $conflictsResolved, error: $error)';
  }
}