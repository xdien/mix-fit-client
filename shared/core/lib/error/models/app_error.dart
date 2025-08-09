import 'package:uuid/uuid.dart';

import 'error_action.dart';
import 'error_severity.dart';
import 'error_type.dart';

/// Abstract base class for all application errors
abstract class AppError {
  /// Unique identifier for the error
  final String id;
  
  /// Human-readable error message
  final String message;
  
  /// Severity level of the error
  final ErrorSeverity severity;
  
  /// Type/category of the error
  final ErrorType type;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;
  
  /// Additional metadata associated with the error
  final Map<String, dynamic>? metadata;
  
  /// List of actions that can be taken to resolve the error
  final List<ErrorAction>? actions;

  AppError({
    String? id,
    required this.message,
    required this.severity,
    required this.type,
    DateTime? timestamp,
    this.metadata,
    this.actions,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  /// Constructor that allows metadata override (used for consolidation)
  AppError.withMetadata({
    String? id,
    required this.message,
    required this.severity,
    required this.type,
    DateTime? timestamp,
    required Map<String, dynamic> metadata,
    this.actions,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       metadata = metadata;

  /// Returns the priority of this error for queue ordering
  int get priority => severity.priority;

  /// Returns whether this error should auto-dismiss
  bool get shouldAutoDismiss => severity.shouldAutoDismiss;

  /// Returns the auto-dismiss duration for this error
  Duration get autoDismissDuration => severity.autoDismissDuration;

  /// Returns whether this error requires user action
  bool get requiresUserAction => type.requiresUserAction;

  /// Returns whether this error should be logged
  bool get shouldLog => type.shouldLog;

  /// Returns a copy of this error with updated properties
  AppError copyWith({
    String? id,
    String? message,
    ErrorSeverity? severity,
    ErrorType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<ErrorAction>? actions,
  });

  /// Converts the error to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'severity': severity.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'priority': priority,
      'shouldAutoDismiss': shouldAutoDismiss,
      'requiresUserAction': requiresUserAction,
    };
  }

  /// Creates an error from a map (for deserialization)
  static AppError fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('Subclasses must implement fromMap');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppError{id: $id, message: $message, severity: $severity, type: $type, timestamp: $timestamp}';
  }
}