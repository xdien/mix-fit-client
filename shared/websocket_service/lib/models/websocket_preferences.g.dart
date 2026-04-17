// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSocketPreferencesImpl _$$WebSocketPreferencesImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketPreferencesImpl(
      enableRealTimeUpdates: json['enableRealTimeUpdates'] as bool? ?? true,
      subscribedChannels: (json['subscribedChannels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      showConnectionStatus: json['showConnectionStatus'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      channelPreferences:
          (json['channelPreferences'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, e as bool),
              ) ??
              const {},
      notificationPriorities:
          (json['notificationPriorities'] as Map<String, dynamic>?)?.map(
                (k, e) =>
                    MapEntry(k, $enumDecode(_$NotificationPriorityEnumMap, e)),
              ) ??
              const {},
    );

Map<String, dynamic> _$$WebSocketPreferencesImplToJson(
        _$WebSocketPreferencesImpl instance) =>
    <String, dynamic>{
      'enableRealTimeUpdates': instance.enableRealTimeUpdates,
      'subscribedChannels': instance.subscribedChannels.toList(),
      'showConnectionStatus': instance.showConnectionStatus,
      'enableNotifications': instance.enableNotifications,
      'channelPreferences': instance.channelPreferences,
      'notificationPriorities': instance.notificationPriorities
          .map((k, e) => MapEntry(k, _$NotificationPriorityEnumMap[e]!)),
    };

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.critical: 'critical',
};

_$WebSocketChannelPreferenceImpl _$$WebSocketChannelPreferenceImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketChannelPreferenceImpl(
      channelId: json['channelId'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      enabled: json['enabled'] as bool? ?? true,
      priority: $enumDecodeNullable(
              _$NotificationPriorityEnumMap, json['priority']) ??
          NotificationPriority.normal,
      showInUI: json['showInUI'] as bool? ?? true,
    );

Map<String, dynamic> _$$WebSocketChannelPreferenceImplToJson(
        _$WebSocketChannelPreferenceImpl instance) =>
    <String, dynamic>{
      'channelId': instance.channelId,
      'displayName': instance.displayName,
      'description': instance.description,
      'enabled': instance.enabled,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'showInUI': instance.showInUI,
    };
