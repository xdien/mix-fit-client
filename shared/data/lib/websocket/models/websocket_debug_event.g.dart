// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_debug_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketDebugEventImpl _$$WebSocketDebugEventImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketDebugEventImpl(
      type: $enumDecode(_$WebSocketDebugEventTypeEnumMap, json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      connectionState: $enumDecodeNullable(
          _$WebSocketConnectionStateEnumMap, json['connectionState']),
      channel: json['channel'] as String?,
      duration: json['duration'] == null
          ? null
          : Duration(microseconds: (json['duration'] as num).toInt()),
      attemptNumber: (json['attemptNumber'] as num?)?.toInt(),
      instanceId: json['instanceId'] as String?,
    );

Map<String, dynamic> _$$WebSocketDebugEventImplToJson(
        _$WebSocketDebugEventImpl instance) =>
    <String, dynamic>{
      'type': _$WebSocketDebugEventTypeEnumMap[instance.type]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'message': instance.message,
      'data': instance.data,
      'connectionState':
          _$WebSocketConnectionStateEnumMap[instance.connectionState],
      'channel': instance.channel,
      'duration': instance.duration?.inMicroseconds,
      'attemptNumber': instance.attemptNumber,
      'instanceId': instance.instanceId,
    };

const _$WebSocketDebugEventTypeEnumMap = {
  WebSocketDebugEventType.connectionAttempt: 'connectionAttempt',
  WebSocketDebugEventType.connectionSuccess: 'connectionSuccess',
  WebSocketDebugEventType.connectionFailure: 'connectionFailure',
  WebSocketDebugEventType.disconnection: 'disconnection',
  WebSocketDebugEventType.messageReceived: 'messageReceived',
  WebSocketDebugEventType.messageSent: 'messageSent',
  WebSocketDebugEventType.subscriptionAdded: 'subscriptionAdded',
  WebSocketDebugEventType.subscriptionRemoved: 'subscriptionRemoved',
  WebSocketDebugEventType.stateChange: 'stateChange',
  WebSocketDebugEventType.error: 'error',
  WebSocketDebugEventType.heartbeat: 'heartbeat',
  WebSocketDebugEventType.authentication: 'authentication',
  WebSocketDebugEventType.tokenRefresh: 'tokenRefresh',
  WebSocketDebugEventType.networkChange: 'networkChange',
  WebSocketDebugEventType.appLifecycleChange: 'appLifecycleChange',
  WebSocketDebugEventType.configurationChange: 'configurationChange',
};

const _$WebSocketConnectionStateEnumMap = {
  WebSocketConnectionState.disconnected: 'disconnected',
  WebSocketConnectionState.connecting: 'connecting',
  WebSocketConnectionState.connected: 'connected',
  WebSocketConnectionState.reconnecting: 'reconnecting',
  WebSocketConnectionState.error: 'error',
};

_$WebSocketDebugSessionImpl _$$WebSocketDebugSessionImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketDebugSessionImpl(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      events: (json['events'] as List<dynamic>)
          .map((e) => WebSocketDebugEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$WebSocketDebugSessionImplToJson(
        _$WebSocketDebugSessionImpl instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'events': instance.events,
      'metadata': instance.metadata,
    };

_$WebSocketDebugConfigImpl _$$WebSocketDebugConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketDebugConfigImpl(
      enableLogging: json['enableLogging'] as bool? ?? false,
      enableEventTracking: json['enableEventTracking'] as bool? ?? false,
      enablePerformanceMonitoring:
          json['enablePerformanceMonitoring'] as bool? ?? false,
      enableErrorAnalytics: json['enableErrorAnalytics'] as bool? ?? false,
      maxEventsInMemory: (json['maxEventsInMemory'] as num?)?.toInt() ?? 1000,
      logLevel: $enumDecodeNullable(
              _$WebSocketDebugLogLevelEnumMap, json['logLevel']) ??
          WebSocketDebugLogLevel.info,
      trackedEventTypes: (json['trackedEventTypes'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$WebSocketDebugEventTypeEnumMap, e))
              .toList() ??
          const [],
      enableConsoleOutput: json['enableConsoleOutput'] as bool? ?? true,
      enableFileLogging: json['enableFileLogging'] as bool? ?? false,
      fileLoggingPath: json['fileLoggingPath'] as String?,
    );

Map<String, dynamic> _$$WebSocketDebugConfigImplToJson(
        _$WebSocketDebugConfigImpl instance) =>
    <String, dynamic>{
      'enableLogging': instance.enableLogging,
      'enableEventTracking': instance.enableEventTracking,
      'enablePerformanceMonitoring': instance.enablePerformanceMonitoring,
      'enableErrorAnalytics': instance.enableErrorAnalytics,
      'maxEventsInMemory': instance.maxEventsInMemory,
      'logLevel': _$WebSocketDebugLogLevelEnumMap[instance.logLevel]!,
      'trackedEventTypes': instance.trackedEventTypes
          .map((e) => _$WebSocketDebugEventTypeEnumMap[e]!)
          .toList(),
      'enableConsoleOutput': instance.enableConsoleOutput,
      'enableFileLogging': instance.enableFileLogging,
      'fileLoggingPath': instance.fileLoggingPath,
    };

const _$WebSocketDebugLogLevelEnumMap = {
  WebSocketDebugLogLevel.verbose: 'verbose',
  WebSocketDebugLogLevel.debug: 'debug',
  WebSocketDebugLogLevel.info: 'info',
  WebSocketDebugLogLevel.warning: 'warning',
  WebSocketDebugLogLevel.error: 'error',
};
