/// Base class for all deeplink-related errors
/// Provides common error handling functionality
abstract class DeeplinkError implements Exception {
  /// Error message describing what went wrong
  final String message;
  
  /// Error code for programmatic handling
  final String code;
  
  /// Additional context about the error
  final Map<String, dynamic> context;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;

  const DeeplinkError({
    required this.message,
    required this.code,
    this.context = const {},
    required this.timestamp,
  });

  /// Create a generic deeplink error
  factory DeeplinkError.generic({
    required String message,
    String? code,
    Map<String, dynamic>? context,
  }) {
    return GenericDeeplinkError(
      message: message,
      code: code ?? 'DEEPLINK_ERROR',
      context: context ?? {},
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return '$runtimeType: $message (Code: $code)';
  }
}

/// Generic deeplink error for unspecified error conditions
class GenericDeeplinkError extends DeeplinkError {
  const GenericDeeplinkError({
    required super.message,
    required super.code,
    super.context,
    required super.timestamp,
  });
}

/// Error thrown when deeplink parsing fails
class DeeplinkParsingError extends DeeplinkError {
  /// The original URL that failed to parse
  final String originalUrl;

  DeeplinkParsingError({
    required super.message,
    required this.originalUrl,
    super.context,
    DateTime? timestamp,
  }) : super(
          code: 'PARSING_ERROR',
          timestamp: timestamp ?? DateTime.now(),
        );

  factory DeeplinkParsingError.invalidFormat({
    required String url,
    String? details,
  }) {
    return DeeplinkParsingError(
      message: 'Invalid deeplink format: $url${details != null ? ' - $details' : ''}',
      originalUrl: url,
      context: {'details': details},
    );
  }

  factory DeeplinkParsingError.missingComponents({
    required String url,
    required List<String> missingComponents,
  }) {
    return DeeplinkParsingError(
      message: 'Missing required components: ${missingComponents.join(', ')}',
      originalUrl: url,
      context: {'missingComponents': missingComponents},
    );
  }

  @override
  String toString() {
    return 'DeeplinkParsingError: $message (URL: $originalUrl)';
  }
}

/// Error thrown when route resolution fails
class RouteResolutionError extends DeeplinkError {
  /// The module that was requested
  final String module;
  
  /// The feature that was requested
  final String feature;

  RouteResolutionError({
    required super.message,
    required this.module,
    required this.feature,
    super.context,
    DateTime? timestamp,
  }) : super(
          code: 'ROUTE_RESOLUTION_ERROR',
          timestamp: timestamp ?? DateTime.now(),
        );

  factory RouteResolutionError.routeNotFound({
    required String module,
    required String feature,
  }) {
    return RouteResolutionError(
      message: 'Route not found: $module/$feature',
      module: module,
      feature: feature,
    );
  }

  factory RouteResolutionError.configurationError({
    required String module,
    required String feature,
    required String details,
  }) {
    return RouteResolutionError(
      message: 'Configuration error for route $module/$feature: $details',
      module: module,
      feature: feature,
      context: {'details': details},
    );
  }

  @override
  String toString() {
    return 'RouteResolutionError: $message (Route: $module/$feature)';
  }
}

/// Error thrown when permission validation fails
class PermissionError extends DeeplinkError {
  /// The user ID that was denied permission
  final String userId;
  
  /// The required permissions that were missing
  final List<String> requiredPermissions;

  PermissionError({
    required super.message,
    required this.userId,
    required this.requiredPermissions,
    super.context,
    DateTime? timestamp,
  }) : super(
          code: 'PERMISSION_ERROR',
          timestamp: timestamp ?? DateTime.now(),
        );

  factory PermissionError.accessDenied({
    required String userId,
    required List<String> requiredPermissions,
    String? route,
  }) {
    return PermissionError(
      message: 'Access denied for user $userId. Required permissions: ${requiredPermissions.join(', ')}',
      userId: userId,
      requiredPermissions: requiredPermissions,
      context: {'route': route},
    );
  }

  factory PermissionError.authenticationRequired({
    required String route,
  }) {
    return PermissionError(
      message: 'Authentication required for route: $route',
      userId: '',
      requiredPermissions: [],
      context: {'route': route},
    );
  }

  @override
  String toString() {
    return 'PermissionError: $message (User: $userId)';
  }
}

/// Error thrown when navigation fails
class NavigationError extends DeeplinkError {
  /// The target screen that failed to navigate to
  final String targetScreen;

  NavigationError({
    required super.message,
    required this.targetScreen,
    super.context,
    DateTime? timestamp,
  }) : super(
          code: 'NAVIGATION_ERROR',
          timestamp: timestamp ?? DateTime.now(),
        );

  factory NavigationError.screenNotFound({
    required String targetScreen,
  }) {
    return NavigationError(
      message: 'Target screen not found: $targetScreen',
      targetScreen: targetScreen,
    );
  }

  factory NavigationError.navigationFailed({
    required String targetScreen,
    required String reason,
  }) {
    return NavigationError(
      message: 'Navigation failed to $targetScreen: $reason',
      targetScreen: targetScreen,
      context: {'reason': reason},
    );
  }

  @override
  String toString() {
    return 'NavigationError: $message (Screen: $targetScreen)';
  }
}

/// Error thrown when configuration loading fails
class ConfigurationError extends DeeplinkError {
  /// The configuration file path that failed to load
  final String configPath;

  ConfigurationError({
    required super.message,
    required this.configPath,
    super.context,
    DateTime? timestamp,
  }) : super(
          code: 'CONFIGURATION_ERROR',
          timestamp: timestamp ?? DateTime.now(),
        );

  factory ConfigurationError.fileNotFound({
    required String configPath,
  }) {
    return ConfigurationError(
      message: 'Configuration file not found: $configPath',
      configPath: configPath,
    );
  }

  factory ConfigurationError.invalidFormat({
    required String configPath,
    required String details,
  }) {
    return ConfigurationError(
      message: 'Invalid configuration format in $configPath: $details',
      configPath: configPath,
      context: {'details': details},
    );
  }

  @override
  String toString() {
    return 'ConfigurationError: $message (Path: $configPath)';
  }
}