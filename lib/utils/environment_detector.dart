import 'package:flutter/foundation.dart';

/// Environment detector service
/// Automatically detects the current environment from build configuration
class EnvironmentDetector {
  static const String _environmentKey = 'ENVIRONMENT';
  static const String _flavorKey = 'FLAVOR';
  
  /// Get current environment from build configuration
  static String getCurrentEnvironment() {
    // Try to get from dart-define first
    final envFromDefine = const String.fromEnvironment(_environmentKey, defaultValue: '');
    if (envFromDefine.isNotEmpty) {
      return envFromDefine;
    }
    
    // Try to get from flavor
    final flavor = const String.fromEnvironment(_flavorKey, defaultValue: '');
    if (flavor.isNotEmpty) {
      return flavor;
    }
    
    // Try to get from kDebugMode
    if (kDebugMode) {
      return 'development';
    }
    
    // Default fallback
    return 'development';
  }
  
  /// Check if current environment is development
  static bool get isDevelopment => getCurrentEnvironment() == 'development';
  
  /// Check if current environment is staging
  static bool get isStaging => getCurrentEnvironment() == 'staging';
  
  /// Check if current environment is production
  static bool get isProduction => getCurrentEnvironment() == 'production';
  
  /// Get environment display name
  static String getEnvironmentDisplayName() {
    switch (getCurrentEnvironment()) {
      case 'development':
        return 'Development';
      case 'staging':
        return 'Staging';
      case 'production':
        return 'Production';
      default:
        return 'Unknown';
    }
  }
  
  /// Get environment info for debugging
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': getCurrentEnvironment(),
      'displayName': getEnvironmentDisplayName(),
      'isDebug': kDebugMode,
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'isProduction': isProduction,
      'dartDefine': const String.fromEnvironment(_environmentKey, defaultValue: 'not_set'),
      'flavor': const String.fromEnvironment(_flavorKey, defaultValue: 'not_set'),
    };
  }
} 