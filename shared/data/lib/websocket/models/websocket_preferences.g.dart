// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketPreferencesImpl _$$WebSocketPreferencesImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketPreferencesImpl(
      enableRealTimeUpdates: json['enableRealTimeUpdates'] as bool? ?? true,
      showConnectionStatus: json['showConnectionStatus'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      subscribedMessageTypes: (json['subscribedMessageTypes'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$WebSocketMessageTypeEnumMap, e))
              .toSet() ??
          const {},
      subscribedChannels: (json['subscribedChannels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      messagePriorities:
          (json['messagePriorities'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(
                    $enumDecode(_$WebSocketMessageTypeEnumMap, k),
                    (e as num).toInt()),
              ) ??
              const {},
      enableSoundNotifications:
          json['enableSoundNotifications'] as bool? ?? false,
      enableVibrationNotifications:
          json['enableVibrationNotifications'] as bool? ?? true,
      showForegroundNotifications:
          json['showForegroundNotifications'] as bool? ?? true,
      enableOfflineMessageQueue:
          json['enableOfflineMessageQueue'] as bool? ?? true,
      maxQueuedMessages: (json['maxQueuedMessages'] as num?)?.toInt() ?? 100,
      enableAutoReconnect: json['enableAutoReconnect'] as bool? ?? true,
      heartbeatIntervalSeconds:
          (json['heartbeatIntervalSeconds'] as num?)?.toInt() ?? 30,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$WebSocketPreferencesImplToJson(
        _$WebSocketPreferencesImpl instance) =>
    <String, dynamic>{
      'enableRealTimeUpdates': instance.enableRealTimeUpdates,
      'showConnectionStatus': instance.showConnectionStatus,
      'enableNotifications': instance.enableNotifications,
      'subscribedMessageTypes': instance.subscribedMessageTypes
          .map((e) => _$WebSocketMessageTypeEnumMap[e]!)
          .toList(),
      'subscribedChannels': instance.subscribedChannels.toList(),
      'messagePriorities': instance.messagePriorities
          .map((k, e) => MapEntry(_$WebSocketMessageTypeEnumMap[k]!, e)),
      'enableSoundNotifications': instance.enableSoundNotifications,
      'enableVibrationNotifications': instance.enableVibrationNotifications,
      'showForegroundNotifications': instance.showForegroundNotifications,
      'enableOfflineMessageQueue': instance.enableOfflineMessageQueue,
      'maxQueuedMessages': instance.maxQueuedMessages,
      'enableAutoReconnect': instance.enableAutoReconnect,
      'heartbeatIntervalSeconds': instance.heartbeatIntervalSeconds,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };

const _$WebSocketMessageTypeEnumMap = {
  WebSocketMessageType.customerUpdate: 'customerUpdate',
  WebSocketMessageType.inventoryUpdate: 'inventoryUpdate',
  WebSocketMessageType.orderStatusUpdate: 'orderStatusUpdate',
  WebSocketMessageType.systemNotification: 'systemNotification',
  WebSocketMessageType.userSpecific: 'userSpecific',
  WebSocketMessageType.unknown: 'unknown',
};
