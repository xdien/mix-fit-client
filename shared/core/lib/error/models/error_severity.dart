/// Defines the severity levels for errors in the application
enum ErrorSeverity {
  /// Informational messages that don't require immediate action
  info,
  
  /// Warning messages that indicate potential issues
  warning,
  
  /// Error messages that indicate something went wrong
  error,
  
  /// Critical errors that require immediate attention
  critical;

  /// Returns the priority value for sorting errors by severity
  /// Higher values indicate higher priority
  int get priority {
    switch (this) {
      case ErrorSeverity.info:
        return 1;
      case ErrorSeverity.warning:
        return 2;
      case ErrorSeverity.error:
        return 3;
      case ErrorSeverity.critical:
        return 4;
    }
  }

  /// Returns whether this severity level should auto-dismiss
  bool get shouldAutoDismiss {
    switch (this) {
      case ErrorSeverity.info:
      case ErrorSeverity.warning:
        return true;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        return false;
    }
  }

  /// Returns the auto-dismiss duration for this severity level
  Duration get autoDismissDuration {
    switch (this) {
      case ErrorSeverity.info:
        return const Duration(seconds: 5);
      case ErrorSeverity.warning:
        return const Duration(seconds: 15);
      case ErrorSeverity.error:
        return const Duration(seconds: 30);
      case ErrorSeverity.critical:
        return Duration.zero; // Never auto-dismiss
    }
  }
}