import 'app_error.dart';
import 'error_action.dart';
import 'error_severity.dart';
import 'error_type.dart';

/// Represents an error that occurred during API communication
class ApiError extends AppError {
  /// HTTP status code of the response
  final int statusCode;
  
  /// API endpoint that caused the error
  final String endpoint;
  
  /// HTTP method used for the request
  final String method;
  
  /// Request data that was sent (for debugging)
  final Map<String, dynamic>? requestData;
  
  /// Response data received from the server
  final Map<String, dynamic>? responseData;

  ApiError({
    super.id,
    required super.message,
    required this.statusCode,
    required this.endpoint,
    required this.method,
    super.timestamp,
    this.requestData,
    this.responseData,
    super.actions,
  }) : super(
          severity: _getSeverityFromStatusCode(statusCode),
          type: ErrorType.api,
          metadata: {
            'statusCode': statusCode,
            'endpoint': endpoint,
            'method': method,
            'requestData': requestData,
            'responseData': responseData,
          },
        );

  /// Constructor with custom metadata (used for consolidation)
  ApiError.withMetadata({
    super.id,
    required super.message,
    required this.statusCode,
    required this.endpoint,
    required this.method,
    super.timestamp,
    this.requestData,
    this.responseData,
    super.actions,
    required Map<String, dynamic> metadata,
  }) : super.withMetadata(
          severity: _getSeverityFromStatusCode(statusCode),
          type: ErrorType.api,
          metadata: metadata,
        );

  /// Determines error severity based on HTTP status code
  static ErrorSeverity _getSeverityFromStatusCode(int statusCode) {
    if (statusCode >= 500) {
      return ErrorSeverity.critical;
    } else if (statusCode >= 400) {
      return ErrorSeverity.error;
    } else if (statusCode >= 300) {
      return ErrorSeverity.warning;
    } else {
      return ErrorSeverity.info;
    }
  }

  /// Returns whether this is a client error (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Returns whether this is a server error (5xx)
  bool get isServerError => statusCode >= 500;

  /// Returns whether this is an authentication error
  bool get isAuthenticationError => statusCode == 401;

  /// Returns whether this is an authorization error
  bool get isAuthorizationError => statusCode == 403;

  /// Returns whether this error is retryable
  bool get isRetryable => isServerError || statusCode == 408 || statusCode == 429;

  @override
  ApiError copyWith({
    String? id,
    String? message,
    ErrorSeverity? severity,
    ErrorType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<ErrorAction>? actions,
    int? statusCode,
    String? endpoint,
    String? method,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) {
    return ApiError(
      id: id ?? this.id,
      message: message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      timestamp: timestamp ?? this.timestamp,
      requestData: requestData ?? this.requestData,
      responseData: responseData ?? this.responseData,
      actions: actions ?? this.actions,
    );
  }

  /// Creates an ApiError from a map
  static ApiError fromMap(Map<String, dynamic> map) {
    return ApiError(
      id: map['id'],
      message: map['message'],
      statusCode: map['statusCode'],
      endpoint: map['endpoint'],
      method: map['method'],
      timestamp: DateTime.parse(map['timestamp']),
      requestData: map['requestData'],
      responseData: map['responseData'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'statusCode': statusCode,
      'endpoint': endpoint,
      'method': method,
      'requestData': requestData,
      'responseData': responseData,
      'isClientError': isClientError,
      'isServerError': isServerError,
      'isAuthenticationError': isAuthenticationError,
      'isAuthorizationError': isAuthorizationError,
      'isRetryable': isRetryable,
    });
    return map;
  }

  @override
  String toString() {
    return 'ApiError{id: $id, message: $message, statusCode: $statusCode, endpoint: $endpoint, method: $method}';
  }
}