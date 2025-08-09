import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/models/api_error.dart';
import '../../../lib/error/models/client_error.dart';
import '../../../lib/error/models/error_action.dart';
import '../../../lib/error/models/error_severity.dart';
import '../../../lib/error/models/error_type.dart';
import '../../../lib/error/models/network_error.dart';
import '../../../lib/error/models/validation_error.dart';
import '../../../lib/error/utils/error_factory.dart';

void main() {
  group('ErrorFactory', () {
    group('createApiError', () {
      test('creates API error with correct properties', () {
        final error = ErrorFactory.createApiError(
          statusCode: 404,
          endpoint: '/api/users',
          method: 'GET',
          message: 'User not found',
        );

        expect(error, isA<ApiError>());
        expect(error.statusCode, equals(404));
        expect(error.endpoint, equals('/api/users'));
        expect(error.method, equals('GET'));
        expect(error.message, equals('User not found'));
        expect(error.severity, equals(ErrorSeverity.error));
        expect(error.type, equals(ErrorType.api));
      });

      test('uses default message for status code', () {
        final error = ErrorFactory.createApiError(
          statusCode: 500,
          endpoint: '/api/test',
          method: 'POST',
        );

        expect(error.message, equals('Server error occurred. Please try again later.'));
        expect(error.severity, equals(ErrorSeverity.critical));
      });

      test('includes default actions based on status code', () {
        final error = ErrorFactory.createApiError(
          statusCode: 500,
          endpoint: '/api/test',
          method: 'POST',
        );

        expect(error.actions, isNotNull);
        expect(error.actions!.length, equals(2));
        expect(error.actions!.first.id, equals('retry'));
        expect(error.actions!.last.id, equals('dismiss'));
      });
    });

    group('createNetworkError', () {
      test('creates network error with correct properties', () {
        final error = ErrorFactory.createNetworkError(
          networkType: NetworkErrorType.timeout,
          message: 'Request timed out',
          timeout: const Duration(seconds: 30),
          url: 'https://api.example.com',
        );

        expect(error, isA<NetworkError>());
        expect(error.networkType, equals(NetworkErrorType.timeout));
        expect(error.message, equals('Request timed out'));
        expect(error.timeout, equals(const Duration(seconds: 30)));
        expect(error.url, equals('https://api.example.com'));
        expect(error.severity, equals(ErrorSeverity.warning));
        expect(error.type, equals(ErrorType.network));
      });

      test('uses default message for network type', () {
        final error = ErrorFactory.createNetworkError(
          networkType: NetworkErrorType.noConnection,
        );

        expect(error.message, equals('No internet connection available'));
        expect(error.severity, equals(ErrorSeverity.error));
      });
    });

    group('createValidationError', () {
      test('creates validation error with correct properties', () {
        final fieldErrors = {
          'email': ['Invalid email format'],
          'password': ['Password too short', 'Password must contain numbers'],
        };

        final error = ErrorFactory.createValidationError(
          fieldErrors: fieldErrors,
          formId: 'login_form',
        );

        expect(error, isA<ValidationError>());
        expect(error.fieldErrors, equals(fieldErrors));
        expect(error.formId, equals('login_form'));
        expect(error.severity, equals(ErrorSeverity.warning));
        expect(error.type, equals(ErrorType.validation));
      });

      test('generates default message based on error count', () {
        final fieldErrors = {
          'email': ['Invalid email format'],
        };

        final error = ErrorFactory.createValidationError(
          fieldErrors: fieldErrors,
        );

        expect(error.message, equals('Please fix the validation error'));

        final multipleErrors = {
          'email': ['Invalid email format'],
          'password': ['Password too short'],
        };

        final multiError = ErrorFactory.createValidationError(
          fieldErrors: multipleErrors,
        );

        expect(multiError.message, equals('Please fix 2 validation errors'));
      });
    });

    group('createClientError', () {
      test('creates client error with correct properties', () {
        final error = ErrorFactory.createClientError(
          message: 'Widget build failed',
          stackTrace: 'Stack trace here',
          componentName: 'MyWidget',
          context: 'build_context',
        );

        expect(error, isA<ClientError>());
        expect(error.message, equals('Widget build failed'));
        expect(error.stackTrace, equals('Stack trace here'));
        expect(error.componentName, equals('MyWidget'));
        expect(error.context, equals('build_context'));
        expect(error.severity, equals(ErrorSeverity.error));
        expect(error.type, equals(ErrorType.client));
      });
    });

    group('convenience methods', () {
      test('createNoInternetError creates correct network error', () {
        final error = ErrorFactory.createNoInternetError();

        expect(error.networkType, equals(NetworkErrorType.noConnection));
        expect(error.message, equals('No internet connection available'));
      });

      test('createTimeoutError creates correct network error', () {
        final error = ErrorFactory.createTimeoutError(
          timeout: const Duration(seconds: 30),
          url: 'https://api.example.com',
        );

        expect(error.networkType, equals(NetworkErrorType.timeout));
        expect(error.message, equals('Request timed out'));
        expect(error.timeout, equals(const Duration(seconds: 30)));
        expect(error.url, equals('https://api.example.com'));
      });

      test('createAuthenticationError creates correct API error', () {
        final error = ErrorFactory.createAuthenticationError();

        expect(error.statusCode, equals(401));
        expect(error.message, equals('Authentication failed'));
        expect(error.actions!.first.id, equals('login'));
      });

      test('createAuthorizationError creates correct API error', () {
        final error = ErrorFactory.createAuthorizationError();

        expect(error.statusCode, equals(403));
        expect(error.message, equals('Access denied'));
        expect(error.actions!.first.id, equals('contact_support'));
      });
    });

    group('fromDioException', () {
      test('creates timeout error from connection timeout', () {
        final dioException = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        final error = ErrorFactory.fromDioException(dioException);

        expect(error, isA<NetworkError>());
        final networkError = error as NetworkError;
        expect(networkError.networkType, equals(NetworkErrorType.timeout));
      });

      test('creates network error from connection error', () {
        final dioException = DioException(
          type: DioExceptionType.connectionError,
          error: const SocketException('Connection failed'),
          requestOptions: RequestOptions(path: '/test'),
        );

        final error = ErrorFactory.fromDioException(dioException);

        expect(error, isA<NetworkError>());
        final networkError = error as NetworkError;
        expect(networkError.networkType, equals(NetworkErrorType.noConnection));
      });

      test('creates API error from bad response', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/test', method: 'GET'),
          ),
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
        );

        final error = ErrorFactory.fromDioException(dioException);

        expect(error, isA<ApiError>());
        final apiError = error as ApiError;
        expect(apiError.statusCode, equals(404));
        expect(apiError.endpoint, equals('/test'));
        expect(apiError.method, equals('GET'));
      });

      test('creates certificate error from bad certificate', () {
        final dioException = DioException(
          type: DioExceptionType.badCertificate,
          requestOptions: RequestOptions(path: '/test'),
        );

        final error = ErrorFactory.fromDioException(dioException);

        expect(error, isA<NetworkError>());
        final networkError = error as NetworkError;
        expect(networkError.networkType, equals(NetworkErrorType.certificateError));
      });

      test('creates cancelled error from cancel', () {
        final dioException = DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: '/test'),
        );

        final error = ErrorFactory.fromDioException(dioException);

        expect(error, isA<NetworkError>());
        final networkError = error as NetworkError;
        expect(networkError.networkType, equals(NetworkErrorType.cancelled));
      });
    });

    group('fromException', () {
      test('creates client error from generic exception', () {
        final exception = Exception('Something went wrong');
        final error = ErrorFactory.fromException(
          exception,
          componentName: 'TestComponent',
          context: 'test_context',
        );

        expect(error, isA<ClientError>());
        expect(error.message, equals('Exception: Something went wrong'));
        expect(error.componentName, equals('TestComponent'));
        expect(error.context, equals('test_context'));
      });
    });

    group('fromFlutterError', () {
      test('creates client error from Flutter error', () {
        final flutterError = FlutterError('Widget build failed');
        final error = ErrorFactory.fromFlutterError(
          flutterError,
          componentName: 'MyWidget',
        );

        expect(error, isA<ClientError>());
        expect(error.message, equals('Widget build failed'));
        expect(error.componentName, equals('MyWidget'));
      });
    });

    group('specialized error methods', () {
      test('createMaintenanceError creates correct API error', () {
        final error = ErrorFactory.createMaintenanceError();

        expect(error.statusCode, equals(503));
        expect(error.message, contains('maintenance'));
        expect(error.actions!.first.id, equals('retry'));
      });

      test('createRateLimitError creates correct API error', () {
        final error = ErrorFactory.createRateLimitError(
          retryAfter: const Duration(seconds: 60),
        );

        expect(error.statusCode, equals(429));
        expect(error.message, contains('60 seconds'));
        expect(error.actions!.first.id, equals('retry'));
      });

      test('createDataCorruptionError creates correct client error', () {
        final error = ErrorFactory.createDataCorruptionError(
          componentName: 'DataStore',
        );

        expect(error, isA<ClientError>());
        expect(error.message, contains('corruption'));
        expect(error.componentName, equals('DataStore'));
        expect(error.context, equals('data_corruption'));
        expect(error.actions!.first.id, equals('refresh'));
      });

      test('createPermissionError creates correct client error', () {
        final error = ErrorFactory.createPermissionError(
          permission: 'camera',
        );

        expect(error, isA<ClientError>());
        expect(error.message, contains('camera'));
        expect(error.context, equals('permission_denied'));
        expect(error.actions!.first.id, equals('settings'));
      });

      test('createStorageFullError creates correct client error', () {
        final error = ErrorFactory.createStorageFullError();

        expect(error, isA<ClientError>());
        expect(error.message, contains('storage'));
        expect(error.context, equals('storage_full'));
        expect(error.actions!.first.id, equals('manage_storage'));
      });
    });
  });
}