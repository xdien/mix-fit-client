import 'dart:convert';

import '../models/api_error.dart';
import '../models/app_error.dart';
import '../models/client_error.dart';
import '../models/error_severity.dart';
import '../models/error_type.dart';
import '../models/network_error.dart';
import '../models/validation_error.dart';

/// Utility functions for error handling and formatting
class ErrorUtils {
  /// Formats an error message for display to users
  static String formatErrorMessage(AppError error, {bool includeDetails = false}) {
    final buffer = StringBuffer();
    
    // Add main message
    buffer.write(error.message);
    
    if (includeDetails && error.metadata != null) {
      final metadata = error.metadata!;
      
      // Add status code for API errors
      if (metadata.containsKey('statusCode')) {
        buffer.write(' (Status: ${metadata['statusCode']})');
      }
      
      // Add network type for network errors
      if (metadata.containsKey('networkType')) {
        buffer.write(' (${_formatNetworkType(metadata['networkType'])})');
      }
      
      // Add field count for validation errors
      if (metadata.containsKey('errorCount')) {
        final count = metadata['errorCount'] as int;
        if (count > 1) {
          buffer.write(' ($count fields affected)');
        }
      }
    }
    
    return buffer.toString();
  }

  /// Formats error message for technical logs
  static String formatErrorForLogging(AppError error) {
    final buffer = StringBuffer();
    
    buffer.writeln('Error ID: ${error.id}');
    buffer.writeln('Type: ${error.type.name}');
    buffer.writeln('Severity: ${error.severity.name}');
    buffer.writeln('Message: ${error.message}');
    buffer.writeln('Timestamp: ${error.timestamp.toIso8601String()}');
    
    if (error.metadata != null && error.metadata!.isNotEmpty) {
      buffer.writeln('Metadata:');
      error.metadata!.forEach((key, value) {
        if (!_isSensitiveField(key)) {
          buffer.writeln('  $key: ${_formatMetadataValue(value)}');
        } else {
          buffer.writeln('  $key: [REDACTED]');
        }
      });
    }
    
    return buffer.toString();
  }

  /// Calculates error severity based on multiple factors
  static ErrorSeverity calculateSeverity({
    required ErrorType type,
    int? statusCode,
    String? networkType,
    int? fieldErrorCount,
    bool hasStackTrace = false,
  }) {
    // Base severity from type
    ErrorSeverity baseSeverity = _getBaseSeverityForType(type);
    
    // Adjust based on specific conditions
    switch (type) {
      case ErrorType.api:
        if (statusCode != null) {
          if (statusCode >= 500) {
            return ErrorSeverity.critical;
          } else if (statusCode == 401 || statusCode == 403) {
            return ErrorSeverity.error;
          } else if (statusCode >= 400) {
            return ErrorSeverity.warning;
          }
        }
        break;
        
      case ErrorType.network:
        if (networkType == 'noConnection') {
          return ErrorSeverity.error;
        } else if (networkType == 'timeout' || networkType == 'poorQuality') {
          return ErrorSeverity.warning;
        }
        break;
        
      case ErrorType.validation:
        if (fieldErrorCount != null && fieldErrorCount > 5) {
          return ErrorSeverity.error;
        }
        break;
        
      case ErrorType.client:
        if (hasStackTrace) {
          return ErrorSeverity.error;
        }
        break;
        
      default:
        break;
    }
    
    return baseSeverity;
  }

  /// Extracts metadata from various error sources
  static Map<String, dynamic> extractMetadata(dynamic source) {
    final metadata = <String, dynamic>{};
    
    if (source == null) return metadata;
    
    try {
      if (source is Map<String, dynamic>) {
        return Map<String, dynamic>.from(source);
      } else if (source is String) {
        // Try to parse as JSON
        try {
          final parsed = jsonDecode(source);
          if (parsed is Map<String, dynamic>) {
            return parsed;
          }
        } catch (_) {
          // Not JSON, treat as plain text
          metadata['raw'] = source;
        }
      } else {
        // Convert to string representation
        metadata['raw'] = source.toString();
      }
    } catch (e) {
      metadata['extraction_error'] = e.toString();
    }
    
    return metadata;
  }

  /// Sanitizes error data by removing sensitive information
  static Map<String, dynamic> sanitizeErrorData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (_isSensitiveField(key)) {
        sanitized[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = sanitizeErrorData(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return sanitizeErrorData(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  /// Generates a user-friendly error summary
  static String generateErrorSummary(List<AppError> errors) {
    if (errors.isEmpty) return 'No errors';
    
    if (errors.length == 1) {
      return formatErrorMessage(errors.first);
    }
    
    final errorsByType = <ErrorType, int>{};
    final errorsBySeverity = <ErrorSeverity, int>{};
    
    for (final error in errors) {
      errorsByType[error.type] = (errorsByType[error.type] ?? 0) + 1;
      errorsBySeverity[error.severity] = (errorsBySeverity[error.severity] ?? 0) + 1;
    }
    
    final buffer = StringBuffer();
    buffer.write('${errors.length} errors: ');
    
    final typeEntries = errorsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final typeDescriptions = typeEntries.map((entry) {
      final count = entry.value;
      final type = entry.key.name;
      return count == 1 ? '1 $type' : '$count ${type}s';
    }).take(2);
    
    buffer.write(typeDescriptions.join(', '));
    
    final criticalCount = errorsBySeverity[ErrorSeverity.critical] ?? 0;
    if (criticalCount > 0) {
      buffer.write(' ($criticalCount critical)');
    }
    
    return buffer.toString();
  }

  /// Determines if two errors should be consolidated
  static bool shouldConsolidateErrors(AppError error1, AppError error2) {
    // Same type and severity
    if (error1.type != error2.type || error1.severity != error2.severity) {
      return false;
    }
    
    // Check type-specific consolidation rules
    switch (error1.type) {
      case ErrorType.api:
        return _shouldConsolidateApiErrors(error1, error2);
      case ErrorType.network:
        return _shouldConsolidateNetworkErrors(error1, error2);
      case ErrorType.validation:
        return _shouldConsolidateValidationErrors(error1, error2);
      default:
        return error1.message == error2.message;
    }
  }

  /// Creates a consolidated error from multiple similar errors
  static AppError consolidateErrors(List<AppError> errors) {
    if (errors.isEmpty) throw ArgumentError('Cannot consolidate empty error list');
    if (errors.length == 1) return errors.first;
    
    final firstError = errors.first;
    final consolidatedMetadata = <String, dynamic>{
      ...firstError.metadata ?? {},
      'consolidated': true,
      'originalCount': errors.length,
      'consolidatedAt': DateTime.now().toIso8601String(),
    };
    
    // Create consolidated message
    final message = errors.length == 2
        ? '${firstError.message} (and 1 similar error)'
        : '${firstError.message} (and ${errors.length - 1} similar errors)';
    
    // Create a new error with the consolidated metadata
    if (firstError is ApiError) {
      return ApiError.withMetadata(
        id: firstError.id,
        message: message,
        statusCode: firstError.statusCode,
        endpoint: firstError.endpoint,
        method: firstError.method,
        timestamp: firstError.timestamp,
        requestData: firstError.requestData,
        responseData: firstError.responseData,
        actions: firstError.actions,
        metadata: consolidatedMetadata,
      );
    } else if (firstError is NetworkError) {
      return NetworkError.withMetadata(
        id: firstError.id,
        message: message,
        networkType: firstError.networkType,
        timeout: firstError.timeout,
        url: firstError.url,
        timestamp: firstError.timestamp,
        actions: firstError.actions,
        metadata: consolidatedMetadata,
      );
    } else if (firstError is ValidationError) {
      return ValidationError.withMetadata(
        id: firstError.id,
        message: message,
        fieldErrors: firstError.fieldErrors,
        formId: firstError.formId,
        timestamp: firstError.timestamp,
        actions: firstError.actions,
        metadata: consolidatedMetadata,
      );
    } else if (firstError is ClientError) {
      return ClientError.withMetadata(
        id: firstError.id,
        message: message,
        stackTrace: firstError.stackTrace,
        componentName: firstError.componentName,
        context: firstError.context,
        timestamp: firstError.timestamp,
        actions: firstError.actions,
        metadata: consolidatedMetadata,
      );
    } else {
      // Fallback to copyWith for unknown types
      return firstError.copyWith(
        message: message,
        metadata: consolidatedMetadata,
      );
    }
  }

  // Private helper methods

  static ErrorSeverity _getBaseSeverityForType(ErrorType type) {
    switch (type) {
      case ErrorType.api:
        return ErrorSeverity.error;
      case ErrorType.network:
        return ErrorSeverity.warning;
      case ErrorType.validation:
        return ErrorSeverity.warning;
      case ErrorType.authentication:
        return ErrorSeverity.error;
      case ErrorType.authorization:
        return ErrorSeverity.error;
      case ErrorType.client:
        return ErrorSeverity.error;
      case ErrorType.server:
        return ErrorSeverity.critical;
      case ErrorType.offline:
        return ErrorSeverity.info;
    }
  }

  static String _formatNetworkType(String networkType) {
    switch (networkType) {
      case 'noConnection':
        return 'No Connection';
      case 'timeout':
        return 'Timeout';
      case 'dnsFailure':
        return 'DNS Failure';
      case 'connectionRefused':
        return 'Connection Refused';
      case 'certificateError':
        return 'Certificate Error';
      case 'poorQuality':
        return 'Poor Quality';
      default:
        return networkType;
    }
  }

  static String _formatMetadataValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is List || value is Map) {
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  static bool _isSensitiveField(String fieldName) {
    const sensitiveFields = {
      'password',
      'token',
      'authorization',
      'cookie',
      'session',
      'secret',
      'key',
      'credential',
      'auth',
      'bearer',
      'requestdata',
      'responsedata',
    };
    
    final lowerField = fieldName.toLowerCase();
    return sensitiveFields.any((sensitive) => lowerField.contains(sensitive));
  }

  static bool _shouldConsolidateApiErrors(AppError error1, AppError error2) {
    final meta1 = error1.metadata ?? {};
    final meta2 = error2.metadata ?? {};
    
    // Same status code and endpoint
    return meta1['statusCode'] == meta2['statusCode'] &&
           meta1['endpoint'] == meta2['endpoint'];
  }

  static bool _shouldConsolidateNetworkErrors(AppError error1, AppError error2) {
    final meta1 = error1.metadata ?? {};
    final meta2 = error2.metadata ?? {};
    
    // Same network type
    return meta1['networkType'] == meta2['networkType'];
  }

  static bool _shouldConsolidateValidationErrors(AppError error1, AppError error2) {
    final meta1 = error1.metadata ?? {};
    final meta2 = error2.metadata ?? {};
    
    // Same form ID
    return meta1['formId'] == meta2['formId'];
  }
}