import '../models/sync_operation.dart';

/// Enum defining conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Use the remote (server) data
  useRemote,
  /// Use the local data
  useLocal,
  /// Merge both datasets using field-level resolution
  merge,
  /// Use the data with the latest timestamp
  useLatest,
  /// Require manual resolution
  manual
}

/// Interface for resolving data conflicts during synchronization
abstract class IConflictResolver {
  /// Resolve a data conflict using the specified strategy
  Future<Map<String, dynamic>> resolveConflict(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  );

  /// Get the default resolution strategy for an entity type
  ConflictResolutionStrategy getDefaultStrategy(String entityType);

  /// Set the default resolution strategy for an entity type
  void setDefaultStrategy(String entityType, ConflictResolutionStrategy strategy);

  /// Check if a conflict can be automatically resolved
  bool canAutoResolve(DataConflict conflict);

  /// Get field-level merge rules for an entity type
  Map<String, ConflictResolutionStrategy> getFieldMergeRules(String entityType);

  /// Set field-level merge rules for an entity type
  void setFieldMergeRules(String entityType, Map<String, ConflictResolutionStrategy> rules);
}