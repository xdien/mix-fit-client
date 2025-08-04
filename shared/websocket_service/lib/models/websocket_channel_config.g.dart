// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_channel_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketChannelConfigImpl _$$WebSocketChannelConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketChannelConfigImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$WebSocketChannelTypeEnumMap, json['type']),
      userConfigurable: json['userConfigurable'] as bool? ?? true,
      defaultPriority: $enumDecodeNullable(
              _$NotificationPriorityEnumMap, json['defaultPriority']) ??
          NotificationPriority.normal,
      defaultEnabled: json['defaultEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$WebSocketChannelConfigImplToJson(
        _$WebSocketChannelConfigImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$WebSocketChannelTypeEnumMap[instance.type]!,
      'userConfigurable': instance.userConfigurable,
      'defaultPriority':
          _$NotificationPriorityEnumMap[instance.defaultPriority]!,
      'defaultEnabled': instance.defaultEnabled,
    };

const _$WebSocketChannelTypeEnumMap = {
  WebSocketChannelType.customer: 'customer',
  WebSocketChannelType.inventory: 'inventory',
  WebSocketChannelType.order: 'order',
  WebSocketChannelType.system: 'system',
  WebSocketChannelType.notification: 'notification',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.critical: 'critical',
};
