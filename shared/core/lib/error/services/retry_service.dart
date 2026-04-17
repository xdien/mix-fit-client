import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

/// Service for handling request retries
class RetryService {
  final Dio _dio;

  RetryService({Dio? dio}) : _dio = dio ?? GetIt.instance<Dio>();

  /// Retries a failed request with the original options
  Future<Response?> retryRequest(RequestOptions options) async {
    try {
      final response = await _dio.request(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: Options(
          method: options.method,
          headers: options.headers,
          contentType: options.contentType,
          responseType: options.responseType,
          validateStatus: options.validateStatus,
          receiveDataWhenStatusError: options.receiveDataWhenStatusError,
          followRedirects: options.followRedirects,
          maxRedirects: options.maxRedirects,
          extra: options.extra,
        ),
      );
      return response;
    } catch (e) {
      // If retry fails, return null - the error will be handled by the interceptor
      return null;
    }
  }

  /// Retries a request with custom modifications
  Future<Response?> retryRequestWithModifications(
    RequestOptions options, {
    Map<String, dynamic>? additionalHeaders,
    Map<String, dynamic>? additionalQueryParams,
    Duration? delay,
  }) async {
    if (delay != null) {
      await Future.delayed(delay);
    }

    try {
      final headers = Map<String, dynamic>.from(options.headers);
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      final queryParams = Map<String, dynamic>.from(options.queryParameters);
      if (additionalQueryParams != null) {
        queryParams.addAll(additionalQueryParams);
      }

      final response = await _dio.request(
        options.path,
        data: options.data,
        queryParameters: queryParams,
        options: Options(
          method: options.method,
          headers: headers,
          contentType: options.contentType,
          responseType: options.responseType,
          validateStatus: options.validateStatus,
          receiveDataWhenStatusError: options.receiveDataWhenStatusError,
          followRedirects: options.followRedirects,
          maxRedirects: options.maxRedirects,
          extra: options.extra,
        ),
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Checks if a request is retryable based on the error
  bool isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return [408, 429, 500, 502, 503, 504].contains(statusCode);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return false;
    }
  }
}