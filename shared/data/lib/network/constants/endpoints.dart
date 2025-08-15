import 'package:app_config/app_config.dart';
import 'package:app_config/utils/environment_variables.dart';

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
    return EnvironmentVariables.apiBaseUrl;
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
    return EnvironmentVariables.websocketUrl;
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
    return EnvironmentVariables.receiveTimeout;
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
    return EnvironmentVariables.connectionTimeout;
  }
}