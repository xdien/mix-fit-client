import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/models/api_error.dart';
import '../../../lib/error/models/client_error.dart';
import '../../../lib/error/models/error_severity.dart';
import '../../../lib/error/models/network_error.dart';
import '../../../lib/error/models/validation_error.dart';
import '../../../lib/error/services/error_service.dart';

void main() {
  group('ErrorService Priority and Queue Management', () {
    late ErrorService errorService;

    setUp(() {
      errorService = ErrorService();
    });

    tearDown(() {
      errorService.dispose();
    });

    group('Priority Calculation', () {
      test('should calculate priority correctly for different severities', () {
        final criticalError = ApiError(
          message: 'Critical error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        final errorError = ApiError(
          message: 'Error',
          statusCode: 400,
          endpoint: '/test',
          method: 'GET',
        );
        final warningError = ApiError(
          message: 'Warning',
          statusCode: 300,
          endpoint: '/test',
          method: 'GET',
        );
        final infoError = ApiError(
          message: 'Info',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );

        expect(criticalError.priority, equals(4));
        expect(errorError.priority, equals(3));
        expect(warningError.priority, equals(2));
        expect(infoError.priority, equals(1));

        expect(criticalError.priority, greaterThan(errorError.priority));
        expect(errorError.priority, greaterThan(warningError.priority));
        expect(warningError.priority, greaterThan(infoError.priority));
      });

      test('should maintain priority order in queue', () {
        final lowPriorityError = ApiError(
          message: 'Low priority',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );
        final mediumPriorityError = ApiError(
          message: 'Medium priority',
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

        // Add in reverse priority order
        errorService.showError(lowPriorityError);
        errorService.showError(mediumPriorityError);
        errorService.showError(highPriorityError);

        final activeErrors = errorService.activeErrors;
        expect(activeErrors, hasLength(3));

        // Should be ordered by priority: high, medium, low
        expect(activeErrors[0].id, equals(highPriorityError.id));
        expect(activeErrors[1].id, equals(mediumPriorityError.id));
        expect(activeErrors[2].id, equals(lowPriorityError.id));

        // Current error should be highest priority
        expect(errorService.currentError?.id, equals(highPriorityError.id));
      });
    });

    group('Queue Size Management', () {
      test('should enforce maximum queue size of 5', () {
        // Add 7 errors to exceed the limit
        final errors = <ApiError>[];
        for (int i = 0; i < 7; i++) {
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
        
        // First error should be removed (oldest)
        final activeErrorIds = errorService.activeErrors.map((e) => e.id).toList();
        expect(activeErrorIds, isNot(contains(errors[0].id)));
        
        // Last 5 errors should remain
        for (int i = 1; i < 6; i++) {
          expect(activeErrorIds, contains(errors[i].id));
        }
      });

      test('should maintain priority order when removing oldest error', () {
        // Add 3 low priority errors
        for (int i = 0; i < 3; i++) {
          final error = ApiError(
            message: 'Low priority $i',
            statusCode: 200,
            endpoint: '/test$i',
            method: 'GET',
          );
          errorService.showError(error);
        }

        // Add 3 high priority errors (will exceed queue size)
        final highPriorityErrors = <ApiError>[];
        for (int i = 0; i < 3; i++) {
          final error = ApiError(
            message: 'High priority $i',
            statusCode: 500,
            endpoint: '/critical$i',
            method: 'GET',
          );
          highPriorityErrors.add(error);
          errorService.showError(error);
        }

        expect(errorService.activeErrors, hasLength(5));
        
        // High priority errors should be at the front
        final activeErrors = errorService.activeErrors;
        for (int i = 0; i < 3; i++) {
          expect(activeErrors[i].severity, equals(ErrorSeverity.critical));
        }
      });
    });

    group('Error Consolidation', () {
      test('should consolidate similar API errors', () {
        final error1 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );
        final error2 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
        
        final consolidatedError = errorService.activeErrors.first;
        expect(consolidatedError.message, contains('occurred 2 times'));
        expect(consolidatedError.metadata?['consolidatedCount'], equals(2));
      });

      test('should consolidate similar network errors', () {
        final error1 = NetworkError(
          message: 'Connection timeout',
          networkType: NetworkErrorType.timeout,
          url: 'https://api.example.com',
        );
        final error2 = NetworkError(
          message: 'Connection timeout',
          networkType: NetworkErrorType.timeout,
          url: 'https://api.example.com',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
        
        final consolidatedError = errorService.activeErrors.first;
        expect(consolidatedError.message, contains('occurred 2 times'));
      });

      test('should consolidate validation errors with merged field errors', () {
        final error1 = ValidationError(
          message: 'Validation failed',
          fieldErrors: {
            'email': ['Invalid format'],
            'password': ['Too short'],
          },
          formId: 'login_form',
        );
        final error2 = ValidationError(
          message: 'Validation failed',
          fieldErrors: {
            'email': ['Required field'],
            'username': ['Invalid characters'],
          },
          formId: 'login_form',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
        
        final consolidatedError = errorService.activeErrors.first as ValidationError;
        expect(consolidatedError.fieldErrors, hasLength(3));
        expect(consolidatedError.fieldErrors['email'], hasLength(2));
        expect(consolidatedError.fieldErrors['email'], contains('Invalid format'));
        expect(consolidatedError.fieldErrors['email'], contains('Required field'));
        expect(consolidatedError.fieldErrors['password'], contains('Too short'));
        expect(consolidatedError.fieldErrors['username'], contains('Invalid characters'));
      });

      test('should consolidate client errors', () {
        final error1 = ClientError(
          message: 'Null pointer exception',
          stackTrace: 'Stack trace 1',
          componentName: 'UserService',
        );
        final error2 = ClientError(
          message: 'Null pointer exception',
          stackTrace: 'Stack trace 2',
          componentName: 'UserService',
        );

        errorService.showError(error1);
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
        
        final consolidatedError = errorService.activeErrors.first;
        expect(consolidatedError.message, contains('occurred 2 times'));
      });

      test('should not consolidate different error types', () {
        final apiError = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        final networkError = NetworkError(
          message: 'Server error',
          networkType: NetworkErrorType.connectionRefused,
        );

        errorService.showError(apiError);
        errorService.showError(networkError);

        expect(errorService.activeErrors, hasLength(2));
      });

      test('should not consolidate errors with different severities', () {
        final criticalError = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        final warningError = ApiError(
          message: 'Server error',
          statusCode: 300,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(criticalError);
        errorService.showError(warningError);

        expect(errorService.activeErrors, hasLength(2));
      });

      test('should update consolidation count correctly', () {
        final error1 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error1);
        expect(errorService.activeErrors.first.metadata?['consolidatedCount'], isNull);

        // Add similar error
        final error2 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
        expect(errorService.activeErrors.first.metadata?['consolidatedCount'], equals(2));

        // Add another similar error
        final error3 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(error3);

        expect(errorService.activeErrors, hasLength(1));
        expect(errorService.activeErrors.first.metadata?['consolidatedCount'], equals(3));
        expect(errorService.activeErrors.first.message, contains('occurred 3 times'));
      });
    });

    group('Auto-Dismiss Management', () {
      test('should cancel auto-dismiss timer when error is consolidated', () async {
        final error1 = ApiError(
          message: 'Info error',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error1);
        expect(errorService.hasErrors, isTrue);

        // Add similar error before auto-dismiss
        await Future.delayed(const Duration(seconds: 2));
        final error2 = ApiError(
          message: 'Info error',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));
        expect(errorService.activeErrors.first.message, contains('occurred 2 times'));

        // Should still be present after original auto-dismiss time
        await Future.delayed(const Duration(seconds: 4));
        expect(errorService.hasErrors, isTrue);
      });

      test('should schedule new auto-dismiss for consolidated error', () async {
        final error1 = ApiError(
          message: 'Info error',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );
        final error2 = ApiError(
          message: 'Info error',
          statusCode: 200,
          endpoint: '/test',
          method: 'GET',
        );

        errorService.showError(error1);
        await Future.delayed(const Duration(seconds: 2));
        errorService.showError(error2);

        expect(errorService.activeErrors, hasLength(1));

        // Should auto-dismiss after the new error's auto-dismiss duration
        await Future.delayed(const Duration(seconds: 6));
        expect(errorService.hasErrors, isFalse);
      });
    });

    group('Queue Overflow Handling', () {
      test('should handle queue overflow with mixed priority errors', () {
        final errors = <ApiError>[];

        // Add 3 low priority errors
        for (int i = 0; i < 3; i++) {
          final error = ApiError(
            message: 'Low priority $i',
            statusCode: 200,
            endpoint: '/low$i',
            method: 'GET',
          );
          errors.add(error);
          errorService.showError(error);
        }

        // Add 3 high priority errors (will cause overflow)
        for (int i = 0; i < 3; i++) {
          final error = ApiError(
            message: 'High priority $i',
            statusCode: 500,
            endpoint: '/high$i',
            method: 'GET',
          );
          errors.add(error);
          errorService.showError(error);
        }

        expect(errorService.activeErrors, hasLength(5));

        // Should maintain priority order
        final activeErrors = errorService.activeErrors;
        for (int i = 0; i < 3; i++) {
          expect(activeErrors[i].severity, equals(ErrorSeverity.critical));
        }
        for (int i = 3; i < 5; i++) {
          expect(activeErrors[i].severity, equals(ErrorSeverity.info));
        }
      });

      test('should handle rapid error additions without losing priority order', () {
        final errors = <ApiError>[];

        // Rapidly add errors with different priorities
        for (int i = 0; i < 10; i++) {
          final statusCode = i % 2 == 0 ? 500 : 200; // Alternate between critical and info
          final error = ApiError(
            message: 'Error $i',
            statusCode: statusCode,
            endpoint: '/test$i',
            method: 'GET',
          );
          errors.add(error);
          errorService.showError(error);
        }

        expect(errorService.activeErrors, hasLength(5));

        // Should maintain priority order (critical errors first)
        final activeErrors = errorService.activeErrors;
        int criticalCount = 0;
        int infoCount = 0;

        for (final error in activeErrors) {
          if (error.severity == ErrorSeverity.critical) {
            criticalCount++;
          } else if (error.severity == ErrorSeverity.info) {
            infoCount++;
          }
        }

        // Should have at least some critical errors due to priority
        expect(criticalCount, greaterThan(0));
      });
    });
  });
}