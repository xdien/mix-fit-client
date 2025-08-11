import 'package:flutter/material.dart';
import 'error_system_config.dart';
import '../models/app_error.dart';

/// Configuration for different app flavors
enum AppFlavor {
  development,
  staging,
  production,
}

/// Flavor-specific error system configurations
class FlavorErrorConfig {
  /// Gets error configuration for a specific flavor
  static ErrorSystemConfig getConfigForFlavor(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.development:
        return _developmentConfig;
      case AppFlavor.staging:
        return _stagingConfig;
      case AppFlavor.production:
        return _productionConfig;
    }
  }

  /// Gets theme configuration for a specific flavor
  static ErrorThemeConfig getThemeForFlavor(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.development:
        return _developmentTheme;
      case AppFlavor.staging:
        return _stagingTheme;
      case AppFlavor.production:
        return const ErrorThemeConfig();
    }
  }

  /// Development flavor configuration
  static const ErrorSystemConfig _developmentConfig = ErrorSystemConfig(
    maxErrorQueueSize: 10, // More errors for debugging
    autoDismissTimeouts: {
      ErrorSeverity.info: Duration(seconds: 5),
      ErrorSeverity.warning: Duration(seconds: 10),
      ErrorSeverity.error: Duration(seconds: 15),
      ErrorSeverity.critical: Duration.zero,
    },
    showErrorBarByDefault: true,
    showNetworkStatus: true,
    enableErrorLogging: true,
    maxErrorHistorySize: 100, // More history for debugging
    showErrorDetailsInDebug: true,
    enableErrorAnalytics: false, // No analytics in dev
    userPreferences: ErrorUserPreferences(
      showDetailedErrors: true,
      enableErrorHistory: true,
    ),
  );

  /// Staging flavor configuration
  static const ErrorSystemConfig _stagingConfig = ErrorSystemConfig(
    maxErrorQueueSize: 7,
    autoDismissTimeouts: {
      ErrorSeverity.info: Duration(seconds: 4),
      ErrorSeverity.warning: Duration(seconds: 7),
      ErrorSeverity.error: Duration(seconds: 12),
      ErrorSeverity.critical: Duration.zero,
    },
    showErrorBarByDefault: true,
    showNetworkStatus: true,
    enableErrorLogging: true,
    maxErrorHistorySize: 75,
    showErrorDetailsInDebug: true,
    enableErrorAnalytics: true, // Enable analytics for staging
    userPreferences: ErrorUserPreferences(
      showDetailedErrors: false, // Less detailed for staging
      enableErrorHistory: true,
    ),
  );

  /// Production flavor configuration
  static const ErrorSystemConfig _productionConfig = ErrorSystemConfig(
    maxErrorQueueSize: 5,
    autoDismissTimeouts: {
      ErrorSeverity.info: Duration(seconds: 3),
      ErrorSeverity.warning: Duration(seconds: 5),
      ErrorSeverity.error: Duration(seconds: 10),
      ErrorSeverity.critical: Duration.zero,
    },
    showErrorBarByDefault: true,
    showNetworkStatus: true,
    enableErrorLogging: true,
    maxErrorHistorySize: 25, // Limited history for production
    showErrorDetailsInDebug: false,
    enableErrorAnalytics: true,
    userPreferences: ErrorUserPreferences(
      showDetailedErrors: false,
      enableErrorHistory: false, // Disabled for privacy
    ),
  );

  /// Development theme with distinct colors for debugging
  static const ErrorThemeConfig _developmentTheme = ErrorThemeConfig(
    severityColors: {
      ErrorSeverity.info: Colors.cyan,
      ErrorSeverity.warning: Colors.amber,
      ErrorSeverity.error: Colors.deepOrange,
      ErrorSeverity.critical: Colors.purple,
    },
    backgroundColors: {
      ErrorSeverity.info: Color(0xFFE0F7FA),
      ErrorSeverity.warning: Color(0xFFFFF8E1),
      ErrorSeverity.error: Color(0xFFFBE9E7),
      ErrorSeverity.critical: Color(0xFFF3E5F5),
    },
    borderColors: {
      ErrorSeverity.info: Colors.cyan,
      ErrorSeverity.warning: Colors.amber,
      ErrorSeverity.error: Colors.deepOrange,
      ErrorSeverity.critical: Colors.purple,
    },
    elevation: 6.0, // Higher elevation for dev
    animationDuration: Duration(milliseconds: 500), // Slower for debugging
  );

  /// Staging theme with warning indicators
  static const ErrorThemeConfig _stagingTheme = ErrorThemeConfig(
    severityColors: {
      ErrorSeverity.info: Colors.blue,
      ErrorSeverity.warning: Colors.orange,
      ErrorSeverity.error: Colors.red,
      ErrorSeverity.critical: Colors.indigo,
    },
    backgroundColors: {
      ErrorSeverity.info: Color(0xFFE3F2FD),
      ErrorSeverity.warning: Color(0xFFFFF3E0),
      ErrorSeverity.error: Color(0xFFFFEBEE),
      ErrorSeverity.critical: Color(0xFFE8EAF6),
    },
    borderColors: {
      ErrorSeverity.info: Colors.blue,
      ErrorSeverity.warning: Colors.orange,
      ErrorSeverity.error: Colors.red,
      ErrorSeverity.critical: Colors.indigo,
    },
    elevation: 4.0,
    animationDuration: Duration(milliseconds: 350),
  );
}

/// Flavor-aware error configuration provider
class FlavorAwareErrorConfig {
  final AppFlavor flavor;
  final ErrorSystemConfig _baseConfig;
  final ErrorThemeConfig _baseTheme;

  FlavorAwareErrorConfig(this.flavor)
      : _baseConfig = FlavorErrorConfig.getConfigForFlavor(flavor),
        _baseTheme = FlavorErrorConfig.getThemeForFlavor(flavor);

  /// Gets the current configuration
  ErrorSystemConfig get config => _baseConfig;

  /// Gets the current theme
  ErrorThemeConfig get theme => _baseTheme;

  /// Creates a customized configuration for specific use cases
  ErrorSystemConfig createCustomConfig({
    bool? enableVerboseLogging,
    bool? enableTestMode,
    Map<ErrorSeverity, Duration>? customTimeouts,
  }) {
    var customConfig = _baseConfig;

    if (enableVerboseLogging == true) {
      customConfig = customConfig.copyWith(
        enableErrorLogging: true,
        maxErrorHistorySize: customConfig.maxErrorHistorySize * 2,
        showErrorDetailsInDebug: true,
      );
    }

    if (enableTestMode == true) {
      customConfig = customConfig.copyWith(
        autoDismissTimeouts: {
          ErrorSeverity.info: const Duration(milliseconds: 100),
          ErrorSeverity.warning: const Duration(milliseconds: 200),
          ErrorSeverity.error: const Duration(milliseconds: 500),
          ErrorSeverity.critical: Duration.zero,
        },
        maxErrorQueueSize: 20,
      );
    }

    if (customTimeouts != null) {
      customConfig = customConfig.copyWith(
        autoDismissTimeouts: customTimeouts,
      );
    }

    return customConfig;
  }

  /// Creates a customized theme for specific branding
  ErrorThemeConfig createCustomTheme({
    Color? primaryBrandColor,
    bool? useHighContrast,
    bool? useReducedMotion,
  }) {
    var customTheme = _baseTheme;

    if (primaryBrandColor != null) {
      customTheme = customTheme.copyWith(
        severityColors: {
          ErrorSeverity.info: primaryBrandColor.withOpacity(0.8),
          ErrorSeverity.warning: Colors.orange,
          ErrorSeverity.error: Colors.red,
          ErrorSeverity.critical: primaryBrandColor,
        },
      );
    }

    if (useHighContrast == true) {
      customTheme = customTheme.adaptForHighContrast();
    }

    if (useReducedMotion == true) {
      customTheme = customTheme.adaptForReducedMotion();
    }

    return customTheme;
  }

  /// Gets flavor-specific error message formatting
  String formatErrorMessage(String originalMessage) {
    switch (flavor) {
      case AppFlavor.development:
        return '[DEV] $originalMessage';
      case AppFlavor.staging:
        return '[STAGING] $originalMessage';
      case AppFlavor.production:
        return originalMessage;
    }
  }

  /// Gets flavor-specific error actions
  List<ErrorAction> getFlavorSpecificActions(AppError error) {
    final actions = <ErrorAction>[];

    // Common actions for all flavors
    actions.add(ErrorAction(
      id: 'dismiss',
      label: 'Dismiss',
      onPressed: () {}, // Will be handled by error service
    ));

    // Flavor-specific actions
    switch (flavor) {
      case AppFlavor.development:
        actions.addAll([
          ErrorAction(
            id: 'copy_details',
            label: 'Copy Details',
            icon: Icons.copy,
            onPressed: () {}, // Copy error details to clipboard
          ),
          ErrorAction(
            id: 'debug',
            label: 'Debug',
            icon: Icons.bug_report,
            onPressed: () {}, // Open debug information
          ),
        ]);
        break;
      case AppFlavor.staging:
        actions.add(ErrorAction(
          id: 'report',
          label: 'Report',
          icon: Icons.report,
          onPressed: () {}, // Report to staging environment
        ));
        break;
      case AppFlavor.production:
        if (error.severity == ErrorSeverity.critical) {
          actions.add(ErrorAction(
            id: 'contact_support',
            label: 'Contact Support',
            icon: Icons.support_agent,
            onPressed: () {}, // Contact support
          ));
        }
        break;
    }

    return actions;
  }

  /// Checks if a feature is enabled for the current flavor
  bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'detailed_errors':
        return flavor == AppFlavor.development;
      case 'error_analytics':
        return flavor != AppFlavor.development;
      case 'error_history':
        return flavor != AppFlavor.production;
      case 'debug_actions':
        return flavor == AppFlavor.development;
      default:
        return true;
    }
  }
}

/// Extension methods for flavor-aware error handling
extension FlavorErrorExtensions on AppError {
  /// Gets flavor-specific error message
  String getFlavorMessage(AppFlavor flavor) {
    final config = FlavorAwareErrorConfig(flavor);
    return config.formatErrorMessage(message);
  }

  /// Gets flavor-specific actions
  List<ErrorAction> getFlavorActions(AppFlavor flavor) {
    final config = FlavorAwareErrorConfig(flavor);
    return config.getFlavorSpecificActions(this);
  }
}