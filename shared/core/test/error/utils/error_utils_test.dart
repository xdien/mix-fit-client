import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/models/api_error.dart';
import '../../../lib/error/models/client_error.dart';
import '../../../lib/error/models/error_severity.dart';
import '../../../lib/error/models/error_type.dart';
import '../../../lib/error/models/network_error.dart';
import '../../../lib/error/models/validation_error.dart';
import '../../../lib/error/utils/error_utils.dart';

void main() {
  group('ErrorUtils', () {
    group('formatErrorMessage', () {
      test('formats basic error message', () {
        final error = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        final formatted = ErrorUtils.formatErrorMessage(error);
        expect(formatted, equals('Server error'));
      });

      test('includes details when requested', () {
        final error = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        final formatted = ErrorUtils.formatErrorMessage(error, includeDetails: true);
        expect(formatted, equals('Server error (Status: 500)'));
      });

      test('includes network type for network errors', () {
        final error = NetworkError(
          message: 'Connection failed',
          networkType: NetworkErrorType.timeout,
        );

        final formatted = ErrorUtils.formatErrorMessage(error, includeDetails: true);
        expect(formatted, equals('Connection failed (Timeout)'));
      });

      test('includes field count for validation errors', () {
        final error = ValidationError(
          message: 'Validation failed',
          fieldErrors: {
            'email': ['Invalid'],
            'password': ['Too short'],
          },
        );

        final formatted = ErrorUtils.formatErrorMessage(error, includeDetails: true);
        expect(formatted, equals('Validation failed (2 fields affected)'));
      });
    });

    group('formatErrorForLogging', () {
      test('formats error for logging with all details', () {
        final error = ApiError(
          id: 'test-id',
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        );

        final formatted = ErrorUtils.formatErrorForLogging(error);
        
        expect(formatted, contains('Error ID: test-id'));
        expect(formatted, contains('Type: api'));
        expect(formatted, contains('Severity: critical'));
        expect(formatted, contains('Message: Server error'));
        expect(formatted, contains('Timestamp: 2023-01-01T12:00:00.000'));
        expect(formatted, contains('statusCode: 500'));
        expect(formatted, contains('endpoint: /api/test'));
      });

      test('redacts sensitive metadata fields', () {
        final error = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          requestData: {'password': 'secret123'},
        );

        final formatted = ErrorUtils.formatErrorForLogging(error);
        expect(formatted, contains('requestData: [REDACTED]'));
      });
    });

    group('calculateSeverity', () {
      test('calculates severity for API errors based on status code', () {
        expect(
          ErrorUtils.calculateSeverity(type: ErrorType.api, statusCode: 500),
          equals(ErrorSeverity.critical),
        );

        expect(
          ErrorUtils.calculateSeverity(type: ErrorType.api, statusCode: 401),
          equals(ErrorSeverity.error),
        );

        expect(
          ErrorUtils.calculateSeverity(type: ErrorType.api, statusCode: 400),
          equals(ErrorSeverity.warning),
        );
      });

      test('calculates severity for network errors based on type', () {
        expect(
          ErrorUtils.calculateSeverity(
            type: ErrorType.network,
            networkType: 'noConnection',
          ),
          equals(ErrorSeverity.error),
        );

        expect(
          ErrorUtils.calculateSeverity(
            type: ErrorType.network,
            networkType: 'timeout',
          ),
          equals(ErrorSeverity.warning),
        );
      });

      test('calculates severity for validation errors based on field count', () {
        expect(
          ErrorUtils.calculateSeverity(
            type: ErrorType.validation,
            fieldErrorCount: 2,
          ),
          equals(ErrorSeverity.warning),
        );

        expect(
          ErrorUtils.calculateSeverity(
            type: ErrorType.validation,
            fieldErrorCount: 10,
          ),
          equals(ErrorSeverity.error),
        );
      });

      test('calculates severity for client errors based on stack trace', () {
        expect(
          ErrorUtils.calculateSeverity(
            type: ErrorType.client,
            hasStackTrace: true,
          ),
          equals(ErrorSeverity.error),
        );

        expect(
          ErrorUtils.calculateSeverity(
            type: ErrorType.client,
            hasStackTrace: false,
          ),
          equals(ErrorSeverity.error), // Base severity for client errors
        );
      });
    });

    group('extractMetadata', () {
      test('extracts metadata from map', () {
        final source = {'key': 'value', 'number': 42};
        final metadata = ErrorUtils.extractMetadata(source);
        
        expect(metadata, equals(source));
      });

      test('extracts metadata from JSON string', () {
        const jsonString = '{"key": "value", "number": 42}';
        final metadata = ErrorUtils.extractMetadata(jsonString);
        
        expect(metadata['key'], equals('value'));
        expect(metadata['number'], equals(42));
      });

      test('handles non-JSON string', () {
        const plainString = 'This is not JSON';
        final metadata = ErrorUtils.extractMetadata(plainString);
        
        expect(metadata['raw'], equals(plainString));
      });

      test('handles null source', () {
        final metadata = ErrorUtils.extractMetadata(null);
        expect(metadata, isEmpty);
      });

      test('handles extraction errors', () {
        // Create an object that will cause an error during processing
        final problematicObject = Object();
        
        final metadata = ErrorUtils.extractMetadata(problematicObject);
        expect(metadata.containsKey('raw'), isTrue);
      });
    });

    group('sanitizeErrorData', () {
      test('redacts sensitive fields', () {
        final data = {
          'username': 'john',
          'password': 'secret123',
          'token': 'abc123',
          'email': 'john@example.com',
        };

        final sanitized = ErrorUtils.sanitizeErrorData(data);
        
        expect(sanitized['username'], equals('john'));
        expect(sanitized['password'], equals('[REDACTED]'));
        expect(sanitized['token'], equals('[REDACTED]'));
        expect(sanitized['email'], equals('john@example.com'));
      });

      test('recursively sanitizes nested objects', () {
        final data = {
          'user': {
            'name': 'john',
            'password': 'secret123',
          },
          'settings': {
            'theme': 'dark',
            'apiKey': 'secret-key',
          },
        };

        final sanitized = ErrorUtils.sanitizeErrorData(data);
        
        expect(sanitized['user']['name'], equals('john'));
        expect(sanitized['user']['password'], equals('[REDACTED]'));
        expect(sanitized['settings']['theme'], equals('dark'));
        expect(sanitized['settings']['apiKey'], equals('[REDACTED]'));
      });

      test('sanitizes arrays with nested objects', () {
        final data = {
          'users': [
            {'name': 'john', 'password': 'secret1'},
            {'name': 'jane', 'password': 'secret2'},
          ],
        };

        final sanitized = ErrorUtils.sanitizeErrorData(data);
        final users = sanitized['users'] as List;
        
        expect(users[0]['name'], equals('john'));
        expect(users[0]['password'], equals('[REDACTED]'));
        expect(users[1]['name'], equals('jane'));
        expect(users[1]['password'], equals('[REDACTED]'));
      });
    });

    group('generateErrorSummary', () {
      test('handles empty error list', () {
        final summary = ErrorUtils.generateErrorSummary([]);
        expect(summary, equals('No errors'));
      });

      test('handles single error', () {
        final error = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        final summary = ErrorUtils.generateErrorSummary([error]);
        expect(summary, equals('Server error'));
      });

      test('generates summary for multiple errors', () {
        final errors = [
          ApiError(
            message: 'Server error 1',
            statusCode: 500,
            endpoint: '/api/test1',
            method: 'GET',
          ),
          ApiError(
            message: 'Server error 2',
            statusCode: 500,
            endpoint: '/api/test2',
            method: 'GET',
          ),
          NetworkError(
            message: 'Network error',
            networkType: NetworkErrorType.timeout,
          ),
        ];

        final summary = ErrorUtils.generateErrorSummary(errors);
        expect(summary, contains('3 errors'));
        expect(summary, contains('2 apis'));
        expect(summary, contains('1 network'));
      });

      test('includes critical error count', () {
        final errors = [
          ApiError(
            message: 'Critical error',
            statusCode: 500,
            endpoint: '/api/test',
            method: 'GET',
          ),
          NetworkError(
            message: 'Network error',
            networkType: NetworkErrorType.timeout,
          ),
        ];

        final summary = ErrorUtils.generateErrorSummary(errors);
        expect(summary, contains('(1 critical)'));
      });
    });

    group('shouldConsolidateErrors', () {
      test('consolidates errors of same type and severity', () {
        final error1 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        final error2 = ApiError(
          message: 'Another server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'POST',
        );

        expect(ErrorUtils.shouldConsolidateErrors(error1, error2), isTrue);
      });

      test('does not consolidate errors of different types', () {
        final apiError = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        final networkError = NetworkError(
          message: 'Network error',
          networkType: NetworkErrorType.timeout,
        );

        expect(ErrorUtils.shouldConsolidateErrors(apiError, networkError), isFalse);
      });

      test('does not consolidate errors of different severities', () {
        final error1 = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        final error2 = ApiError(
          message: 'Client error',
          statusCode: 400,
          endpoint: '/api/test',
          method: 'GET',
        );

        expect(ErrorUtils.shouldConsolidateErrors(error1, error2), isFalse);
      });

      test('consolidates validation errors with same form ID', () {
        final error1 = ValidationError(
          message: 'Validation error 1',
          fieldErrors: {'field1': ['error1']},
          formId: 'form1',
        );

        final error2 = ValidationError(
          message: 'Validation error 2',
          fieldErrors: {'field2': ['error2']},
          formId: 'form1',
        );

        expect(ErrorUtils.shouldConsolidateErrors(error1, error2), isTrue);
      });
    });

    group('consolidateErrors', () {
      test('throws error for empty list', () {
        expect(
          () => ErrorUtils.consolidateErrors([]),
          throwsArgumentError,
        );
      });

      test('returns single error unchanged', () {
        final error = ApiError(
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        final consolidated = ErrorUtils.consolidateErrors([error]);
        expect(consolidated, equals(error));
      });

      test('consolidates multiple errors', () {
        final errors = [
          ApiError(
            message: 'Server error',
            statusCode: 500,
            endpoint: '/api/test',
            method: 'GET',
          ),
          ApiError(
            message: 'Another server error',
            statusCode: 500,
            endpoint: '/api/test',
            method: 'POST',
          ),
          ApiError(
            message: 'Third server error',
            statusCode: 500,
            endpoint: '/api/test',
            method: 'PUT',
          ),
        ];

        final consolidated = ErrorUtils.consolidateErrors(errors);
        
        expect(consolidated.message, contains('and 2 similar errors'));
        expect(consolidated.metadata!['consolidated'], equals(true));
        expect(consolidated.metadata!['originalCount'], equals(3));
      });

      test('handles two errors specially', () {
        final errors = [
          ApiError(
            message: 'Server error',
            statusCode: 500,
            endpoint: '/api/test',
            method: 'GET',
          ),
          ApiError(
            message: 'Another server error',
            statusCode: 500,
            endpoint: '/api/test',
            method: 'POST',
          ),
        ];

        final consolidated = ErrorUtils.consolidateErrors(errors);
        expect(consolidated.message, contains('and 1 similar error'));
      });
    });
  });
}