import 'dart:async';
import 'dart:developer' as developer;
import '../models/websocket_message.dart';

/// Handles synchronization of missed updates when app returns from background
/// 
/// This service manages the process of catching up on data changes that occurred
/// while the app was in the background, ensuring data consistency and providing
/// conflict resolution when needed.
class MissedUpdateSynchronizer {
  final Future<List<WebSocketMessage>> Function(DateTime from, DateTime to) _fetchMissedUpdates;
  final Future<void> Function(List<WebSocketMessage>) _processBatchUpdates;
  final Future<void> Function() _performFullRefresh;
  
  // Configuration
  static const Duration _maxSyncDuration = Duration(minutes: 30);
  static const int _maxBatchSize = 100;
  static const Duration _syncTimeout = Duration(minutes: 5);
  
  final StreamController<SynchronizationEvent> _syncEventController =
      StreamController<SynchronizationEvent>.broadcast();
  
  bool _isSynchronizing = false;

  MissedUpdateSynchronizer({
    required Future<List<WebSocketMessage>> Function(DateTime from, DateTime to) fetchMissedUpdates,
    required Future<void> Function(List<WebSocketMessage>) processBatchUpdates,
    required Future<void> Function() performFullRefresh,
  }) : _fetchMissedUpdates = fetchMissedUpdates,
       _processBatchUpdates = processBatchUpdates,
       _performFullRefresh = performFullRefresh;

  /// Stream of synchronization events
  Stream<SynchronizationEvent> get synchronizationEvents => _syncEventController.stream;

  /// Whether synchronization is currently in progress
  bool get isSynchronizing => _isSynchronizing;

  /// Synchronize missed updates for the specified time period
  Future<SynchronizationResult> synchronizeMissedUpdates({
    required DateTime backgroundTime,
    required DateTime resumeTime,
  }) async {
    if (_isSynchronizing) {
      developer.log('Synchronization already in progress, skipping', name: 'MissedUpdateSynchronizer');
      return SynchronizationResult.alreadyInProgress();
    }

    final duration = resumeTime.difference(backgroundTime);
    
    // Check if the background duration is within reasonable limits
    if (duration > _maxSyncDuration) {
      developer.log('Background duration too long (${duration.inMinutes} min), performing full refresh', name: 'MissedUpdateSynchronizer');
      return await performFullDataRefresh();
    }

    _isSynchronizing = true;
    final startTime = DateTime.now();
    
    _emitSyncEvent(SynchronizationEvent.started(
      backgroundTime: backgroundTime,
      resumeTime: resumeTime,
      expectedDuration: duration,
    ));

    try {
      developer.log('Starting missed update synchronization from $backgroundTime to $resumeTime', name: 'MissedUpdateSynchronizer');
      
      // Fetch missed updates with timeout
      final missedUpdates = await _fetchMissedUpdates(backgroundTime, resumeTime)
          .timeout(_syncTimeout);
      
      developer.log('Found ${missedUpdates.length} missed updates', name: 'MissedUpdateSynchronizer');
      
      if (missedUpdates.isEmpty) {
        final result = SynchronizationResult.success(
          updatesProcessed: 0,
          duration: DateTime.now().difference(startTime),
          backgroundDuration: duration,
        );
        
        _emitSyncEvent(SynchronizationEvent.completed(result));
        return result;
      }

      // Process updates in batches to avoid overwhelming the system
      int totalProcessed = 0;
      final batches = _createBatches(missedUpdates, _maxBatchSize);
      
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        developer.log('Processing batch ${i + 1}/${batches.length} with ${batch.length} updates', name: 'MissedUpdateSynchronizer');
        
        _emitSyncEvent(SynchronizationEvent.batchProcessing(
          batchNumber: i + 1,
          totalBatches: batches.length,
          batchSize: batch.length,
        ));
        
        await _processBatchUpdates(batch);
        totalProcessed += batch.length;
        
        // Small delay between batches to prevent overwhelming the UI
        if (i < batches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      final result = SynchronizationResult.success(
        updatesProcessed: totalProcessed,
        duration: DateTime.now().difference(startTime),
        backgroundDuration: duration,
      );
      
      developer.log('Missed update synchronization completed: $totalProcessed updates processed', name: 'MissedUpdateSynchronizer');
      _emitSyncEvent(SynchronizationEvent.completed(result));
      
      return result;
      
    } catch (error) {
      developer.log('Error during missed update synchronization: $error', name: 'MissedUpdateSynchronizer');
      
      final result = SynchronizationResult.error(
        error: error,
        duration: DateTime.now().difference(startTime),
        backgroundDuration: duration,
      );
      
      _emitSyncEvent(SynchronizationEvent.failed(error));
      return result;
      
    } finally {
      _isSynchronizing = false;
    }
  }

  /// Perform a full data refresh instead of incremental sync
  Future<SynchronizationResult> performFullDataRefresh() async {
    if (_isSynchronizing) {
      developer.log('Synchronization already in progress, skipping full refresh', name: 'MissedUpdateSynchronizer');
      return SynchronizationResult.alreadyInProgress();
    }

    _isSynchronizing = true;
    final startTime = DateTime.now();
    
    _emitSyncEvent(SynchronizationEvent.fullRefreshStarted());

    try {
      developer.log('Starting full data refresh', name: 'MissedUpdateSynchronizer');
      
      await _performFullRefresh().timeout(_syncTimeout);
      
      final result = SynchronizationResult.fullRefresh(
        duration: DateTime.now().difference(startTime),
      );
      
      developer.log('Full data refresh completed', name: 'MissedUpdateSynchronizer');
      _emitSyncEvent(SynchronizationEvent.completed(result));
      
      return result;
      
    } catch (error) {
      developer.log('Error during full data refresh: $error', name: 'MissedUpdateSynchronizer');
      
      final result = SynchronizationResult.error(
        error: error,
        duration: DateTime.now().difference(startTime),
      );
      
      _emitSyncEvent(SynchronizationEvent.failed(error));
      return result;
      
    } finally {
      _isSynchronizing = false;
    }
  }

  List<List<WebSocketMessage>> _createBatches(List<WebSocketMessage> updates, int batchSize) {
    final batches = <List<WebSocketMessage>>[];
    
    for (int i = 0; i < updates.length; i += batchSize) {
      final end = (i + batchSize < updates.length) ? i + batchSize : updates.length;
      batches.add(updates.sublist(i, end));
    }
    
    return batches;
  }

  void _emitSyncEvent(SynchronizationEvent event) {
    if (!_syncEventController.isClosed) {
      _syncEventController.add(event);
    }
  }

  void dispose() {
    _syncEventController.close();
  }
}

/// Represents different types of synchronization events
class SynchronizationEvent {
  final SynchronizationEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const SynchronizationEvent._({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory SynchronizationEvent.started({
    required DateTime backgroundTime,
    required DateTime resumeTime,
    required Duration expectedDuration,
  }) {
    return SynchronizationEvent._(
      type: SynchronizationEventType.started,
      timestamp: DateTime.now(),
      data: {
        'backgroundTime': backgroundTime,
        'resumeTime': resumeTime,
        'expectedDuration': expectedDuration,
      },
    );
  }

  factory SynchronizationEvent.batchProcessing({
    required int batchNumber,
    required int totalBatches,
    required int batchSize,
  }) {
    return SynchronizationEvent._(
      type: SynchronizationEventType.batchProcessing,
      timestamp: DateTime.now(),
      data: {
        'batchNumber': batchNumber,
        'totalBatches': totalBatches,
        'batchSize': batchSize,
      },
    );
  }

  factory SynchronizationEvent.completed(SynchronizationResult result) {
    return SynchronizationEvent._(
      type: SynchronizationEventType.completed,
      timestamp: DateTime.now(),
      data: {'result': result},
    );
  }

  factory SynchronizationEvent.failed(dynamic error) {
    return SynchronizationEvent._(
      type: SynchronizationEventType.failed,
      timestamp: DateTime.now(),
      data: {'error': error},
    );
  }

  factory SynchronizationEvent.fullRefreshStarted() {
    return SynchronizationEvent._(
      type: SynchronizationEventType.fullRefreshStarted,
      timestamp: DateTime.now(),
      data: {},
    );
  }

  @override
  String toString() {
    return 'SynchronizationEvent(type: $type, timestamp: $timestamp, data: $data)';
  }
}

enum SynchronizationEventType {
  started,
  batchProcessing,
  completed,
  failed,
  fullRefreshStarted,
}

/// Result of a synchronization operation
class SynchronizationResult {
  final SynchronizationResultType type;
  final int? updatesProcessed;
  final Duration duration;
  final Duration? backgroundDuration;
  final dynamic error;

  const SynchronizationResult._({
    required this.type,
    this.updatesProcessed,
    required this.duration,
    this.backgroundDuration,
    this.error,
  });

  factory SynchronizationResult.success({
    required int updatesProcessed,
    required Duration duration,
    required Duration backgroundDuration,
  }) {
    return SynchronizationResult._(
      type: SynchronizationResultType.success,
      updatesProcessed: updatesProcessed,
      duration: duration,
      backgroundDuration: backgroundDuration,
    );
  }

  factory SynchronizationResult.fullRefresh({
    required Duration duration,
  }) {
    return SynchronizationResult._(
      type: SynchronizationResultType.fullRefresh,
      duration: duration,
    );
  }

  factory SynchronizationResult.error({
    required dynamic error,
    required Duration duration,
    Duration? backgroundDuration,
  }) {
    return SynchronizationResult._(
      type: SynchronizationResultType.error,
      error: error,
      duration: duration,
      backgroundDuration: backgroundDuration,
    );
  }

  factory SynchronizationResult.alreadyInProgress() {
    return SynchronizationResult._(
      type: SynchronizationResultType.alreadyInProgress,
      duration: Duration.zero,
    );
  }

  bool get isSuccess => type == SynchronizationResultType.success || type == SynchronizationResultType.fullRefresh;
  bool get isError => type == SynchronizationResultType.error;

  @override
  String toString() {
    return 'SynchronizationResult(type: $type, updatesProcessed: $updatesProcessed, duration: $duration, error: $error)';
  }
}

enum SynchronizationResultType {
  success,
  fullRefresh,
  error,
  alreadyInProgress,
}