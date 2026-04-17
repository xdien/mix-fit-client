import 'package:flutter/material.dart';
import '../models/app_error.dart';

/// Configuration class for the error system
class ErrorSystemConfig {
  /// Maximum number of errors to keep in the queue
  final int maxErrorQueueSize;

  /// Auto-dismiss timeout for different error severities
  final Map<ErrorSeverity, Duration> autoDismissTimeouts;

  /// Whether to show error bar by default
  final bool showErrorBarByDefault;

  /// Whether to show network status in error bar
  final bool showNetworkStatus;

  /// Whether to enable error logging
  final bool enableErrorLogging;

  /// Maximum number of errors to keep in history for debugging
  final int maxErrorHistorySize;

  /// Whether to show error details in debug mode
  final bool showErrorDetailsInDebug;

  /// Whether to enable error analytics
  final bool enableErrorAnalytics;

  /// Custom error message formatter
  final String Function(AppError error)? customMessageFormatter;

  /// Custom error action provider
  final List<ErrorAction> Function(AppError error)? customActionProvider;

  /// Theme configuration for error UI
  final ErrorThemeConfig themeConfig;

  /// User preferences for error display
  final ErrorUserPreferences userPreferences;

  const ErrorSystemConfig({
    this.maxErrorQueueSize = 5,
    this.autoDismissTimeouts = const {
      ErrorSeverity.info: Duration(seconds: 3),
      ErrorSeverity.warning: Duration(seconds: 5),
      ErrorSeverity.error: Duration(seconds: 10),
      ErrorSeverity.critical: Duration.zero, // Never auto-dismiss
    },
    this.showErrorBarByDefault = true,
    this.showNetworkStatus = true,
    this.enableErrorLogging = true,
    this.maxErrorHistorySize = 50,
    this.showErrorDetailsInDebug = true,
    this.enableErrorAnalytics = false,
    this.customMessageFormatter,
    this.customActionProvider,
    this.themeConfig = const ErrorThemeConfig(),
    this.userPreferences = const ErrorUserPreferences(),
  });

  /// Creates a copy of this config with updated values
  ErrorSystemConfig copyWith({
    int? maxErrorQueueSize,
    Map<ErrorSeverity, Duration>? autoDismissTimeouts,
    bool? showErrorBarByDefault,
    bool? showNetworkStatus,
    bool? enableErrorLogging,
    int? maxErrorHistorySize,
    bool? showErrorDetailsInDebug,
    bool? enableErrorAnalytics,
    String Function(AppError error)? customMessageFormatter,
    List<ErrorAction> Function(AppError error)? customActionProvider,
    ErrorThemeConfig? themeConfig,
    ErrorUserPreferences? userPreferences,
  }) {
    return ErrorSystemConfig(
      maxErrorQueueSize: maxErrorQueueSize ?? this.maxErrorQueueSize,
      autoDismissTimeouts: autoDismissTimeouts ?? this.autoDismissTimeouts,
      showErrorBarByDefault: showErrorBarByDefault ?? this.showErrorBarByDefault,
      showNetworkStatus: showNetworkStatus ?? this.showNetworkStatus,
      enableErrorLogging: enableErrorLogging ?? this.enableErrorLogging,
      maxErrorHistorySize: maxErrorHistorySize ?? this.maxErrorHistorySize,
      showErrorDetailsInDebug: showErrorDetailsInDebug ?? this.showErrorDetailsInDebug,
      enableErrorAnalytics: enableErrorAnalytics ?? this.enableErrorAnalytics,
      customMessageFormatter: customMessageFormatter ?? this.customMessageFormatter,
      customActionProvider: customActionProvider ?? this.customActionProvider,
      themeConfig: themeConfig ?? this.themeConfig,
      userPreferences: userPreferences ?? this.userPreferences,
    );
  }

  /// Default configuration for development environment
  static const ErrorSystemConfig development = ErrorSystemConfig(
    showErrorDetailsInDebug: true,
    enableErrorLogging: true,
    enableErrorAnalytics: false,
    maxErrorHistorySize: 100,
  );

  /// Default configuration for production environment
  static const ErrorSystemConfig production = ErrorSystemConfig(
    showErrorDetailsInDebug: false,
    enableErrorLogging: true,
    enableErrorAnalytics: true,
    maxErrorHistorySize: 25,
  );

  /// Configuration for testing environment
  static const ErrorSystemConfig testing = ErrorSystemConfig(
    showErrorBarByDefault: false,
    enableErrorLogging: false,
    enableErrorAnalytics: false,
    autoDismissTimeouts: {
      ErrorSeverity.info: Duration(milliseconds: 100),
      ErrorSeverity.warning: Duration(milliseconds: 200),
      ErrorSeverity.error: Duration(milliseconds: 500),
      ErrorSeverity.critical: Duration.zero,
    },
  );
}

/// Theme configuration for error UI components
class ErrorThemeConfig {
  /// Colors for different error severities
  final Map<ErrorSeverity, Color> severityColors;

  /// Background colors for error components
  final Map<ErrorSeverity, Color> backgroundColors;

  /// Text colors for error components
  final Map<ErrorSeverity, Color> textColors;

  /// Icon colors for error components
  final Map<ErrorSeverity, Color> iconColors;

  /// Border colors for error components
  final Map<ErrorSeverity, Color> borderColors;

  /// Icons for different error severities
  final Map<ErrorSeverity, IconData> severityIcons;

  /// Animation duration for error UI transitions
  final Duration animationDuration;

  /// Border radius for error components
  final BorderRadius borderRadius;

  /// Elevation for error dialogs and snackbars
  final double elevation;

  /// Text styles for error messages
  final TextStyle messageTextStyle;

  /// Text styles for error action buttons
  final TextStyle actionTextStyle;

  const ErrorThemeConfig({
    this.severityColors = const {
      ErrorSeverity.info: Colors.blue,
      ErrorSeverity.warning: Colors.orange,
      ErrorSeverity.error: Colors.red,
      ErrorSeverity.critical: Colors.deepPurple,
    },
    this.backgroundColors = const {
      ErrorSeverity.info: Color(0xFFE3F2FD),
      ErrorSeverity.warning: Color(0xFFFFF3E0),
      ErrorSeverity.error: Color(0xFFFFEBEE),
      ErrorSeverity.critical: Color(0xFFF3E5F5),
    },
    this.textColors = const {
      ErrorSeverity.info: Color(0xFF1565C0),
      ErrorSeverity.warning: Color(0xFFE65100),
      ErrorSeverity.error: Color(0xFFC62828),
      ErrorSeverity.critical: Color(0xFF6A1B9A),
    },
    this.iconColors = const {
      ErrorSeverity.info: Color(0xFF1976D2),
      ErrorSeverity.warning: Color(0xFFF57C00),
      ErrorSeverity.error: Color(0xFFD32F2F),
      ErrorSeverity.critical: Color(0xFF7B1FA2),
    },
    this.borderColors = const {
      ErrorSeverity.info: Color(0xFF90CAF9),
      ErrorSeverity.warning: Color(0xFFFFCC02),
      ErrorSeverity.error: Color(0xFFEF5350),
      ErrorSeverity.critical: Color(0xFFBA68C8),
    },
    this.severityIcons = const {
      ErrorSeverity.info: Icons.info_outline,
      ErrorSeverity.warning: Icons.warning_amber_outlined,
      ErrorSeverity.error: Icons.error_outline,
      ErrorSeverity.critical: Icons.dangerous_outlined,
    },
    this.animationDuration = const Duration(milliseconds: 300),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.elevation = 4.0,
    this.messageTextStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    this.actionTextStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  });

  /// Creates a copy of this theme config with updated values
  ErrorThemeConfig copyWith({
    Map<ErrorSeverity, Color>? severityColors,
    Map<ErrorSeverity, Color>? backgroundColors,
    Map<ErrorSeverity, Color>? textColors,
    Map<ErrorSeverity, Color>? iconColors,
    Map<ErrorSeverity, Color>? borderColors,
    Map<ErrorSeverity, IconData>? severityIcons,
    Duration? animationDuration,
    BorderRadius? borderRadius,
    double? elevation,
    TextStyle? messageTextStyle,
    TextStyle? actionTextStyle,
  }) {
    return ErrorThemeConfig(
      severityColors: severityColors ?? this.severityColors,
      backgroundColors: backgroundColors ?? this.backgroundColors,
      textColors: textColors ?? this.textColors,
      iconColors: iconColors ?? this.iconColors,
      borderColors: borderColors ?? this.borderColors,
      severityIcons: severityIcons ?? this.severityIcons,
      animationDuration: animationDuration ?? this.animationDuration,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      actionTextStyle: actionTextStyle ?? this.actionTextStyle,
    );
  }

  /// Dark theme configuration
  static const ErrorThemeConfig dark = ErrorThemeConfig(
    severityColors: {
      ErrorSeverity.info: Colors.lightBlue,
      ErrorSeverity.warning: Colors.amber,
      ErrorSeverity.error: Colors.redAccent,
      ErrorSeverity.critical: Colors.purpleAccent,
    },
    backgroundColors: {
      ErrorSeverity.info: Color(0xFF0D47A1),
      ErrorSeverity.warning: Color(0xFFE65100),
      ErrorSeverity.error: Color(0xFFB71C1C),
      ErrorSeverity.critical: Color(0xFF4A148C),
    },
    textColors: {
      ErrorSeverity.info: Colors.white,
      ErrorSeverity.warning: Colors.white,
      ErrorSeverity.error: Colors.white,
      ErrorSeverity.critical: Colors.white,
    },
  );

  /// High contrast theme configuration for accessibility
  static const ErrorThemeConfig highContrast = ErrorThemeConfig(
    severityColors: {
      ErrorSeverity.info: Colors.black,
      ErrorSeverity.warning: Colors.black,
      ErrorSeverity.error: Colors.black,
      ErrorSeverity.critical: Colors.black,
    },
    backgroundColors: {
      ErrorSeverity.info: Colors.white,
      ErrorSeverity.warning: Colors.yellow,
      ErrorSeverity.error: Colors.red,
      ErrorSeverity.critical: Colors.purple,
    },
    textColors: {
      ErrorSeverity.info: Colors.black,
      ErrorSeverity.warning: Colors.black,
      ErrorSeverity.error: Colors.white,
      ErrorSeverity.critical: Colors.white,
    },
    borderColors: {
      ErrorSeverity.info: Colors.black,
      ErrorSeverity.warning: Colors.black,
      ErrorSeverity.error: Colors.black,
      ErrorSeverity.critical: Colors.black,
    },
    elevation: 8.0,
  );
}

/// User preferences for error display
class ErrorUserPreferences {
  /// Whether user wants to see error bar
  final bool showErrorBar;

  /// Whether user wants to see network status
  final bool showNetworkStatus;

  /// Whether user wants auto-dismiss for non-critical errors
  final bool enableAutoDismiss;

  /// Whether user wants sound notifications for errors
  final bool enableSoundNotifications;

  /// Whether user wants vibration for critical errors
  final bool enableVibration;

  /// Preferred error display position
  final ErrorDisplayPosition displayPosition;

  /// Whether user wants detailed error information
  final bool showDetailedErrors;

  /// Whether user wants to see error history
  final bool enableErrorHistory;

  /// Custom timeout overrides for different severities
  final Map<ErrorSeverity, Duration>? customTimeouts;

  const ErrorUserPreferences({
    this.showErrorBar = true,
    this.showNetworkStatus = true,
    this.enableAutoDismiss = true,
    this.enableSoundNotifications = false,
    this.enableVibration = true,
    this.displayPosition = ErrorDisplayPosition.top,
    this.showDetailedErrors = false,
    this.enableErrorHistory = true,
    this.customTimeouts,
  });

  /// Creates a copy of this preferences with updated values
  ErrorUserPreferences copyWith({
    bool? showErrorBar,
    bool? showNetworkStatus,
    bool? enableAutoDismiss,
    bool? enableSoundNotifications,
    bool? enableVibration,
    ErrorDisplayPosition? displayPosition,
    bool? showDetailedErrors,
    bool? enableErrorHistory,
    Map<ErrorSeverity, Duration>? customTimeouts,
  }) {
    return ErrorUserPreferences(
      showErrorBar: showErrorBar ?? this.showErrorBar,
      showNetworkStatus: showNetworkStatus ?? this.showNetworkStatus,
      enableAutoDismiss: enableAutoDismiss ?? this.enableAutoDismiss,
      enableSoundNotifications: enableSoundNotifications ?? this.enableSoundNotifications,
      enableVibration: enableVibration ?? this.enableVibration,
      displayPosition: displayPosition ?? this.displayPosition,
      showDetailedErrors: showDetailedErrors ?? this.showDetailedErrors,
      enableErrorHistory: enableErrorHistory ?? this.enableErrorHistory,
      customTimeouts: customTimeouts ?? this.customTimeouts,
    );
  }

  /// Converts preferences to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'showErrorBar': showErrorBar,
      'showNetworkStatus': showNetworkStatus,
      'enableAutoDismiss': enableAutoDismiss,
      'enableSoundNotifications': enableSoundNotifications,
      'enableVibration': enableVibration,
      'displayPosition': displayPosition.name,
      'showDetailedErrors': showDetailedErrors,
      'enableErrorHistory': enableErrorHistory,
      'customTimeouts': customTimeouts?.map(
        (key, value) => MapEntry(key.name, value.inMilliseconds),
      ),
    };
  }

  /// Creates preferences from JSON
  factory ErrorUserPreferences.fromJson(Map<String, dynamic> json) {
    return ErrorUserPreferences(
      showErrorBar: json['showErrorBar'] ?? true,
      showNetworkStatus: json['showNetworkStatus'] ?? true,
      enableAutoDismiss: json['enableAutoDismiss'] ?? true,
      enableSoundNotifications: json['enableSoundNotifications'] ?? false,
      enableVibration: json['enableVibration'] ?? true,
      displayPosition: ErrorDisplayPosition.values.firstWhere(
        (e) => e.name == json['displayPosition'],
        orElse: () => ErrorDisplayPosition.top,
      ),
      showDetailedErrors: json['showDetailedErrors'] ?? false,
      enableErrorHistory: json['enableErrorHistory'] ?? true,
      customTimeouts: json['customTimeouts'] != null
          ? (json['customTimeouts'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                ErrorSeverity.values.firstWhere((e) => e.name == key),
                Duration(milliseconds: value),
              ),
            )
          : null,
    );
  }
}

/// Error display position options
enum ErrorDisplayPosition {
  top,
  bottom,
  center,
}

/// Error action for user interactions
class ErrorAction {
  final String id;
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;

  const ErrorAction({
    required this.id,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.color,
  });
}