import 'package:app_config/app_config.dart';

class Endpoints {
  Endpoints._();

  // Get environment configuration service
  static EnvironmentConfigService get _configService => EnvironmentConfigService();

  // base url - use environment config if available, fallback to environment variable
  static String get baseUrl {
    try {
      if (_configService.isInitialized) {
        return _configService.apiBaseUrl;
      }
    } catch (e) {
      // Fallback to environment variable if config service is not available
    }
    return const String.fromEnvironment("BASE_URL", defaultValue: "http://localhost:3000");
  }

  // WebSocket URL - use environment config if available
  static String? get websocketUrl {
    try {
      if (_configService.isInitialized) {
        return _configService.websocketUrl;
      }
    } catch (e) {
      // Fallback to environment variable if config service is not available
    }
    return const String.fromEnvironment("WEBSOCKET_URL", defaultValue: "ws://localhost:3001");
  }

  // receiveTimeout - use environment config if available
  static int get receiveTimeout {
    try {
      if (_configService.isInitialized) {
        return _configService.timeout;
      }
    } catch (e) {
      // Fallback to default if config service is not available
    }
    return const int.fromEnvironment("RECEIVE_TIMEOUT", defaultValue: 15000);
  }

  // connectTimeout - use environment config if available
  static int get connectionTimeout {
    try {
      if (_configService.isInitialized) {
        return _configService.timeout;
      }
    } catch (e) {
      // Fallback to default if config service is not available
    }
    return const int.fromEnvironment("CONNECTION_TIMEOUT", defaultValue: 30000);
  }
}