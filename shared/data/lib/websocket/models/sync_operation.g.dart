// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncOperationImpl _$$SyncOperationImplFromJson(Map<String, dynamic> json) =>
    _$SyncOperationImpl(
      id: json['id'] as String,
      type: $enumDecode(_$SyncOperationTypeEnumMap, json['type']),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: $enumDecodeNullable(_$SyncPriorityEnumMap, json['priority']) ??
          SyncPriority.normal,
      conflictResolutionStrategy: json['conflictResolutionStrategy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$SyncOperationImplToJson(_$SyncOperationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SyncOperationTypeEnumMap[instance.type]!,
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'priority': _$SyncPriorityEnumMap[instance.priority]!,
      'conflictResolutionStrategy': instance.conflictResolutionStrategy,
      'metadata': instance.metadata,
    };

const _$SyncOperationTypeEnumMap = {
  SyncOperationType.create: 'create',
  SyncOperationType.update: 'update',
  SyncOperationType.delete: 'delete',
  SyncOperationType.merge: 'merge',
};

const _$SyncPriorityEnumMap = {
  SyncPriority.low: 'low',
  SyncPriority.normal: 'normal',
  SyncPriority.high: 'high',
  SyncPriority.critical: 'critical',
};

_$SyncResultImpl _$$SyncResultImplFromJson(Map<String, dynamic> json) =>
    _$SyncResultImpl(
      operationId: json['operationId'] as String,
      success: json['success'] as bool,
      error: json['error'] as String?,
      conflictData: json['conflictData'] as Map<String, dynamic>?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$$SyncResultImplToJson(_$SyncResultImpl instance) =>
    <String, dynamic>{
      'operationId': instance.operationId,
      'success': instance.success,
      'error': instance.error,
      'conflictData': instance.conflictData,
      'completedAt': instance.completedAt?.toIso8601String(),
    };

_$DataConflictImpl _$$DataConflictImplFromJson(Map<String, dynamic> json) =>
    _$DataConflictImpl(
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      localData: json['localData'] as Map<String, dynamic>,
      remoteData: json['remoteData'] as Map<String, dynamic>,
      localTimestamp: DateTime.parse(json['localTimestamp'] as String),
      remoteTimestamp: DateTime.parse(json['remoteTimestamp'] as String),
      conflictField: json['conflictField'] as String?,
    );

Map<String, dynamic> _$$DataConflictImplToJson(_$DataConflictImpl instance) =>
    <String, dynamic>{
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'localData': instance.localData,
      'remoteData': instance.remoteData,
      'localTimestamp': instance.localTimestamp.toIso8601String(),
      'remoteTimestamp': instance.remoteTimestamp.toIso8601String(),
      'conflictField': instance.conflictField,
    };
