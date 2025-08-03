import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_config.freezed.dart';
part 'websocket_config.g.dart';

@freezed
class WebSocketConfig with _$WebSocketConfig {
  const factory WebSocketConfig({
    required String url,
    required Duration reconnectInterval,
    required int maxReconnectAttempts,
    required Duration heartbeatInterval,
    @Default(true) bool autoReconnect,
  }) = _WebSocketConfig;

  factory WebSocketConfig.fromJson(Map<String, dynamic> json) =>
      _$WebSocketConfigFromJson(json);
}