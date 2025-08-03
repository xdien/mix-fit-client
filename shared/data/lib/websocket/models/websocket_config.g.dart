// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketConfigImpl _$$WebSocketConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketConfigImpl(
      url: json['url'] as String,
      reconnectInterval:
          Duration(microseconds: (json['reconnectInterval'] as num).toInt()),
      maxReconnectAttempts: (json['maxReconnectAttempts'] as num).toInt(),
      heartbeatInterval:
          Duration(microseconds: (json['heartbeatInterval'] as num).toInt()),
      autoReconnect: json['autoReconnect'] as bool? ?? true,
    );

Map<String, dynamic> _$$WebSocketConfigImplToJson(
        _$WebSocketConfigImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'reconnectInterval': instance.reconnectInterval.inMicroseconds,
      'maxReconnectAttempts': instance.maxReconnectAttempts,
      'heartbeatInterval': instance.heartbeatInterval.inMicroseconds,
      'autoReconnect': instance.autoReconnect,
    };
