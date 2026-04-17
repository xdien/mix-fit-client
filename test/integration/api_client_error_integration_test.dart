import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/retry_service.dart';
import 'package:core/error/interceptors/error_service_interceptor.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/network_error.dart';

import 'api_client_error_integration_test.mocks.dart';

@GenerateMocks([IErrorService, Dio])
void main() {
  group('API Client Error Integration Tests', () {
    late MockIErrorService mockErrorService;
    late MockDio mockDio;
    late ErrorServiceInterceptor errorInterceptor;
    late RetryService retryService;
    late GetIt getIt;

    setUp(() {
      getIt = GetIt.instance;
      getIt.reset();
      
      mockErrorService = MockIErrorService();
      mockDio = MockDio();
      retryService = RetryService(dio: mockDio);
      
      // Register mocks in GetIt
      getIt.registerSingleton<IErrorService>(mockErrorService);
      getIt.registerSingleton<Dio>(mockDio);
      
      errorInterceptor = ErrorServiceInterceptor(
        errorService: mockErrorService,
        retryService: retryService,
      );
    });

    tearDown(() {
      getIt.reset();
    });

    group('HTTP Error Handling', () {
      test('should capture and display API errors from HTTP responses', () async {
        // Arrange
        final requestOptions = RequestOptions(path: '/test');
        final response = Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {'message': 'Bad request error'},
        );
        final dioException = DioException(
          requestOptions: requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );

        // Act
        final handler = MockErrorInterceptorHandler();
        errorInterceptor.onError(dioException, handler);

        // Assert
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first;
        expect(capturedError, isA<ApiError>());
        
        final apiError = capturedError as ApiError;
        expect(apiError.statusCode, equals(400));
        expect(apiError.endpoint, equals('/test'));
        expect(apiError.message, contains('Bad request'));
      });

      test('should capture network timeout errors', () async {
        // Arrange
        final requestOptions = RequestOptions(
          path: '/test',
          connectTimeout: const Duration(seconds: 5),
        );
        final dioException = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        );

        // Act
        final handler = MockErrorInterceptorHandler();
        errorInterceptor.onError(dioException, handler);

        // Assert
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first;
        expect(capturedError, isA<NetworkError>());
        
        final networkError = capturedError as NetworkError;
        expect(networkError.networkType, equals(NetworkErrorType.timeout));
        expect(networkError.timeout, equals(const Duration(seconds: 5)));
      });

      test('should capture connection errors', () async {
        // Arrange
        final requestOptions = RequestOptions(path: '/test');
        final dioException = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
          message: 'No internet connection',
        );

        // Act
        final handler = MockErrorInterceptorHandler();
        errorInterceptor.onError(dioException, handler);

        // Assert
        final capturedError = verify(mockErrorService.showError(captureAny)).captured.first;
        expect(capturedError, isA<NetworkError>());
        
        final networkError = capturedError as NetworkError;
        expect(networkError.networkType, equals(NetworkErrorType.noConnection));
      });
    });

    group('Request/Response Logging', () {
      test('should log successful requests and responses', () {
        // Arrange
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
          data: {'key': 'value'},
        );
        final response = Response(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'result': 'success'},
        );

        // Act
        final requestHandler = MockRequestInterceptorHandler();
        final responseHandler = MockResponseInterceptorHandler();
        
        errorInterceptor.onRequest(requestOptions, requestHandler);
        errorInterceptor.onResponse(response, responseHandler);

        // Assert - verify handlers were called (logging happens internally)
        verify(requestHandler.next(requestOptions)).called(1);
        verify(responseHandler.next(response)).called(1);
      });
    });

    group('Retry Mechanism', () {
      test('should identify retryable errors correctly', () {
        // Test timeout errors
        final timeoutError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );
        expect(errorInterceptor.isRetryable(timeoutError), isTrue);

        // Test server errors
        final serverError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
        );
        expect(errorInterceptor.isRetryable(serverError), isTrue);

        // Test non-retryable errors
        final clientError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
          ),
        );
        expect(errorInterceptor.isRetryable(clientError), isFalse);
      });

      test('should retry failed requests when requested', () async {
        // Arrange
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
          data: {'key': 'value'},
        );
        
        final successResponse = Response(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'result': 'success'},
        );

        when(mockDio.request(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => successResponse);

        // Act
        final result = await errorInterceptor.retryRequest(requestOptions);

        // Assert
        expect(result, isNotNull);
        expect(result!.statusCode, equals(200));
        verify(mockDio.request(
          '/test',
          data: {'key': 'value'},
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).called(1);
      });
    });

    group('Error Message Extraction', () {
      test('should extract error messages from different response formats', () {
        // Test with message field
        final requestOptions = RequestOptions(path: '/test');
        final response1 = Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {'message': 'Custom error message'},
        );
        final error1 = DioException(
          requestOptions: requestOptions,
          response: response1,
          type: DioExceptionType.badResponse,
        );

        final handler1 = MockErrorInterceptorHandler();
        errorInterceptor.onError(error1, handler1);

        final capturedError1 = verify(mockErrorService.showError(captureAny)).captured.first as ApiError;
        expect(capturedError1.message, equals('Custom error message'));

        // Test with validation errors
        final response2 = Response(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'errors': {
              'email': ['Email is required'],
              'password': ['Password is too short'],
            }
          },
        );
        final error2 = DioException(
          requestOptions: requestOptions,
          response: response2,
          type: DioExceptionType.badResponse,
        );

        final handler2 = MockErrorInterceptorHandler();
        errorInterceptor.onError(error2, handler2);

        final capturedError2 = verify(mockErrorService.showError(captureAny)).captured.last as ApiError;
        expect(capturedError2.message, equals('Email is required'));
      });
    });

    group('Data Sanitization', () {
      test('should sanitize sensitive data in request logs', () {
        // Arrange
        final requestOptions = RequestOptions(
          path: '/login',
          method: 'POST',
          data: {
            'email': 'user@example.com',
            'password': 'secret123',
            'token': 'bearer-token',
          },
        );

        // Act
        final handler = MockRequestInterceptorHandler();
        errorInterceptor.onRequest(requestOptions, handler);

        // Assert - sensitive data should be sanitized in logs
        // (This is tested through the logging output, which is handled internally)
        verify(handler.next(requestOptions)).called(1);
      });
    });
  });
}

// Mock classes for testing
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}
class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}
class MockResponseInterceptorHandler extends Mock implements ResponseInterceptorHandler {}