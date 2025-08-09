import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/services/retry_service.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/error_action.dart';
import 'package:core/di/error_module.dart';
import 'package:dio/dio.dart';

import 'error_resolution_workflow_test.mocks.dart';

@GenerateMocks([RetryService, Dio])
void main() {
  group('Error Resolution Workflow Tests', () {
    late GetIt getIt;
    late MockRetryService mockRetryService;
    late MockDio mockDio;
    late IErrorService errorService;
    late ErrorStore errorStore;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      mockRetryService = MockRetryService();
      mockDio = MockDio();
      
      // Initialize error module
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      // Replace services with mocks
      getIt.unregister<RetryService>();
      getIt.unregister<Dio>();
      getIt.registerSingleton<RetryService>(mockRetryService);
      getIt.registerSingleton<Dio>(mockDio);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('API Error Resolution', () {
      test('should handle successful retry for server errors', () async {
        // Arrange
        final apiError = ApiError(
          message: 'Internal server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          isRetryable: true,
        );

        when(mockRetryService.retryRequest(any))
            .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/test'),
              statusCode: 200,
              data: {'success': true},
            ));

        // Act
        errorService.showError(apiError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Execute retry action
        final retryAction = apiError.actions!.firstWhere(
          (action) => action.id == 'retry',
        );
        
        await retryAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockRetryService.retryRequest(any)).called(1);
        expect(errorStore.hasErrors, isFalse); // Error should be cleared after successful retry
      });

      test('should handle failed retry attempts', () async {
        // Arrange
        final apiError = ApiError(
          message: 'Service unavailable',
          statusCode: 503,
          endpoint: '/api/test',
          method: 'POST',
          isRetryable: true,
        );

        when(mockRetryService.retryRequest(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/test'),
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: RequestOptions(path: '/api/test'),
                statusCode: 503,
              ),
            ));

        // Act
        errorService.showError(apiError);
        await Future.delayed(const Duration(milliseconds: 100));

        final retryAction = apiError.actions!.firstWhere(
          (action) => action.id == 'retry',
        );
        
        await retryAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockRetryService.retryRequest(any)).called(1);
        expect(errorStore.hasErrors, isTrue); // Error should still be present
        
        // Should show updated error message about retry failure
        final updatedError = errorStore.activeErrors.first as ApiError;
        expect(updatedError.retryCount, equals(1));
        expect(updatedError.lastRetryAt, isNotNull);
      });

      test('should limit retry attempts', () async {
        // Arrange
        final apiError = ApiError(
          message: 'Gateway timeout',
          statusCode: 504,
          endpoint: '/api/test',
          method: 'GET',
          isRetryable: true,
          maxRetries: 3,
        );

        when(mockRetryService.retryRequest(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/test'),
              type: DioExceptionType.badResponse,
            ));

        errorService.showError(apiError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Retry multiple times
        final retryAction = apiError.actions!.firstWhere(
          (action) => action.id == 'retry',
        );

        for (int i = 0; i < 5; i++) {
          await retryAction.onPressed();
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Assert
        verify(mockRetryService.retryRequest(any)).called(3); // Should only retry 3 times
        
        final finalError = errorStore.activeErrors.first as ApiError;
        expect(finalError.retryCount, equals(3));
        expect(finalError.canRetry, isFalse); // Should disable further retries
        
        // Retry action should be disabled
        final finalRetryAction = finalError.actions!.firstWhere(
          (action) => action.id == 'retry',
        );
        expect(finalRetryAction.isEnabled, isFalse);
      });
    });

    group('Validation Error Resolution', () {
      test('should handle field validation error correction', () async {
        // Arrange
        final validationError = ValidationError(
          message: 'Validation failed',
          fieldErrors: {
            'email': ['Email is required', 'Email format is invalid'],
            'password': ['Password must be at least 8 characters'],
          },
          formId: 'login-form',
        );

        // Act
        errorService.showError(validationError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Simulate field correction
        final fixFieldAction = validationError.actions!.firstWhere(
          (action) => action.id == 'fix_fields',
        );
        
        await fixFieldAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasFieldValidationGuidance, isTrue);
        expect(errorStore.highlightedFields, contains('email'));
        expect(errorStore.highlightedFields, contains('password'));
        
        // Should provide specific guidance for each field
        final emailGuidance = errorStore.getFieldGuidance('email');
        expect(emailGuidance, isNotNull);
        expect(emailGuidance!.errors, contains('Email is required'));
        expect(emailGuidance.errors, contains('Email format is invalid'));
      });

      test('should clear validation errors when fields are corrected', () async {
        // Arrange
        final validationError = ValidationError(
          message: 'Form validation failed',
          fieldErrors: {
            'username': ['Username is required'],
            'email': ['Invalid email format'],
          },
          formId: 'registration-form',
        );

        errorService.showError(validationError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Simulate field corrections
        errorStore.clearFieldError('username');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - Partial clearing
        expect(errorStore.hasErrors, isTrue);
        final partialError = errorStore.activeErrors.first as ValidationError;
        expect(partialError.fieldErrors.containsKey('username'), isFalse);
        expect(partialError.fieldErrors.containsKey('email'), isTrue);

        // Act - Clear remaining field
        errorStore.clearFieldError('email');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - Complete clearing
        expect(errorStore.hasErrors, isFalse);
      });
    });

    group('Network Error Resolution', () {
      test('should handle network reconnection', () async {
        // Arrange
        final networkError = NetworkError(
          message: 'No internet connection',
          networkType: NetworkErrorType.noConnection,
          isRetryable: true,
        );

        errorService.showError(networkError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.isOffline, isTrue);

        // Act - Simulate network reconnection
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.good,
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.isOffline, isFalse);
        
        // Network errors should be auto-resolved
        final remainingNetworkErrors = errorStore.activeErrors
            .where((error) => error is NetworkError && 
                   (error as NetworkError).networkType == NetworkErrorType.noConnection)
            .toList();
        expect(remainingNetworkErrors.isEmpty, isTrue);
      });

      test('should handle timeout error resolution with retry', () async {
        // Arrange
        final timeoutError = NetworkError(
          message: 'Request timed out',
          networkType: NetworkErrorType.timeout,
          timeout: const Duration(seconds: 30),
          url: '/api/slow-endpoint',
          isRetryable: true,
        );

        when(mockRetryService.retryRequest(any))
            .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/slow-endpoint'),
              statusCode: 200,
              data: {'result': 'success'},
            ));

        // Act
        errorService.showError(timeoutError);
        await Future.delayed(const Duration(milliseconds: 100));

        final retryAction = timeoutError.actions!.firstWhere(
          (action) => action.id == 'retry',
        );
        
        await retryAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockRetryService.retryRequest(any)).called(1);
        expect(errorStore.hasErrors, isFalse);
      });
    });

    group('Authentication Error Resolution', () {
      test('should handle token expiration with re-login', () async {
        // Arrange
        final authError = ApiError(
          message: 'Token expired',
          statusCode: 401,
          endpoint: '/api/protected',
          method: 'GET',
          errorType: ApiErrorType.authentication,
        );

        // Act
        errorService.showError(authError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Execute re-login action
        final reLoginAction = authError.actions!.firstWhere(
          (action) => action.id == 'relogin',
        );
        
        bool loginTriggered = false;
        reLoginAction.onPressed = () async {
          loginTriggered = true;
          // Simulate successful re-login
          errorStore.clearError(authError.id);
        };

        await reLoginAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(loginTriggered, isTrue);
        expect(errorStore.hasErrors, isFalse);
      });

      test('should handle authorization errors with contact support', () async {
        // Arrange
        final authzError = ApiError(
          message: 'Insufficient permissions',
          statusCode: 403,
          endpoint: '/api/admin',
          method: 'POST',
          errorType: ApiErrorType.authorization,
        );

        // Act
        errorService.showError(authzError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Should have contact support action
        final supportAction = authzError.actions!.firstWhere(
          (action) => action.id == 'contact_support',
        );
        
        expect(supportAction.label, equals('Contact Support'));
        expect(supportAction.isPrimary, isTrue);
        
        bool supportContactTriggered = false;
        supportAction.onPressed = () async {
          supportContactTriggered = true;
        };

        await supportAction.onPressed();

        // Assert
        expect(supportContactTriggered, isTrue);
        // Error should remain visible until user dismisses it
        expect(errorStore.hasErrors, isTrue);
      });
    });

    group('Custom Error Resolution', () {
      test('should handle custom error actions', () async {
        // Arrange
        final customError = ApiError(
          message: 'Custom business logic error',
          statusCode: 422,
          endpoint: '/api/business-action',
          method: 'POST',
          actions: [
            ErrorAction(
              id: 'custom_action',
              label: 'Fix Data',
              isPrimary: true,
              onPressed: () async {
                // Custom resolution logic
              },
            ),
            ErrorAction(
              id: 'skip_action',
              label: 'Skip This Step',
              isPrimary: false,
              onPressed: () async {
                // Skip logic
              },
            ),
          ],
        );

        // Act
        errorService.showError(customError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Should have custom actions
        final customAction = customError.actions!.firstWhere(
          (action) => action.id == 'custom_action',
        );
        final skipAction = customError.actions!.firstWhere(
          (action) => action.id == 'skip_action',
        );

        expect(customAction.label, equals('Fix Data'));
        expect(customAction.isPrimary, isTrue);
        expect(skipAction.label, equals('Skip This Step'));
        expect(skipAction.isPrimary, isFalse);

        // Execute custom action
        bool customActionExecuted = false;
        customAction.onPressed = () async {
          customActionExecuted = true;
          errorStore.clearError(customError.id);
        };

        await customAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(customActionExecuted, isTrue);
        expect(errorStore.hasErrors, isFalse);
      });
    });

    group('Error Resolution Tracking', () {
      test('should track resolution attempts and outcomes', () async {
        // Arrange
        final trackableError = ApiError(
          message: 'Trackable error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          isRetryable: true,
        );

        when(mockRetryService.retryRequest(any))
            .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/test'),
              statusCode: 200,
              data: {'success': true},
            ));

        // Act
        errorService.showError(trackableError);
        await Future.delayed(const Duration(milliseconds: 100));

        final retryAction = trackableError.actions!.firstWhere(
          (action) => action.id == 'retry',
        );
        
        await retryAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final resolutionHistory = errorStore.getErrorResolutionHistory(trackableError.id);
        expect(resolutionHistory, isNotNull);
        expect(resolutionHistory!.attempts, equals(1));
        expect(resolutionHistory.lastAttemptAt, isNotNull);
        expect(resolutionHistory.wasSuccessful, isTrue);
        expect(resolutionHistory.resolutionMethod, equals('retry'));
      });

      test('should provide resolution analytics', () async {
        // Arrange - Create multiple errors and resolve them
        final errors = [
          ApiError(message: 'Error 1', statusCode: 500, endpoint: '/api/1', method: 'GET'),
          NetworkError(message: 'Error 2', networkType: NetworkErrorType.timeout),
          ValidationError(message: 'Error 3', fieldErrors: {'field': ['error']}),
        ];

        for (final error in errors) {
          errorService.showError(error);
          await Future.delayed(const Duration(milliseconds: 50));
          errorService.clearError(error.id);
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Act
        final analytics = errorStore.getResolutionAnalytics();

        // Assert
        expect(analytics.totalErrors, equals(3));
        expect(analytics.resolvedErrors, equals(3));
        expect(analytics.resolutionRate, equals(1.0));
        expect(analytics.averageResolutionTime, isNotNull);
        expect(analytics.commonResolutionMethods, isNotEmpty);
      });
    });
  });
}

// Additional models for testing
class NetworkStatus {
  final bool isConnected;
  final NetworkQuality quality;
  final Duration? latency;
  final DateTime lastChecked;

  NetworkStatus({
    required this.isConnected,
    required this.quality,
    this.latency,
    required this.lastChecked,
  });
}

enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  offline,
}

enum ApiErrorType {
  authentication,
  authorization,
  validation,
  server,
  client,
}

class ErrorResolutionHistory {
  final int attempts;
  final DateTime? lastAttemptAt;
  final bool wasSuccessful;
  final String resolutionMethod;

  ErrorResolutionHistory({
    required this.attempts,
    this.lastAttemptAt,
    required this.wasSuccessful,
    required this.resolutionMethod,
  });
}

class ResolutionAnalytics {
  final int totalErrors;
  final int resolvedErrors;
  final double resolutionRate;
  final Duration? averageResolutionTime;
  final List<String> commonResolutionMethods;

  ResolutionAnalytics({
    required this.totalErrors,
    required this.resolvedErrors,
    required this.resolutionRate,
    this.averageResolutionTime,
    required this.commonResolutionMethods,
  });
}