import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_error.dart';
import '../config/error_system_config.dart';

/// Service for collecting and reporting error analytics
abstract class IErrorAnalyticsService {
  /// Records an error occurrence for analytics
  Future<void> recordError(AppError error);

  /// Records error resolution (user action taken)
  Future<void> recordErrorResolution(String errorId, String action);

  /// Records error dismissal
  Future<void> recordErrorDismissal(String errorId, String dismissalType);

  /// Records user interaction with error UI
  Future<void> recordErrorInteraction(String errorId, String interactionType);

  /// Gets error analytics summary
  Future<ErrorAnalyticsSummary> getAnalyticsSummary();

  /// Exports analytics data for reporting
  Future<String> exportAnalyticsData();
}

/// Implementation of error analytics service
class ErrorAnalyticsService implements IErrorAnalyticsService {
  final bool _isEnabled;
  final Duration _batchInterval;
  final int _maxBatchSize;

  final List<ErrorAnalyticsEvent> _eventQueue = [];
  final Map<String, ErrorMetrics> _errorMetrics = {};
  Timer? _batchTimer;

  ErrorAnalyticsService({
    bool isEnabled = true,
    Duration batchInterval = const Duration(minutes: 5),
    int maxBatchSize = 50,
  }) : _isEnabled = isEnabled,
       _batchInterval = batchInterval,
       _maxBatchSize = maxBatchSize {
    if (_isEnabled) {
      _startBatchTimer();
    }
  }

  @override
  Future<void> recordError(AppError error) async {
    if (!_isEnabled) return;

    final event = ErrorAnalyticsEvent(
      type: ErrorAnalyticsEventType.errorOccurred,
      errorId: error.id,
      errorType: error.type.toString(),
      errorSeverity: error.severity.toString(),
      errorMessage: _sanitizeMessage(error.message),
      timestamp: DateTime.now(),
      metadata: _extractAnalyticsMetadata(error),
    );

    _addEvent(event);
    _updateErrorMetrics(error);
  }

  @override
  Future<void> recordErrorResolution(String errorId, String action) async {
    if (!_isEnabled) return;

    final event = ErrorAnalyticsEvent(
      type: ErrorAnalyticsEventType.errorResolved,
      errorId: errorId,
      action: action,
      timestamp: DateTime.now(),
    );

    _addEvent(event);
    _updateResolutionMetrics(errorId, action);
  }

  @override
  Future<void> recordErrorDismissal(String errorId, String dismissalType) async {
    if (!_isEnabled) return;

    final event = ErrorAnalyticsEvent(
      type: ErrorAnalyticsEventType.errorDismissed,
      errorId: errorId,
      dismissalType: dismissalType,
      timestamp: DateTime.now(),
    );

    _addEvent(event);
    _updateDismissalMetrics(errorId, dismissalType);
  }

  @override
  Future<void> recordErrorInteraction(String errorId, String interactionType) async {
    if (!_isEnabled) return;

    final event = ErrorAnalyticsEvent(
      type: ErrorAnalyticsEventType.userInteraction,
      errorId: errorId,
      interactionType: interactionType,
      timestamp: DateTime.now(),
    );

    _addEvent(event);
  }

  @override
  Future<ErrorAnalyticsSummary> getAnalyticsSummary() async {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final recent24hEvents = _eventQueue.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final recent7dEvents = _eventQueue.where((e) => e.timestamp.isAfter(last7Days)).toList();

    return ErrorAnalyticsSummary(
      totalErrors: _errorMetrics.length,
      errorsLast24h: recent24hEvents.where((e) => e.type == ErrorAnalyticsEventType.errorOccurred).length,
      errorsLast7d: recent7dEvents.where((e) => e.type == ErrorAnalyticsEventType.errorOccurred).length,
      mostCommonErrorTypes: _getMostCommonErrorTypes(),
      averageResolutionTime: _calculateAverageResolutionTime(),
      dismissalRate: _calculateDismissalRate(),
      topErrorMessages: _getTopErrorMessages(),
      errorsByHour: _getErrorsByHour(recent24hEvents),
      resolutionActions: _getResolutionActionStats(),
    );
  }

  @override
  Future<String> exportAnalyticsData() async {
    final summary = await getAnalyticsSummary();
    final exportData = {
      'summary': summary.toJson(),
      'events': _eventQueue.map((e) => e.toJson()).toList(),
      'metrics': _errorMetrics.map((key, value) => MapEntry(key, value.toJson())),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(exportData);
  }

  void _addEvent(ErrorAnalyticsEvent event) {
    _eventQueue.add(event);

    // Limit queue size to prevent memory issues
    if (_eventQueue.length > 1000) {
      _eventQueue.removeAt(0);
    }

    // Trigger batch processing if queue is full
    if (_eventQueue.length >= _maxBatchSize) {
      _processBatch();
    }
  }

  void _updateErrorMetrics(AppError error) {
    final metrics = _errorMetrics.putIfAbsent(
      error.id,
      () => ErrorMetrics(
        errorId: error.id,
        errorType: error.type.toString(),
        severity: error.severity.toString(),
        firstOccurrence: DateTime.now(),
      ),
    );

    metrics.occurrenceCount++;
    metrics.lastOccurrence = DateTime.now();
  }

  void _updateResolutionMetrics(String errorId, String action) {
    final metrics = _errorMetrics[errorId];
    if (metrics != null) {
      metrics.resolutionAction = action;
      metrics.resolutionTime = DateTime.now();
      metrics.wasResolved = true;
    }
  }

  void _updateDismissalMetrics(String errorId, String dismissalType) {
    final metrics = _errorMetrics[errorId];
    if (metrics != null) {
      metrics.dismissalType = dismissalType;
      metrics.dismissalTime = DateTime.now();
      metrics.wasDismissed = true;
    }
  }

  void _startBatchTimer() {
    _batchTimer = Timer.periodic(_batchInterval, (_) => _processBatch());
  }

  void _processBatch() {
    if (_eventQueue.isEmpty) return;

    // In a real implementation, this would send data to analytics service
    if (kDebugMode) {
      debugPrint('Processing ${_eventQueue.length} error analytics events');
    }

    // For now, we just keep the events in memory
    // In production, you would send them to your analytics backend
  }

  String _sanitizeMessage(String message) {
    // Remove potentially sensitive information
    var sanitized = message;
    
    // Remove email addresses
    sanitized = sanitized.replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '[EMAIL]');
    
    // Remove phone numbers
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{3}-\d{3}-\d{4}\b'), '[PHONE]');
    
    // Remove potential API keys or tokens
    sanitized = sanitized.replaceAll(RegExp(r'\b[A-Za-z0-9]{32,}\b'), '[TOKEN]');
    
    return sanitized;
  }

  Map<String, dynamic> _extractAnalyticsMetadata(AppError error) {
    final metadata = <String, dynamic>{
      'errorType': error.type.toString(),
      'severity': error.severity.toString(),
    };

    if (error is ApiError) {
      metadata['statusCode'] = error.statusCode;
      metadata['method'] = error.method;
      metadata['endpoint'] = error.endpoint;
    } else if (error is ValidationError) {
      metadata['fieldCount'] = error.fieldErrors.length;
      metadata['formId'] = error.formId;
    } else if (error is NetworkError) {
      metadata['networkType'] = error.networkType.toString();
    } else if (error is ClientError) {
      metadata['componentName'] = error.componentName;
    }

    return metadata;
  }

  Map<String, int> _getMostCommonErrorTypes() {
    final typeCounts = <String, int>{};
    
    for (final metrics in _errorMetrics.values) {
      typeCounts[metrics.errorType] = (typeCounts[metrics.errorType] ?? 0) + metrics.occurrenceCount;
    }

    // Sort by count and return top 10
    final sorted = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sorted.take(10));
  }

  Duration _calculateAverageResolutionTime() {
    final resolvedErrors = _errorMetrics.values.where((m) => m.wasResolved && m.resolutionTime != null);
    
    if (resolvedErrors.isEmpty) return Duration.zero;

    final totalDuration = resolvedErrors.fold<Duration>(
      Duration.zero,
      (sum, metrics) => sum + metrics.resolutionTime!.difference(metrics.firstOccurrence),
    );

    return Duration(milliseconds: totalDuration.inMilliseconds ~/ resolvedErrors.length);
  }

  double _calculateDismissalRate() {
    if (_errorMetrics.isEmpty) return 0.0;

    final dismissedCount = _errorMetrics.values.where((m) => m.wasDismissed).length;
    return dismissedCount / _errorMetrics.length;
  }

  List<String> _getTopErrorMessages() {
    final messageCounts = <String, int>{};
    
    for (final event in _eventQueue) {
      if (event.type == ErrorAnalyticsEventType.errorOccurred && event.errorMessage != null) {
        messageCounts[event.errorMessage!] = (messageCounts[event.errorMessage!] ?? 0) + 1;
      }
    }

    final sorted = messageCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(10).map((e) => e.key).toList();
  }

  Map<int, int> _getErrorsByHour(List<ErrorAnalyticsEvent> events) {
    final hourCounts = <int, int>{};
    
    for (final event in events) {
      if (event.type == ErrorAnalyticsEventType.errorOccurred) {
        final hour = event.timestamp.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }

    return hourCounts;
  }

  Map<String, int> _getResolutionActionStats() {
    final actionCounts = <String, int>{};
    
    for (final event in _eventQueue) {
      if (event.type == ErrorAnalyticsEventType.errorResolved && event.action != null) {
        actionCounts[event.action!] = (actionCounts[event.action!] ?? 0) + 1;
      }
    }

    return actionCounts;
  }

  void dispose() {
    _batchTimer?.cancel();
    _eventQueue.clear();
    _errorMetrics.clear();
  }
}

/// Analytics event types
enum ErrorAnalyticsEventType {
  errorOccurred,
  errorResolved,
  errorDismissed,
  userInteraction,
}

/// Analytics event data
class ErrorAnalyticsEvent {
  final ErrorAnalyticsEventType type;
  final String errorId;
  final String? errorType;
  final String? errorSeverity;
  final String? errorMessage;
  final String? action;
  final String? dismissalType;
  final String? interactionType;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ErrorAnalyticsEvent({
    required this.type,
    required this.errorId,
    required this.timestamp,
    this.errorType,
    this.errorSeverity,
    this.errorMessage,
    this.action,
    this.dismissalType,
    this.interactionType,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'errorId': errorId,
      'errorType': errorType,
      'errorSeverity': errorSeverity,
      'errorMessage': errorMessage,
      'action': action,
      'dismissalType': dismissalType,
      'interactionType': interactionType,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Error metrics for analytics
class ErrorMetrics {
  final String errorId;
  final String errorType;
  final String severity;
  final DateTime firstOccurrence;
  
  DateTime lastOccurrence;
  int occurrenceCount = 1;
  bool wasResolved = false;
  bool wasDismissed = false;
  String? resolutionAction;
  DateTime? resolutionTime;
  String? dismissalType;
  DateTime? dismissalTime;

  ErrorMetrics({
    required this.errorId,
    required this.errorType,
    required this.severity,
    required this.firstOccurrence,
  }) : lastOccurrence = firstOccurrence;

  Map<String, dynamic> toJson() {
    return {
      'errorId': errorId,
      'errorType': errorType,
      'severity': severity,
      'firstOccurrence': firstOccurrence.toIso8601String(),
      'lastOccurrence': lastOccurrence.toIso8601String(),
      'occurrenceCount': occurrenceCount,
      'wasResolved': wasResolved,
      'wasDismissed': wasDismissed,
      'resolutionAction': resolutionAction,
      'resolutionTime': resolutionTime?.toIso8601String(),
      'dismissalType': dismissalType,
      'dismissalTime': dismissalTime?.toIso8601String(),
    };
  }
}

/// Summary of error analytics
class ErrorAnalyticsSummary {
  final int totalErrors;
  final int errorsLast24h;
  final int errorsLast7d;
  final Map<String, int> mostCommonErrorTypes;
  final Duration averageResolutionTime;
  final double dismissalRate;
  final List<String> topErrorMessages;
  final Map<int, int> errorsByHour;
  final Map<String, int> resolutionActions;

  ErrorAnalyticsSummary({
    required this.totalErrors,
    required this.errorsLast24h,
    required this.errorsLast7d,
    required this.mostCommonErrorTypes,
    required this.averageResolutionTime,
    required this.dismissalRate,
    required this.topErrorMessages,
    required this.errorsByHour,
    required this.resolutionActions,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalErrors': totalErrors,
      'errorsLast24h': errorsLast24h,
      'errorsLast7d': errorsLast7d,
      'mostCommonErrorTypes': mostCommonErrorTypes,
      'averageResolutionTimeMs': averageResolutionTime.inMilliseconds,
      'dismissalRate': dismissalRate,
      'topErrorMessages': topErrorMessages,
      'errorsByHour': errorsByHour,
      'resolutionActions': resolutionActions,
    };
  }
}