import 'package:flutter/foundation.dart';
import '../services/environment_config_service.dart';
import '../adapters/legacy_config_adapter.dart';

/// Helper class to manage integration between old and new configuration systems
class ConfigIntegrationHelper {
  static final ConfigIntegrationHelper _instance = ConfigIntegrationHelper._internal();
  factory ConfigIntegrationHelper() => _instance;
  ConfigIntegrationHelper._internal();

  final EnvironmentConfigService _configService = EnvironmentConfigService();
  final LegacyConfigAdapter _legacyAdapter = LegacyConfigAdapter();

  /// Initialize configuration system with proper fallbacks
  Future<void> initialize([String? environment]) async {
    try {
      // Try to initialize environment configuration first
      await _configService.initialize(environment);
      debugPrint('Environment configuration system initialized successfully');
    } catch (e) {
      debugPrint('Environment configuration initialization failed: $e');
      debugPrint('Falling back to legacy configuration system');
    }
  }

  /// Get API base URL with proper fallback chain
  String getApiBaseUrl() {
    try {
      if (_configService.isInitialized) {
        return _configService.apiBaseUrl;
      }
    } catch (e) {
      debugPrint('Failed to get API base URL from environment config: $e');
    }
    
    return _legacyAdapter.endpoint;
  }

  /// Get WebSocket URL with proper fallback chain
  String? getWebSocketUrl() {
    try {
      if (_configService.isInitialized) {
        return _configService.websocketUrl;
      }
    } catch (e) {
      debugPrint('Failed to get WebSocket URL from environment config: $e');
    }
    
    return _legacyAdapter.websocketUrl;
  }

  /// Get app name with proper fallback chain
  String getAppName() {
    try {
      if (_configService.isInitialized) {
        return _configService.appName;
      }
    } catch (e) {
      debugPrint('Failed to get app name from environment config: $e');
    }
    
    return _legacyAdapter.appName;
  }

  /// Get bundle ID with proper fallback chain
  String getBundleId() {
    try {
      if (_configService.isInitialized) {
        return _configService.bundleId;
      }
    } catch (e) {
      debugPrint('Failed to get bundle ID from environment config: $e');
    }
    
    return _legacyAdapter.bundleId;
  }

  /// Get network timeout with proper fallback chain
  int getTimeout() {
    try {
      if (_configService.isInitialized) {
        return _configService.timeout;
      }
    } catch (e) {
      debugPrint('Failed to get timeout from environment config: $e');
    }
    
    return _legacyAdapter.timeout;
  }

  /// Get environment name with proper fallback chain
  String getEnvironmentName() {
    try {
      if (_configService.isInitialized) {
        return _configService.environmentName;
      }
    } catch (e) {
      debugPrint('Failed to get environment name from environment config: $e');
    }
    
    return _legacyAdapter.environmentName;
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
    
    return _legacyAdapter.debugMode;
  }

  /// Check if any configuration system is available
  bool isConfigurationAvailable() {
    try {
      return _configService.isInitialized || _legacyAdapter.isConfigured;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigurationSummary() {
    return {
      'environmentConfigAvailable': _configService.isInitialized,
      'legacyConfigAvailable': _legacyAdapter.isConfigured,
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
    
    // Basic validation for legacy config
    final apiUrl = getApiBaseUrl();
    return apiUrl.isNotEmpty && Uri.tryParse(apiUrl) != null;
  }

  @override
  String toString() {
    return 'ConfigIntegrationHelper(${getConfigurationSummary()})';
  }
}