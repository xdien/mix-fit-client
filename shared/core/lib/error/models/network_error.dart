import 'app_error.dart';
import 'error_action.dart';
import 'error_severity.dart';
import 'error_type.dart';

/// Defines the specific type of network error
enum NetworkErrorType {
  /// No internet connection available
  noConnection,
  
  /// Request timed out
  timeout,
  
  /// DNS resolution failed
  dnsFailure,
  
  /// Connection refused by server
  connectionRefused,
  
  /// SSL/TLS certificate error
  certificateError,
  
  /// SSL certificate error (alias for certificateError)
  sslError,
  
  /// Request was cancelled
  cancelled,
  
  /// Poor network quality
  poorQuality,
  
  /// Unknown network error
  unknown;

  /// Returns the severity for this network error type
  ErrorSeverity get severity {
    switch (this) {
      case NetworkErrorType.noConnection:
        return ErrorSeverity.error;
      case NetworkErrorType.timeout:
      case NetworkErrorType.poorQuality:
        return ErrorSeverity.warning;
      case NetworkErrorType.dnsFailure:
      case NetworkErrorType.connectionRefused:
      case NetworkErrorType.certificateError:
      case NetworkErrorType.sslError:
        return ErrorSeverity.error;
      case NetworkErrorType.cancelled:
        return ErrorSeverity.info;
      case NetworkErrorType.unknown:
        return ErrorSeverity.warning;
    }
  }

  /// Returns whether this error type is retryable
  bool get isRetryable {
    switch (this) {
      case NetworkErrorType.noConnection:
      case NetworkErrorType.timeout:
      case NetworkErrorType.poorQuality:
      case NetworkErrorType.unknown:
        return true;
      case NetworkErrorType.dnsFailure:
      case NetworkErrorType.connectionRefused:
      case NetworkErrorType.certificateError:
      case NetworkErrorType.sslError:
      case NetworkErrorType.cancelled:
        return false;
    }
  }
}

/// Represents a network connectivity error
class NetworkError extends AppError {
  /// Specific type of network error
  final NetworkErrorType networkType;
  
  /// Timeout duration if applicable
  final Duration? timeout;
  
  /// URL that failed to load
  final String? url;

  NetworkError({
    super.id,
    required super.message,
    required this.networkType,
    this.timeout,
    this.url,
    super.timestamp,
    super.actions,
  }) : super(
          severity: networkType.severity,
          type: ErrorType.network,
          metadata: {
            'networkType': networkType.name,
            'timeout': timeout?.inMilliseconds,
            'url': url,
            'isRetryable': networkType.isRetryable,
          },
        );

  /// Constructor with custom metadata (used for consolidation)
  NetworkError.withMetadata({
    super.id,
    required super.message,
    required this.networkType,
    this.timeout,
    this.url,
    super.timestamp,
    super.actions,
    required Map<String, dynamic> metadata,
  }) : super.withMetadata(
          severity: networkType.severity,
          type: ErrorType.network,
          metadata: metadata,
        );

  /// Returns whether this network error is retryable
  bool get isRetryable => networkType.isRetryable;

  /// Returns whether this indicates a complete loss of connectivity
  bool get isOffline => networkType == NetworkErrorType.noConnection;

  /// Returns whether this is a timeout error
  bool get isTimeout => networkType == NetworkErrorType.timeout;

  @override
  NetworkError copyWith({
    String? id,
    String? message,
    ErrorSeverity? severity,
    ErrorType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<ErrorAction>? actions,
    NetworkErrorType? networkType,
    Duration? timeout,
    String? url,
  }) {
    return NetworkError(
      id: id ?? this.id,
      message: message ?? this.message,
      networkType: networkType ?? this.networkType,
      timeout: timeout ?? this.timeout,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
    );
  }

  /// Creates a NetworkError from a map
  static NetworkError fromMap(Map<String, dynamic> map) {
    final networkTypeName = map['networkType'] as String;
    final networkType = NetworkErrorType.values.firstWhere(
      (type) => type.name == networkTypeName,
      orElse: () => NetworkErrorType.unknown,
    );

    final timeoutMs = map['timeout'] as int?;
    final timeout = timeoutMs != null ? Duration(milliseconds: timeoutMs) : null;

    return NetworkError(
      id: map['id'],
      message: map['message'],
      networkType: networkType,
      timeout: timeout,
      url: map['url'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'networkType': networkType.name,
      'timeout': timeout?.inMilliseconds,
      'url': url,
      'isRetryable': isRetryable,
      'isOffline': isOffline,
      'isTimeout': isTimeout,
    });
    return map;
  }

  @override
  String toString() {
    return 'NetworkError{id: $id, message: $message, networkType: $networkType, url: $url}';
  }
}