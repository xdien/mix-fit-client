/// Enum representing the status of a navigation operation
enum NavigationStatus {
  /// Navigation completed successfully
  success,
  
  /// User lacks required permissions for the route
  permissionDenied,
  
  /// The requested route was not found in configuration
  routeNotFound,
  
  /// Invalid or missing parameters for the route
  invalidParameters,
  
  /// General navigation error occurred
  navigationError,
  
  /// User authentication is required
  authenticationRequired,
  
  /// The target screen is not available
  screenNotAvailable,
  
  /// Navigation was cancelled by user or system
  cancelled;

  /// Check if the status represents a successful navigation
  bool get isSuccess => this == NavigationStatus.success;
  
  /// Check if the status represents an error condition
  bool get isError => !isSuccess;
  
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case NavigationStatus.success:
        return 'Navigation completed successfully';
      case NavigationStatus.permissionDenied:
        return 'Permission denied for this route';
      case NavigationStatus.routeNotFound:
        return 'Route not found';
      case NavigationStatus.invalidParameters:
        return 'Invalid parameters provided';
      case NavigationStatus.navigationError:
        return 'Navigation error occurred';
      case NavigationStatus.authenticationRequired:
        return 'Authentication required';
      case NavigationStatus.screenNotAvailable:
        return 'Target screen not available';
      case NavigationStatus.cancelled:
        return 'Navigation cancelled';
    }
  }
}

/// Represents the result of a navigation operation
/// Contains status, message, and metadata about the navigation
class NavigationResult {
  /// Status of the navigation operation
  final NavigationStatus status;
  
  /// Detailed message about the navigation result
  final String message;
  
  /// Target screen that was navigated to (if successful)
  final String? targetScreen;
  
  /// Timestamp when the navigation occurred
  final DateTime timestamp;
  
  /// Additional metadata about the navigation
  final Map<String, dynamic> metadata;
  
  /// Error details if navigation failed
  final String? errorDetails;

  const NavigationResult({
    required this.status,
    required this.message,
    this.targetScreen,
    required this.timestamp,
    this.metadata = const {},
    this.errorDetails,
  });

  /// Create a successful navigation result
  factory NavigationResult.success({
    required String targetScreen,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return NavigationResult(
      status: NavigationStatus.success,
      message: message ?? 'Navigation completed successfully',
      targetScreen: targetScreen,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Create a failed navigation result
  factory NavigationResult.failure({
    required NavigationStatus status,
    required String message,
    String? errorDetails,
    Map<String, dynamic>? metadata,
  }) {
    return NavigationResult(
      status: status,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      errorDetails: errorDetails,
    );
  }

  /// Create a permission denied result
  factory NavigationResult.permissionDenied({
    required String message,
    String? fallbackRoute,
    Map<String, dynamic>? metadata,
  }) {
    return NavigationResult(
      status: NavigationStatus.permissionDenied,
      message: message,
      timestamp: DateTime.now(),
      metadata: {
        ...?metadata,
        if (fallbackRoute != null) 'fallbackRoute': fallbackRoute,
      },
    );
  }

  /// Create a route not found result
  factory NavigationResult.routeNotFound({
    required String message,
    String? requestedRoute,
    Map<String, dynamic>? metadata,
  }) {
    return NavigationResult(
      status: NavigationStatus.routeNotFound,
      message: message,
      timestamp: DateTime.now(),
      metadata: {
        ...?metadata,
        if (requestedRoute != null) 'requestedRoute': requestedRoute,
      },
    );
  }

  /// Check if the navigation was successful
  bool get isSuccess => status.isSuccess;
  
  /// Check if the navigation failed
  bool get isFailure => status.isError;

  /// Get fallback route from metadata if available
  String? get fallbackRoute => metadata['fallbackRoute'] as String?;

  /// Create a copy of the result with modified properties
  NavigationResult copyWith({
    NavigationStatus? status,
    String? message,
    String? targetScreen,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? errorDetails,
  }) {
    return NavigationResult(
      status: status ?? this.status,
      message: message ?? this.message,
      targetScreen: targetScreen ?? this.targetScreen,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      errorDetails: errorDetails ?? this.errorDetails,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'message': message,
      'targetScreen': targetScreen,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'errorDetails': errorDetails,
    };
  }

  /// Create from JSON deserialization
  factory NavigationResult.fromJson(Map<String, dynamic> json) {
    return NavigationResult(
      status: NavigationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NavigationStatus.navigationError,
      ),
      message: json['message'] as String,
      targetScreen: json['targetScreen'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      errorDetails: json['errorDetails'] as String?,
    );
  }

  @override
  String toString() {
    return 'NavigationResult(status: ${status.name}, message: $message, '
           'targetScreen: $targetScreen, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NavigationResult &&
        other.status == status &&
        other.message == message &&
        other.targetScreen == targetScreen &&
        other.errorDetails == errorDetails;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        message.hashCode ^
        targetScreen.hashCode ^
        timestamp.hashCode;
  }
}