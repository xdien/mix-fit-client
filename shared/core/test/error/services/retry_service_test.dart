import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/error/services/retry_service.dart';

import 'retry_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('RetryService', () {
    late MockDio mockDio;
    late RetryService retryService;

    setUp(() {
      mockDio = MockDio();
      retryService = RetryService(dio: mockDio);
    });

    group('retryRequest', () {
      test('should successfully retry a request', () async {
        // Arrange
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
          data: {'key': 'value'},
          queryParameters: {'param': 'value'},
          headers: {'Authorization': 'Bearer token'},
        );

        final expectedResponse = Response(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'result': 'success'},
        );

        when(mockDio.request(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        final result = await retryService.retryRequest(requestOptions);

        // Assert
        expect(result, isNotNull);
        expect(result!.statusCode, equals(200));
        expect(result.data, equals({'result': 'success'}));

        verify(mockDio.request(
          '/test',
          data: {'key': 'value'},
          queryParameters: {'param': 'value'},
          options: argThat(
            isA<Options>()
                .having((o) => o.method, 'method', 'GET')
                .having((o) => o.headers, 'headers', {'Authorization': 'Bearer token'}),
            named: 'options',
          ),
        )).called(1);
      });

      test('should return null when retry fails', () async {
        // Arrange
        final requestOptions = RequestOptions(path: '/test');

        when(mockDio.request(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        ));

        // Act
        final result = await retryService.retryRequest(requestOptions);

        // Assert
        expect(result, isNull);
      });
    });

    group('retryRequestWithModifications', () {
      test('should retry request with additional headers and query params', () async {
        // Arrange
        final requestOptions = RequestOptions(
          path: '/test',
          headers: {'Original': 'header'},
          queryParameters: {'original': 'param'},
        );

        final expectedResponse = Response(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'result': 'success'},
        );

        when(mockDio.request(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        final result = await retryService.retryRequestWithModifications(
          requestOptions,
          additionalHeaders: {'Additional': 'header'},
          additionalQueryParams: {'additional': 'param'},
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.statusCode, equals(200));

        verify(mockDio.request(
          '/test',
          data: anyNamed('data'),
          queryParameters: {
            'original': 'param',
            'additional': 'param',
          },
          options: argThat(
            isA<Options>().having(
              (o) => o.headers,
              'headers',
              {
                'Original': 'header',
                'Additional': 'header',
              },
            ),
            named: 'options',
          ),
        )).called(1);
      });

      test('should apply delay before retrying', () async {
        // Arrange
        final requestOptions = RequestOptions(path: '/test');
        final expectedResponse = Response(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'result': 'success'},
        );

        when(mockDio.request(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => expectedResponse);

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await retryService.retryRequestWithModifications(
          requestOptions,
          delay: const Duration(milliseconds: 100),
        );

        stopwatch.stop();

        // Assert
        expect(result, isNotNull);
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
      });
    });

    group('isRetryable', () {
      test('should return true for timeout errors', () {
        final timeoutErrors = [
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.connectionTimeout,
          ),
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.sendTimeout,
          ),
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.receiveTimeout,
          ),
        ];

        for (final error in timeoutErrors) {
          expect(retryService.isRetryable(error), isTrue);
        }
      });

      test('should return true for connection errors', () {
        final connectionError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        expect(retryService.isRetryable(connectionError), isTrue);
      });

      test('should return true for retryable HTTP status codes', () {
        final retryableStatusCodes = [408, 429, 500, 502, 503, 504];

        for (final statusCode in retryableStatusCodes) {
          final error = DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: statusCode,
            ),
          );

          expect(retryService.isRetryable(error), isTrue);
        }
      });

      test('should return false for non-retryable errors', () {
        final nonRetryableErrors = [
          // Cancel error
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.cancel,
          ),
          // Bad certificate
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badCertificate,
          ),
          // Unknown error
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.unknown,
          ),
          // Client errors (4xx except 408 and 429)
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: 400,
            ),
          ),
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: 404,
            ),
          ),
        ];

        for (final error in nonRetryableErrors) {
          expect(retryService.isRetryable(error), isFalse);
        }
      });
    });
  });
}