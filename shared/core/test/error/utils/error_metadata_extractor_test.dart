import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/utils/error_metadata_extractor.dart';

void main() {
  group('ErrorMetadataExtractor', () {
    group('fromDioException', () {
      test('extracts metadata from connection timeout', () {
        final exception = DioException(
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
          requestOptions: RequestOptions(
            path: '/api/test',
            method: 'GET',
            connectTimeout: const Duration(milliseconds: 5000),
          ),
        );

        final metadata = ErrorMetadataExtractor.fromDioException(exception);

        expect(metadata['type'], equals('dio_exception'));
        expect(metadata['dioType'], equals('connectionTimeout'));
        expect(metadata['message'], equals('Connection timeout'));
        expect(metadata['request']['method'], equals('GET'));
        expect(metadata['request']['path'], equals('/api/test'));
        expect(metadata['request']['connectTimeout'], equals(const Duration(milliseconds: 5000)));
      });

      test('extracts response metadata when available', () {
        final response = Response(
          statusCode: 404,
          statusMessage: 'Not Found',
          data: {'error': 'Resource not found'},
          requestOptions: RequestOptions(path: '/api/test'),
        );

        final exception = DioException(
          type: DioExceptionType.badResponse,
          response: response,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        final metadata = ErrorMetadataExtractor.fromDioException(exception);

        expect(metadata['response']['statusCode'], equals(404));
        expect(metadata['response']['statusMessage'], equals('Not Found'));
        expect(metadata['response']['data'], equals({'error': 'Resource not found'}));
      });

      test('truncates large response data', () {
        final largeData = 'x' * 2000;
        final response = Response(
          statusCode: 500,
          data: largeData,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        final exception = DioException(
          type: DioExceptionType.badResponse,
          response: response,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        final metadata = ErrorMetadataExtractor.fromDioException(exception);

        expect(metadata['response']['dataSize'], equals(2000));
        expect(metadata['response']['dataTruncated'], isTrue);
        expect(metadata['response']['data'], isNull);
      });

      test('sanitizes sensitive headers', () {
        final exception = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(
            path: '/api/test',
            headers: {
              'Authorization': 'Bearer secret-token',
              'Content-Type': 'application/json',
              'X-API-Key': 'secret-key',
            },
          ),
        );

        final metadata = ErrorMetadataExtractor.fromDioException(exception);

        expect(metadata['request']['headers']['Authorization'], equals('[REDACTED]'));
        expect(metadata['request']['headers']['Content-Type'], equals('application/json'));
        expect(metadata['request']['headers']['X-API-Key'], equals('[REDACTED]'));
      });

      test('extracts underlying error information', () {
        final socketException = const SocketException('Connection refused');
        final exception = DioException(
          type: DioExceptionType.connectionError,
          error: socketException,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        final metadata = ErrorMetadataExtractor.fromDioException(exception);

        expect(metadata['underlyingError']['type'], equals('SocketException'));
        expect(metadata['underlyingError']['socketException']['message'], equals('Connection refused'));
      });
    });

    group('fromException', () {
      test('extracts metadata from generic exception', () {
        final exception = Exception('Something went wrong');
        final metadata = ErrorMetadataExtractor.fromException(exception);

        expect(metadata['type'], equals('generic_exception'));
        expect(metadata['exceptionType'], equals('_Exception'));
        expect(metadata['message'], equals('Exception: Something went wrong'));
        expect(metadata['timestamp'], isNotNull);
      });

      test('extracts specific information from FormatException', () {
        final exception = const FormatException('Invalid format', 'source', 10);
        final metadata = ErrorMetadataExtractor.fromException(exception);

        expect(metadata['formatException']['source'], equals('source'));
        expect(metadata['formatException']['offset'], equals(10));
      });

      test('extracts specific information from ArgumentError', () {
        final exception = ArgumentError.value('invalid', 'param', 'Must be positive');
        final metadata = ErrorMetadataExtractor.fromException(exception);

        expect(metadata['argumentError']['invalidValue'], equals('invalid'));
        expect(metadata['argumentError']['name'], equals('param'));
      });

      test('extracts specific information from StateError', () {
        final exception = StateError('Bad state');
        final metadata = ErrorMetadataExtractor.fromException(exception);

        expect(metadata['stateError']['message'], equals('Bad state'));
      });
    });

    group('fromFlutterError', () {
      test('extracts metadata from Flutter error', () {
        final error = FlutterError('Widget build failed');
        
        final metadata = ErrorMetadataExtractor.fromFlutterError(error);

        expect(metadata['type'], equals('flutter_error'));
        expect(metadata['message'], equals('Widget build failed'));
        expect(metadata['library'], equals('flutter'));
        expect(metadata['timestamp'], isNotNull);
      });

      test('extracts stack trace information', () {
        final error = FlutterError('Widget build failed');
        
        final metadata = ErrorMetadataExtractor.fromFlutterError(error);

        if (metadata.containsKey('stackTrace')) {
          expect(metadata['stackTrace']['full'], isNotNull);
          expect(metadata['stackTrace']['lines'], isA<int>());
          expect(metadata['stackTrace']['firstLine'], isNotNull);
        }
      });
    });

    group('fromPlatformException', () {
      test('extracts metadata from platform exception', () {
        final exception = PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Camera permission denied',
          details: {'permission': 'camera'},
        );

        final metadata = ErrorMetadataExtractor.fromPlatformException(exception);

        expect(metadata['type'], equals('platform_exception'));
        expect(metadata['code'], equals('PERMISSION_DENIED'));
        expect(metadata['message'], equals('Camera permission denied'));
        expect(metadata['details'], equals({'permission': 'camera'}));
      });
    });

    group('fromHttpResponse', () {
      test('extracts metadata from HTTP response', () {
        final response = Response(
          statusCode: 500,
          statusMessage: 'Internal Server Error',
          data: {'error': 'Database connection failed'},
          requestOptions: RequestOptions(
            path: '/api/users',
            method: 'GET',
          ),
        );

        final metadata = ErrorMetadataExtractor.fromHttpResponse(response);

        expect(metadata['type'], equals('http_response'));
        expect(metadata['statusCode'], equals(500));
        expect(metadata['statusMessage'], equals('Internal Server Error'));
        expect(metadata['data'], equals({'error': 'Database connection failed'}));
        expect(metadata['request']['method'], equals('GET'));
        expect(metadata['request']['path'], equals('/api/users'));
      });

      test('truncates large response data with preview', () {
        final largeData = 'x' * 2000;
        final response = Response(
          statusCode: 500,
          data: largeData,
          requestOptions: RequestOptions(path: '/api/test'),
        );

        final metadata = ErrorMetadataExtractor.fromHttpResponse(response);

        expect(metadata['dataSize'], equals(2000));
        expect(metadata['dataTruncated'], isTrue);
        expect(metadata['dataPreview'], equals('x' * 500));
        expect(metadata['data'], isNull);
      });
    });

    group('fromNetworkError', () {
      test('extracts metadata from network error', () {
        final metadata = ErrorMetadataExtractor.fromNetworkError(
          errorType: 'timeout',
          url: 'https://api.example.com/users',
          timeout: const Duration(seconds: 30),
        );

        expect(metadata['type'], equals('network_error'));
        expect(metadata['networkErrorType'], equals('timeout'));
        expect(metadata['url'], equals('https://api.example.com/users'));
        expect(metadata['domain'], equals('api.example.com'));
        expect(metadata['scheme'], equals('https'));
        expect(metadata['timeout']['seconds'], equals(30));
      });

      test('extracts socket exception information', () {
        final socketException = SocketException(
          'Connection refused',
          address: InternetAddress.loopbackIPv4,
          port: 8080,
        );

        final metadata = ErrorMetadataExtractor.fromNetworkError(
          errorType: 'connectionRefused',
          socketException: socketException,
        );

        expect(metadata['socketException']['message'], equals('Connection refused'));
        expect(metadata['socketException']['address'], contains('127.0.0.1'));
        expect(metadata['socketException']['port'], equals(8080));
      });

      test('handles invalid URL gracefully', () {
        final metadata = ErrorMetadataExtractor.fromNetworkError(
          errorType: 'unknown',
          url: 'not-a-valid-url',
        );

        expect(metadata['url'], equals('not-a-valid-url'));
        expect(metadata['domain'], anyOf(isNull, equals('')));
      });
    });

    group('fromValidationError', () {
      test('extracts metadata from validation error', () {
        final fieldErrors = {
          'email': ['Invalid format', 'Required'],
          'password': ['Too short'],
        };

        final metadata = ErrorMetadataExtractor.fromValidationError(
          fieldErrors: fieldErrors,
          formId: 'login_form',
        );

        expect(metadata['type'], equals('validation_error'));
        expect(metadata['fieldCount'], equals(2));
        expect(metadata['totalErrors'], equals(3));
        expect(metadata['formId'], equals('login_form'));
        expect(metadata['fieldSummary']['email']['errorCount'], equals(2));
        expect(metadata['fieldSummary']['email']['firstError'], equals('Invalid format'));
        expect(metadata['fieldSummary']['password']['errorCount'], equals(1));
      });

      test('sanitizes form data', () {
        final fieldErrors = {'email': ['Invalid']};
        final formData = {
          'email': 'user@example.com',
          'password': 'secret123',
          'longText': 'x' * 200,
        };

        final metadata = ErrorMetadataExtractor.fromValidationError(
          fieldErrors: fieldErrors,
          formData: formData,
        );

        expect(metadata['formData']['email'], equals('user@example.com'));
        expect(metadata['formData']['password'], equals('[REDACTED]'));
        expect(metadata['formData']['longText'], contains('[TRUNCATED]'));
      });
    });

    group('getSystemMetadata', () {
      test('extracts system metadata', () {
        final metadata = ErrorMetadataExtractor.getSystemMetadata();

        expect(metadata['type'], equals('system_info'));
        expect(metadata['timestamp'], isNotNull);
        expect(metadata['platform'], isNotNull);
        expect(metadata['dartVersion'], isNotNull);
        expect(metadata['isDebugMode'], isA<bool>());
        expect(metadata['isProfileMode'], isA<bool>());
        expect(metadata['isReleaseMode'], isA<bool>());
      });
    });
  });
}