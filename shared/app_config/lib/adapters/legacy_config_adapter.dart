import 'package:flutter/foundation.dart';
import '../services/environment_config_service.dart';

/// Adapter to bridge legacy configuration system with new environment configuration
class LegacyConfigAdapter {
  static final LegacyConfigAdapter _instance = LegacyConfigAdapter._internal();
  factory LegacyConfigAdapter() => _instance;
  LegacyConfigAdapter._internal();

  final EnvironmentConfigService _configService = EnvironmentConfigService();

  /// Get API endpoint with fallback to legacy configuration
  String get endpoint {
    try {
      if (_configService.isInitialized) {
        return _configService.apiBaseUrl;
      }
    } catch (e) {
      debugPrint('Failed to get endpoint from environment config: $e');
    }
    
    // Fallback to environment variable
    return const String.fromEnvironment('API_ENDPOINT', defaultValue: 'http://localhost:3000');
  }

  /// Get WebSocket URL with fallback
  String get websocketUrl {
    try {
      if (_configService.isInitialized) {
        return _configService.websocketUrl ?? 'ws://localhost:3001';
      }
    } catch (e) {
      debugPrint('Failed to get websocket URL from environment config: $e');
    }
    
    // Fallback to environment variable
    return const String.fromEnvironment('WEBSOCKET_URL', defaultValue: 'ws://localhost:3001');
  }

  /// Get API key (placeholder for future implementation)
  String get apiKey {
    // This would come from secure storage or environment config in the future
    return const String.fromEnvironment('API_KEY', defaultValue: '');
  }

  /// Get debug mode status
  bool get debugMode {
    try {
      if (_configService.isInitialized) {
        return _configService.isDebugMode;
      }
    } catch (e) {
      debugPrint('Failed to get debug mode from environment config: $e');
    }
    
    // Fallback to debug mode detection
    return kDebugMode;
  }

  /// Get app name
  String get appName {
    try {
      if (_configService.isInitialized) {
        return _configService.appName;
      }
    } catch (e) {
      debugPrint('Failed to get app name from environment config: $e');
    }
    
    return const String.fromEnvironment('APP_NAME', defaultValue: 'CMS Business');
  }

  /// Get bundle ID
  String get bundleId {
    try {
      if (_configService.isInitialized) {
        return _configService.bundleId;
      }
    } catch (e) {
      debugPrint('Failed to get bundle ID from environment config: $e');
    }
    
    return const String.fromEnvironment('BUNDLE_ID', defaultValue: 'com.ankhanh.cms');
  }

  /// Get environment name
  String get environmentName {
    try {
      if (_configService.isInitialized) {
        return _configService.environmentName;
      }
    } catch (e) {
      debugPrint('Failed to get environment name from environment config: $e');
    }
    
    return const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  }

  /// Get network timeout
  int get timeout {
    try {
      if (_configService.isInitialized) {
        return _configService.timeout;
      }
    } catch (e) {
      debugPrint('Failed to get timeout from environment config: $e');
    }
    
    return const int.fromEnvironment('NETWORK_TIMEOUT', defaultValue: 30000);
  }

  /// Check if configuration is available
  bool get isConfigured {
    try {
      return _configService.isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration as map for debugging
  Map<String, dynamic> toMap() {
    return {
      'endpoint': endpoint,
      'websocketUrl': websocketUrl,
      'apiKey': apiKey.isNotEmpty ? '***' : 'not_set',
      'debugMode': debugMode,
      'appName': appName,
      'bundleId': bundleId,
      'environmentName': environmentName,
      'timeout': timeout,
      'isConfigured': isConfigured,
    };
  }

  @override
  String toString() {
    return 'LegacyConfigAdapter(${toMap()})';
  }
}