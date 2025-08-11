import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../lib/error/services/error_service.dart';
import '../../../lib/error/utils/error_migration_helper.dart';
import '../../../lib/error/models/app_error.dart';
import '../../../lib/error/models/api_error.dart';
import '../../../lib/error/models/validation_error.dart';
import '../../../lib/error/models/network_error.dart';
import '../../../lib/error/models/client_error.dart';

import 'error_migration_helper_test.mocks.dart';

@GenerateMocks([IErrorService])
void main() {
  late MockIErrorService mockErrorService;
  late ErrorMigrationHelper migrationHelper;

  setUp(() {
    mockErrorService = MockIErrorService();
    migrationHelper = ErrorMigrationHelper(mockErrorService);
  });

  group('ErrorMigrationHelper', () {
    group('migrateException', () {
      test('should create ClientError for generic exceptions', () {
        // Arrange
        final exception = Exception('Test exception');
        const context = 'TestComponent';
        final metadata = {'key': 'value'};

        // Act
        migrationHelper.migrateException(
          exception,
          context: context,
          metadata: metadata,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.message, equals('Exception: Test exception'));
        expect(capturedError.componentName, equals(context));
        expect(capturedError.metadata, equals(metadata));
        expect(capturedError.severity, equals(ErrorSeverity.error));
      });

      test('should handle null context and metadata', () {
        // Arrange
        final exception = Exception('Test exception');

        // Act
        migrationHelper.migrateException(exception);

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.componentName, isNull);
        expect(capturedError.metadata, isNull);
      });
    });

    group('migrateValidationErrors', () {
      test('should create ValidationError with field errors', () {
        // Arrange
        final fieldErrors = {
          'name': ['Name is required', 'Name too short'],
          'email': ['Invalid email format'],
        };
        const formId = 'user_form';
        const context = 'UserFormStore';

        // Act
        migrationHelper.migrateValidationErrors(
          fieldErrors,
          formId: formId,
          context: context,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ValidationError;
        expect(capturedError.message, equals('Validation failed'));
        expect(capturedError.fieldErrors, equals(fieldErrors));
        expect(capturedError.formId, equals(formId));
        expect(capturedError.metadata, equals({'context': context}));
        expect(capturedError.severity, equals(ErrorSeverity.warning));
      });

      test('should handle null optional parameters', () {
        // Arrange
        final fieldErrors = {'field': ['error']};

        // Act
        migrationHelper.migrateValidationErrors(fieldErrors);

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ValidationError;
        expect(capturedError.formId, isNull);
        expect(capturedError.metadata, isNull);
      });
    });

    group('migrateNetworkError', () {
      test('should create NetworkError with all parameters', () {
        // Arrange
        const message = 'Connection timeout';
        const url = 'https://api.example.com/data';
        const timeout = Duration(seconds: 30);
        const type = NetworkErrorType.timeout;

        // Act
        migrationHelper.migrateNetworkError(
          message,
          url: url,
          timeout: timeout,
          type: type,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as NetworkError;
        expect(capturedError.message, equals(message));
        expect(capturedError.url, equals(url));
        expect(capturedError.timeout, equals(timeout));
        expect(capturedError.networkType, equals(type));
        expect(capturedError.severity, equals(ErrorSeverity.error));
      });

      test('should use default network type when not specified', () {
        // Arrange
        const message = 'Network error';

        // Act
        migrationHelper.migrateNetworkError(message);

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as NetworkError;
        expect(capturedError.networkType, equals(NetworkErrorType.connectivity));
      });
    });

    group('migrateSyncError', () {
      test('should create ClientError for sync operations', () {
        // Arrange
        const message = 'Sync failed';
        const details = 'Connection lost during sync';
        final metadata = {'operation': 'customer_sync'};

        // Act
        migrationHelper.migrateSyncError(
          message,
          details: details,
          metadata: metadata,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.message, equals(message));
        expect(capturedError.componentName, equals('SyncService'));
        expect(capturedError.metadata!['details'], equals(details));
        expect(capturedError.metadata!['operation'], equals('customer_sync'));
      });
    });

    group('migrateCustomerError', () {
      test('should create ClientError with customer context', () {
        // Arrange
        const message = 'Customer validation failed';
        const customerId = 'cust_123';
        const operation = 'update';
        final customerData = {'name': 'John Doe'};

        // Act
        migrationHelper.migrateCustomerError(
          message,
          customerId: customerId,
          operation: operation,
          customerData: customerData,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.message, equals(message));
        expect(capturedError.componentName, equals('CustomerManagement'));
        expect(capturedError.metadata!['customerId'], equals(customerId));
        expect(capturedError.metadata!['operation'], equals(operation));
        expect(capturedError.metadata!['customerData'], equals(customerData));
      });
    });

    group('migrateAuthError', () {
      test('should create ApiError when status code and endpoint provided', () {
        // Arrange
        const message = 'Authentication failed';
        const endpoint = '/api/auth/login';
        const statusCode = 401;
        final requestData = {'username': 'user', 'password': '***'};

        // Act
        migrationHelper.migrateAuthError(
          message,
          endpoint: endpoint,
          statusCode: statusCode,
          requestData: requestData,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ApiError;
        expect(capturedError.message, equals(message));
        expect(capturedError.endpoint, equals(endpoint));
        expect(capturedError.statusCode, equals(statusCode));
        expect(capturedError.method, equals('POST'));
        expect(capturedError.requestData, equals(requestData));
      });

      test('should create ClientError when status code or endpoint missing', () {
        // Arrange
        const message = 'Authentication failed';
        final requestData = {'username': 'user'};

        // Act
        migrationHelper.migrateAuthError(
          message,
          requestData: requestData,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.message, equals(message));
        expect(capturedError.componentName, equals('Authentication'));
        expect(capturedError.metadata, equals(requestData));
      });
    });

    group('migrateWebSocketError', () {
      test('should create NetworkError for websocket operations', () {
        // Arrange
        const message = 'WebSocket connection failed';
        const channel = 'notifications';
        const operation = 'subscribe';
        final metadata = {'retry_count': 3};

        // Act
        migrationHelper.migrateWebSocketError(
          message,
          channel: channel,
          operation: operation,
          metadata: metadata,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as NetworkError;
        expect(capturedError.message, equals(message));
        expect(capturedError.networkType, equals(NetworkErrorType.websocket));
        expect(capturedError.metadata!['channel'], equals(channel));
        expect(capturedError.metadata!['operation'], equals(operation));
        expect(capturedError.metadata!['retry_count'], equals(3));
      });
    });

    group('replaceErrorStoreUsage', () {
      test('should create ClientError with specified severity', () {
        // Arrange
        const errorMessage = 'Legacy error message';
        const context = 'LegacyComponent';
        const severity = ErrorSeverity.warning;

        // Act
        migrationHelper.replaceErrorStoreUsage(
          errorMessage,
          context: context,
          severity: severity,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.message, equals(errorMessage));
        expect(capturedError.componentName, equals(context));
        expect(capturedError.severity, equals(severity));
      });

      test('should use default error severity when not specified', () {
        // Arrange
        const errorMessage = 'Default severity error';

        // Act
        migrationHelper.replaceErrorStoreUsage(errorMessage);

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.severity, equals(ErrorSeverity.error));
      });
    });

    group('Error ID Generation', () {
      test('should generate unique IDs for different errors', () {
        // Arrange
        final errors = <AppError>[];
        when(mockErrorService.showError(any)).thenAnswer((invocation) {
          errors.add(invocation.positionalArguments[0] as AppError);
        });

        // Act
        migrationHelper.migrateException(Exception('Error 1'));
        migrationHelper.migrateException(Exception('Error 2'));

        // Assert
        expect(errors.length, equals(2));
        expect(errors[0].id, isNot(equals(errors[1].id)));
      });
    });
  });
}