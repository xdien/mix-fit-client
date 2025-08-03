import 'package:freezed_annotation/freezed_annotation.dart';

part 'environment_config.freezed.dart';
part 'environment_config.g.dart';

@freezed
class EnvironmentConfig with _$EnvironmentConfig {
  @JsonSerializable(explicitToJson: true)
  const factory EnvironmentConfig({
    required EnvironmentInfo environment,
    required AppEnvironmentConfig app,
    required NetworkConfig network,
    WebSocketEnvironmentConfig? websocket,
    BuildConfig? build,
    SigningConfig? signing,
    DistributionConfig? distribution,
    NotificationConfig? notifications,
  }) = _EnvironmentConfig;

  factory EnvironmentConfig.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentConfigFromJson(json);
}

@freezed
class EnvironmentInfo with _$EnvironmentInfo {
  const factory EnvironmentInfo({
    required String name,
    @JsonKey(name: 'display_name') required String displayName,
  }) = _EnvironmentInfo;

  factory EnvironmentInfo.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentInfoFromJson(json);
}

@freezed
class AppEnvironmentConfig with _$AppEnvironmentConfig {
  const factory AppEnvironmentConfig({
    required String name,
    @JsonKey(name: 'bundle_id') required String bundleId,
    @JsonKey(name: 'version_name') String? versionName,
    @JsonKey(name: 'version_code') int? versionCode,
  }) = _AppEnvironmentConfig;

  factory AppEnvironmentConfig.fromJson(Map<String, dynamic> json) =>
      _$AppEnvironmentConfigFromJson(json);
}

@freezed
class NetworkConfig with _$NetworkConfig {
  const factory NetworkConfig({
    @JsonKey(name: 'api_base_url') required String apiBaseUrl,
    @JsonKey(name: 'websocket_url') String? websocketUrl,
    @Default(30000) int timeout,
  }) = _NetworkConfig;

  factory NetworkConfig.fromJson(Map<String, dynamic> json) =>
      _$NetworkConfigFromJson(json);
}

@freezed
class BuildConfig with _$BuildConfig {
  const factory BuildConfig({
    String? flavor,
    @JsonKey(name: 'build_type') String? buildType,
    @Default(false) bool obfuscate,
    @JsonKey(name: 'shrink_resources') @Default(false) bool shrinkResources,
  }) = _BuildConfig;

  factory BuildConfig.fromJson(Map<String, dynamic> json) =>
      _$BuildConfigFromJson(json);
}

@freezed
class SigningConfig with _$SigningConfig {
  const factory SigningConfig({
    @JsonKey(name: 'store_file') String? storeFile,
    @JsonKey(name: 'store_password_env') String? storePasswordEnv,
    @JsonKey(name: 'key_alias') String? keyAlias,
    @JsonKey(name: 'key_password_env') String? keyPasswordEnv,
  }) = _SigningConfig;

  factory SigningConfig.fromJson(Map<String, dynamic> json) =>
      _$SigningConfigFromJson(json);
}

@freezed
class DistributionConfig with _$DistributionConfig {
  const factory DistributionConfig({
    String? platform,
    String? track,
  }) = _DistributionConfig;

  factory DistributionConfig.fromJson(Map<String, dynamic> json) =>
      _$DistributionConfigFromJson(json);
}

@freezed
class NotificationConfig with _$NotificationConfig {
  const factory NotificationConfig({
    @JsonKey(name: 'slack_webhook') String? slackWebhook,
    @JsonKey(name: 'email_recipients') List<String>? emailRecipients,
  }) = _NotificationConfig;

  factory NotificationConfig.fromJson(Map<String, dynamic> json) =>
      _$NotificationConfigFromJson(json);
}

@freezed
class WebSocketEnvironmentConfig with _$WebSocketEnvironmentConfig {
  const factory WebSocketEnvironmentConfig({
    @Default(true) bool enabled,
    @JsonKey(name: 'auto_connect') @Default(true) bool autoConnect,
    @JsonKey(name: 'reconnect_interval') @Default(5000) int reconnectInterval,
    @JsonKey(name: 'max_reconnect_attempts') @Default(5) int maxReconnectAttempts,
    @JsonKey(name: 'heartbeat_interval') @Default(30000) int heartbeatInterval,
    @JsonKey(name: 'connection_timeout') @Default(10000) int connectionTimeout,
    @JsonKey(name: 'message_queue_size') @Default(1000) int messageQueueSize,
    @Default([]) List<String> channels,
    WebSocketFeatureFlags? features,
  }) = _WebSocketEnvironmentConfig;

  factory WebSocketEnvironmentConfig.fromJson(Map<String, dynamic> json) =>
      _$WebSocketEnvironmentConfigFromJson(json);
}

@freezed
class WebSocketFeatureFlags with _$WebSocketFeatureFlags {
  const factory WebSocketFeatureFlags({
    @JsonKey(name: 'real_time_updates') @Default(true) bool realTimeUpdates,
    @JsonKey(name: 'offline_support') @Default(true) bool offlineSupport,
    @JsonKey(name: 'background_sync') @Default(true) bool backgroundSync,
    @JsonKey(name: 'push_notifications') @Default(true) bool pushNotifications,
  }) = _WebSocketFeatureFlags;

  factory WebSocketFeatureFlags.fromJson(Map<String, dynamic> json) =>
      _$WebSocketFeatureFlagsFromJson(json);
}