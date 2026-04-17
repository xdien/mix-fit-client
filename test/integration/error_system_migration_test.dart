import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/app_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/client_error.dart';
import 'package:core/error/utils/error_migration_helper.dart';
import 'package:customer_management/domain/usecases/validate_customer_fields_usecase.dart';
import 'package:customer_management/presentation/stores/customer_form_store.dart';
import 'package:websocket_service/domain/repository/websocket_preferences_repository.dart';
import 'package:websocket_service/stores/websocket_preferences_store.dart';

import 'error_system_migration_test.mocks.dart';

@GenerateMocks([
  IErrorService,
  ErrorStore,
  ValidateCustomerFieldsUseCase,
  WebSocketPreferencesRepository,
])
void main() {
  late GetIt getIt;
  late MockIErrorService mockErrorService;
  late MockErrorStore mockErrorStore;
  late MockValidateCustomerFieldsUseCase mockValidateUseCase;
  late MockWebSocketPreferencesRepository mockWebSocketRepository;

  setUp(() {
    getIt = GetIt.instance;
    mockErrorService = MockIErrorService();
    mockErrorStore = MockErrorStore();
    mockValidateUseCase = MockValidateCustomerFieldsUseCase();
    mockWebSocketRepository = MockWebSocketPreferencesRepository();

    // Register mocks
    getIt.registerSingleton<IErrorService>(mockErrorService);
    getIt.registerSingleton<ErrorStore>(mockErrorStore);
  });

  tearDown(() {
    getIt.reset();
  });

  group('Error System Migration Tests', () {
    group('Customer Management Migration', () {
      test('should migrate customer form validation errors to shared error system', () {
        // Arrange
        final store = CustomerFormStore(mockValidateUseCase, mockErrorService);
        final fieldErrors = {'name': ['Name is required'], 'phone': ['Invalid phone number']};
        
        when(mockValidateUseCase.validateField(any, any, any))
            .thenReturn(['Name is required']);

        // Act
        store.updateName(''); // This should trigger validation and error migration

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ValidationError;
        expect(capturedError.fieldErrors, contains('name'));
        expect(capturedError.formId, equals('customer_form'));
      });

      test('should not migrate non-critical field validation errors', () {
        // Arrange
        final store = CustomerFormStore(mockValidateUseCase, mockErrorService);
        
        when(mockValidateUseCase.validateField(any, any, any))
            .thenReturn(['Optional field error']);

        // Act
        store.updateNotes(''); // Non-critical field

        // Assert
        verifyNever(mockErrorService.showError(any));
      });

      test('should migrate all validation errors when validating all fields', () {
        // Arrange
        final store = CustomerFormStore(mockValidateUseCase, mockErrorService);
        final validationResult = ValidationResult(
          fieldErrors: {'name': ['Required'], 'phone': ['Invalid']},
          businessRuleErrors: ['Business rule violation'],
        );
        
        when(mockValidateUseCase.execute(any)).thenReturn(validationResult);
        store.updateName('Test'); // Set some data to create a customer

        // Act
        store.validateAllFields();

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ValidationError;
        expect(capturedError.fieldErrors.length, equals(2));
      });
    });

    group('WebSocket Service Migration', () {
      test('should migrate websocket initialization errors to shared error system', () {
        // Arrange
        when(mockWebSocketRepository.getPreferences())
            .thenThrow(Exception('Connection failed'));
        when(mockWebSocketRepository.getAvailableChannels()).thenReturn([]);
        when(mockWebSocketRepository.preferencesStream)
            .thenAnswer((_) => Stream.empty());

        // Act
        final store = WebSocketPreferencesStore(mockWebSocketRepository, mockErrorService);

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as NetworkError;
        expect(capturedError.networkType, equals(NetworkErrorType.websocket));
        expect(capturedError.message, contains('Failed to load WebSocket preferences'));
      });

      test('should migrate websocket operation errors to shared error system', () async {
        // Arrange
        when(mockWebSocketRepository.getPreferences())
            .thenAnswer((_) async => WebSocketPreferences.defaultPreferences());
        when(mockWebSocketRepository.getAvailableChannels()).thenReturn([]);
        when(mockWebSocketRepository.preferencesStream)
            .thenAnswer((_) => Stream.empty());
        when(mockWebSocketRepository.setRealTimeUpdatesEnabled(any))
            .thenThrow(Exception('Update failed'));

        final store = WebSocketPreferencesStore(mockWebSocketRepository, mockErrorService);

        // Act
        await store.setRealTimeUpdatesEnabled(true);

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as NetworkError;
        expect(capturedError.networkType, equals(NetworkErrorType.websocket));
        expect(capturedError.message, contains('Failed to update real-time settings'));
      });
    });

    group('Error Migration Helper', () {
      test('should create appropriate error types for different scenarios', () {
        // Arrange
        final helper = ErrorMigrationHelper(mockErrorService);

        // Act & Assert - Exception migration
        helper.migrateException(Exception('Test exception'), context: 'TestContext');
        verify(mockErrorService.showError(any)).called(1);
        var capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.componentName, equals('TestContext'));

        // Reset mock
        reset(mockErrorService);

        // Act & Assert - Network error migration
        helper.migrateNetworkError('Network timeout', type: NetworkErrorType.timeout);
        verify(mockErrorService.showError(any)).called(1);
        capturedError = verify(mockErrorService.showError(captureAny)).captured.first as NetworkError;
        expect(capturedError.networkType, equals(NetworkErrorType.timeout));

        // Reset mock
        reset(mockErrorService);

        // Act & Assert - Validation error migration
        helper.migrateValidationErrors({'field': ['error']}, formId: 'test_form');
        verify(mockErrorService.showError(any)).called(1);
        final validationError = verify(mockErrorService.showError(captureAny)).captured.first as ValidationError;
        expect(validationError.formId, equals('test_form'));
      });
    });

    group('Legacy Error Store Replacement', () {
      test('should replace direct error store usage with shared error system', () {
        // Arrange
        final helper = ErrorMigrationHelper(mockErrorService);

        // Act
        helper.replaceErrorStoreUsage(
          'Legacy error message',
          context: 'LegacyComponent',
          severity: ErrorSeverity.warning,
        );

        // Assert
        verify(mockErrorService.showError(any)).called(1);
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first as ClientError;
        expect(capturedError.message, equals('Legacy error message'));
        expect(capturedError.componentName, equals('LegacyComponent'));
        expect(capturedError.severity, equals(ErrorSeverity.warning));
      });
    });
  });

  group('Integration with Error Store', () {
    test('should integrate migrated errors with error store', () {
      // Arrange
      final helper = ErrorMigrationHelper(mockErrorService);
      when(mockErrorService.showError(any)).thenAnswer((invocation) {
        final error = invocation.positionalArguments[0] as AppError;
        // Simulate error service adding to store
        when(mockErrorStore.activeErrors).thenReturn([error]);
        when(mockErrorStore.hasErrors).thenReturn(true);
      });

      // Act
      helper.migrateException(Exception('Test error'));

      // Assert
      verify(mockErrorService.showError(any)).called(1);
      expect(mockErrorStore.hasErrors, isTrue);
    });
  });
}

// Mock classes for testing
class ValidationResult {
  final Map<String, List<String>> fieldErrors;
  final List<String> businessRuleErrors;

  ValidationResult({
    required this.fieldErrors,
    required this.businessRuleErrors,
  });
}

class WebSocketPreferences {
  static WebSocketPreferences defaultPreferences() {
    return WebSocketPreferences();
  }
}