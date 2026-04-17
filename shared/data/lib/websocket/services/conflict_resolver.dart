import 'dart:developer' as developer;
import '../interfaces/i_conflict_resolver.dart';
import '../models/sync_operation.dart';

/// Implementation of conflict resolver for data synchronization
class ConflictResolver implements IConflictResolver {
  final Map<String, ConflictResolutionStrategy> _defaultStrategies = {};
  final Map<String, Map<String, ConflictResolutionStrategy>> _fieldMergeRules = {};

  ConflictResolver() {
    _initializeDefaultStrategies();
  }

  void _initializeDefaultStrategies() {
    // Set default strategies for different entity types
    _defaultStrategies['customer'] = ConflictResolutionStrategy.useLatest;
    _defaultStrategies['inventory'] = ConflictResolutionStrategy.useRemote;
    _defaultStrategies['order'] = ConflictResolutionStrategy.merge;
    _defaultStrategies['user'] = ConflictResolutionStrategy.manual;

    // Set field-level merge rules for customers
    _fieldMergeRules['customer'] = {
      'name': ConflictResolutionStrategy.useLatest,
      'email': ConflictResolutionStrategy.useLatest,
      'phone': ConflictResolutionStrategy.useLatest,
      'address': ConflictResolutionStrategy.useLatest,
      'balance': ConflictResolutionStrategy.useRemote,
      'credit_limit': ConflictResolutionStrategy.useRemote,
      'status': ConflictResolutionStrategy.useRemote,
    };

    // Set field-level merge rules for inventory
    _fieldMergeRules['inventory'] = {
      'quantity': ConflictResolutionStrategy.useRemote,
      'price': ConflictResolutionStrategy.useRemote,
      'name': ConflictResolutionStrategy.useLatest,
      'description': ConflictResolutionStrategy.useLatest,
      'category': ConflictResolutionStrategy.useLatest,
    };

    // Set field-level merge rules for orders
    _fieldMergeRules['order'] = {
      'status': ConflictResolutionStrategy.useRemote,
      'total_amount': ConflictResolutionStrategy.useRemote,
      'payment_status': ConflictResolutionStrategy.useRemote,
      'notes': ConflictResolutionStrategy.merge,
      'delivery_address': ConflictResolutionStrategy.useLatest,
    };
  }

  @override
  Future<Map<String, dynamic>> resolveConflict(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    developer.log(
      'Resolving conflict for ${conflict.entityType}:${conflict.entityId} using strategy: $strategy',
      name: 'ConflictResolver',
    );

    switch (strategy) {
      case ConflictResolutionStrategy.useRemote:
        return conflict.remoteData;

      case ConflictResolutionStrategy.useLocal:
        return conflict.localData;

      case ConflictResolutionStrategy.useLatest:
        return _resolveByTimestamp(conflict);

      case ConflictResolutionStrategy.merge:
        return await _mergeData(conflict);

      case ConflictResolutionStrategy.manual:
        throw ConflictResolutionException(
          'Manual resolution required for ${conflict.entityType}:${conflict.entityId}',
          conflict,
        );
    }
  }

  @override
  ConflictResolutionStrategy getDefaultStrategy(String entityType) {
    return _defaultStrategies[entityType] ?? ConflictResolutionStrategy.useLatest;
  }

  @override
  void setDefaultStrategy(String entityType, ConflictResolutionStrategy strategy) {
    developer.log(
      'Setting default strategy for $entityType: $strategy',
      name: 'ConflictResolver',
    );
    _defaultStrategies[entityType] = strategy;
  }

  @override
  bool canAutoResolve(DataConflict conflict) {
    final strategy = getDefaultStrategy(conflict.entityType);
    return strategy != ConflictResolutionStrategy.manual;
  }

  @override
  Map<String, ConflictResolutionStrategy> getFieldMergeRules(String entityType) {
    return _fieldMergeRules[entityType] ?? {};
  }

  @override
  void setFieldMergeRules(String entityType, Map<String, ConflictResolutionStrategy> rules) {
    developer.log(
      'Setting field merge rules for $entityType: ${rules.keys.join(', ')}',
      name: 'ConflictResolver',
    );
    _fieldMergeRules[entityType] = rules;
  }

  Map<String, dynamic> _resolveByTimestamp(DataConflict conflict) {
    final useRemote = conflict.remoteTimestamp.isAfter(conflict.localTimestamp);
    developer.log(
      'Resolving by timestamp: using ${useRemote ? 'remote' : 'local'} data',
      name: 'ConflictResolver',
    );
    return useRemote ? conflict.remoteData : conflict.localData;
  }

  Future<Map<String, dynamic>> _mergeData(DataConflict conflict) async {
    developer.log('Merging data for ${conflict.entityType}', name: 'ConflictResolver');
    
    final mergedData = <String, dynamic>{};
    final fieldRules = getFieldMergeRules(conflict.entityType);
    
    // Get all unique fields from both datasets
    final allFields = <String>{
      ...conflict.localData.keys,
      ...conflict.remoteData.keys,
    };

    for (final field in allFields) {
      final fieldStrategy = fieldRules[field] ?? ConflictResolutionStrategy.useLatest;
      
      switch (fieldStrategy) {
        case ConflictResolutionStrategy.useRemote:
          if (conflict.remoteData.containsKey(field)) {
            mergedData[field] = conflict.remoteData[field];
          }
          break;

        case ConflictResolutionStrategy.useLocal:
          if (conflict.localData.containsKey(field)) {
            mergedData[field] = conflict.localData[field];
          }
          break;

        case ConflictResolutionStrategy.useLatest:
          final useRemote = conflict.remoteTimestamp.isAfter(conflict.localTimestamp);
          final sourceData = useRemote ? conflict.remoteData : conflict.localData;
          if (sourceData.containsKey(field)) {
            mergedData[field] = sourceData[field];
          }
          break;

        case ConflictResolutionStrategy.merge:
          // For merge strategy on individual fields, try to combine values
          mergedData[field] = _mergeFieldValues(
            field,
            conflict.localData[field],
            conflict.remoteData[field],
          );
          break;

        case ConflictResolutionStrategy.manual:
          // Skip manual fields in automatic merge
          if (conflict.localData.containsKey(field)) {
            mergedData[field] = conflict.localData[field];
          }
          break;
      }
    }

    developer.log('Data merge completed for ${conflict.entityType}', name: 'ConflictResolver');
    return mergedData;
  }

  dynamic _mergeFieldValues(String fieldName, dynamic localValue, dynamic remoteValue) {
    // Handle null values
    if (localValue == null) return remoteValue;
    if (remoteValue == null) return localValue;

    // For string fields that might be notes or descriptions, try to combine
    if (localValue is String && remoteValue is String) {
      if (fieldName.toLowerCase().contains('note') || 
          fieldName.toLowerCase().contains('description') ||
          fieldName.toLowerCase().contains('comment')) {
        return '$localValue\n---\n$remoteValue';
      }
    }

    // For other types, use remote value as default
    return remoteValue;
  }
}

/// Exception thrown when conflict resolution fails
class ConflictResolutionException implements Exception {
  final String message;
  final DataConflict conflict;

  const ConflictResolutionException(this.message, this.conflict);

  @override
  String toString() => 'ConflictResolutionException: $message';
}