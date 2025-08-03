// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnvironmentConfigImpl _$$EnvironmentConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$EnvironmentConfigImpl(
      environment:
          EnvironmentInfo.fromJson(json['environment'] as Map<String, dynamic>),
      app: AppEnvironmentConfig.fromJson(json['app'] as Map<String, dynamic>),
      network: NetworkConfig.fromJson(json['network'] as Map<String, dynamic>),
      websocket: json['websocket'] == null
          ? null
          : WebSocketEnvironmentConfig.fromJson(
              json['websocket'] as Map<String, dynamic>),
      build: json['build'] == null
          ? null
          : BuildConfig.fromJson(json['build'] as Map<String, dynamic>),
      signing: json['signing'] == null
          ? null
          : SigningConfig.fromJson(json['signing'] as Map<String, dynamic>),
      distribution: json['distribution'] == null
          ? null
          : DistributionConfig.fromJson(
              json['distribution'] as Map<String, dynamic>),
      notifications: json['notifications'] == null
          ? null
          : NotificationConfig.fromJson(
              json['notifications'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$EnvironmentConfigImplToJson(
        _$EnvironmentConfigImpl instance) =>
    <String, dynamic>{
      'environment': instance.environment.toJson(),
      'app': instance.app.toJson(),
      'network': instance.network.toJson(),
      'websocket': instance.websocket?.toJson(),
      'build': instance.build?.toJson(),
      'signing': instance.signing?.toJson(),
      'distribution': instance.distribution?.toJson(),
      'notifications': instance.notifications?.toJson(),
    };

_$EnvironmentInfoImpl _$$EnvironmentInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$EnvironmentInfoImpl(
      name: json['name'] as String,
      displayName: json['display_name'] as String,
    );

Map<String, dynamic> _$$EnvironmentInfoImplToJson(
        _$EnvironmentInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'display_name': instance.displayName,
    };

_$AppEnvironmentConfigImpl _$$AppEnvironmentConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$AppEnvironmentConfigImpl(
      name: json['name'] as String,
      bundleId: json['bundle_id'] as String,
      versionName: json['version_name'] as String?,
      versionCode: (json['version_code'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$AppEnvironmentConfigImplToJson(
        _$AppEnvironmentConfigImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'bundle_id': instance.bundleId,
      'version_name': instance.versionName,
      'version_code': instance.versionCode,
    };

_$NetworkConfigImpl _$$NetworkConfigImplFromJson(Map<String, dynamic> json) =>
    _$NetworkConfigImpl(
      apiBaseUrl: json['api_base_url'] as String,
      websocketUrl: json['websocket_url'] as String?,
      timeout: (json['timeout'] as num?)?.toInt() ?? 30000,
    );

Map<String, dynamic> _$$NetworkConfigImplToJson(_$NetworkConfigImpl instance) =>
    <String, dynamic>{
      'api_base_url': instance.apiBaseUrl,
      'websocket_url': instance.websocketUrl,
      'timeout': instance.timeout,
    };

_$BuildConfigImpl _$$BuildConfigImplFromJson(Map<String, dynamic> json) =>
    _$BuildConfigImpl(
      flavor: json['flavor'] as String?,
      buildType: json['build_type'] as String?,
      obfuscate: json['obfuscate'] as bool? ?? false,
      shrinkResources: json['shrink_resources'] as bool? ?? false,
    );

Map<String, dynamic> _$$BuildConfigImplToJson(_$BuildConfigImpl instance) =>
    <String, dynamic>{
      'flavor': instance.flavor,
      'build_type': instance.buildType,
      'obfuscate': instance.obfuscate,
      'shrink_resources': instance.shrinkResources,
    };

_$SigningConfigImpl _$$SigningConfigImplFromJson(Map<String, dynamic> json) =>
    _$SigningConfigImpl(
      storeFile: json['store_file'] as String?,
      storePasswordEnv: json['store_password_env'] as String?,
      keyAlias: json['key_alias'] as String?,
      keyPasswordEnv: json['key_password_env'] as String?,
    );

Map<String, dynamic> _$$SigningConfigImplToJson(_$SigningConfigImpl instance) =>
    <String, dynamic>{
      'store_file': instance.storeFile,
      'store_password_env': instance.storePasswordEnv,
      'key_alias': instance.keyAlias,
      'key_password_env': instance.keyPasswordEnv,
    };

_$DistributionConfigImpl _$$DistributionConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$DistributionConfigImpl(
      platform: json['platform'] as String?,
      track: json['track'] as String?,
    );

Map<String, dynamic> _$$DistributionConfigImplToJson(
        _$DistributionConfigImpl instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'track': instance.track,
    };

_$NotificationConfigImpl _$$NotificationConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationConfigImpl(
      slackWebhook: json['slack_webhook'] as String?,
      emailRecipients: (json['email_recipients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$NotificationConfigImplToJson(
        _$NotificationConfigImpl instance) =>
    <String, dynamic>{
      'slack_webhook': instance.slackWebhook,
      'email_recipients': instance.emailRecipients,
    };

_$WebSocketEnvironmentConfigImpl _$$WebSocketEnvironmentConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketEnvironmentConfigImpl(
      enabled: json['enabled'] as bool? ?? true,
      autoConnect: json['auto_connect'] as bool? ?? true,
      reconnectInterval: (json['reconnect_interval'] as num?)?.toInt() ?? 5000,
      maxReconnectAttempts:
          (json['max_reconnect_attempts'] as num?)?.toInt() ?? 5,
      heartbeatInterval: (json['heartbeat_interval'] as num?)?.toInt() ?? 30000,
      connectionTimeout: (json['connection_timeout'] as num?)?.toInt() ?? 10000,
      messageQueueSize: (json['message_queue_size'] as num?)?.toInt() ?? 1000,
      channels: (json['channels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      features: json['features'] == null
          ? null
          : WebSocketFeatureFlags.fromJson(
              json['features'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$WebSocketEnvironmentConfigImplToJson(
        _$WebSocketEnvironmentConfigImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'auto_connect': instance.autoConnect,
      'reconnect_interval': instance.reconnectInterval,
      'max_reconnect_attempts': instance.maxReconnectAttempts,
      'heartbeat_interval': instance.heartbeatInterval,
      'connection_timeout': instance.connectionTimeout,
      'message_queue_size': instance.messageQueueSize,
      'channels': instance.channels,
      'features': instance.features,
    };

_$WebSocketFeatureFlagsImpl _$$WebSocketFeatureFlagsImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSocketFeatureFlagsImpl(
      realTimeUpdates: json['real_time_updates'] as bool? ?? true,
      offlineSupport: json['offline_support'] as bool? ?? true,
      backgroundSync: json['background_sync'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
    );

Map<String, dynamic> _$$WebSocketFeatureFlagsImplToJson(
        _$WebSocketFeatureFlagsImpl instance) =>
    <String, dynamic>{
      'real_time_updates': instance.realTimeUpdates,
      'offline_support': instance.offlineSupport,
      'background_sync': instance.backgroundSync,
      'push_notifications': instance.pushNotifications,
    };
