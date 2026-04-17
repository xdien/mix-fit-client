// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketMetricsImpl _$$WebSocketMetricsImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketMetricsImpl(
      connectionAttempts: (json['connectionAttempts'] as num?)?.toInt() ?? 0,
      successfulConnections:
          (json['successfulConnections'] as num?)?.toInt() ?? 0,
      failedConnections: (json['failedConnections'] as num?)?.toInt() ?? 0,
      reconnectionAttempts:
          (json['reconnectionAttempts'] as num?)?.toInt() ?? 0,
      messagesSent: (json['messagesSent'] as num?)?.toInt() ?? 0,
      messagesReceived: (json['messagesReceived'] as num?)?.toInt() ?? 0,
      subscriptions: (json['subscriptions'] as num?)?.toInt() ?? 0,
      unsubscriptions: (json['unsubscriptions'] as num?)?.toInt() ?? 0,
      totalUptimeMs: (json['totalUptimeMs'] as num?)?.toInt() ?? 0,
      currentConnectionDurationMs:
          (json['currentConnectionDurationMs'] as num?)?.toInt() ?? 0,
      averageConnectionDurationMs:
          (json['averageConnectionDurationMs'] as num?)?.toDouble() ?? 0,
      averageMessageProcessingTimeMs:
          (json['averageMessageProcessingTimeMs'] as num?)?.toDouble() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      heartbeatTimeouts: (json['heartbeatTimeouts'] as num?)?.toInt() ?? 0,
      authenticationFailures:
          (json['authenticationFailures'] as num?)?.toInt() ?? 0,
      networkErrors: (json['networkErrors'] as num?)?.toInt() ?? 0,
      lastConnectionTime: json['lastConnectionTime'] == null
          ? null
          : DateTime.parse(json['lastConnectionTime'] as String),
      lastDisconnectionTime: json['lastDisconnectionTime'] == null
          ? null
          : DateTime.parse(json['lastDisconnectionTime'] as String),
      lastErrorTime: json['lastErrorTime'] == null
          ? null
          : DateTime.parse(json['lastErrorTime'] as String),
      connectionQualityScore:
          (json['connectionQualityScore'] as num?)?.toInt() ?? 0,
      dataTransfer: json['dataTransfer'] == null
          ? const WebSocketDataTransferStats()
          : WebSocketDataTransferStats.fromJson(
              json['dataTransfer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$WebSocketMetricsImplToJson(
        _$WebSocketMetricsImpl instance) =>
    <String, dynamic>{
      'connectionAttempts': instance.connectionAttempts,
      'successfulConnections': instance.successfulConnections,
      'failedConnections': instance.failedConnections,
      'reconnectionAttempts': instance.reconnectionAttempts,
      'messagesSent': instance.messagesSent,
      'messagesReceived': instance.messagesReceived,
      'subscriptions': instance.subscriptions,
      'unsubscriptions': instance.unsubscriptions,
      'totalUptimeMs': instance.totalUptimeMs,
      'currentConnectionDurationMs': instance.currentConnectionDurationMs,
      'averageConnectionDurationMs': instance.averageConnectionDurationMs,
      'averageMessageProcessingTimeMs': instance.averageMessageProcessingTimeMs,
      'errorCount': instance.errorCount,
      'heartbeatTimeouts': instance.heartbeatTimeouts,
      'authenticationFailures': instance.authenticationFailures,
      'networkErrors': instance.networkErrors,
      'lastConnectionTime': instance.lastConnectionTime?.toIso8601String(),
      'lastDisconnectionTime':
          instance.lastDisconnectionTime?.toIso8601String(),
      'lastErrorTime': instance.lastErrorTime?.toIso8601String(),
      'connectionQualityScore': instance.connectionQualityScore,
      'dataTransfer': instance.dataTransfer,
    };

_$WebSocketDataTransferStatsImpl _$$WebSocketDataTransferStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketDataTransferStatsImpl(
      bytesSent: (json['bytesSent'] as num?)?.toInt() ?? 0,
      bytesReceived: (json['bytesReceived'] as num?)?.toInt() ?? 0,
      averageMessageSize: (json['averageMessageSize'] as num?)?.toDouble() ?? 0,
      peakMessageRate: (json['peakMessageRate'] as num?)?.toDouble() ?? 0,
      currentMessageRate: (json['currentMessageRate'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$WebSocketDataTransferStatsImplToJson(
        _$WebSocketDataTransferStatsImpl instance) =>
    <String, dynamic>{
      'bytesSent': instance.bytesSent,
      'bytesReceived': instance.bytesReceived,
      'averageMessageSize': instance.averageMessageSize,
      'peakMessageRate': instance.peakMessageRate,
      'currentMessageRate': instance.currentMessageRate,
    };

_$WebSocketHealthCheckImpl _$$WebSocketHealthCheckImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketHealthCheckImpl(
      status: $enumDecode(_$WebSocketHealthStatusEnumMap, json['status']),
      score: (json['score'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      issues:
          (json['issues'] as List<dynamic>).map((e) => e as String).toList(),
      details: json['details'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$WebSocketHealthCheckImplToJson(
        _$WebSocketHealthCheckImpl instance) =>
    <String, dynamic>{
      'status': _$WebSocketHealthStatusEnumMap[instance.status]!,
      'score': instance.score,
      'timestamp': instance.timestamp.toIso8601String(),
      'issues': instance.issues,
      'details': instance.details,
    };

const _$WebSocketHealthStatusEnumMap = {
  WebSocketHealthStatus.excellent: 'excellent',
  WebSocketHealthStatus.good: 'good',
  WebSocketHealthStatus.fair: 'fair',
  WebSocketHealthStatus.poor: 'poor',
  WebSocketHealthStatus.critical: 'critical',
};
