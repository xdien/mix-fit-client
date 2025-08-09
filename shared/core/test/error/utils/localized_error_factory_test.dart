import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/localization/error_localizations.dart';
import '../../../lib/error/models/api_error.dart';
import '../../../lib/error/models/client_error.dart';
import '../../../lib/error/models/network_error.dart';
import '../../../lib/error/models/validation_error.dart';
import '../../../lib/error/utils/localized_error_factory.dart';

void main() {
  group('LocalizedErrorFactory', () {
    late LocalizedErrorFactory englishFactory;
    late LocalizedErrorFactory vietnameseFactory;

    setUp(() {
      englishFactory = LocalizedErrorFactory.forLocale(const Locale('en'));
      vietnameseFactory = LocalizedErrorFactory.forLocale(const Locale('vi'));
    });

    group('createApiError', () {
      test('creates API error with localized message', () {
        final error = englishFactory.createApiError(
          statusCode: 404,
          endpoint: '/api/users',
          method: 'GET',
        );

        expect(error, isA<ApiError>());
        expect(error.statusCode, equals(404));
        expect(error.endpoint, equals('/api/users'));
        expect(error.method, equals('GET'));
        expect(error.message, equals('The requested resource was not found.'));
        expect(error.actions, isNotNull);
        expect(error.actions!.length, equals(1));
        expect(error.actions!.first.label, equals('Dismiss'));
      });

      test('creates API error with Vietnamese localization', () {
        final error = vietnameseFactory.createApiError(
          statusCode: 500,
          endpoint: '/api/test',
          method: 'POST',
        );

        expect(error.message, equals('Lỗi máy chủ nội bộ. Vui lòng thử lại sau.'));
        expect(error.actions!.first.label, equals('Thử lại'));
        expect(error.actions!.last.label, equals('Bỏ qua'));
      });

      test('uses custom message when provided', () {
        final error = englishFactory.createApiError(
          statusCode: 400,
          endpoint: '/api/test',
          method: 'POST',
          message: 'Custom error message',
        );

        expect(error.message, equals('Custom error message'));
      });
    });

    group('createNetworkError', () {
      test('creates network error with localized message', () {
        final error = englishFactory.createNetworkError(
          networkType: NetworkErrorType.noConnection,
        );

        expect(error, isA<NetworkError>());
        expect(error.networkType, equals(NetworkErrorType.noConnection));
        expect(error.message, equals('No internet connection available'));
        expect(error.actions!.first.label, equals('Retry'));
        expect(error.actions!.last.label, equals('Dismiss'));
      });

      test('creates network error with Vietnamese localization', () {
        final error = vietnameseFactory.createNetworkError(
          networkType: NetworkErrorType.timeout,
        );

        expect(error.message, equals('Kết nối hết thời gian'));
        expect(error.actions!.first.label, equals('Thử lại'));
      });
    });

    group('createValidationError', () {
      test('creates validation error with localized message', () {
        final fieldErrors = {
          'email': ['Invalid email'],
          'password': ['Too short'],
        };

        final error = englishFactory.createValidationError(
          fieldErrors: fieldErrors,
        );

        expect(error, isA<ValidationError>());
        expect(error.fieldErrors, equals(fieldErrors));
        expect(error.message, equals('Please fix 2 validation errors'));
      });

      test('handles single validation error', () {
        final fieldErrors = {
          'email': ['Invalid email'],
        };

        final error = englishFactory.createValidationError(
          fieldErrors: fieldErrors,
        );

        expect(error.message, equals('Please fix the validation error'));
      });

      test('creates validation error with Vietnamese localization', () {
        final fieldErrors = {
          'email': ['Invalid email'],
          'password': ['Too short'],
        };

        final error = vietnameseFactory.createValidationError(
          fieldErrors: fieldErrors,
        );

        expect(error.message, equals('Vui lòng sửa 2 lỗi xác thực'));
      });
    });

    group('createClientError', () {
      test('creates client error with provided message', () {
        final error = englishFactory.createClientError(
          message: 'Widget build failed',
          componentName: 'MyWidget',
        );

        expect(error, isA<ClientError>());
        expect(error.message, equals('Widget build failed'));
        expect(error.componentName, equals('MyWidget'));
      });
    });

    group('convenience methods', () {
      test('createNoInternetError creates localized error', () {
        final error = englishFactory.createNoInternetError();

        expect(error.networkType, equals(NetworkErrorType.noConnection));
        expect(error.message, equals('No internet connection available'));
        expect(error.actions!.first.label, equals('Retry'));
      });

      test('createTimeoutError creates localized error', () {
        final error = englishFactory.createTimeoutError(
          timeout: const Duration(seconds: 30),
        );

        expect(error.networkType, equals(NetworkErrorType.timeout));
        expect(error.message, equals('Connection timed out'));
        expect(error.timeout, equals(const Duration(seconds: 30)));
      });

      test('createAuthenticationError creates localized error', () {
        final error = englishFactory.createAuthenticationError();

        expect(error.statusCode, equals(401));
        expect(error.message, equals('Authentication required. Please log in.'));
        expect(error.actions!.first.label, equals('Login'));
      });

      test('createAuthorizationError creates localized error', () {
        final error = englishFactory.createAuthorizationError();

        expect(error.statusCode, equals(403));
        expect(error.message, equals('Access denied. You don\'t have permission.'));
        expect(error.actions!.first.label, equals('Contact Support'));
      });

      test('createMaintenanceError creates localized error', () {
        final error = englishFactory.createMaintenanceError();

        expect(error.statusCode, equals(503));
        expect(error.message, equals('Server is under maintenance. Please try again later.'));
        expect(error.actions!.first.label, equals('Retry'));
      });

      test('createRateLimitError creates localized error', () {
        final error = englishFactory.createRateLimitError(
          retryAfter: const Duration(seconds: 60),
        );

        expect(error.statusCode, equals(429));
        expect(error.message, equals('Please try again in 60 seconds'));
        expect(error.actions!.first.label, equals('Retry'));
      });

      test('createDataCorruptionError creates localized error', () {
        final error = englishFactory.createDataCorruptionError(
          componentName: 'DataStore',
        );

        expect(error, isA<ClientError>());
        expect(error.message, equals('Data corruption detected. Please refresh the app.'));
        expect(error.componentName, equals('DataStore'));
        expect(error.context, equals('data_corruption'));
        expect(error.actions!.first.label, equals('Refresh'));
      });

      test('createPermissionError creates localized error', () {
        final error = englishFactory.createPermissionError(
          permission: 'camera',
        );

        expect(error, isA<ClientError>());
        expect(error.message, equals('Permission denied: camera'));
        expect(error.context, equals('permission_denied'));
        expect(error.actions!.first.label, equals('Open Settings'));
      });

      test('createStorageFullError creates localized error', () {
        final error = englishFactory.createStorageFullError();

        expect(error, isA<ClientError>());
        expect(error.message, equals('Device storage is full. Please free up space.'));
        expect(error.context, equals('storage_full'));
        expect(error.actions!.first.label, equals('Manage Storage'));
      });
    });

    group('createLocalizedFieldErrors', () {
      test('creates localized field errors for common validations', () {
        final errors = englishFactory.createLocalizedFieldErrors(
          emailRequired: true,
          emailInvalid: true,
          passwordTooShort: true,
          passwordsDoNotMatch: true,
        );

        expect(errors['email'], contains('This field is required'));
        expect(errors['email'], contains('Please enter a valid email address'));
        expect(errors['password'], contains('Password is too short'));
        expect(errors['confirmPassword'], contains('Passwords do not match'));
      });

      test('creates Vietnamese localized field errors', () {
        final errors = vietnameseFactory.createLocalizedFieldErrors(
          emailRequired: true,
          phoneInvalid: true,
        );

        expect(errors['email'], contains('Trường này là bắt buộc'));
        expect(errors['phone'], contains('Vui lòng nhập số điện thoại hợp lệ'));
      });

      test('merges custom errors with standard validations', () {
        final customErrors = {
          'username': ['Username already exists'],
        };

        final errors = englishFactory.createLocalizedFieldErrors(
          customErrors: customErrors,
          emailRequired: true,
        );

        expect(errors['username'], contains('Username already exists'));
        expect(errors['email'], contains('This field is required'));
      });

      test('handles multiple errors for same field', () {
        final errors = englishFactory.createLocalizedFieldErrors(
          passwordRequired: true,
          passwordTooShort: true,
          passwordTooWeak: true,
        );

        expect(errors['password'], hasLength(3));
        expect(errors['password'], contains('This field is required'));
        expect(errors['password'], contains('Password is too short'));
        expect(errors['password'], contains('Password is too weak'));
      });

      test('handles all validation types', () {
        final errors = englishFactory.createLocalizedFieldErrors(
          emailRequired: true,
          emailInvalid: true,
          phoneRequired: true,
          phoneInvalid: true,
          passwordRequired: true,
          passwordTooShort: true,
          passwordTooWeak: true,
          passwordsDoNotMatch: true,
          urlInvalid: true,
          dateInvalid: true,
          valueTooSmall: true,
          valueTooLarge: true,
        );

        expect(errors.keys, containsAll([
          'email',
          'phone',
          'password',
          'confirmPassword',
          'url',
          'date',
          'value',
        ]));

        expect(errors['email'], hasLength(2));
        expect(errors['phone'], hasLength(2));
        expect(errors['password'], hasLength(3));
        expect(errors['confirmPassword'], hasLength(1));
        expect(errors['url'], hasLength(1));
        expect(errors['date'], hasLength(1));
        expect(errors['value'], hasLength(2));
      });
    });

    group('Vietnamese localization', () {
      test('creates Vietnamese authentication error', () {
        final error = vietnameseFactory.createAuthenticationError();

        expect(error.message, equals('Cần xác thực. Vui lòng đăng nhập.'));
        expect(error.actions!.first.label, equals('Đăng nhập'));
        expect(error.actions!.last.label, equals('Bỏ qua'));
      });

      test('creates Vietnamese maintenance error', () {
        final error = vietnameseFactory.createMaintenanceError();

        expect(error.message, equals('Máy chủ đang bảo trì. Vui lòng thử lại sau.'));
        expect(error.actions!.first.label, equals('Thử lại'));
      });

      test('creates Vietnamese permission error', () {
        final error = vietnameseFactory.createPermissionError(
          permission: 'camera',
        );

        expect(error.message, equals('Quyền bị từ chối: camera'));
        expect(error.actions!.first.label, equals('Mở cài đặt'));
      });
    });
  });
}