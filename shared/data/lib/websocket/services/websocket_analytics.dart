import 'dart:async';
import 'dart:developer' as developer;
import '../models/websocket_debug_event.dart';
import '../models/websocket_metrics.dart';
import '../models/websocket_connection_state.dart';

/// Analytics integration for WebSocket error reporting and performance tracking
class WebSocketAnalytics {
  final StreamController<WebSocketAnalyticsEvent> _eventController = 
      StreamController<WebSocketAnalyticsEvent>.broadcast();
  
  final List<WebSocketAnalyticsEvent> _pendingEvents = [];
  Timer? _batchTimer;
  bool _isEnabled = false;
  
  // Configuration
  final Duration _batchInterval;
  final int _maxBatchSize;
  final bool _enableErrorReporting;
  final bool _enablePerformanceTracking;
  final bool _enableUserAnalytics;
  
  WebSocketAnalytics({
    Duration batchInterval = const Duration(minutes: 5),
    int maxBatchSize = 50,
    bool enableErrorReporting = true,
    bool enablePerformanceTracking = true,
    bool enableUserAnalytics = false,
  }) : _batchInterval = batchInterval,
       _maxBatchSize = maxBatchSize,
       _enableErrorReporting = enableErrorReporting,
       _enablePerformanceTracking = enablePerformanceTracking,
       _enableUserAnalytics = enableUserAnalytics {
    _initializeAnalytics();
  }

  /// Stream of analytics events
  Stream<WebSocketAnalyticsEvent> get eventStream => _eventController.stream;
  
  /// Check if analytics is enabled
  bool get isEnabled => _isEnabled;
  
  /// Get pending events count
  int get pendingEventsCount => _pendingEvents.length;

  void _initializeAnalytics() {
    _isEnabled = true;
    
    // Start batch processing timer
    _batchTimer = Timer.periodic(_batchInterval, (_) => _processBatch());
    
    developer.log(
      'WebSocket analytics initialized (errors: $_enableErrorReporting, performance: $_enablePerformanceTracking)',
      name: 'WebSocketAnalytics',
    );
  }

  /// Track connection event
  void trackConnectionEvent({
    required String eventType,
    required WebSocketConnectionState state,
    Duration? connectionTime,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled || !_enablePerformanceTracking) return;

    final event = WebSocketAnalyticsEvent(
      type: WebSocketAnalyticsEventType.connection,
      timestamp: DateTime.now(),
      data: {
        'eventType': eventType,
        'connectionState': state.name,
        if (connectionTime != null) 'connectionTimeMs': connectionTime.inMilliseconds,
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (metadata != null) ...metadata,
      },
    );

    _addEvent(event);
  }

  /// Track error event
  void trackError({
    required WebSocketError error,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isEnabled || !_enableErrorReporting) return;

    final event = WebSocketAnalyticsEvent(
      type: WebSocketAnalyticsEventType.error,
      timestamp: DateTime.now(),
      data: {
        'errorType': error.type.name,
        'errorMessage': error.message,
        'isRecoverable': error.isRecoverable,
        'attemptNumber': error.attemptNumber,
        if (context != null) 'context': context,
        if (error.originalError != null) 'originalError': error.originalError.toString(),
        if (additionalData != null) ...additionalData,
      },
      severity: _getErrorSeverity(error),
    );

    _addEvent(event);
  }

  /// Track performance metrics
  void trackPerformanceMetrics(WebSocketMetrics metrics) {
    if (!_isEnabled || !_enablePerformanceTracking) return;

    final event = WebSocketAnalyticsEvent(
      type: WebSocketAnalyticsEventType.performance,
      timestamp: DateTime.now(),
      data: {
        'connectionAttempts': metrics.connectionAttempts,
        'successfulConnections': metrics.successfulConnections,
        'failedConnections': metrics.failedConnections,
        'reconnectionAttempts': metrics.reconnectionAttempts,
        'messagesSent': metrics.messagesSent,
        'messagesReceived': metrics.messagesReceived,
        'totalUptimeMs': metrics.totalUptimeMs,
        'averageConnectionDurationMs': metrics.averageConnectionDurationMs,
        'averageMessageProcessingTimeMs': metrics.averageMessageProcessingTimeMs,
        'errorCount': metrics.errorCount,
        'connectionQualityScore': metrics.connectionQualityScore,
        'bytesSent': metrics.dataTransfer.bytesSent,
        'bytesReceived': metrics.dataTransfer.bytesReceived,
        'averageMessageSize': metrics.dataTransfer.averageMessageSize,
        'peakMessageRate': metrics.dataTransfer.peakMessageRate,
      },
    );

    _addEvent(event);
  }

  /// Track user interaction
  void trackUserInteraction({
    required String action,
    String? feature,
    Map<String, dynamic>? properties,
  }) {
    if (!_isEnabled || !_enableUserAnalytics) return;

    final event = WebSocketAnalyticsEvent(
      type: WebSocketAnalyticsEventType.userInteraction,
      timestamp: DateTime.now(),
      data: {
        'action': action,
        if (feature != null) 'feature': feature,
        if (properties != null) ...properties,
      },
    );

    _addEvent(event);
  }

  /// Track configuration change
  void trackConfigurationChange({
    required String setting,
    required dynamic oldValue,
    required dynamic newValue,
    String? reason,
  }) {
    if (!_isEnabled) return;

    final event = WebSocketAnalyticsEvent(
      type: WebSocketAnalyticsEventType.configuration,
      timestamp: DateTime.now(),
      data: {
        'setting': setting,
        'oldValue': oldValue,
        'newValue': newValue,
        if (reason != null) 'reason': reason,
      },
    );

    _addEvent(event);
  }

  /// Track custom event
  void trackCustomEvent({
    required String eventName,
    Map<String, dynamic>? properties,
    WebSocketAnalyticsEventSeverity severity = WebSocketAnalyticsEventSeverity.info,
  }) {
    if (!_isEnabled) return;

    final event = WebSocketAnalyticsEvent(
      type: WebSocketAnalyticsEventType.custom,
      timestamp: DateTime.now(),
      data: {
        'eventName': eventName,
        if (properties != null) ...properties,
      },
      severity: severity,
    );

    _addEvent(event);
  }

  void _addEvent(WebSocketAnalyticsEvent event) {
    _pendingEvents.add(event);
    
    // Emit event to stream
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }

    // Process batch immediately if it's full or if it's a critical error
    if (_pendingEvents.length >= _maxBatchSize || 
        event.severity == WebSocketAnalyticsEventSeverity.critical) {
      _processBatch();
    }
  }

  void _processBatch() {
    if (_pendingEvents.isEmpty) return;

    final batch = List<WebSocketAnalyticsEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    developer.log(
      'Processing analytics batch: ${batch.length} events',
      name: 'WebSocketAnalytics',
    );

    // In a real implementation, this would send data to analytics service
    _sendToAnalyticsService(batch);
  }

  Future<void> _sendToAnalyticsService(List<WebSocketAnalyticsEvent> events) async {
    try {
      // Group events by type for better organization
      final eventsByType = <WebSocketAnalyticsEventType, List<WebSocketAnalyticsEvent>>{};
      
      for (final event in events) {
        eventsByType.putIfAbsent(event.type, () => []).add(event);
      }

      // Process each event type
      for (final entry in eventsByType.entries) {
        await _processEventsByType(entry.key, entry.value);
      }

      developer.log(
        'Successfully sent ${events.length} events to analytics service',
        name: 'WebSocketAnalytics',
      );

    } catch (e) {
      developer.log(
        'Failed to send analytics events: $e',
        name: 'WebSocketAnalytics',
        error: e,
      );

      // Re-add events to pending list for retry (with limit to prevent memory issues)
      if (_pendingEvents.length < _maxBatchSize * 2) {
        _pendingEvents.addAll(events);
      }
    }
  }

  Future<void> _processEventsByType(
    WebSocketAnalyticsEventType type,
    List<WebSocketAnalyticsEvent> events,
  ) async {
    switch (type) {
      case WebSocketAnalyticsEventType.error:
        await _processErrorEvents(events);
        break;
      case WebSocketAnalyticsEventType.performance:
        await _processPerformanceEvents(events);
        break;
      case WebSocketAnalyticsEventType.connection:
        await _processConnectionEvents(events);
        break;
      case WebSocketAnalyticsEventType.userInteraction:
        await _processUserInteractionEvents(events);
        break;
      case WebSocketAnalyticsEventType.configuration:
        await _processConfigurationEvents(events);
        break;
      case WebSocketAnalyticsEventType.custom:
        await _processCustomEvents(events);
        break;
    }
  }

  Future<void> _processErrorEvents(List<WebSocketAnalyticsEvent> events) async {
    // In a real implementation, this would send error data to error tracking service
    // like Sentry, Crashlytics, or custom error reporting service
    
    for (final event in events) {
      developer.log(
        'Error tracked: ${event.data['errorType']} - ${event.data['errorMessage']}',
        name: 'WebSocketAnalytics.Error',
      );
    }
  }

  Future<void> _processPerformanceEvents(List<WebSocketAnalyticsEvent> events) async {
    // In a real implementation, this would send performance data to analytics service
    // like Google Analytics, Mixpanel, or custom analytics service
    
    for (final event in events) {
      developer.log(
        'Performance tracked: Quality Score ${event.data['connectionQualityScore']}, Uptime ${event.data['totalUptimeMs']}ms',
        name: 'WebSocketAnalytics.Performance',
      );
    }
  }

  Future<void> _processConnectionEvents(List<WebSocketAnalyticsEvent> events) async {
    // Track connection-related events
    for (final event in events) {
      developer.log(
        'Connection tracked: ${event.data['eventType']} - ${event.data['connectionState']}',
        name: 'WebSocketAnalytics.Connection',
      );
    }
  }

  Future<void> _processUserInteractionEvents(List<WebSocketAnalyticsEvent> events) async {
    // Track user interaction events
    for (final event in events) {
      developer.log(
        'User interaction tracked: ${event.data['action']}',
        name: 'WebSocketAnalytics.UserInteraction',
      );
    }
  }

  Future<void> _processConfigurationEvents(List<WebSocketAnalyticsEvent> events) async {
    // Track configuration changes
    for (final event in events) {
      developer.log(
        'Configuration tracked: ${event.data['setting']} changed from ${event.data['oldValue']} to ${event.data['newValue']}',
        name: 'WebSocketAnalytics.Configuration',
      );
    }
  }

  Future<void> _processCustomEvents(List<WebSocketAnalyticsEvent> events) async {
    // Track custom events
    for (final event in events) {
      developer.log(
        'Custom event tracked: ${event.data['eventName']}',
        name: 'WebSocketAnalytics.Custom',
      );
    }
  }

  WebSocketAnalyticsEventSeverity _getErrorSeverity(WebSocketError error) {
    switch (error.type) {
      case WebSocketErrorType.authenticationFailed:
      case WebSocketErrorType.tokenRefreshFailed:
      case WebSocketErrorType.maxReconnectAttemptsExceeded:
        return WebSocketAnalyticsEventSeverity.critical;
      
      case WebSocketErrorType.connectionTimeout:
      case WebSocketErrorType.networkError:
      case WebSocketErrorType.serverError:
      case WebSocketErrorType.unexpectedDisconnection:
        return WebSocketAnalyticsEventSeverity.error;
      
      case WebSocketErrorType.heartbeatTimeout:
      case WebSocketErrorType.tokenExpired:
        return WebSocketAnalyticsEventSeverity.warning;
      
      case WebSocketErrorType.invalidMessage:
      case WebSocketErrorType.subscriptionFailed:
        return WebSocketAnalyticsEventSeverity.info;
      
      default:
        return WebSocketAnalyticsEventSeverity.info;
    }
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final eventsByType = <String, int>{};
    final eventsBySeverity = <String, int>{};
    
    for (final event in _pendingEvents) {
      eventsByType[event.type.name] = (eventsByType[event.type.name] ?? 0) + 1;
      eventsBySeverity[event.severity.name] = (eventsBySeverity[event.severity.name] ?? 0) + 1;
    }
    
    return {
      'isEnabled': _isEnabled,
      'pendingEventsCount': _pendingEvents.length,
      'eventsByType': eventsByType,
      'eventsBySeverity': eventsBySeverity,
      'configuration': {
        'batchIntervalMs': _batchInterval.inMilliseconds,
        'maxBatchSize': _maxBatchSize,
        'enableErrorReporting': _enableErrorReporting,
        'enablePerformanceTracking': _enablePerformanceTracking,
        'enableUserAnalytics': _enableUserAnalytics,
      },
    };
  }

  /// Force process pending events
  void flushEvents() {
    if (_pendingEvents.isNotEmpty) {
      _processBatch();
    }
  }

  /// Enable or disable analytics
  void setEnabled(bool enabled) {
    if (_isEnabled == enabled) return;
    
    _isEnabled = enabled;
    
    if (enabled) {
      _batchTimer ??= Timer.periodic(_batchInterval, (_) => _processBatch());
    } else {
      _batchTimer?.cancel();
      _batchTimer = null;
      _pendingEvents.clear();
    }
    
    developer.log('WebSocket analytics ${enabled ? 'enabled' : 'disabled'}', name: 'WebSocketAnalytics');
  }

  /// Dispose resources
  void dispose() {
    _isEnabled = false; // Disable first to prevent new events
    _batchTimer?.cancel();
    flushEvents(); // Send any remaining events
    _eventController.close();
    
    developer.log('WebSocket analytics disposed', name: 'WebSocketAnalytics');
  }
}

/// Analytics event types
enum WebSocketAnalyticsEventType {
  error,
  performance,
  connection,
  userInteraction,
  configuration,
  custom,
}

/// Analytics event severity levels
enum WebSocketAnalyticsEventSeverity {
  info,
  warning,
  error,
  critical,
}

/// Analytics event model
class WebSocketAnalyticsEvent {
  final WebSocketAnalyticsEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final WebSocketAnalyticsEventSeverity severity;

  const WebSocketAnalyticsEvent({
    required this.type,
    required this.timestamp,
    required this.data,
    this.severity = WebSocketAnalyticsEventSeverity.info,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'severity': severity.name,
    };
  }

  @override
  String toString() {
    return 'WebSocketAnalyticsEvent(type: $type, severity: $severity, timestamp: $timestamp)';
  }
}