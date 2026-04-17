/// Centralized management of all environment variables
/// This class provides a single source of truth for all environment variable access
class EnvironmentVariables {
  EnvironmentVariables._();

  // API Configuration
  static const String apiEndpoint = String.fromEnvironment(
    'API_ENDPOINT',
    defaultValue: 'http://localhost:3000/api',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  // WebSocket Configuration
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const bool websocketEnabled = bool.fromEnvironment(
    'WEBSOCKET_ENABLED',
    defaultValue: true,
  );

  static const bool websocketAutoConnect = bool.fromEnvironment(
    'WEBSOCKET_AUTO_CONNECT',
    defaultValue: true,
  );

  static const int websocketReconnectInterval = int.fromEnvironment(
    'WEBSOCKET_RECONNECT_INTERVAL',
    defaultValue: 5000,
  );

  static const int websocketMaxReconnectAttempts = int.fromEnvironment(
    'WEBSOCKET_MAX_RECONNECT_ATTEMPTS',
    defaultValue: 5,
  );

  static const int websocketHeartbeatInterval = int.fromEnvironment(
    'WEBSOCKET_HEARTBEAT_INTERVAL',
    defaultValue: 30000,
  );

  static const int websocketConnectionTimeout = int.fromEnvironment(
    'WEBSOCKET_CONNECTION_TIMEOUT',
    defaultValue: 10000,
  );

  static const int websocketMessageQueueSize = int.fromEnvironment(
    'WEBSOCKET_MESSAGE_QUEUE_SIZE',
    defaultValue: 1000,
  );

  // WebSocket Feature Flags
  static const bool websocketRealTimeUpdates = bool.fromEnvironment(
    'WEBSOCKET_REAL_TIME_UPDATES',
    defaultValue: true,
  );

  static const bool websocketOfflineSupport = bool.fromEnvironment(
    'WEBSOCKET_OFFLINE_SUPPORT',
    defaultValue: true,
  );

  static const bool websocketBackgroundSync = bool.fromEnvironment(
    'WEBSOCKET_BACKGROUND_SYNC',
    defaultValue: true,
  );

  static const bool websocketPushNotifications = bool.fromEnvironment(
    'WEBSOCKET_PUSH_NOTIFICATIONS',
    defaultValue: true,
  );

  // App Configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Mix Fit',
  );

  static const String bundleId = String.fromEnvironment(
    'BUNDLE_ID',
    defaultValue: 'com.xdien.mixfit.dev',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Network Configuration
  static const int networkTimeout = int.fromEnvironment(
    'NETWORK_TIMEOUT',
    defaultValue: 30000,
  );

  static const int connectionTimeout = int.fromEnvironment(
    'CONNECTION_TIMEOUT',
    defaultValue: 30000,
  );

  static const int receiveTimeout = int.fromEnvironment(
    'RECEIVE_TIMEOUT',
    defaultValue: 15000,
  );

  // Build Configuration
  static const String buildFlavor = String.fromEnvironment(
    'BUILD_FLAVOR',
    defaultValue: 'development',
  );

  static const String buildType = String.fromEnvironment(
    'BUILD_TYPE',
    defaultValue: 'debug',
  );

  static const bool buildObfuscate = bool.fromEnvironment(
    'BUILD_OBFUSCATE',
    defaultValue: false,
  );

  static const bool buildShrinkResources = bool.fromEnvironment(
    'BUILD_SHRINK_RESOURCES',
    defaultValue: false,
  );

  // Signing Configuration
  static const String signingStoreFile = String.fromEnvironment(
    'SIGNING_STORE_FILE',
    defaultValue: '',
  );

  static const String signingStorePasswordEnv = String.fromEnvironment(
    'SIGNING_STORE_PASSWORD_ENV',
    defaultValue: 'KEYSTORE_PASSWORD',
  );

  static const String signingKeyAlias = String.fromEnvironment(
    'SIGNING_KEY_ALIAS',
    defaultValue: '',
  );

  static const String signingKeyPasswordEnv = String.fromEnvironment(
    'SIGNING_KEY_PASSWORD_ENV',
    defaultValue: 'KEY_PASSWORD',
  );

  // Distribution Configuration
  static const String distributionPlatform = String.fromEnvironment(
    'DISTRIBUTION_PLATFORM',
    defaultValue: '',
  );

  static const String distributionTrack = String.fromEnvironment(
    'DISTRIBUTION_TRACK',
    defaultValue: '',
  );

  // Notification Configuration
  static const String notificationSlackWebhook = String.fromEnvironment(
    'NOTIFICATION_SLACK_WEBHOOK',
    defaultValue: '',
  );

  static const String notificationEmailRecipients = String.fromEnvironment(
    'NOTIFICATION_EMAIL_RECIPIENTS',
    defaultValue: '',
  );

  /// Get all environment variables as a map for debugging
  static Map<String, dynamic> toMap() {
    return {
      // API Configuration
      'apiEndpoint': apiEndpoint,
      'apiBaseUrl': apiBaseUrl,
      'apiKey': apiKey.isNotEmpty ? '***' : 'not_set',
      
      // WebSocket Configuration
      'websocketUrl': websocketUrl,
      'websocketEnabled': websocketEnabled,
      'websocketAutoConnect': websocketAutoConnect,
      'websocketReconnectInterval': websocketReconnectInterval,
      'websocketMaxReconnectAttempts': websocketMaxReconnectAttempts,
      'websocketHeartbeatInterval': websocketHeartbeatInterval,
      'websocketConnectionTimeout': websocketConnectionTimeout,
      'websocketMessageQueueSize': websocketMessageQueueSize,
      
      // WebSocket Feature Flags
      'websocketRealTimeUpdates': websocketRealTimeUpdates,
      'websocketOfflineSupport': websocketOfflineSupport,
      'websocketBackgroundSync': websocketBackgroundSync,
      'websocketPushNotifications': websocketPushNotifications,
      
      // App Configuration
      'appName': appName,
      'bundleId': bundleId,
      'environment': environment,
      
      // Network Configuration
      'networkTimeout': networkTimeout,
      'connectionTimeout': connectionTimeout,
      'receiveTimeout': receiveTimeout,
      
      // Build Configuration
      'buildFlavor': buildFlavor,
      'buildType': buildType,
      'buildObfuscate': buildObfuscate,
      'buildShrinkResources': buildShrinkResources,
      
      // Signing Configuration
      'signingStoreFile': signingStoreFile.isNotEmpty ? '***' : 'not_set',
      'signingStorePasswordEnv': signingStorePasswordEnv,
      'signingKeyAlias': signingKeyAlias.isNotEmpty ? '***' : 'not_set',
      'signingKeyPasswordEnv': signingKeyPasswordEnv,
      
      // Distribution Configuration
      'distributionPlatform': distributionPlatform,
      'distributionTrack': distributionTrack,
      
      // Notification Configuration
      'notificationSlackWebhook': notificationSlackWebhook.isNotEmpty ? '***' : 'not_set',
      'notificationEmailRecipients': notificationEmailRecipients,
    };
  }

  @override
  String toString() {
    return 'EnvironmentVariables(${toMap()})';
  }
}
