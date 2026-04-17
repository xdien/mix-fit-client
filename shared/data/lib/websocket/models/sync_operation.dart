import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_operation.freezed.dart';
part 'sync_operation.g.dart';

/// Enum defining the types of synchronization operations
enum SyncOperationType {
  create,
  update,
  delete,
  merge
}

/// Enum defining the priority of synchronization operations
enum SyncPriority {
  low,
  normal,
  high,
  critical
}

/// Represents a synchronization operation to be performed on local data
@freezed
class SyncOperation with _$SyncOperation {
  const factory SyncOperation({
    required String id,
    required SyncOperationType type,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
    @Default(SyncPriority.normal) SyncPriority priority,
    String? conflictResolutionStrategy,
    Map<String, dynamic>? metadata,
  }) = _SyncOperation;

  factory SyncOperation.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationFromJson(json);
}

/// Represents the result of a synchronization operation
@freezed
class SyncResult with _$SyncResult {
  const factory SyncResult({
    required String operationId,
    required bool success,
    String? error,
    Map<String, dynamic>? conflictData,
    DateTime? completedAt,
  }) = _SyncResult;

  factory SyncResult.fromJson(Map<String, dynamic> json) =>
      _$SyncResultFromJson(json);
}

/// Represents a data conflict that needs resolution
@freezed
class DataConflict with _$DataConflict {
  const factory DataConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
    String? conflictField,
  }) = _DataConflict;

  factory DataConflict.fromJson(Map<String, dynamic> json) =>
      _$DataConflictFromJson(json);
}