import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class for extracting metadata from various error sources
class ErrorMetadataExtractor {
  /// Extracts metadata from a Dio exception
  static Map<String, dynamic> fromDioException(DioException exception) {
    final metadata = <String, dynamic>{
      'type': 'dio_exception',
      'dioType': exception.type.name,
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Request information
    final requestOptions = exception.requestOptions;
    metadata['request'] = {
      'method': requestOptions.method,
      'uri': requestOptions.uri.toString(),
      'path': requestOptions.path,
      'connectTimeout': requestOptions.connectTimeout,
      'receiveTimeout': requestOptions.receiveTimeout,
      'sendTimeout': requestOptions.sendTimeout,
      'headers': _sanitizeHeaders(requestOptions.headers),
    };

    // Response information (if available)
    if (exception.response != null) {
      final response = exception.response!;
      metadata['response'] = {
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
        'headers': _sanitizeHeaders(response.headers.map),
        'contentLength': response.headers.value('content-length'),
        'contentType': response.headers.value('content-type'),
      };

      // Include response data if it's not too large
      if (response.data != null) {
        final dataString = response.data.toString();
        if (dataString.length <= 1000) {
          metadata['response']['data'] = response.data;
        } else {
          metadata['response']['dataSize'] = dataString.length;
          metadata['response']['dataTruncated'] = true;
        }
      }
    }

    // Error-specific information
    if (exception.error != null) {
      metadata['underlyingError'] = _extractUnderlyingErrorInfo(exception.error!);
    }

    return metadata;
  }

  /// Extracts metadata from a generic exception or error
  static Map<String, dynamic> fromException(Object exception) {
    final metadata = <String, dynamic>{
      'type': 'generic_exception',
      'exceptionType': exception.runtimeType.toString(),
      'message': exception.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add specific information based on exception type
    if (exception is FormatException) {
      metadata['formatException'] = {
        'source': exception.source,
        'offset': exception.offset,
      };
    } else if (exception is ArgumentError) {
      metadata['argumentError'] = {
        'invalidValue': exception.invalidValue?.toString(),
        'name': exception.name,
      };
    } else if (exception is StateError) {
      metadata['stateError'] = {
        'message': exception.message,
      };
    } else if (exception is UnsupportedError) {
      metadata['unsupportedError'] = {
        'message': exception.message,
      };
    }

    return metadata;
  }

  /// Extracts metadata from a Flutter error
  static Map<String, dynamic> fromFlutterError(FlutterError error) {
    final metadata = <String, dynamic>{
      'type': 'flutter_error',
      'message': error.message,
      'library': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Stack trace information
    if (error.stackTrace != null) {
      final stackTrace = error.stackTrace.toString();
      metadata['stackTrace'] = {
        'full': stackTrace,
        'lines': stackTrace.split('\n').length,
        'firstLine': stackTrace.split('\n').first,
      };
    }

    // Diagnostics information
    if (error.diagnostics.isNotEmpty) {
      metadata['diagnostics'] = error.diagnostics.map((diagnostic) => {
        'level': diagnostic.level.name,
        'description': diagnostic.toString(),
      }).toList();
    }

    return metadata;
  }

  /// Extracts metadata from platform-specific errors
  static Map<String, dynamic> fromPlatformException(PlatformException exception) {
    return {
      'type': 'platform_exception',
      'code': exception.code,
      'message': exception.message,
      'details': exception.details,
      'stacktrace': exception.stacktrace,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Extracts metadata from HTTP response
  static Map<String, dynamic> fromHttpResponse(Response response) {
    final metadata = <String, dynamic>{
      'type': 'http_response',
      'statusCode': response.statusCode,
      'statusMessage': response.statusMessage,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Headers
    metadata['headers'] = _sanitizeHeaders(response.headers.map);

    // Response data
    if (response.data != null) {
      final dataString = response.data.toString();
      if (dataString.length <= 1000) {
        metadata['data'] = response.data;
      } else {
        metadata['dataSize'] = dataString.length;
        metadata['dataTruncated'] = true;
        // Include first 500 characters for context
        metadata['dataPreview'] = dataString.substring(0, 500);
      }
    }

    // Request information
    final requestOptions = response.requestOptions;
    metadata['request'] = {
      'method': requestOptions.method,
      'uri': requestOptions.uri.toString(),
      'path': requestOptions.path,
    };

    return metadata;
  }

  /// Extracts metadata from network connectivity issues
  static Map<String, dynamic> fromNetworkError({
    required String errorType,
    String? url,
    Duration? timeout,
    SocketException? socketException,
  }) {
    final metadata = <String, dynamic>{
      'type': 'network_error',
      'networkErrorType': errorType,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (url != null) {
      metadata['url'] = url;
      // Extract domain for analysis
      try {
        final uri = Uri.parse(url);
        metadata['domain'] = uri.host;
        metadata['port'] = uri.port;
        metadata['scheme'] = uri.scheme;
      } catch (_) {
        // Invalid URL, keep as is
      }
    }

    if (timeout != null) {
      metadata['timeout'] = {
        'milliseconds': timeout.inMilliseconds,
        'seconds': timeout.inSeconds,
      };
    }

    if (socketException != null) {
      metadata['socketException'] = {
        'message': socketException.message,
        'osError': socketException.osError?.toString(),
        'address': socketException.address?.toString(),
        'port': socketException.port,
      };
    }

    return metadata;
  }

  /// Extracts metadata from validation errors
  static Map<String, dynamic> fromValidationError({
    required Map<String, List<String>> fieldErrors,
    String? formId,
    Map<String, dynamic>? formData,
  }) {
    final metadata = <String, dynamic>{
      'type': 'validation_error',
      'fieldCount': fieldErrors.length,
      'totalErrors': fieldErrors.values.fold<int>(0, (sum, errors) => sum + errors.length),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (formId != null) {
      metadata['formId'] = formId;
    }

    // Field error summary
    metadata['fieldSummary'] = fieldErrors.map((field, errors) => MapEntry(
      field,
      {
        'errorCount': errors.length,
        'firstError': errors.isNotEmpty ? errors.first : null,
      },
    ));

    // Form data (sanitized)
    if (formData != null) {
      metadata['formData'] = _sanitizeFormData(formData);
    }

    return metadata;
  }

  /// Extracts metadata from device/system information
  static Map<String, dynamic> getSystemMetadata() {
    final metadata = <String, dynamic>{
      'type': 'system_info',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Platform information
    if (kIsWeb) {
      metadata['platform'] = 'web';
    } else {
      metadata['platform'] = Platform.operatingSystem;
      metadata['operatingSystemVersion'] = Platform.operatingSystemVersion;
    }

    // Flutter/Dart information
    metadata['dartVersion'] = Platform.version;
    metadata['isDebugMode'] = kDebugMode;
    metadata['isProfileMode'] = kProfileMode;
    metadata['isReleaseMode'] = kReleaseMode;

    return metadata;
  }

  // Private helper methods

  static Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    
    headers.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (_isSensitiveHeader(lowerKey)) {
        sanitized[key] = '[REDACTED]';
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  static bool _isSensitiveHeader(String headerName) {
    const sensitiveHeaders = {
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'x-auth-token',
      'bearer',
      'authentication',
    };
    
    return sensitiveHeaders.any((sensitive) => headerName.contains(sensitive));
  }

  static Map<String, dynamic> _extractUnderlyingErrorInfo(Object error) {
    final info = <String, dynamic>{
      'type': error.runtimeType.toString(),
      'message': error.toString(),
    };

    if (error is SocketException) {
      info['socketException'] = {
        'message': error.message,
        'osError': error.osError?.toString(),
        'address': error.address?.toString(),
        'port': error.port,
      };
    } else if (error is HttpException) {
      info['httpException'] = {
        'message': error.message,
        'uri': error.uri?.toString(),
      };
    } else if (error is FormatException) {
      info['formatException'] = {
        'source': error.source,
        'offset': error.offset,
      };
    }

    return info;
  }

  static Map<String, dynamic> _sanitizeFormData(Map<String, dynamic> formData) {
    final sanitized = <String, dynamic>{};
    
    formData.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (_isSensitiveFormField(lowerKey)) {
        sanitized[key] = '[REDACTED]';
      } else if (value is String && value.length > 100) {
        // Truncate long strings
        sanitized[key] = '${value.substring(0, 100)}... [TRUNCATED]';
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  static bool _isSensitiveFormField(String fieldName) {
    const sensitiveFields = {
      'password',
      'token',
      'secret',
      'key',
      'credential',
      'ssn',
      'social',
      'credit',
      'card',
      'cvv',
      'pin',
    };
    
    return sensitiveFields.any((sensitive) => fieldName.contains(sensitive));
  }
}