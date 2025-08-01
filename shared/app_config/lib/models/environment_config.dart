import 'package:freezed_annotation/freezed_annotation.dart';

part 'environment_config.freezed.dart';
part 'environment_config.g.dart';

@freezed
class EnvironmentConfig with _$EnvironmentConfig {
  @JsonSerializable(explicitToJson: true)
  const factory EnvironmentConfig({
    required EnvironmentInfo environment,
    required AppConfig app,
    required NetworkConfig network,
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
class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String name,
    @JsonKey(name: 'bundle_id') required String bundleId,
    @JsonKey(name: 'version_name') String? versionName,
    @JsonKey(name: 'version_code') int? versionCode,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
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