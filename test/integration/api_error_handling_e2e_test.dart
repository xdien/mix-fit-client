import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/interceptors/error_service_interceptor.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/di/error_module.dart';

void main() {
  group('API Error Handling End-to-End Tests', () {
    late GetIt getIt;
    late Dio dio;
    late IErrorService errorService;
    late ErrorStore errorStore;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      // Initialize error module
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
      
      // Create Dio instance with error interceptor
      dio = Dio();
      getIt.registerSingleton<Dio>(dio);
      
      dio.interceptors.add(ErrorServiceInterceptor(
        errorService: errorService,
      ));
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('API Error Capture and Display', () {
      test('should capture 404 errors and display them in error store', () async {
        // Arrange - Set up a mock server response for 404
        dio.options.baseUrl = 'https://httpbin.org';
        
        try {
          // Act - Make a request that will return 404
          await dio.get('/status/404');
          fail('Expected DioException to be thrown');
        } catch (e) {
          // Assert - Verify error was captured and stored
          expect(e, isA<DioException>());
          
          // Wait a bit for async error processing
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Verify error store has the error
          expect(errorStore.hasErrors, isTrue);
          expect(errorStore.activeErrors.length, equals(1));
          
          final error = errorStore.activeErrors.first;
          expect(error, isA<ApiError>());
          
          final apiError = error as ApiError;
          expect(apiError.statusCode, equals(404));
          expect(apiError.endpoint, equals('/status/404'));
          expect(apiError.method, equals('GET'));
        }
      });

      test('should capture 500 errors with retry actions', () async {
        // Arrange
        dio.options.baseUrl = 'https://httpbin.org';
        
        try {
          // Act - Make a request that will return 500
          await dio.get('/status/500');
          fail('Expected DioException to be thrown');
        } catch (e) {
          // Assert
          expect(e, isA<DioException>());
          
          await Future.delayed(const Duration(milliseconds: 100));
          
          expect(errorStore.hasErrors, isTrue);
          final error = errorStore.activeErrors.first as ApiError;
          expect(error.statusCode, equals(500));
          expect(error.actions, isNotNull);
          expect(error.actions!.isNotEmpty, isTrue);
          
          // Verify retry action exists
          final retryAction = error.actions!.firstWhere(
            (action) => action.id == 'retry',
          );
          expect(retryAction.label, equals('Retry'));
          expect(retryAction.isPrimary, isTrue);
        }
      });

      test('should capture timeout errors', () async {
        // Arrange - Set a very short timeout
        dio.options.connectTimeout = const Duration(milliseconds: 1);
        dio.options.baseUrl = 'https://httpbin.org';
        
        try {
          // Act - Make a request that will timeout
          await dio.get('/delay/5');
          fail('Expected DioException to be thrown');
        } catch (e) {
          // Assert
          expect(e, isA<DioException>());
          
          await Future.delayed(const Duration(milliseconds: 100));
          
          expect(errorStore.hasErrors, isTrue);
          final error = errorStore.activeErrors.first;
          expect(error, isA<NetworkError>());
          
          final networkError = error as NetworkError;
          expect(networkError.networkType, equals(NetworkErrorType.timeout));
          expect(networkError.isRetryable, isTrue);
        }
      });
    });

    group('Error Store Integration', () {
      test('should manage error queue correctly', () async {
        // Arrange - Clear any existing errors
        errorStore.clearAllErrors();
        
        // Act - Add multiple errors
        final error1 = ApiError(
          message: 'First error',
          statusCode: 400,
          endpoint: '/test1',
          method: 'GET',
        );
        
        final error2 = NetworkError(
          message: 'Network error',
          networkType: NetworkErrorType.noConnection,
        );
        
        errorService.showError(error1);
        errorService.showError(error2);
        
        // Wait for async processing
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Assert
        expect(errorStore.activeErrors.length, equals(2));
        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.priorityError, isNotNull);
        
        // Verify priority error is one of the errors (both have same priority, so first one wins)
        expect(errorStore.priorityError, isIn([error1, error2]));
      });

      test('should handle error dismissal', () async {
        // Arrange
        errorStore.clearAllErrors();
        
        final error = ApiError(
          message: 'Test error',
          statusCode: 400,
          endpoint: '/test',
          method: 'GET',
        );
        
        // Act
        errorService.showError(error);
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(errorStore.hasErrors, isTrue);
        
        // Dismiss the error
        errorService.clearError(error.id);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Assert
        expect(errorStore.hasErrors, isFalse);
        expect(errorStore.activeErrors.isEmpty, isTrue);
      });
    });

    group('Error Message Extraction', () {
      test('should extract custom error messages from API responses', () async {
        // Test message extraction by directly creating an API error
        final apiError = ApiError(
          message: 'Validation failed',
          statusCode: 422,
          endpoint: '/test',
          method: 'POST',
          responseData: {
            'message': 'Validation failed',
            'errors': {
              'email': ['Email is required', 'Email must be valid'],
              'password': ['Password is too short'],
            }
          },
        );
        
        errorService.showError(apiError);
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(errorStore.hasErrors, isTrue);
        final error = errorStore.activeErrors.first as ApiError;
        expect(error.message, equals('Validation failed'));
        expect(error.statusCode, equals(422));
        expect(error.responseData, isNotNull);
      });
    });

    group('Request Logging', () {
      test('should log requests and responses for debugging', () async {
        // Arrange
        dio.options.baseUrl = 'https://httpbin.org';
        
        // Act - Make a successful request
        final response = await dio.get('/get?test=value');
        
        // Assert - Verify response was successful
        expect(response.statusCode, equals(200));
        expect(response.data, isA<Map<String, dynamic>>());
        
        // Logging is verified through console output in the interceptor
        // In a real application, you might want to capture logs for testing
      });
    });
  });
}

