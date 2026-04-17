import '../models/websocket_message.dart';
import '../models/sync_operation.dart';

/// Interface for WebSocket data synchronization
abstract class IWebSocketDataSynchronizer {
  /// Process an incoming WebSocket message and perform necessary synchronization
  Future<SyncResult> processMessage(WebSocketMessage message);

  /// Process multiple messages in batch
  Future<List<SyncResult>> processBatch(List<WebSocketMessage> messages);

  /// Handle data conflicts during synchronization
  Future<SyncResult> resolveConflict(DataConflict conflict, String strategy);

  /// Get pending synchronization operations
  Future<List<SyncOperation>> getPendingOperations();

  /// Clear completed synchronization operations
  Future<void> clearCompletedOperations();

  /// Stream of synchronization results
  Stream<SyncResult> get syncResultStream;

  /// Stream of data conflicts that need manual resolution
  Stream<DataConflict> get conflictStream;

  /// Dispose resources
  void dispose();
}