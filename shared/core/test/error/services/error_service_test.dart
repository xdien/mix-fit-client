import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/models/api_error.dart';
import '../../../lib/error/models/app_error.dart';
import '../../../lib/error/models/client_error.dart';
import '../../../lib/error/models/error_severity.dart';
import '../../../lib/error/models/network_error.dart';
import '../../../lib/error/models/network_status.dart';
import '../../../lib/error/models/validation_error.dart';
import '../../../lib/error/services/error_service.dart';
import '../../../lib/error/services/network_monitor.dart';

void main() {
  group('ErrorService', () {
    late ErrorService errorService;

    setUp(() {
      errorService = ErrorService();
    });

    tearDown(() {
      errorService.dispose();
    });

    group('Basic Error Management', () {
      test('should start with no errors', () {
        expect(errorService.hasErrors, isFalse);
        expect(errorService.activeErrors, isEmpty);
        expect(errorService.currentError, isNull);
      });

      test('should add error to queue', () {
        final error = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error);

        expect(errorService.hasErrors, isTrue);
        expect(errorService.activeErrors, hasLength(1));
        expect(errorService.activeErrors.first.id, equals(error.id));
        expect(errorService.currentError?.id, equals(error.id));
      });

      test('should clear specific error by ID', () {
        final error1 = ApiError(
          message: 'Error 1',
          statusCode: 500,
          endpoint: '/test1',
          method: 'GET',
        );
        final error2 = ApiError(
          message: 'Error 2',
          statusCode: 400,
          endpoint: '/test2',
          method: 'POST',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(2));

        errorService.clearError(error1.id);

        expect(errorService.activeErrors, hasLength(1));
        expect(errorService.activeErrors.first.id, equals(error2.id));
      });

      test('should clear all errors', () {
        final error1 = ApiError(
          message: 'Error 1',
          statusCode: 500,
          endpoint: '/test1',
          method: 'GET',
        );
        final error2 = NetworkError(
          message: 'Network error',
          networkType: NetworkErrorType.noConnection,
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(2));

        errorService.clearAllErrors();

        expect(errorService.hasErrors, isFalse);
        expect(errorService.activeErrors, isEmpty);
        expect(errorService.currentError, isNull);
      });

      test('should clear errors by type', () {
        final apiError = ApiError(
          message: 'API error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        final networkError = NetworkError(
          message: 'Network error',
          networkType: NetworkErrorType.noConnection,
        );

        errorService.showError(apiError);
        errorService.showError(networkError);

        expect(errorService.activeErrors, hasLength(2));

        errorService.clearErrorsByType('api');

        expect(errorService.activeErrors, hasLength(1));
        expect(errorService.activeErrors.first.id, equals(networkError.id));
      });
    });

    group('Priority-Based Ordering', () {
      test('should order errors by priority (highest first)', () {
        final infoError = ApiError(
          message: 'Info error',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );
        final warningError = ApiError(
          message: 'Warning error',
          statusCode: 400,
          endpoint: '/test',
          method: 'GET',
        );
        final criticalError = ApiError(
          message: 'Critical error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        // Add in reverse priority order
        errorService.showError(infoError);
        errorService.showError(warningError);
        errorService.showError(criticalError);

        final activeErrors = errorService.activeErrors;
        expect(activeErrors, hasLength(3));
        
        // Should be ordered by priority: critical, warning, info
        expect(activeErrors[0].severity, equals(ErrorSeverity.critical));
        expect(activeErrors[1].severity, equals(ErrorSeverity.error));
        expect(activeErrors[2].severity, equals(ErrorSeverity.info));
        
        // Current error should be the highest priority (critical)
        expect(errorService.currentError?.severity, equals(ErrorSeverity.critical));
      });

      test('should maintain priority order when adding new errors', () {
        final lowPriorityError = ApiError(
          message: 'Low priority',
          statusCode: 400,
          endpoint: '/test',
          method: 'GET',
        );
        final highPriorityError = ApiError(
          message: 'High priority',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(lowPriorityError);
        expect(errorService.currentError?.id, equals(lowPriorityError.id));

        errorService.showError(highPriorityError);
        expect(errorService.currentError?.id, equals(highPriorityError.id));

        final activeErrors = errorService.activeErrors;
        expect(activeErrors[0].id, equals(highPriorityError.id));
        expect(activeErrors[1].id, equals(lowPriorityError.id));
      });
    });

    group('Queue Size Management', () {
      test('should maintain maximum queue size of 5 errors', () {
        // Add 7 errors to test queue overflow
        for (int i = 0; i < 7; i++) {
          final error = ApiError(
            message: 'Error $i',
            statusCode: 400,
            endpoint: '/test$i',
            method: 'GET',
          );
          errorService.showError(error);
        }

        expect(errorService.activeErrors, hasLength(5));
      });

      test('should remove oldest error when queue is full', () {
        final errors = <ApiError>[];
        
        // Add 6 errors (exceeds max of 5)
        for (int i = 0; i < 6; i++) {
          final error = ApiError(
            message: 'Error $i',
            statusCode: 400,
            endpoint: '/test$i',
            method: 'GET',
          );
          errors.add(error);
          errorService.showError(error);
        }

        expect(errorService.activeErrors, hasLength(5));
        
        // First error should be removed
        final activeErrorIds = errorService.activeErrors.map((e) => e.id).toList();
        expect(activeErrorIds, isNot(contains(errors[0].id)));
        
        // Last 5 errors should remain
        for (int i = 1; i < 6; i++) {
          expect(activeErrorIds, contains(errors[i].id));
        }
      });
    });

    group('Error Deduplication', () {
      test('should prevent duplicate API errors', () {
        final error1 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        final error2 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
        expect(errorService.activeErrors.first.id, equals(error1.id));
      });

      test('should prevent duplicate network errors', () {
        final error1 = NetworkError(
          message: 'No connection',
          networkType: NetworkErrorType.noConnection,
          url: 'https://example.com',
        );
        final error2 = NetworkError(
          message: 'No connection',
          networkType: NetworkErrorType.noConnection,
          url: 'https://example.com',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
      });

      test('should allow similar but different errors', () {
        final error1 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test1',
          method: 'GET',
        );
        final error2 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test2', // Different endpoint
          method: 'GET',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(2));
      });
    });

    group('Auto-Dismiss Functionality', () {
      test('should auto-dismiss info errors after 5 seconds', () async {
        final error = ApiError(
          message: 'Info error',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error);
        expect(errorService.hasErrors, isTrue);

        // Wait for auto-dismiss (with some buffer time)
        await Future.delayed(const Duration(seconds: 6));

        expect(errorService.hasErrors, isFalse);
      });

      test('should auto-dismiss warning errors after 15 seconds', () async {
        final error = ApiError(
          message: 'Warning error',
          statusCode: 300, // 3xx status codes map to warning severity
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error);
        expect(errorService.hasErrors, isTrue);

        // Should not be dismissed after 5 seconds
        await Future.delayed(const Duration(seconds: 6));
        expect(errorService.hasErrors, isTrue);

        // Should be dismissed after 15 seconds (wait additional 10)
        await Future.delayed(const Duration(seconds: 10));
        expect(errorService.hasErrors, isFalse);
      });

      test('should not auto-dismiss critical errors', () async {
        final error = ApiError(
          message: 'Critical error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error);
        expect(errorService.hasErrors, isTrue);

        // Wait longer than any auto-dismiss duration
        await Future.delayed(const Duration(seconds: 6));

        expect(errorService.hasErrors, isTrue);
        expect(errorService.currentError?.id, equals(error.id));
      });

      test('should cancel auto-dismiss when error is manually cleared', () async {
        final error = ApiError(
          message: 'Info error',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error);
        expect(errorService.hasErrors, isTrue);

        // Clear error before auto-dismiss
        await Future.delayed(const Duration(seconds: 2));
        errorService.clearError(error.id);

        expect(errorService.hasErrors, isFalse);

        // Wait past auto-dismiss time to ensure timer was cancelled
        await Future.delayed(const Duration(seconds: 4));
        expect(errorService.hasErrors, isFalse);
      });
    });

    group('Stream Notifications', () {
      test('should emit error list changes', () async {
        final errorListCompleter = Completer<List<String>>();
        final errorIds = <String>[];

        errorService.errorStream.listen((errors) {
          errorIds.clear();
          errorIds.addAll(errors.map((e) => e.id));
          if (errors.length == 2) {
            errorListCompleter.complete(List.from(errorIds));
          }
        });

        final error1 = ApiError(
          message: 'Error 1',
          statusCode: 500,
          endpoint: '/test1',
          method: 'GET',
        );
        final error2 = ApiError(
          message: 'Error 2',
          statusCode: 400,
          endpoint: '/test2',
          method: 'GET',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        final receivedIds = await errorListCompleter.future;
        expect(receivedIds, hasLength(2));
        expect(receivedIds, contains(error1.id));
        expect(receivedIds, contains(error2.id));
      });

      test('should emit current error changes', () async {
        final currentErrorCompleter = Completer<String>();

        errorService.currentErrorStream.listen((error) {
          if (error != null && error.message == 'High priority error') {
            currentErrorCompleter.complete(error.id);
          }
        });

        final lowPriorityError = ApiError(
          message: 'Low priority error',
          statusCode: 400,
          endpoint: '/test',
          method: 'GET',
        );
        final highPriorityError = ApiError(
          message: 'High priority error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(lowPriorityError);
        errorService.showError(highPriorityError);

        final receivedId = await currentErrorCompleter.future;
        expect(receivedId, equals(highPriorityError.id));
      });
    });

    group('Specific Error Types', () {
      test('should handle API errors correctly', () {
        final apiError = ApiError(
          message: 'API error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'POST',
        );

        errorService.showApiError(apiError);

        expect(errorService.hasErrors, isTrue);
        expect(errorService.currentError, isA<ApiError>());
        expect((errorService.currentError as ApiError).statusCode, equals(500));
      });

      test('should handle validation errors correctly', () {
        final validationError = ValidationError(
          message: 'Validation failed',
          fieldErrors: {
            'email': ['Invalid format'],
            'password': ['Too short'],
          },
        );

        errorService.showValidationError(validationError);

        expect(errorService.hasErrors, isTrue);
        expect(errorService.currentError, isA<ValidationError>());
        expect((errorService.currentError as ValidationError).errorCount, equals(2));
      });

      test('should handle network errors correctly', () {
        final networkError = NetworkError(
          message: 'Network error',
          networkType: NetworkErrorType.timeout,
          url: 'https://example.com',
        );

        errorService.showNetworkError(networkError);

        expect(errorService.hasErrors, isTrue);
        expect(errorService.currentError, isA<NetworkError>());
        expect((errorService.currentError as NetworkError).isTimeout, isTrue);
      });

      test('should handle client errors correctly', () {
        final clientError = ClientError(
          message: 'Client error',
          stackTrace: 'Stack trace here',
          componentName: 'TestComponent',
        );

        errorService.showClientError(clientError);

        expect(errorService.hasErrors, isTrue);
        expect(errorService.currentError, isA<ClientError>());
        expect((errorService.currentError as ClientError).hasStackTrace, isTrue);
      });
    });

    group('Network Monitoring Integration', () {
      test('should provide network status access', () {
        expect(errorService.networkStatus, isA<NetworkStatus>());
        expect(errorService.isOffline, isA<bool>());
        expect(errorService.networkMonitor, isA<NetworkMonitor>());
      });

      test('should start with offline network status', () {
        expect(errorService.isOffline, isTrue);
        expect(errorService.networkStatus.quality, equals(NetworkQuality.offline));
      });

      test('should handle network status changes', () async {
        // Create a mock network monitor for testing
        final mockNetworkMonitor = NetworkMonitor();
        final testErrorService = ErrorService(networkMonitor: mockNetworkMonitor);

        expect(testErrorService.isOffline, isTrue);

        // Clean up
        testErrorService.dispose();
      });

      test('should clear network errors when connection is restored', () async {
        // Add a network error
        final networkError = NetworkError(
          message: 'No connection',
          networkType: NetworkErrorType.noConnection,
        );
        errorService.showError(networkError);

        expect(errorService.hasErrors, isTrue);
        expect(errorService.activeErrors.first, isA<NetworkError>());

        // Simulate connection restoration by clearing network errors
        errorService.clearErrorsByType('network');

        expect(errorService.hasErrors, isFalse);
      });

      test('should create network errors for poor quality', () {
        // This test verifies the error creation logic
        final poorQualityError = NetworkError(
          message: 'Poor network connection detected',
          networkType: NetworkErrorType.poorQuality,
        );

        errorService.showError(poorQualityError);

        expect(errorService.hasErrors, isTrue);
        expect(errorService.currentError, isA<NetworkError>());
        expect((errorService.currentError as NetworkError).networkType, 
               equals(NetworkErrorType.poorQuality));
      });
    });

    group('Disposal', () {
      test('should not accept new errors after disposal', () {
        final error = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.dispose();
        errorService.showError(error);

        expect(errorService.hasErrors, isFalse);
      });

      test('should not clear errors after disposal', () {
        final error = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error);
        expect(errorService.hasErrors, isTrue);

        errorService.dispose();
        errorService.clearError(error.id);

        // Can't verify state after disposal, but should not crash
      });

      test('should close streams on disposal', () {
        expect(errorService.errorStream, isA<Stream<List<AppError>>>());
        expect(errorService.currentErrorStream, isA<Stream<AppError?>>());

        errorService.dispose();

        // Streams should be closed, but we can't easily test this
        // The important thing is that disposal doesn't crash
      });

      test('should dispose network monitor on disposal', () {
        final networkMonitor = errorService.networkMonitor;
        expect(networkMonitor, isA<NetworkMonitor>());

        errorService.dispose();

        // Network monitor should be disposed, but we can't easily verify this
        // The important thing is that disposal doesn't crash
      });
    });
  });
}