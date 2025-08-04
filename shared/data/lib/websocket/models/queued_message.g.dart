// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QueuedMessageImpl _$$QueuedMessageImplFromJson(Map<String, dynamic> json) =>
    _$QueuedMessageImpl(
      id: json['id'] as String,
      message: _messageFromJson(json['message'] as Map<String, dynamic>),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      status: $enumDecode(_$QueuedMessageStatusEnumMap, json['status']),
      priority: $enumDecodeNullable(
              _$QueuedMessagePriorityEnumMap, json['priority']) ??
          QueuedMessagePriority.normal,
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      error: json['error'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$QueuedMessageImplToJson(_$QueuedMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': _messageToJson(instance.message),
      'queuedAt': instance.queuedAt.toIso8601String(),
      'status': _$QueuedMessageStatusEnumMap[instance.status]!,
      'priority': _$QueuedMessagePriorityEnumMap[instance.priority]!,
      'processedAt': instance.processedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'error': instance.error,
      'retryCount': instance.retryCount,
      'metadata': instance.metadata,
    };

const _$QueuedMessageStatusEnumMap = {
  QueuedMessageStatus.pending: 'pending',
  QueuedMessageStatus.processing: 'processing',
  QueuedMessageStatus.completed: 'completed',
  QueuedMessageStatus.failed: 'failed',
  QueuedMessageStatus.expired: 'expired',
};

const _$QueuedMessagePriorityEnumMap = {
  QueuedMessagePriority.low: 'low',
  QueuedMessagePriority.normal: 'normal',
  QueuedMessagePriority.high: 'high',
  QueuedMessagePriority.critical: 'critical',
};

_$MessageQueueConfigImpl _$$MessageQueueConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$MessageQueueConfigImpl(
      maxQueueSize: (json['maxQueueSize'] as num?)?.toInt() ?? 1000,
      messageExpiration: json['messageExpiration'] == null
          ? const Duration(hours: 24)
          : Duration(microseconds: (json['messageExpiration'] as num).toInt()),
      maxRetryAttempts: (json['maxRetryAttempts'] as num?)?.toInt() ?? 3,
      retryDelay: json['retryDelay'] == null
          ? const Duration(seconds: 30)
          : Duration(microseconds: (json['retryDelay'] as num).toInt()),
      processingTimeout: json['processingTimeout'] == null
          ? const Duration(minutes: 5)
          : Duration(microseconds: (json['processingTimeout'] as num).toInt()),
      enablePriorityProcessing:
          json['enablePriorityProcessing'] as bool? ?? true,
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 100,
    );

Map<String, dynamic> _$$MessageQueueConfigImplToJson(
        _$MessageQueueConfigImpl instance) =>
    <String, dynamic>{
      'maxQueueSize': instance.maxQueueSize,
      'messageExpiration': instance.messageExpiration.inMicroseconds,
      'maxRetryAttempts': instance.maxRetryAttempts,
      'retryDelay': instance.retryDelay.inMicroseconds,
      'processingTimeout': instance.processingTimeout.inMicroseconds,
      'enablePriorityProcessing': instance.enablePriorityProcessing,
      'batchSize': instance.batchSize,
    };

_$MessageQueueStatsImpl _$$MessageQueueStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$MessageQueueStatsImpl(
      totalQueued: (json['totalQueued'] as num).toInt(),
      pending: (json['pending'] as num).toInt(),
      processing: (json['processing'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
      failed: (json['failed'] as num).toInt(),
      expired: (json['expired'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      averageProcessingTime: json['averageProcessingTime'] == null
          ? null
          : Duration(
              microseconds: (json['averageProcessingTime'] as num).toInt()),
      messagesPerSecond: (json['messagesPerSecond'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$MessageQueueStatsImplToJson(
        _$MessageQueueStatsImpl instance) =>
    <String, dynamic>{
      'totalQueued': instance.totalQueued,
      'pending': instance.pending,
      'processing': instance.processing,
      'completed': instance.completed,
      'failed': instance.failed,
      'expired': instance.expired,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'averageProcessingTime': instance.averageProcessingTime?.inMicroseconds,
      'messagesPerSecond': instance.messagesPerSecond,
    };

_$QueueProcessingResultImpl _$$QueueProcessingResultImplFromJson(
        Map<String, dynamic> json) =>
    _$QueueProcessingResultImpl(
      messageId: json['messageId'] as String,
      success: json['success'] as bool,
      processingTime:
          Duration(microseconds: (json['processingTime'] as num).toInt()),
      error: json['error'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$QueueProcessingResultImplToJson(
        _$QueueProcessingResultImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'success': instance.success,
      'processingTime': instance.processingTime.inMicroseconds,
      'error': instance.error,
      'metadata': instance.metadata,
    };
