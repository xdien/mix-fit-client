import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../models/api_error.dart';
import '../models/error_action.dart';
import '../models/network_error.dart';
import '../services/error_service_interface.dart';
import '../services/retry_service.dart';

/// Dio interceptor that integrates API errors with the error service
class ErrorServiceInterceptor extends Interceptor {
  final IErrorService _errorService;
  final RetryService _retryService;

  ErrorServiceInterceptor({
    IErrorService? errorService,
    RetryService? retryService,
  })  : _errorService = errorService ?? GetIt.instance<IErrorService>(),
        _retryService = retryService ?? RetryService();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Create appropriate error based on the type of Dio exception
    final appError = _createErrorFromDioException(err);
    
    // Show the error through the error service
    _errorService.showError(appError);
    
    // Continue with the error handling chain
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log successful responses for debugging
    _logResponse(response);
    super.onResponse(response, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Log requests for debugging
    _logRequest(options);
    super.onRequest(options, handler);
  }

  /// Creates an appropriate AppError from a DioException
  dynamic _createErrorFromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          message: _getTimeoutMessage(dioException.type),
          networkType: NetworkErrorType.timeout,
          timeout: _getTimeoutDuration(dioException),
          url: dioException.requestOptions.uri.toString(),
        );

      case DioExceptionType.badResponse:
        return _createApiErrorFromResponse(dioException);

      case DioExceptionType.cancel:
        return NetworkError(
          message: 'Request was cancelled',
          networkType: NetworkErrorType.cancelled,
          url: dioException.requestOptions.uri.toString(),
        );

      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'Connection error: ${dioException.message}',
          networkType: NetworkErrorType.noConnection,
          url: dioException.requestOptions.uri.toString(),
        );

      case DioExceptionType.badCertificate:
        return NetworkError(
          message: 'SSL certificate error',
          networkType: NetworkErrorType.sslError,
          url: dioException.requestOptions.uri.toString(),
        );

      case DioExceptionType.unknown:
      default:
        return NetworkError(
          message: 'Unknown network error: ${dioException.message}',
          networkType: NetworkErrorType.unknown,
          url: dioException.requestOptions.uri.toString(),
        );
    }
  }

  /// Creates an ApiError from a bad response
  ApiError _createApiErrorFromResponse(DioException dioException) {
    final response = dioException.response;
    final statusCode = response?.statusCode ?? 0;
    final requestOptions = dioException.requestOptions;

    // Extract error message from response
    String message = _extractErrorMessage(response, statusCode);

    // Create retry action for certain status codes
    final actions = _createRetryActionsForStatusCode(statusCode, requestOptions);

    return ApiError(
      message: message,
      statusCode: statusCode,
      endpoint: requestOptions.path,
      method: requestOptions.method,
      requestData: _sanitizeRequestData(requestOptions.data),
      responseData: _sanitizeResponseData(response?.data),
      actions: actions,
    );
  }

  /// Extracts a user-friendly error message from the response
  String _extractErrorMessage(Response? response, int statusCode) {
    if (response?.data != null) {
      try {
        final data = response!.data;
        
        // Try to extract message from common API error formats
        if (data is Map<String, dynamic>) {
          // Common error message fields
          final messageFields = ['message', 'error', 'detail', 'description'];
          for (final field in messageFields) {
            if (data.containsKey(field) && data[field] is String) {
              return data[field] as String;
            }
          }
          
          // Handle validation errors
          if (data.containsKey('errors') && data['errors'] is Map) {
            final errors = data['errors'] as Map<String, dynamic>;
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }
      } catch (e) {
        // If parsing fails, fall back to status code message
      }
    }

    // Default messages based on status code
    return _getDefaultMessageForStatusCode(statusCode);
  }

  /// Returns default error messages for common HTTP status codes
  String _getDefaultMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request - please check your input';
      case 401:
        return 'Authentication required - please log in';
      case 403:
        return 'Access denied - insufficient permissions';
      case 404:
        return 'Resource not found';
      case 408:
        return 'Request timeout - please try again';
      case 409:
        return 'Conflict - resource already exists';
      case 422:
        return 'Validation error - please check your input';
      case 429:
        return 'Too many requests - please wait and try again';
      case 500:
        return 'Internal server error - please try again later';
      case 502:
        return 'Bad gateway - server is temporarily unavailable';
      case 503:
        return 'Service unavailable - please try again later';
      case 504:
        return 'Gateway timeout - please try again';
      default:
        return 'Request failed with status $statusCode';
    }
  }

  /// Creates retry actions for recoverable errors
  List<ErrorAction>? _createRetryActionsForStatusCode(int statusCode, RequestOptions options) {
    // Only create retry actions for certain status codes
    final retryableStatusCodes = [408, 429, 500, 502, 503, 504];
    
    if (!retryableStatusCodes.contains(statusCode)) {
      return null;
    }

    // Create retry action that will retry the original request
    final retryAction = ErrorAction.retry(() async {
      await retryRequest(options);
    });

    return [retryAction];
  }

  /// Retries a failed request using the retry service
  Future<Response?> retryRequest(RequestOptions options) async {
    return await _retryService.retryRequest(options);
  }

  /// Checks if a request is retryable
  bool isRetryable(DioException error) {
    return _retryService.isRetryable(error);
  }

  /// Gets timeout message based on exception type
  String _getTimeoutMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - please check your internet connection';
      case DioExceptionType.sendTimeout:
        return 'Send timeout - request took too long to send';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout - server took too long to respond';
      default:
        return 'Request timeout';
    }
  }

  /// Gets timeout duration from DioException
  Duration? _getTimeoutDuration(DioException dioException) {
    final options = dioException.requestOptions;
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return options.connectTimeout;
      case DioExceptionType.sendTimeout:
        return options.sendTimeout;
      case DioExceptionType.receiveTimeout:
        return options.receiveTimeout;
      default:
        return null;
    }
  }

  /// Sanitizes request data for logging (removes sensitive information)
  Map<String, dynamic>? _sanitizeRequestData(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(data);
        
        // Remove sensitive fields
        final sensitiveFields = [
          'password', 'token', 'secret', 'key', 'authorization',
          'auth', 'credential', 'pass', 'pwd'
        ];
        
        for (final field in sensitiveFields) {
          if (sanitized.containsKey(field)) {
            sanitized[field] = '[REDACTED]';
          }
        }
        
        return sanitized;
      }
      
      // For non-map data, return a simple representation
      return {'data': data.toString()};
    } catch (e) {
      return {'error': 'Failed to sanitize request data'};
    }
  }

  /// Sanitizes response data for logging
  Map<String, dynamic>? _sanitizeResponseData(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is Map<String, dynamic>) {
        // For response data, we typically don't need to sanitize as much
        // but we should limit the size to prevent memory issues
        final sanitized = Map<String, dynamic>.from(data);
        
        // Limit the size of large responses
        if (sanitized.toString().length > 1000) {
          return {'message': 'Response data too large to display'};
        }
        
        return sanitized;
      }
      
      return {'data': data.toString()};
    } catch (e) {
      return {'error': 'Failed to sanitize response data'};
    }
  }

  /// Logs request for debugging
  void _logRequest(RequestOptions options) {
    print('🚀 API Request: ${options.method} ${options.uri}');
    if (options.data != null) {
      final sanitizedData = _sanitizeRequestData(options.data);
      print('📤 Request Data: $sanitizedData');
    }
  }

  /// Logs response for debugging
  void _logResponse(Response response) {
    print('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
    if (response.data != null) {
      final sanitizedData = _sanitizeResponseData(response.data);
      print('📥 Response Data: $sanitizedData');
    }
  }
}