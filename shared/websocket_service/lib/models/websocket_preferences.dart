import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_preferences.freezed.dart';
part 'websocket_preferences.g.dart';

@freezed
class WebSocketPreferences with _$WebSocketPreferences {
  const factory WebSocketPreferences({
    @Default(true) bool enableRealTimeUpdates,
    @Default({}) Set<String> subscribedChannels,
    @Default(true) bool showConnectionStatus,
    @Default(true) bool enableNotifications,
    @Default({}) Map<String, bool> channelPreferences,
    @Default({}) Map<String, NotificationPriority> notificationPriorities,
  }) = _WebSocketPreferences;

  factory WebSocketPreferences.fromJson(Map<String, dynamic> json) =>
      _$WebSocketPreferencesFromJson(json);
}

@freezed
class WebSocketChannelPreference with _$WebSocketChannelPreference {
  const factory WebSocketChannelPreference({
    required String channelId,
    required String displayName,
    required String description,
    @Default(true) bool enabled,
    @Default(NotificationPriority.normal) NotificationPriority priority,
    @Default(true) bool showInUI,
  }) = _WebSocketChannelPreference;

  factory WebSocketChannelPreference.fromJson(Map<String, dynamic> json) =>
      _$WebSocketChannelPreferenceFromJson(json);
}

enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.critical:
        return 'Critical';
    }
  }

  int get value {
    switch (this) {
      case NotificationPriority.low:
        return 1;
      case NotificationPriority.normal:
        return 2;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.critical:
        return 4;
    }
  }
}