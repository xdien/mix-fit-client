import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/app_error.dart';
import '../models/client_error.dart';
import '../models/error_action.dart';
import '../models/error_severity.dart';
import '../models/error_type.dart';
import '../models/network_error.dart';
import '../models/validation_error.dart';

/// Factory class for creating common error types with enhanced utilities
class ErrorFactory {
  /// Creates an API error from an HTTP response
  static ApiError createApiError({
    required int statusCode,
    required String endpoint,
    required String method,
    String? message,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    List<ErrorAction>? actions,
  }) {
    final errorMessage = message ?? _getDefaultApiErrorMessage(statusCode);
    
    return ApiError(
      message: errorMessage,
      statusCode: statusCode,
      endpoint: endpoint,
      method: method,
      requestData: requestData,
      responseData: responseData,
      actions: actions ?? _getDefaultApiErrorActions(statusCode),
    );
  }

  /// Creates a network error
  static NetworkError createNetworkError({
    required NetworkErrorType networkType,
    String? message,
    Duration? timeout,
    String? url,
    List<ErrorAction>? actions,
  }) {
    final errorMessage = message ?? _getDefaultNetworkErrorMessage(networkType);
    
    return NetworkError(
      message: errorMessage,
      networkType: networkType,
      timeout: timeout,
      url: url,
      actions: actions ?? _getDefaultNetworkErrorActions(networkType),
    );
  }

  /// Creates a validation error
  static ValidationError createValidationError({
    required Map<String, List<String>> fieldErrors,
    String? message,
    String? formId,
    List<ErrorAction>? actions,
  }) {
    final errorMessage = message ?? _getDefaultValidationErrorMessage(fieldErrors);
    
    return ValidationError(
      message: errorMessage,
      fieldErrors: fieldErrors,
      formId: formId,
      actions: actions,
    );
  }

  /// Creates a client error
  static ClientError createClientError({
    required String message,
    String? stackTrace,
    String? componentName,
    String? context,
    List<ErrorAction>? actions,
  }) {
    return ClientError(
      message: message,
      stackTrace: stackTrace ?? '',
      componentName: componentName,
      context: context,
      actions: actions,
    );
  }

  /// Creates a no internet connection error
  static NetworkError createNoInternetError({
    List<ErrorAction>? actions,
  }) {
    return createNetworkError(
      networkType: NetworkErrorType.noConnection,
      message: 'No internet connection available',
      actions: actions,
    );
  }

  /// Creates a timeout error
  static NetworkError createTimeoutError({
    Duration? timeout,
    String? url,
    List<ErrorAction>? actions,
  }) {
    return createNetworkError(
      networkType: NetworkErrorType.timeout,
      message: 'Request timed out',
      timeout: timeout,
      url: url,
      actions: actions,
    );
  }

  /// Creates an authentication error
  static ApiError createAuthenticationError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    return createApiError(
      statusCode: 401,
      endpoint: '/auth',
      method: 'POST',
      message: message ?? 'Authentication failed',
      actions: actions ?? [
        ErrorAction.login(() {}),
        ErrorAction.dismiss(() {}),
      ],
    );
  }

  /// Creates an authorization error
  static ApiError createAuthorizationError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    return createApiError(
      statusCode: 403,
      endpoint: '/api',
      method: 'GET',
      message: message ?? 'Access denied',
      actions: actions ?? [
        ErrorAction.contactSupport(() {}),
        ErrorAction.dismiss(() {}),
      ],
    );
  }

  /// Gets default error message for API errors based on status code
  static String _getDefaultApiErrorMessage(int statusCode) {
    if (statusCode >= 500) {
      return 'Server error occurred. Please try again later.';
    } else if (statusCode == 404) {
      return 'The requested resource was not found.';
    } else if (statusCode == 403) {
      return 'Access denied. You don\'t have permission to perform this action.';
    } else if (statusCode == 401) {
      return 'Authentication failed. Please log in again.';
    } else if (statusCode >= 400) {
      return 'Bad request. Please check your input and try again.';
    } else {
      return 'An unexpected error occurred.';
    }
  }

  /// Gets default error message for network errors
  static String _getDefaultNetworkErrorMessage(NetworkErrorType networkType) {
    switch (networkType) {
      case NetworkErrorType.noConnection:
        return 'No internet connection available';
      case NetworkErrorType.timeout:
        return 'Request timed out';
      case NetworkErrorType.dnsFailure:
        return 'Unable to resolve server address';
      case NetworkErrorType.connectionRefused:
        return 'Connection refused by server';
      case NetworkErrorType.certificateError:
      case NetworkErrorType.sslError:
        return 'SSL certificate error';
      case NetworkErrorType.cancelled:
        return 'Request was cancelled';
      case NetworkErrorType.poorQuality:
        return 'Poor network quality detected';
      case NetworkErrorType.unknown:
        return 'Network error occurred';
      case NetworkErrorType.connectivity:
        return 'Connectivity error occurred';
      case NetworkErrorType.websocket:
        return 'WebSocket connection error occurred';
    }
  }

  /// Gets default error message for validation errors
  static String _getDefaultValidationErrorMessage(Map<String, List<String>> fieldErrors) {
    final errorCount = fieldErrors.values.fold<int>(
      0, 
      (sum, errors) => sum + errors.length,
    );
    
    if (errorCount == 1) {
      return 'Please fix the validation error';
    } else {
      return 'Please fix $errorCount validation errors';
    }
  }

  /// Gets default actions for API errors
  static List<ErrorAction> _getDefaultApiErrorActions(int statusCode) {
    if (statusCode >= 500 || statusCode == 408 || statusCode == 429) {
      return [
        ErrorAction.retry(() {}),
        ErrorAction.dismiss(() {}),
      ];
    } else if (statusCode == 401) {
      return [
        ErrorAction.login(() {}),
        ErrorAction.dismiss(() {}),
      ];
    } else if (statusCode == 403) {
      return [
        ErrorAction.contactSupport(() {}),
        ErrorAction.dismiss(() {}),
      ];
    } else {
      return [
        ErrorAction.dismiss(() {}),
      ];
    }
  }

  /// Gets default actions for network errors
  static List<ErrorAction> _getDefaultNetworkErrorActions(NetworkErrorType networkType) {
    if (networkType.isRetryable) {
      return [
        ErrorAction.retry(() {}),
        ErrorAction.dismiss(() {}),
      ];
    } else {
      return [
        ErrorAction.contactSupport(() {}),
        ErrorAction.dismiss(() {}),
      ];
    }
  }

  // Enhanced factory methods for common scenarios

  /// Creates an error from a Dio exception
  static AppError fromDioException(DioException exception, {
    List<ErrorAction>? actions,
  }) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        final timeoutMs = exception.response?.requestOptions.connectTimeout;
        final timeoutDuration = timeoutMs is Duration ? timeoutMs : const Duration(milliseconds: 30000);
        return createTimeoutError(
          timeout: timeoutDuration,
          url: exception.requestOptions.uri.toString(),
          actions: actions,
        );

      case DioExceptionType.connectionError:
        if (exception.error is SocketException) {
          return createNoInternetError(actions: actions);
        }
        return createNetworkError(
          networkType: NetworkErrorType.connectionRefused,
          url: exception.requestOptions.uri.toString(),
          actions: actions,
        );

      case DioExceptionType.badCertificate:
        return createNetworkError(
          networkType: NetworkErrorType.certificateError,
          url: exception.requestOptions.uri.toString(),
          actions: actions,
        );

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode ?? 500;
        return createApiError(
          statusCode: statusCode,
          endpoint: exception.requestOptions.path,
          method: exception.requestOptions.method,
          message: exception.response?.data?['message'] ?? exception.message,
          requestData: exception.requestOptions.data,
          responseData: exception.response?.data,
          actions: actions,
        );

      case DioExceptionType.cancel:
        return createNetworkError(
          networkType: NetworkErrorType.cancelled,
          message: 'Request was cancelled',
          url: exception.requestOptions.uri.toString(),
          actions: actions,
        );

      case DioExceptionType.unknown:
      default:
        return createNetworkError(
          networkType: NetworkErrorType.unknown,
          message: exception.message ?? 'Unknown network error',
          url: exception.requestOptions.uri.toString(),
          actions: actions,
        );
    }
  }

  /// Creates an error from a generic exception
  static ClientError fromException(
    Exception exception, {
    String? componentName,
    String? context,
    List<ErrorAction>? actions,
  }) {
    return createClientError(
      message: exception.toString(),
      stackTrace: StackTrace.current.toString(),
      componentName: componentName,
      context: context,
      actions: actions,
    );
  }

  /// Creates an error from a Flutter error
  static ClientError fromFlutterError(
    FlutterError error, {
    String? componentName,
    List<ErrorAction>? actions,
  }) {
    return createClientError(
      message: error.message,
      stackTrace: error.stackTrace?.toString() ?? '',
      componentName: componentName,
      context: 'flutter_error',
      actions: actions,
    );
  }

  /// Creates a server maintenance error
  static ApiError createMaintenanceError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    return createApiError(
      statusCode: 503,
      endpoint: '/api',
      method: 'GET',
      message: message ?? 'Server is under maintenance. Please try again later.',
      actions: actions ?? [
        ErrorAction.retry(() {}),
        ErrorAction.dismiss(() {}),
      ],
    );
  }

  /// Creates a rate limit error
  static ApiError createRateLimitError({
    String? message,
    Duration? retryAfter,
    List<ErrorAction>? actions,
  }) {
    final retryMessage = retryAfter != null 
        ? 'Too many requests. Please try again in ${retryAfter.inSeconds} seconds.'
        : 'Too many requests. Please try again later.';
    
    return createApiError(
      statusCode: 429,
      endpoint: '/api',
      method: 'GET',
      message: message ?? retryMessage,
      actions: actions ?? [
        ErrorAction.retry(() {}),
        ErrorAction.dismiss(() {}),
      ],
    );
  }

  /// Creates a data corruption error
  static ClientError createDataCorruptionError({
    String? message,
    String? componentName,
    List<ErrorAction>? actions,
  }) {
    return createClientError(
      message: message ?? 'Data corruption detected. Please refresh the app.',
      stackTrace: StackTrace.current.toString(),
      componentName: componentName,
      context: 'data_corruption',
      actions: actions ?? [
        ErrorAction(
          id: 'refresh',
          label: 'Refresh',
          icon: Icons.refresh,
          onPressed: () {},
          isPrimary: true,
        ),
        ErrorAction.dismiss(() {}),
      ],
    );
  }

  /// Creates a permission denied error
  static ClientError createPermissionError({
    String? message,
    String? permission,
    List<ErrorAction>? actions,
  }) {
    final permissionMessage = permission != null
        ? 'Permission denied: $permission'
        : 'Permission denied';
    
    return createClientError(
      message: message ?? permissionMessage,
      stackTrace: StackTrace.current.toString(),
      context: 'permission_denied',
      actions: actions ?? [
        ErrorAction(
          id: 'settings',
          label: 'Open Settings',
          icon: Icons.settings,
          onPressed: () {},
          isPrimary: true,
        ),
        ErrorAction.dismiss(() {}),
      ],
    );
  }

  /// Creates a storage full error
  static ClientError createStorageFullError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    return createClientError(
      message: message ?? 'Device storage is full. Please free up space.',
      stackTrace: StackTrace.current.toString(),
      context: 'storage_full',
      actions: actions ?? [
        ErrorAction(
          id: 'manage_storage',
          label: 'Manage Storage',
          icon: Icons.storage,
          onPressed: () {},
          isPrimary: true,
        ),
        ErrorAction.dismiss(() {}),
      ],
    );
  }
}