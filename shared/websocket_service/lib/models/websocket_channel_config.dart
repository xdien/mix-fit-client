import 'package:freezed_annotation/freezed_annotation.dart';
import 'websocket_preferences.dart';

part 'websocket_channel_config.freezed.dart';
part 'websocket_channel_config.g.dart';

@freezed
class WebSocketChannelConfig with _$WebSocketChannelConfig {
  const factory WebSocketChannelConfig({
    required String id,
    required String name,
    required String description,
    required WebSocketChannelType type,
    @Default(true) bool userConfigurable,
    @Default(NotificationPriority.normal) NotificationPriority defaultPriority,
    @Default(true) bool defaultEnabled,
  }) = _WebSocketChannelConfig;

  factory WebSocketChannelConfig.fromJson(Map<String, dynamic> json) =>
      _$WebSocketChannelConfigFromJson(json);
}

enum WebSocketChannelType {
  @JsonValue('customer')
  customer,
  @JsonValue('inventory')
  inventory,
  @JsonValue('order')
  order,
  @JsonValue('system')
  system,
  @JsonValue('notification')
  notification,
}

extension WebSocketChannelTypeExtension on WebSocketChannelType {
  String get displayName {
    switch (this) {
      case WebSocketChannelType.customer:
        return 'Customer Updates';
      case WebSocketChannelType.inventory:
        return 'Inventory Changes';
      case WebSocketChannelType.order:
        return 'Order Status';
      case WebSocketChannelType.system:
        return 'System Notifications';
      case WebSocketChannelType.notification:
        return 'General Notifications';
    }
  }

  String get description {
    switch (this) {
      case WebSocketChannelType.customer:
        return 'Real-time updates for customer information changes';
      case WebSocketChannelType.inventory:
        return 'Live inventory level changes and stock updates';
      case WebSocketChannelType.order:
        return 'Order status changes and fulfillment updates';
      case WebSocketChannelType.system:
        return 'System-wide notifications and alerts';
      case WebSocketChannelType.notification:
        return 'General application notifications';
    }
  }
}