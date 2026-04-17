import 'package:flutter/foundation.dart';
import '../services/environment_config_service.dart';
import '../utils/environment_variables.dart';

/// Helper class to manage environment configuration system
class ConfigIntegrationHelper {
  static final ConfigIntegrationHelper _instance = ConfigIntegrationHelper._internal();
  factory ConfigIntegrationHelper() => _instance;
  ConfigIntegrationHelper._internal();

  final EnvironmentConfigService _configService = EnvironmentConfigService();

  /// Initialize configuration system
  Future<void> initialize([String? environment]) async {
    try {
      // Initialize environment configuration
      await _configService.initialize(environment);
      debugPrint('Environment configuration system initialized successfully');
    } catch (e) {
      debugPrint('Environment configuration initialization failed: $e');
    }
  }

  /// Get API base URL with fallback
  String getApiBaseUrl() {
    try {
      if (_configService.isInitialized) {
        return _configService.apiBaseUrl;
      }
    } catch (e) {
      debugPrint('Failed to get API base URL from environment config: $e');
    }
    
    // Fallback to environment variable
    return EnvironmentVariables.apiEndpoint;
  }

  /// Get WebSocket URL with fallback
  String? getWebSocketUrl() {
    try {
      if (_configService.isInitialized) {
        return _configService.websocketUrl;
      }
    } catch (e) {
      debugPrint('Failed to get WebSocket URL from environment config: $e');
    }
    
    // Fallback to environment variable
    return EnvironmentVariables.websocketUrl;
  }

  /// Get app name with fallback
  String getAppName() {
    try {
      if (_configService.isInitialized) {
        return _configService.appName;
      }
    } catch (e) {
      debugPrint('Failed to get app name from environment config: $e');
    }
    
    return EnvironmentVariables.appName;
  }

  /// Get bundle ID with fallback
  String getBundleId() {
    try {
      if (_configService.isInitialized) {
        return _configService.bundleId;
      }
    } catch (e) {
      debugPrint('Failed to get bundle ID from environment config: $e');
    }
    
    return EnvironmentVariables.bundleId;
  }

  /// Get network timeout with fallback
  int getTimeout() {
    try {
      if (_configService.isInitialized) {
        return _configService.timeout;
      }
    } catch (e) {
      debugPrint('Failed to get timeout from environment config: $e');
    }
    
    return EnvironmentVariables.networkTimeout;
  }

  /// Get environment name with fallback
  String getEnvironmentName() {
    try {
      if (_configService.isInitialized) {
        return _configService.environmentName;
      }
    } catch (e) {
      debugPrint('Failed to get environment name from environment config: $e');
    }
    
    return EnvironmentVariables.environment;
  }

  /// Check if debug mode is enabled
  bool isDebugMode() {
    try {
      if (_configService.isInitialized) {
        return _configService.isDebugMode;
      }
    } catch (e) {
      debugPrint('Failed to get debug mode from environment config: $e');
    }
    
    return kDebugMode;
  }

  /// Check if configuration system is available
  bool isConfigurationAvailable() {
    try {
      return _configService.isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigurationSummary() {
    return {
      'environmentConfigAvailable': _configService.isInitialized,
      'apiBaseUrl': getApiBaseUrl(),
      'websocketUrl': getWebSocketUrl(),
      'appName': getAppName(),
      'bundleId': getBundleId(),
      'environmentName': getEnvironmentName(),
      'timeout': getTimeout(),
      'debugMode': isDebugMode(),
    };
  }

  /// Validate current configuration
  Future<bool> validateConfiguration() async {
    try {
      if (_configService.isInitialized) {
        return await _configService.validateCurrentConfig();
      }
    } catch (e) {
      debugPrint('Failed to validate environment configuration: $e');
    }
    
    // Basic validation for fallback config
    final apiUrl = getApiBaseUrl();
    return apiUrl.isNotEmpty && Uri.tryParse(apiUrl) != null;
  }

  @override
  String toString() {
    return 'ConfigIntegrationHelper(${getConfigurationSummary()})';
  }
}