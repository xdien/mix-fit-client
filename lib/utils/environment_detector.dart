import 'package:flutter/foundation.dart';
import 'package:app_config/app_config.dart';

/// Environment detector service
/// Automatically detects the current environment from build configuration
class EnvironmentDetector {
  /// Get current environment from build configuration
  static String getCurrentEnvironment() {
    // Use centralized environment variables
    final envFromDefine = EnvironmentVariables.environment;
    if (envFromDefine.isNotEmpty) {
      return envFromDefine;
    }
    
    // Try to get from flavor
    final flavor = EnvironmentVariables.buildFlavor;
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
      'dartDefine': EnvironmentVariables.environment,
      'flavor': EnvironmentVariables.buildFlavor,
    };
  }
} 