import 'dart:async';
import 'dart:developer' as developer;
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_debug_event.dart';
import '../models/websocket_metrics.dart';
import '../models/websocket_connection_state.dart';
import 'websocket_monitor.dart';
import 'websocket_debug_logger.dart';
import 'websocket_dev_tools.dart';
import 'websocket_analytics.dart';

/// Integrated monitoring service that combines all WebSocket monitoring tools
class WebSocketMonitoringService {
  final IWebSocketService _webSocketService;
  late final WebSocketMonitor _monitor;
  late final WebSocketDebugLogger _debugLogger;
  late final WebSocketDevTools _devTools;
  late final WebSocketAnalytics _analytics;
  
  final StreamController<WebSocketMonitoringUpdate> _updateController = 
      StreamController<WebSocketMonitoringUpdate>.broadcast();
  
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _metricsSubscription;
  StreamSubscription? _debugEventSubscription;
  StreamSubscription? _healthSubscription;
  StreamSubscription? _analyticsSubscription;
  
  bool _isInitialized = false;
  WebSocketDebugConfig _debugConfig = const WebSocketDebugConfig();

  WebSocketMonitoringService(this._webSocketService);

  /// Stream of monitoring updates
  Stream<WebSocketMonitoringUpdate> get updateStream => _updateController.stream;
  
  /// Check if monitoring is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get current debug configuration
  WebSocketDebugConfig get debugConfig => _debugConfig;
  
  /// Get monitor instance
  WebSocketMonitor get monitor => _monitor;
  
  /// Get debug logger instance
  WebSocketDebugLogger get debugLogger => _debugLogger;
  
  /// Get development tools instance
  WebSocketDevTools get devTools => _devTools;
  
  /// Get analytics instance
  WebSocketAnalytics get analytics => _analytics;

  /// Initialize monitoring with configuration
  Future<void> initialize({
    WebSocketDebugConfig? debugConfig,
    bool enableAnalytics = true,
    bool enableDevTools = true,
  }) async {
    if (_isInitialized) {
      developer.log('WebSocket monitoring already initialized', name: 'WebSocketMonitoringService');
      return;
    }

    _debugConfig = debugConfig ?? const WebSocketDebugConfig(
      enableLogging: true,
      enableEventTracking: true,
      enablePerformanceMonitoring: true,
      enableErrorAnalytics: true,
      logLevel: WebSocketDebugLogLevel.info,
    );

    // Initialize components
    _monitor = WebSocketMonitor(_webSocketService);
    _debugLogger = WebSocketDebugLogger(_debugConfig);
    _analytics = WebSocketAnalytics(
      enableErrorReporting: enableAnalytics,
      enablePerformanceTracking: enableAnalytics,
    );
    _devTools = WebSocketDevTools(_webSocketService, _monitor, _debugLogger);

    // Set up subscriptions
    _setupSubscriptions();
    
    _isInitialized = true;
    
    developer.log('WebSocket monitoring service initialized', name: 'WebSocketMonitoringService');
    
    // Emit initialization update
    _emitUpdate(WebSocketMonitoringUpdateType.initialization, {
      'initialized': true,
      'debugConfig': _debugConfig.toJson(),
      'enableAnalytics': enableAnalytics,
      'enableDevTools': enableDevTools,
    });
  }

  void _setupSubscriptions() {
    // Monitor connection state changes
    _connectionStateSubscription = _webSocketService.connectionState.listen((state) {
      _onConnectionStateChanged(state);
    });

    // Monitor metrics updates
    _metricsSubscription = _monitor.metricsStream.listen((metrics) {
      _onMetricsUpdated(metrics);
    });

    // Monitor debug events
    _debugEventSubscription = _debugLogger.eventStream.listen((event) {
      _onDebugEvent(event);
    });

    // Monitor health checks
    _healthSubscription = _monitor.healthStream.listen((healthCheck) {
      _onHealthCheckCompleted(healthCheck);
    });

    // Monitor analytics events
    _analyticsSubscription = _analytics.eventStream.listen((event) {
      _onAnalyticsEvent(event);
    });
  }

  void _onConnectionStateChanged(WebSocketConnectionState state) {
    final now = DateTime.now();
    
    // Log state change
    _debugLogger.logStateChange(_webSocketService.currentState, state);
    
    // Track analytics
    _analytics.trackConnectionEvent(
      eventType: 'stateChange',
      state: state,
    );
    
    // Emit monitoring update
    _emitUpdate(WebSocketMonitoringUpdateType.connectionState, {
      'state': state.name,
      'timestamp': now.toIso8601String(),
    });
  }

  void _onMetricsUpdated(WebSocketMetrics metrics) {
    // Track performance analytics
    _analytics.trackPerformanceMetrics(metrics);
    
    // Emit monitoring update
    _emitUpdate(WebSocketMonitoringUpdateType.metrics, {
      'metrics': metrics.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _onDebugEvent(WebSocketDebugEvent event) {
    // Track error analytics if it's an error event
    if (event.error != null) {
      _analytics.trackError(
        error: event.error!,
        context: event.type.name,
        additionalData: event.data,
      );
    }
    
    // Emit monitoring update for significant events
    if (_isSignificantEvent(event.type)) {
      _emitUpdate(WebSocketMonitoringUpdateType.debugEvent, {
        'event': {
          'type': event.type.name,
          'message': event.message,
          'timestamp': event.timestamp.toIso8601String(),
          'data': event.data,
        },
      });
    }
  }

  void _onHealthCheckCompleted(WebSocketHealthCheck healthCheck) {
    // Track health analytics
    _analytics.trackCustomEvent(
      eventName: 'healthCheck',
      properties: {
        'status': healthCheck.status.name,
        'score': healthCheck.score,
        'issuesCount': healthCheck.issues.length,
      },
      severity: _getHealthSeverity(healthCheck.status),
    );
    
    // Emit monitoring update
    _emitUpdate(WebSocketMonitoringUpdateType.healthCheck, {
      'healthCheck': healthCheck.toJson(),
    });
  }

  void _onAnalyticsEvent(WebSocketAnalyticsEvent event) {
    // Emit monitoring update for critical analytics events
    if (event.severity == WebSocketAnalyticsEventSeverity.critical) {
      _emitUpdate(WebSocketMonitoringUpdateType.analytics, {
        'event': event.toJson(),
      });
    }
  }

  bool _isSignificantEvent(WebSocketDebugEventType type) {
    return [
      WebSocketDebugEventType.connectionSuccess,
      WebSocketDebugEventType.connectionFailure,
      WebSocketDebugEventType.disconnection,
      WebSocketDebugEventType.error,
      WebSocketDebugEventType.authentication,
    ].contains(type);
  }

  WebSocketAnalyticsEventSeverity _getHealthSeverity(WebSocketHealthStatus status) {
    switch (status) {
      case WebSocketHealthStatus.excellent:
      case WebSocketHealthStatus.good:
        return WebSocketAnalyticsEventSeverity.info;
      case WebSocketHealthStatus.fair:
        return WebSocketAnalyticsEventSeverity.warning;
      case WebSocketHealthStatus.poor:
        return WebSocketAnalyticsEventSeverity.error;
      case WebSocketHealthStatus.critical:
        return WebSocketAnalyticsEventSeverity.critical;
    }
  }

  void _emitUpdate(WebSocketMonitoringUpdateType type, Map<String, dynamic> data) {
    final update = WebSocketMonitoringUpdate(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    
    if (!_updateController.isClosed) {
      _updateController.add(update);
    }
  }

  /// Record a message being sent (to be called by WebSocket service)
  void recordMessageSent(String channel, Map<String, dynamic> data) {
    if (!_isInitialized) return;
    
    _monitor.recordMessageSent(channel, data);
    _debugLogger.logMessageSent(channel, data);
  }

  /// Record a message being received (to be called by WebSocket service)
  void recordMessageReceived(String channel, Map<String, dynamic> data, {Duration? processingTime}) {
    if (!_isInitialized) return;
    
    _monitor.recordMessageReceived(channel, data, processingTime: processingTime);
    _debugLogger.logMessageReceived(channel, data, processingTime: processingTime);
  }

  /// Record a subscription (to be called by WebSocket service)
  void recordSubscription(String channel) {
    if (!_isInitialized) return;
    
    _monitor.recordSubscription(channel);
    _debugLogger.logSubscription(channel);
  }

  /// Record an unsubscription (to be called by WebSocket service)
  void recordUnsubscription(String channel) {
    if (!_isInitialized) return;
    
    _monitor.recordUnsubscription(channel);
    _debugLogger.logUnsubscription(channel);
  }

  /// Record an error (to be called by WebSocket service)
  void recordError(WebSocketError error, {String? context}) {
    if (!_isInitialized) return;
    
    _monitor.recordError(error);
    _debugLogger.logError(error, context: context);
  }

  /// Update debug configuration
  void updateDebugConfig(WebSocketDebugConfig newConfig) {
    if (!_isInitialized) return;
    
    final oldConfig = _debugConfig;
    _debugConfig = newConfig;
    
    _debugLogger.updateConfig(newConfig);
    _analytics.trackConfigurationChange(
      setting: 'debugConfig',
      oldValue: oldConfig.toJson(),
      newValue: newConfig.toJson(),
    );
    
    _emitUpdate(WebSocketMonitoringUpdateType.configuration, {
      'setting': 'debugConfig',
      'oldValue': oldConfig.toJson(),
      'newValue': newConfig.toJson(),
    });
  }

  /// Get comprehensive monitoring report
  Map<String, dynamic> getMonitoringReport() {
    if (!_isInitialized) {
      return {'error': 'Monitoring service not initialized'};
    }
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'isInitialized': _isInitialized,
      'debugConfig': _debugConfig.toJson(),
      'serviceStatus': _devTools.getServiceStatus(),
      'metrics': _monitor.currentMetrics.toJson(),
      'debugReport': _devTools.generateDebugReport(),
      'analyticsSummary': _analytics.getAnalyticsSummary(),
      'debugSession': _debugLogger.currentSession?.toJson(),
    };
  }

  /// Export all monitoring data
  Map<String, dynamic> exportAllData() {
    if (!_isInitialized) {
      return {'error': 'Monitoring service not initialized'};
    }
    
    return _devTools.exportAllData();
  }

  /// Reset all monitoring data
  void resetAllData() {
    if (!_isInitialized) return;
    
    _devTools.resetAllData();
    _emitUpdate(WebSocketMonitoringUpdateType.reset, {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Enable or disable analytics
  void setAnalyticsEnabled(bool enabled) {
    if (!_isInitialized) return;
    
    _analytics.setEnabled(enabled);
    _analytics.trackConfigurationChange(
      setting: 'analyticsEnabled',
      oldValue: !enabled,
      newValue: enabled,
    );
    
    _emitUpdate(WebSocketMonitoringUpdateType.configuration, {
      'setting': 'analyticsEnabled',
      'value': enabled,
    });
  }

  /// Dispose all resources
  void dispose() {
    if (!_isInitialized) return;
    
    _connectionStateSubscription?.cancel();
    _metricsSubscription?.cancel();
    _debugEventSubscription?.cancel();
    _healthSubscription?.cancel();
    _analyticsSubscription?.cancel();
    
    _monitor.dispose();
    _debugLogger.dispose();
    _devTools.dispose();
    _analytics.dispose();
    
    _updateController.close();
    
    _isInitialized = false;
    
    developer.log('WebSocket monitoring service disposed', name: 'WebSocketMonitoringService');
  }
}

/// Types of monitoring updates
enum WebSocketMonitoringUpdateType {
  initialization,
  connectionState,
  metrics,
  debugEvent,
  healthCheck,
  analytics,
  configuration,
  reset,
}

/// Monitoring update event
class WebSocketMonitoringUpdate {
  final WebSocketMonitoringUpdateType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const WebSocketMonitoringUpdate({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  @override
  String toString() {
    return 'WebSocketMonitoringUpdate(type: $type, timestamp: $timestamp)';
  }
}