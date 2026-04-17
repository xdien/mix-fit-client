import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_subscription.freezed.dart';

@Freezed(toJson: false, fromJson: false)
class WebSocketSubscription with _$WebSocketSubscription {
  const factory WebSocketSubscription({
    required String channel,
    required Function(dynamic) callback,
    required DateTime subscribedAt,
    @Default(true) bool isActive,
  }) = _WebSocketSubscription;
}