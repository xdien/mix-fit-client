import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../models/websocket_debug_event.dart';
import '../models/websocket_metrics.dart';
import '../models/websocket_connection_state.dart';
import '../interfaces/i_websocket_service.dart';
import 'websocket_monitor.dart';
import 'websocket_debug_logger.dart';

/// Development tools for testing and debugging WebSocket functionality
class WebSocketDevTools {
  final IWebSocketService _webSocketService;
  final WebSocketMonitor _monitor;
  final WebSocketDebugLogger _debugLogger;
  
  Timer? _loadTestTimer;
  Timer? _connectionTestTimer;
  bool _isLoadTesting = false;
  bool _isConnectionTesting = false;
  
  WebSocketDevTools(
    this._webSocketService,
    this._monitor,
    this._debugLogger,
  );

  /// Check if development tools are available (debug mode only)
  bool get isAvailable => _isDebugMode();

  /// Get current WebSocket service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'connectionState': _webSocketService.currentState.name,
      'isConnected': _webSocketService.currentState == WebSocketConnectionState.connected,
      'metrics': _monitor.currentMetrics.toJson(),
      'healthCheckEnabled': true,
      'debugSessionActive': _debugLogger.currentSession != null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Simulate connection issues for testing
  Future<void> simulateConnectionIssues({
    int disconnectionCount = 3,
    Duration disconnectionInterval = const Duration(seconds: 10),
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Development tools not available in release mode');
    }

    developer.log(
      'Starting connection issue simulation: $disconnectionCount disconnections every ${disconnectionInterval.inSeconds}s',
      name: 'WebSocketDevTools',
    );

    _debugLogger.logConfigurationChange(
      'simulateConnectionIssues',
      null,
      {
        'disconnectionCount': disconnectionCount,
        'disconnectionInterval': disconnectionInterval.inSeconds,
      },
    );

    for (int i = 0; i < disconnectionCount; i++) {
      if (_webSocketService.currentState == WebSocketConnectionState.connected) {
        developer.log('Simulating disconnection ${i + 1}/$disconnectionCount', name: 'WebSocketDevTools');
        
        await _webSocketService.disconnect();
        await Future.delayed(const Duration(seconds: 2));
        await _webSocketService.connect();
        
        if (i < disconnectionCount - 1) {
          await Future.delayed(disconnectionInterval);
        }
      }
    }

    developer.log('Connection issue simulation completed', name: 'WebSocketDevTools');
  }

  /// Run load test by sending multiple messages
  Future<void> startLoadTest({
    int messagesPerSecond = 10,
    Duration duration = const Duration(minutes: 1),
    String testChannel = 'load_test',
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Development tools not available in release mode');
    }

    if (_isLoadTesting) {
      throw StateError('Load test already running');
    }

    _isLoadTesting = true;
    final startTime = DateTime.now();
    int messagesSent = 0;

    developer.log(
      'Starting load test: ${messagesPerSecond}msg/s for ${duration.inSeconds}s',
      name: 'WebSocketDevTools',
    );

    _debugLogger.logConfigurationChange(
      'loadTest',
      null,
      {
        'messagesPerSecond': messagesPerSecond,
        'durationSeconds': duration.inSeconds,
        'testChannel': testChannel,
      },
    );

    final interval = Duration(milliseconds: (1000 / messagesPerSecond).round());
    
    _loadTestTimer = Timer.periodic(interval, (timer) {
      if (DateTime.now().difference(startTime) >= duration) {
        stopLoadTest();
        return;
      }

      if (_webSocketService.currentState == WebSocketConnectionState.connected) {
        final message = {
          'type': 'load_test',
          'messageId': messagesSent,
          'timestamp': DateTime.now().toIso8601String(),
          'payload': _generateTestPayload(),
        };

        // Simulate sending message (actual implementation would depend on WebSocket service)
        _monitor.recordMessageSent(testChannel, message);
        _debugLogger.logMessageSent(testChannel, message, messageId: messagesSent.toString());
        
        messagesSent++;
      }
    });

    // Auto-stop after duration
    Timer(duration, () {
      if (_isLoadTesting) {
        stopLoadTest();
      }
    });
  }

  /// Stop load test
  void stopLoadTest() {
    if (!_isLoadTesting) return;

    _loadTestTimer?.cancel();
    _loadTestTimer = null;
    _isLoadTesting = false;

    developer.log('Load test stopped', name: 'WebSocketDevTools');
  }

  /// Test connection stability by repeatedly connecting/disconnecting
  Future<void> startConnectionStabilityTest({
    int cycles = 10,
    Duration cycleInterval = const Duration(seconds: 5),
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Development tools not available in release mode');
    }

    if (_isConnectionTesting) {
      throw StateError('Connection test already running');
    }

    _isConnectionTesting = true;
    
    developer.log(
      'Starting connection stability test: $cycles cycles every ${cycleInterval.inSeconds}s',
      name: 'WebSocketDevTools',
    );

    _debugLogger.logConfigurationChange(
      'connectionStabilityTest',
      null,
      {
        'cycles': cycles,
        'cycleIntervalSeconds': cycleInterval.inSeconds,
      },
    );

    int completedCycles = 0;

    _connectionTestTimer = Timer.periodic(cycleInterval, (timer) async {
      if (completedCycles >= cycles) {
        stopConnectionStabilityTest();
        return;
      }

      developer.log('Connection test cycle ${completedCycles + 1}/$cycles', name: 'WebSocketDevTools');

      try {
        // Disconnect if connected
        if (_webSocketService.currentState == WebSocketConnectionState.connected) {
          await _webSocketService.disconnect();
          await Future.delayed(const Duration(seconds: 1));
        }

        // Reconnect
        await _webSocketService.connect();
        completedCycles++;
        
      } catch (e) {
        developer.log('Connection test cycle failed: $e', name: 'WebSocketDevTools');
        _debugLogger.logError(
          WebSocketError(
            type: WebSocketErrorType.serverError,
            message: 'Connection test cycle failed: $e',
            timestamp: DateTime.now(),
            isRecoverable: true,
          ),
          context: 'connectionStabilityTest',
        );
      }
    });
  }

  /// Stop connection stability test
  void stopConnectionStabilityTest() {
    if (!_isConnectionTesting) return;

    _connectionTestTimer?.cancel();
    _connectionTestTimer = null;
    _isConnectionTesting = false;

    developer.log('Connection stability test stopped', name: 'WebSocketDevTools');
  }

  /// Inject test messages to simulate server responses
  void injectTestMessage({
    required String channel,
    Map<String, dynamic>? data,
    WebSocketDebugEventType eventType = WebSocketDebugEventType.messageReceived,
  }) {
    if (!isAvailable) {
      throw UnsupportedError('Development tools not available in release mode');
    }

    final testData = data ?? _generateTestPayload();
    final processingStart = DateTime.now();
    
    // Simulate message processing
    Future.delayed(Duration(milliseconds: math.Random().nextInt(50)), () {
      final processingTime = DateTime.now().difference(processingStart);
      
      _monitor.recordMessageReceived(channel, testData, processingTime: processingTime);
      _debugLogger.logMessageReceived(channel, testData, processingTime: processingTime);
    });

    developer.log('Test message injected to channel: $channel', name: 'WebSocketDevTools');
  }

  /// Generate test error for error handling testing
  void injectTestError({
    WebSocketErrorType errorType = WebSocketErrorType.networkError,
    String? customMessage,
  }) {
    if (!isAvailable) {
      throw UnsupportedError('Development tools not available in release mode');
    }

    final error = WebSocketError(
      type: errorType,
      message: customMessage ?? 'Test error: ${errorType.name}',
      timestamp: DateTime.now(),
      isRecoverable: errorType != WebSocketErrorType.authenticationFailed,
    );

    _monitor.recordError(error);
    _debugLogger.logError(error, context: 'testErrorInjection');

    developer.log('Test error injected: ${error.type.name}', name: 'WebSocketDevTools');
  }

  /// Get comprehensive debug report
  Map<String, dynamic> generateDebugReport() {
    final events = _debugLogger.events;
    final metrics = _monitor.currentMetrics;
    
    return {
      'reportGeneratedAt': DateTime.now().toIso8601String(),
      'serviceStatus': getServiceStatus(),
      'metrics': metrics.toJson(),
      'performanceReport': _monitor.getPerformanceReport(),
      'debugSession': _debugLogger.currentSession?.toJson(),
      'eventSummary': _generateEventSummary(events),
      'errorAnalysis': _generateErrorAnalysis(events),
      'connectionAnalysis': _generateConnectionAnalysis(events),
      'recommendations': _generateRecommendations(metrics, events),
    };
  }

  Map<String, dynamic> _generateEventSummary(List<WebSocketDebugEvent> events) {
    final eventCounts = <String, int>{};
    final eventsByHour = <int, int>{};
    
    for (final event in events) {
      // Count by type
      eventCounts[event.type.name] = (eventCounts[event.type.name] ?? 0) + 1;
      
      // Count by hour
      final hour = event.timestamp.hour;
      eventsByHour[hour] = (eventsByHour[hour] ?? 0) + 1;
    }
    
    return {
      'totalEvents': events.length,
      'eventsByType': eventCounts,
      'eventsByHour': eventsByHour,
      'timeRange': events.isNotEmpty ? {
        'start': events.first.timestamp.toIso8601String(),
        'end': events.last.timestamp.toIso8601String(),
      } : null,
    };
  }

  Map<String, dynamic> _generateErrorAnalysis(List<WebSocketDebugEvent> events) {
    final errorEvents = events.where((e) => e.error != null).toList();
    final errorTypes = <String, int>{};
    final errorsByHour = <int, int>{};
    
    for (final event in errorEvents) {
      final errorType = event.error!.type.name;
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
      
      final hour = event.timestamp.hour;
      errorsByHour[hour] = (errorsByHour[hour] ?? 0) + 1;
    }
    
    return {
      'totalErrors': errorEvents.length,
      'errorsByType': errorTypes,
      'errorsByHour': errorsByHour,
      'errorRate': events.isNotEmpty ? errorEvents.length / events.length : 0.0,
      'mostCommonError': errorTypes.isNotEmpty 
          ? errorTypes.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  Map<String, dynamic> _generateConnectionAnalysis(List<WebSocketDebugEvent> events) {
    final connectionEvents = events.where((e) => 
      e.type == WebSocketDebugEventType.connectionAttempt ||
      e.type == WebSocketDebugEventType.connectionSuccess ||
      e.type == WebSocketDebugEventType.connectionFailure ||
      e.type == WebSocketDebugEventType.disconnection
    ).toList();
    
    int attempts = 0;
    int successes = 0;
    int failures = 0;
    int disconnections = 0;
    
    for (final event in connectionEvents) {
      switch (event.type) {
        case WebSocketDebugEventType.connectionAttempt:
          attempts++;
          break;
        case WebSocketDebugEventType.connectionSuccess:
          successes++;
          break;
        case WebSocketDebugEventType.connectionFailure:
          failures++;
          break;
        case WebSocketDebugEventType.disconnection:
          disconnections++;
          break;
        default:
          break;
      }
    }
    
    return {
      'connectionAttempts': attempts,
      'successfulConnections': successes,
      'failedConnections': failures,
      'disconnections': disconnections,
      'successRate': attempts > 0 ? successes / attempts : 0.0,
      'failureRate': attempts > 0 ? failures / attempts : 0.0,
    };
  }

  List<String> _generateRecommendations(WebSocketMetrics metrics, List<WebSocketDebugEvent> events) {
    final recommendations = <String>[];
    
    // Connection quality recommendations
    if (metrics.connectionQualityScore < 70) {
      recommendations.add('Connection quality is poor (${metrics.connectionQualityScore}/100). Consider checking network stability.');
    }
    
    // Error rate recommendations
    final errorRate = metrics.connectionAttempts > 0 
        ? metrics.errorCount / metrics.connectionAttempts 
        : 0.0;
    
    if (errorRate > 0.1) {
      recommendations.add('High error rate detected (${(errorRate * 100).toStringAsFixed(1)}%). Review error logs and connection settings.');
    }
    
    // Reconnection recommendations
    if (metrics.reconnectionAttempts > metrics.successfulConnections * 0.5) {
      recommendations.add('Frequent reconnections detected. Consider increasing heartbeat interval or checking network stability.');
    }
    
    // Authentication recommendations
    if (metrics.authenticationFailures > 0) {
      recommendations.add('Authentication failures detected. Verify token refresh mechanism and server authentication settings.');
    }
    
    // Performance recommendations
    if (metrics.averageMessageProcessingTimeMs > 100) {
      recommendations.add('Message processing time is high (${metrics.averageMessageProcessingTimeMs.toStringAsFixed(1)}ms). Consider optimizing message handlers.');
    }
    
    return recommendations;
  }

  Map<String, dynamic> _generateTestPayload() {
    final random = math.Random();
    return {
      'id': random.nextInt(10000),
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'value': random.nextDouble() * 100,
        'status': ['active', 'inactive', 'pending'][random.nextInt(3)],
        'metadata': {
          'source': 'dev_tools',
          'version': '1.0.0',
        },
      },
    };
  }

  bool _isDebugMode() {
    // In Flutter, this would typically check kDebugMode
    // For now, we'll assume debug mode is available
    return true;
  }

  /// Export all debugging data
  Map<String, dynamic> exportAllData() {
    return {
      'debugReport': generateDebugReport(),
      'debugSession': _debugLogger.exportSession(),
      'performanceReport': _monitor.getPerformanceReport(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Reset all monitoring data
  void resetAllData() {
    _monitor.resetMetrics();
    _debugLogger.clearEvents();
    
    developer.log('All WebSocket debugging data reset', name: 'WebSocketDevTools');
  }

  /// Dispose resources
  void dispose() {
    stopLoadTest();
    stopConnectionStabilityTest();
    
    developer.log('WebSocket development tools disposed', name: 'WebSocketDevTools');
  }
}