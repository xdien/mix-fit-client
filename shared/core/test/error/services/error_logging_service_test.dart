import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/models/api_error.dart';
import '../../../lib/error/models/client_error.dart';
import '../../../lib/error/models/error_severity.dart';
import '../../../lib/error/models/error_type.dart';
import '../../../lib/error/models/network_error.dart';
import '../../../lib/error/services/error_logging_service.dart';

void main() {
  group('ErrorLoggingService', () {
    late ErrorLoggingService loggingService;

    setUp(() {
      loggingService = ErrorLoggingService(
        enableConsoleLogging: false, // Disable for tests
        enableDeveloperLogging: false,
        enableFileLogging: false,
      );
    });

    group('logError', () {
      test('logs error and adds to history', () {
        final error = ApiError(
          message: 'Test API error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        loggingService.logError(error, context: 'test_context');

        final history = loggingService.getErrorHistory();
        expect(history.length, equals(1));
        
        final logEntry = history.first as ErrorLogEntry;
        expect(logEntry.error, equals(error));
        expect(logEntry.context, equals('test_context'));
        expect(logEntry.severity, equals(ErrorSeverity.critical));
      });

      test('respects minimum log level', () {
        final service = ErrorLoggingService(
          minimumLogLevel: ErrorSeverity.error,
          enableConsoleLogging: false,
          enableDeveloperLogging: false,
          enableFileLogging: false,
        );

        final infoError = NetworkError(
          message: 'Info level error',
          networkType: NetworkErrorType.cancelled, // Info severity
        );

        final errorError = ApiError(
          message: 'Error level error',
          statusCode: 404,
          endpoint: '/api/test',
          method: 'GET',
        );

        service.logError(infoError);
        service.logError(errorError);

        final history = service.getErrorHistory();
        expect(history.length, equals(1));
        expect((history.first as ErrorLogEntry).error, equals(errorError));
      });

      test('includes additional data in log entry', () {
        final error = ClientError(
          message: 'Test client error',
          stackTrace: 'stack trace here',
        );

        final additionalData = {
          'userId': '123',
          'action': 'button_click',
        };

        loggingService.logError(error, additionalData: additionalData);

        final history = loggingService.getErrorHistory();
        final logEntry = history.first as ErrorLogEntry;
        expect(logEntry.additionalData, equals(additionalData));
      });
    });

    group('logException', () {
      test('logs exception with stack trace', () {
        final exception = Exception('Test exception');
        final stackTrace = StackTrace.current;

        loggingService.logException(
          exception,
          stackTrace,
          context: 'exception_context',
          severity: ErrorSeverity.critical,
        );

        final history = loggingService.getErrorHistory();
        expect(history.length, equals(1));
        
        final logEntry = history.first as ExceptionLogEntry;
        expect(logEntry.exception, equals(exception));
        expect(logEntry.stackTrace, equals(stackTrace));
        expect(logEntry.context, equals('exception_context'));
        expect(logEntry.severity, equals(ErrorSeverity.critical));
      });

      test('uses default severity for exceptions', () {
        final exception = Exception('Test exception');
        final stackTrace = StackTrace.current;

        loggingService.logException(exception, stackTrace);

        final history = loggingService.getErrorHistory();
        final logEntry = history.first as ExceptionLogEntry;
        expect(logEntry.severity, equals(ErrorSeverity.error));
      });
    });

    group('logDebug', () {
      test('logs debug message', () {
        loggingService.logDebug(
          'Debug message',
          context: 'debug_context',
          data: {'key': 'value'},
        );

        final history = loggingService.getErrorHistory();
        expect(history.length, equals(1));
        
        final logEntry = history.first as DebugLogEntry;
        expect(logEntry.message, equals('Debug message'));
        expect(logEntry.context, equals('debug_context'));
        expect(logEntry.severity, equals(ErrorSeverity.info));
        expect(logEntry.data, equals({'key': 'value'}));
      });
    });

    group('logWarning', () {
      test('logs warning message', () {
        loggingService.logWarning(
          'Warning message',
          context: 'warning_context',
          data: {'warning': 'data'},
        );

        final history = loggingService.getErrorHistory();
        expect(history.length, equals(1));
        
        final logEntry = history.first as WarningLogEntry;
        expect(logEntry.message, equals('Warning message'));
        expect(logEntry.context, equals('warning_context'));
        expect(logEntry.severity, equals(ErrorSeverity.warning));
        expect(logEntry.data, equals({'warning': 'data'}));
      });
    });

    group('getErrorHistory', () {
      setUp(() {
        // Add various log entries
        loggingService.logError(ApiError(
          message: 'API error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        ));
        
        loggingService.logException(
          Exception('Test exception'),
          StackTrace.current,
          severity: ErrorSeverity.warning,
        );
        
        loggingService.logDebug('Debug message');
        loggingService.logWarning('Warning message');
      });

      test('returns all entries by default', () {
        final history = loggingService.getErrorHistory();
        expect(history.length, equals(4));
      });

      test('filters by minimum severity', () {
        final history = loggingService.getErrorHistory(
          minimumSeverity: ErrorSeverity.warning,
        );
        expect(history.length, equals(3)); // Excludes debug (info level)
      });

      test('filters by error type', () {
        final history = loggingService.getErrorHistory(
          errorType: ErrorType.api,
        );
        expect(history.length, equals(1));
        expect(history.first, isA<ErrorLogEntry>());
        expect((history.first as ErrorLogEntry).error.type, equals(ErrorType.api));
      });

      test('filters by time', () {
        final now = DateTime.now();
        final future = now.add(const Duration(minutes: 1));
        
        final history = loggingService.getErrorHistory(since: future);
        expect(history.isEmpty, isTrue);
      });

      test('limits results', () {
        final history = loggingService.getErrorHistory(limit: 2);
        expect(history.length, equals(2));
      });

      test('sorts by timestamp (newest first)', () {
        final history = loggingService.getErrorHistory();
        expect(history.length, greaterThan(1));
        
        for (int i = 0; i < history.length - 1; i++) {
          expect(
            history[i].timestamp.isAfter(history[i + 1].timestamp) ||
            history[i].timestamp.isAtSameMomentAs(history[i + 1].timestamp),
            isTrue,
          );
        }
      });
    });

    group('getErrorStatistics', () {
      setUp(() {
        // Add various log entries
        loggingService.logError(ApiError(
          message: 'API error 1',
          statusCode: 500,
          endpoint: '/api/test1',
          method: 'GET',
        ));
        
        loggingService.logError(ApiError(
          message: 'API error 2',
          statusCode: 404,
          endpoint: '/api/test2',
          method: 'GET',
        ));
        
        loggingService.logError(NetworkError(
          message: 'Network error',
          networkType: NetworkErrorType.timeout,
        ));
        
        loggingService.logException(
          Exception('Test exception'),
          StackTrace.current,
          severity: ErrorSeverity.error,
        );
        
        loggingService.logDebug('Debug message');
        loggingService.logWarning('Warning message');
      });

      test('calculates correct statistics', () {
        final stats = loggingService.getErrorStatistics();
        
        expect(stats.totalEntries, equals(6));
        expect(stats.errorsByType[ErrorType.api], equals(2));
        expect(stats.errorsByType[ErrorType.network], equals(1));
        expect(stats.errorsBySeverity[ErrorSeverity.critical], equals(1)); // 500 error
        expect(stats.errorsBySeverity[ErrorSeverity.error], equals(2)); // 404 error + exception
        expect(stats.errorsBySeverity[ErrorSeverity.warning], equals(2)); // network error + warning
        expect(stats.errorsBySeverity[ErrorSeverity.info], equals(1)); // debug message
        expect(stats.exceptionsCount, equals(1));
        expect(stats.debugMessagesCount, equals(1));
        expect(stats.warningMessagesCount, equals(1));
        expect(stats.oldestEntry, isNotNull);
        expect(stats.newestEntry, isNotNull);
      });

      test('filters statistics by time', () {
        final future = DateTime.now().add(const Duration(minutes: 1));
        final stats = loggingService.getErrorStatistics(since: future);
        
        expect(stats.totalEntries, equals(0));
        expect(stats.errorsByType.isEmpty, isTrue);
        expect(stats.errorsBySeverity.isEmpty, isTrue);
        expect(stats.exceptionsCount, equals(0));
        expect(stats.debugMessagesCount, equals(0));
        expect(stats.warningMessagesCount, equals(0));
        expect(stats.oldestEntry, isNull);
        expect(stats.newestEntry, isNull);
      });
    });

    group('generateDebugReport', () {
      setUp(() {
        loggingService.logError(ApiError(
          message: 'Test API error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        ));
        
        loggingService.logException(
          Exception('Test exception'),
          StackTrace.current,
        );
      });

      test('generates complete debug report', () {
        final report = loggingService.generateDebugReport();
        
        expect(report, contains('ERROR SYSTEM DEBUG REPORT'));
        expect(report, contains('SYSTEM INFORMATION'));
        expect(report, contains('ERROR STATISTICS'));
        expect(report, contains('ERROR HISTORY'));
        expect(report, contains('Test API error'));
        expect(report, contains('Test exception'));
      });

      test('generates report with specific sections', () {
        final report = loggingService.generateDebugReport(
          includeHistory: false,
          includeSystemInfo: false,
        );
        
        expect(report, contains('ERROR STATISTICS'));
        expect(report, isNot(contains('SYSTEM INFORMATION')));
        expect(report, isNot(contains('ERROR HISTORY')));
      });
    });

    group('clearHistory', () {
      test('clears all log entries', () {
        loggingService.logDebug('Test message');
        loggingService.logWarning('Test warning');
        
        expect(loggingService.getErrorHistory().length, equals(2));
        
        loggingService.clearHistory();
        
        expect(loggingService.getErrorHistory().isEmpty, isTrue);
      });
    });

    group('exportHistoryAsJson', () {
      setUp(() {
        loggingService.logError(ApiError(
          message: 'Test API error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        ));
        
        loggingService.logDebug('Debug message', data: {'key': 'value'});
      });

      test('exports history as valid JSON', () {
        final json = loggingService.exportHistoryAsJson();
        
        expect(json, isA<String>());
        expect(() => jsonDecode(json), returnsNormally);
        
        final decoded = jsonDecode(json) as List;
        expect(decoded.length, equals(2));
        
        final errorEntry = decoded.firstWhere((entry) => entry['type'] == 'error');
        expect(errorEntry['message'], equals('Test API error'));
        expect(errorEntry['errorType'], equals('api'));
        
        final debugEntry = decoded.firstWhere((entry) => entry['type'] == 'debug');
        expect(debugEntry['message'], equals('Debug message'));
      });

      test('sanitizes sensitive data by default', () {
        loggingService.logError(ApiError(
          message: 'API error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          requestData: {'password': 'secret123'},
        ));
        
        final json = loggingService.exportHistoryAsJson();
        expect(json, contains('[REDACTED]'));
      });

      test('includes sensitive data when sanitize is false', () {
        loggingService.logError(ApiError(
          message: 'API error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          requestData: {'password': 'secret123'},
        ));
        
        final json = loggingService.exportHistoryAsJson(sanitize: false);
        expect(json, contains('secret123'));
      });
    });

    group('history size management', () {
      test('maintains maximum history size', () {
        final service = ErrorLoggingService(
          enableConsoleLogging: false,
          enableDeveloperLogging: false,
          enableFileLogging: false,
        );
        
        // Add more than 50 entries (the maximum)
        for (int i = 0; i < 60; i++) {
          service.logDebug('Debug message $i');
        }
        
        final history = service.getErrorHistory();
        expect(history.length, equals(50));
        
        // Check that the oldest entries were removed
        expect(history.last.message, equals('Debug message 10'));
        expect(history.first.message, equals('Debug message 59'));
      });
    });

    group('log entry types', () {
      test('ErrorLogEntry formats correctly', () {
        final error = ApiError(
          message: 'Test error',
          statusCode: 404,
          endpoint: '/api/test',
          method: 'GET',
        );
        
        final entry = ErrorLogEntry(
          error: error,
          context: 'test_context',
          timestamp: DateTime.now(),
        );
        
        expect(entry.toLogString(), contains('API: Test error'));
        expect(entry.toLogString(), contains('[Context: test_context]'));
        
        final detailed = entry.toDetailedString();
        expect(detailed, contains('Type: api'));
        expect(detailed, contains('Message: Test error'));
        expect(detailed, contains('Context: test_context'));
        
        final json = entry.toJson();
        expect(json['type'], equals('error'));
        expect(json['errorType'], equals('api'));
        expect(json['message'], equals('Test error'));
        expect(json['context'], equals('test_context'));
      });

      test('ExceptionLogEntry formats correctly', () {
        final exception = Exception('Test exception');
        final stackTrace = StackTrace.current;
        
        final entry = ExceptionLogEntry(
          exception: exception,
          stackTrace: stackTrace,
          context: 'exception_context',
          severity: ErrorSeverity.critical,
          timestamp: DateTime.now(),
        );
        
        expect(entry.toLogString(), contains('EXCEPTION: Exception: Test exception'));
        expect(entry.toLogString(), contains('[Context: exception_context]'));
        
        final detailed = entry.toDetailedString();
        expect(detailed, contains('EXCEPTION (CRITICAL)'));
        expect(detailed, contains('Exception: Exception: Test exception'));
        expect(detailed, contains('Stack Trace:'));
        
        final json = entry.toJson();
        expect(json['type'], equals('exception'));
        expect(json['severity'], equals('critical'));
        expect(json['exception'], equals('Exception: Test exception'));
      });

      test('DebugLogEntry formats correctly', () {
        final entry = DebugLogEntry(
          message: 'Debug message',
          context: 'debug_context',
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );
        
        expect(entry.toLogString(), contains('DEBUG: Debug message'));
        expect(entry.toLogString(), contains('[Context: debug_context]'));
        
        final detailed = entry.toDetailedString();
        expect(detailed, contains('DEBUG'));
        expect(detailed, contains('Message: Debug message'));
        expect(detailed, contains('Data:'));
        expect(detailed, contains('key: value'));
        
        final json = entry.toJson(sanitize: false);
        expect(json['type'], equals('debug'));
        expect(json['message'], equals('Debug message'));
        expect(json['data'], equals({'key': 'value'}));
      });

      test('WarningLogEntry formats correctly', () {
        final entry = WarningLogEntry(
          message: 'Warning message',
          context: 'warning_context',
          data: {'warning': 'data'},
          timestamp: DateTime.now(),
        );
        
        expect(entry.toLogString(), contains('WARNING: Warning message'));
        expect(entry.toLogString(), contains('[Context: warning_context]'));
        
        final detailed = entry.toDetailedString();
        expect(detailed, contains('WARNING'));
        expect(detailed, contains('Message: Warning message'));
        expect(detailed, contains('Data:'));
        expect(detailed, contains('warning: data'));
        
        final json = entry.toJson(sanitize: false);
        expect(json['type'], equals('warning'));
        expect(json['message'], equals('Warning message'));
        expect(json['data'], equals({'warning': 'data'}));
      });
    });
  });
}