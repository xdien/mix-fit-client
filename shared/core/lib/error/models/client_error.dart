import 'app_error.dart';
import 'error_action.dart';
import 'error_severity.dart';
import 'error_type.dart';

/// Represents a client-side application error
class ClientError extends AppError {
  /// Stack trace of the error
  final String stackTrace;
  
  /// Name of the component where the error occurred
  final String? componentName;
  
  /// Additional context about the error
  final String? context;

  ClientError({
    super.id,
    required super.message,
    required this.stackTrace,
    this.componentName,
    this.context,
    super.timestamp,
    super.actions,
  }) : super(
          severity: ErrorSeverity.error,
          type: ErrorType.client,
          metadata: {
            'stackTrace': stackTrace,
            'componentName': componentName,
            'context': context,
            'hasStackTrace': stackTrace.isNotEmpty,
          },
        );

  /// Constructor with custom metadata (used for consolidation)
  ClientError.withMetadata({
    super.id,
    required super.message,
    required this.stackTrace,
    this.componentName,
    this.context,
    super.timestamp,
    super.actions,
    required Map<String, dynamic> metadata,
  }) : super.withMetadata(
          severity: ErrorSeverity.error,
          type: ErrorType.client,
          metadata: metadata,
        );

  /// Returns whether this error has a stack trace
  bool get hasStackTrace => stackTrace.isNotEmpty;

  /// Returns whether this error has component context
  bool get hasComponentContext => componentName != null;

  /// Returns a shortened version of the stack trace for display
  String get shortStackTrace {
    final lines = stackTrace.split('\n');
    if (lines.length <= 3) return stackTrace;
    
    return '${lines.take(3).join('\n')}\n... (${lines.length - 3} more lines)';
  }

  @override
  ClientError copyWith({
    String? id,
    String? message,
    ErrorSeverity? severity,
    ErrorType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<ErrorAction>? actions,
    String? stackTrace,
    String? componentName,
    String? context,
  }) {
    return ClientError(
      id: id ?? this.id,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      componentName: componentName ?? this.componentName,
      context: context ?? this.context,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
    );
  }

  /// Creates a ClientError from a map
  static ClientError fromMap(Map<String, dynamic> map) {
    return ClientError(
      id: map['id'],
      message: map['message'],
      stackTrace: map['stackTrace'] ?? '',
      componentName: map['componentName'],
      context: map['context'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'stackTrace': stackTrace,
      'componentName': componentName,
      'context': context,
      'hasStackTrace': hasStackTrace,
      'hasComponentContext': hasComponentContext,
      'shortStackTrace': shortStackTrace,
    });
    return map;
  }

  @override
  String toString() {
    return 'ClientError{id: $id, message: $message, componentName: $componentName, context: $context}';
  }
}