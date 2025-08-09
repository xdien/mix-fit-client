import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/app_error.dart';
import '../models/error_severity.dart';
import '../models/error_type.dart';
import '../utils/error_utils.dart';

/// Service for logging and debugging errors
class ErrorLoggingService {
  static const int _maxHistorySize = 50;
  static const String _logTag = 'ErrorSystem';

  final List<LogEntry> _errorHistory = [];
  final bool _enableConsoleLogging;
  final bool _enableDeveloperLogging;
  final bool _enableFileLogging;
  final ErrorSeverity _minimumLogLevel;

  ErrorLoggingService({
    bool enableConsoleLogging = true,
    bool enableDeveloperLogging = true,
    bool enableFileLogging = false,
    ErrorSeverity minimumLogLevel = ErrorSeverity.info,
  })  : _enableConsoleLogging = enableConsoleLogging,
        _enableDeveloperLogging = enableDeveloperLogging,
        _enableFileLogging = enableFileLogging,
        _minimumLogLevel = minimumLogLevel;

  /// Logs an error with full details
  void logError(AppError error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_shouldLog(error.severity)) return;

    final logEntry = ErrorLogEntry(
      error: error,
      context: context,
      additionalData: additionalData,
      timestamp: DateTime.now(),
    );

    _addToHistory(logEntry);
    _writeToLogs(logEntry);
  }

  /// Logs an exception with context
  void logException(
    Object exception,
    StackTrace stackTrace, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_shouldLog(severity)) return;

    final logEntry = ExceptionLogEntry(
      exception: exception,
      stackTrace: stackTrace,
      context: context,
      severity: severity,
      additionalData: additionalData,
      timestamp: DateTime.now(),
    );

    _addToHistory(logEntry);
    _writeToLogs(logEntry);
  }

  /// Logs a debug message
  void logDebug(
    String message, {
    String? context,
    Map<String, dynamic>? data,
  }) {
    if (!_shouldLog(ErrorSeverity.info)) return;

    final logEntry = DebugLogEntry(
      message: message,
      context: context,
      data: data,
      timestamp: DateTime.now(),
    );

    _addToHistory(logEntry);
    _writeToLogs(logEntry);
  }

  /// Logs a warning message
  void logWarning(
    String message, {
    String? context,
    Map<String, dynamic>? data,
  }) {
    if (!_shouldLog(ErrorSeverity.warning)) return;

    final logEntry = WarningLogEntry(
      message: message,
      context: context,
      data: data,
      timestamp: DateTime.now(),
    );

    _addToHistory(logEntry);
    _writeToLogs(logEntry);
  }

  /// Gets the error history
  List<LogEntry> getErrorHistory({
    ErrorSeverity? minimumSeverity,
    ErrorType? errorType,
    DateTime? since,
    int? limit,
  }) {
    var filtered = _errorHistory.where((entry) {
      if (minimumSeverity != null && entry.severity.priority < minimumSeverity.priority) {
        return false;
      }
      
      if (errorType != null) {
        if (entry is ErrorLogEntry && entry.error.type != errorType) {
          return false;
        } else if (entry is! ErrorLogEntry) {
          return false; // Non-error entries don't match error type filter
        }
      }
      
      if (since != null && entry.timestamp.isBefore(since)) {
        return false;
      }
      
      return true;
    }).toList();

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  /// Gets error statistics
  ErrorStatistics getErrorStatistics({
    DateTime? since,
  }) {
    final relevantEntries = _errorHistory.where((entry) {
      return since == null || entry.timestamp.isAfter(since);
    }).toList();

    final errorsByType = <ErrorType, int>{};
    final errorsBySeverity = <ErrorSeverity, int>{};
    final exceptionsCount = relevantEntries.whereType<ExceptionLogEntry>().length;
    final debugMessagesCount = relevantEntries.whereType<DebugLogEntry>().length;
    final warningMessagesCount = relevantEntries.whereType<WarningLogEntry>().length;

    for (final entry in relevantEntries) {
      if (entry is ErrorLogEntry) {
        final type = entry.error.type;
        errorsByType[type] = (errorsByType[type] ?? 0) + 1;
      }
      
      final severity = entry.severity;
      errorsBySeverity[severity] = (errorsBySeverity[severity] ?? 0) + 1;
    }

    return ErrorStatistics(
      totalEntries: relevantEntries.length,
      errorsByType: errorsByType,
      errorsBySeverity: errorsBySeverity,
      exceptionsCount: exceptionsCount,
      debugMessagesCount: debugMessagesCount,
      warningMessagesCount: warningMessagesCount,
      oldestEntry: relevantEntries.isEmpty ? null : relevantEntries.last.timestamp,
      newestEntry: relevantEntries.isEmpty ? null : relevantEntries.first.timestamp,
    );
  }

  /// Generates a debug report
  String generateDebugReport({
    bool includeHistory = true,
    bool includeStatistics = true,
    bool includeSystemInfo = true,
    DateTime? since,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== ERROR SYSTEM DEBUG REPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    if (includeSystemInfo) {
      buffer.writeln('=== SYSTEM INFORMATION ===');
      buffer.writeln('Debug Mode: ${kDebugMode}');
      buffer.writeln('Profile Mode: ${kProfileMode}');
      buffer.writeln('Release Mode: ${kReleaseMode}');
      buffer.writeln('Platform: ${defaultTargetPlatform.name}');
      buffer.writeln();
    }

    if (includeStatistics) {
      buffer.writeln('=== ERROR STATISTICS ===');
      final stats = getErrorStatistics(since: since);
      buffer.writeln('Total Entries: ${stats.totalEntries}');
      buffer.writeln('Exceptions: ${stats.exceptionsCount}');
      buffer.writeln('Debug Messages: ${stats.debugMessagesCount}');
      buffer.writeln('Warning Messages: ${stats.warningMessagesCount}');
      
      if (stats.oldestEntry != null && stats.newestEntry != null) {
        buffer.writeln('Time Range: ${stats.oldestEntry!.toIso8601String()} - ${stats.newestEntry!.toIso8601String()}');
      }
      
      buffer.writeln();
      
      if (stats.errorsByType.isNotEmpty) {
        buffer.writeln('Errors by Type:');
        stats.errorsByType.entries.forEach((entry) {
          buffer.writeln('  ${entry.key.name}: ${entry.value}');
        });
        buffer.writeln();
      }
      
      if (stats.errorsBySeverity.isNotEmpty) {
        buffer.writeln('Errors by Severity:');
        stats.errorsBySeverity.entries.forEach((entry) {
          buffer.writeln('  ${entry.key.name}: ${entry.value}');
        });
        buffer.writeln();
      }
    }

    if (includeHistory) {
      buffer.writeln('=== ERROR HISTORY ===');
      final history = getErrorHistory(since: since);
      
      if (history.isEmpty) {
        buffer.writeln('No errors in history');
      } else {
        for (final entry in history) {
          buffer.writeln(entry.toDetailedString());
          buffer.writeln('---');
        }
      }
    }

    return buffer.toString();
  }

  /// Clears the error history
  void clearHistory() {
    _errorHistory.clear();
  }

  /// Exports error history as JSON
  String exportHistoryAsJson({
    DateTime? since,
    bool sanitize = true,
  }) {
    final history = getErrorHistory(since: since);
    final jsonData = history.map((entry) => entry.toJson(sanitize: sanitize)).toList();
    return jsonEncode(jsonData);
  }

  // Private methods

  bool _shouldLog(ErrorSeverity severity) {
    return severity.priority >= _minimumLogLevel.priority;
  }

  void _addToHistory(LogEntry entry) {
    _errorHistory.add(entry);
    
    // Maintain maximum history size
    while (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  void _writeToLogs(LogEntry entry) {
    final logMessage = entry.toLogString();
    
    if (_enableConsoleLogging) {
      _writeToConsole(entry.severity, logMessage);
    }
    
    if (_enableDeveloperLogging) {
      _writeToDeveloperLog(entry.severity, logMessage);
    }
    
    if (_enableFileLogging) {
      _writeToFile(entry.severity, logMessage);
    }
  }

  void _writeToConsole(ErrorSeverity severity, String message) {
    switch (severity) {
      case ErrorSeverity.info:
        debugPrint('[$_logTag] INFO: $message');
        break;
      case ErrorSeverity.warning:
        debugPrint('[$_logTag] WARNING: $message');
        break;
      case ErrorSeverity.error:
        debugPrint('[$_logTag] ERROR: $message');
        break;
      case ErrorSeverity.critical:
        debugPrint('[$_logTag] CRITICAL: $message');
        break;
    }
  }

  void _writeToDeveloperLog(ErrorSeverity severity, String message) {
    final level = _severityToLogLevel(severity);
    developer.log(
      message,
      name: _logTag,
      level: level,
    );
  }

  void _writeToFile(ErrorSeverity severity, String message) {
    // File logging implementation would go here
    // This could write to a local file or send to a remote logging service
    // For now, we'll just use developer log as a placeholder
    developer.log(
      'FILE LOG: $message',
      name: _logTag,
      level: _severityToLogLevel(severity),
    );
  }

  int _severityToLogLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 800; // INFO level
      case ErrorSeverity.warning:
        return 900; // WARNING level
      case ErrorSeverity.error:
        return 1000; // SEVERE level
      case ErrorSeverity.critical:
        return 1200; // SHOUT level
    }
  }
}

/// Base class for log entries
abstract class LogEntry {
  final DateTime timestamp;
  final String? context;
  final Map<String, dynamic>? additionalData;

  LogEntry({
    required this.timestamp,
    this.context,
    this.additionalData,
  });

  ErrorSeverity get severity;
  String get message;
  
  String toLogString();
  String toDetailedString();
  Map<String, dynamic> toJson({bool sanitize = true});
}

/// Log entry for application errors
class ErrorLogEntry extends LogEntry {
  final AppError error;

  ErrorLogEntry({
    required this.error,
    super.context,
    super.additionalData,
    required super.timestamp,
  });

  @override
  ErrorSeverity get severity => error.severity;

  @override
  String get message => error.message;

  @override
  String toLogString() {
    final buffer = StringBuffer();
    buffer.write('${error.type.name.toUpperCase()}: ${error.message}');
    
    if (context != null) {
      buffer.write(' [Context: $context]');
    }
    
    return buffer.toString();
  }

  @override
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('${timestamp.toIso8601String()} - ${severity.name.toUpperCase()}');
    buffer.writeln('Type: ${error.type.name}');
    buffer.writeln('Message: ${error.message}');
    buffer.writeln('ID: ${error.id}');
    
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    
    if (error.metadata != null && error.metadata!.isNotEmpty) {
      buffer.writeln('Metadata:');
      final sanitized = ErrorUtils.sanitizeErrorData(error.metadata!);
      sanitized.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    if (additionalData != null && additionalData!.isNotEmpty) {
      buffer.writeln('Additional Data:');
      final sanitized = ErrorUtils.sanitizeErrorData(additionalData!);
      sanitized.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson({bool sanitize = true}) {
    final json = <String, dynamic>{
      'type': 'error',
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'errorType': error.type.name,
      'message': error.message,
      'errorId': error.id,
    };
    
    if (context != null) {
      json['context'] = context;
    }
    
    if (error.metadata != null) {
      json['metadata'] = sanitize 
          ? ErrorUtils.sanitizeErrorData(error.metadata!)
          : error.metadata;
    }
    
    if (additionalData != null) {
      json['additionalData'] = sanitize 
          ? ErrorUtils.sanitizeErrorData(additionalData!)
          : additionalData;
    }
    
    return json;
  }
}

/// Log entry for exceptions
class ExceptionLogEntry extends LogEntry {
  final Object exception;
  final StackTrace stackTrace;
  final ErrorSeverity _severity;

  ExceptionLogEntry({
    required this.exception,
    required this.stackTrace,
    super.context,
    ErrorSeverity severity = ErrorSeverity.error,
    super.additionalData,
    required super.timestamp,
  }) : _severity = severity;

  @override
  ErrorSeverity get severity => _severity;

  @override
  String get message => exception.toString();

  @override
  String toLogString() {
    final buffer = StringBuffer();
    buffer.write('EXCEPTION: ${exception.toString()}');
    
    if (context != null) {
      buffer.write(' [Context: $context]');
    }
    
    return buffer.toString();
  }

  @override
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('${timestamp.toIso8601String()} - EXCEPTION (${severity.name.toUpperCase()})');
    buffer.writeln('Exception: ${exception.toString()}');
    buffer.writeln('Type: ${exception.runtimeType}');
    
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    
    buffer.writeln('Stack Trace:');
    buffer.writeln(stackTrace.toString());
    
    if (additionalData != null && additionalData!.isNotEmpty) {
      buffer.writeln('Additional Data:');
      final sanitized = ErrorUtils.sanitizeErrorData(additionalData!);
      sanitized.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson({bool sanitize = true}) {
    final json = <String, dynamic>{
      'type': 'exception',
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'exception': exception.toString(),
      'exceptionType': exception.runtimeType.toString(),
      'stackTrace': stackTrace.toString(),
    };
    
    if (context != null) {
      json['context'] = context;
    }
    
    if (additionalData != null) {
      json['additionalData'] = sanitize 
          ? ErrorUtils.sanitizeErrorData(additionalData!)
          : additionalData;
    }
    
    return json;
  }
}

/// Log entry for debug messages
class DebugLogEntry extends LogEntry {
  final String _message;
  final Map<String, dynamic>? data;

  DebugLogEntry({
    required String message,
    super.context,
    this.data,
    required super.timestamp,
  }) : _message = message;

  @override
  ErrorSeverity get severity => ErrorSeverity.info;

  @override
  String get message => _message;

  @override
  String toLogString() {
    final buffer = StringBuffer();
    buffer.write('DEBUG: $_message');
    
    if (context != null) {
      buffer.write(' [Context: $context]');
    }
    
    return buffer.toString();
  }

  @override
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('${timestamp.toIso8601String()} - DEBUG');
    buffer.writeln('Message: $_message');
    
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    
    if (data != null && data!.isNotEmpty) {
      buffer.writeln('Data:');
      data!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson({bool sanitize = true}) {
    final json = <String, dynamic>{
      'type': 'debug',
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'message': _message,
    };
    
    if (context != null) {
      json['context'] = context;
    }
    
    if (data != null) {
      json['data'] = sanitize 
          ? ErrorUtils.sanitizeErrorData(data!)
          : data;
    }
    
    return json;
  }
}

/// Log entry for warning messages
class WarningLogEntry extends LogEntry {
  final String _message;
  final Map<String, dynamic>? data;

  WarningLogEntry({
    required String message,
    super.context,
    this.data,
    required super.timestamp,
  }) : _message = message;

  @override
  ErrorSeverity get severity => ErrorSeverity.warning;

  @override
  String get message => _message;

  @override
  String toLogString() {
    final buffer = StringBuffer();
    buffer.write('WARNING: $_message');
    
    if (context != null) {
      buffer.write(' [Context: $context]');
    }
    
    return buffer.toString();
  }

  @override
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('${timestamp.toIso8601String()} - WARNING');
    buffer.writeln('Message: $_message');
    
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    
    if (data != null && data!.isNotEmpty) {
      buffer.writeln('Data:');
      data!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson({bool sanitize = true}) {
    final json = <String, dynamic>{
      'type': 'warning',
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'message': _message,
    };
    
    if (context != null) {
      json['context'] = context;
    }
    
    if (data != null) {
      json['data'] = sanitize 
          ? ErrorUtils.sanitizeErrorData(data!)
          : data;
    }
    
    return json;
  }
}

/// Statistics about errors in the system
class ErrorStatistics {
  final int totalEntries;
  final Map<ErrorType, int> errorsByType;
  final Map<ErrorSeverity, int> errorsBySeverity;
  final int exceptionsCount;
  final int debugMessagesCount;
  final int warningMessagesCount;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  ErrorStatistics({
    required this.totalEntries,
    required this.errorsByType,
    required this.errorsBySeverity,
    required this.exceptionsCount,
    required this.debugMessagesCount,
    required this.warningMessagesCount,
    this.oldestEntry,
    this.newestEntry,
  });
}