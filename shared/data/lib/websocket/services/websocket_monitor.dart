import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../models/websocket_metrics.dart';
import '../models/websocket_debug_event.dart';
import '../models/websocket_connection_state.dart';
import '../interfaces/i_websocket_service.dart';

/// Monitors WebSocket connections and collects performance metrics
class WebSocketMonitor {
  final IWebSocketService _webSocketService;
  final StreamController<WebSocketMetrics> _metricsController = 
      StreamController<WebSocketMetrics>.broadcast();
  final StreamController<WebSocketHealthCheck> _healthController = 
      StreamController<WebSocketHealthCheck>.broadcast();
  
  WebSocketMetrics _currentMetrics = const WebSocketMetrics();
  DateTime? _connectionStartTime;
  DateTime? _lastMessageTime;
  final List<Duration> _connectionDurations = [];
  final List<Duration> _messageProcessingTimes = [];
  final List<DateTime> _messageTimestamps = [];
  Timer? _metricsUpdateTimer;
  Timer? _healthCheckTimer;
  
  // Performance tracking
  int _messagesInLastSecond = 0;
  DateTime _lastSecondStart = DateTime.now();
  
  WebSocketMonitor(this._webSocketService) {
    _setupMonitoring();
  }

  /// Stream of WebSocket metrics updates
  Stream<WebSocketMetrics> get metricsStream => _metricsController.stream;
  
  /// Stream of health check results
  Stream<WebSocketHealthCheck> get healthStream => _healthController.stream;
  
  /// Get current metrics
  WebSocketMetrics get currentMetrics => _currentMetrics;

  void _setupMonitoring() {
    // Monitor connection state changes
    _webSocketService.connectionState.listen(_onConnectionStateChanged);
    
    // Start periodic metrics updates
    _metricsUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateMetrics(),
    );
    
    // Start periodic health checks
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performHealthCheck(),
    );
    
    developer.log('WebSocket monitoring started', name: 'WebSocketMonitor');
  }

  void _onConnectionStateChanged(WebSocketConnectionState state) {
    final now = DateTime.now();
    
    switch (state) {
      case WebSocketConnectionState.connecting:
        _recordConnectionAttempt();
        break;
        
      case WebSocketConnectionState.connected:
        _connectionStartTime = now;
        _recordSuccessfulConnection();
        break;
        
      case WebSocketConnectionState.disconnected:
        _recordDisconnection();
        break;
        
      case WebSocketConnectionState.reconnecting:
        _recordReconnectionAttempt();
        break;
        
      case WebSocketConnectionState.error:
        _recordConnectionFailure();
        break;
    }
    
    _updateMetrics();
  }

  void _recordConnectionAttempt() {
    _currentMetrics = _currentMetrics.copyWith(
      connectionAttempts: _currentMetrics.connectionAttempts + 1,
    );
  }

  void _recordSuccessfulConnection() {
    _currentMetrics = _currentMetrics.copyWith(
      successfulConnections: _currentMetrics.successfulConnections + 1,
      lastConnectionTime: DateTime.now(),
    );
  }

  void _recordConnectionFailure() {
    _currentMetrics = _currentMetrics.copyWith(
      failedConnections: _currentMetrics.failedConnections + 1,
      errorCount: _currentMetrics.errorCount + 1,
      lastErrorTime: DateTime.now(),
    );
  }

  void _recordDisconnection() {
    final now = DateTime.now();
    
    if (_connectionStartTime != null) {
      final duration = now.difference(_connectionStartTime!);
      _connectionDurations.add(duration);
      
      // Keep only last 100 connection durations for average calculation
      if (_connectionDurations.length > 100) {
        _connectionDurations.removeAt(0);
      }
      
      final averageDuration = _connectionDurations.isEmpty
          ? 0.0
          : _connectionDurations
              .map((d) => d.inMilliseconds)
              .reduce((a, b) => a + b) / _connectionDurations.length;
      
      _currentMetrics = _currentMetrics.copyWith(
        totalUptimeMs: _currentMetrics.totalUptimeMs + duration.inMilliseconds,
        averageConnectionDurationMs: averageDuration,
        lastDisconnectionTime: now,
        currentConnectionDurationMs: 0,
      );
    }
    
    _connectionStartTime = null;
  }

  void _recordReconnectionAttempt() {
    _currentMetrics = _currentMetrics.copyWith(
      reconnectionAttempts: _currentMetrics.reconnectionAttempts + 1,
    );
  }

  /// Record a message being sent
  void recordMessageSent(String channel, Map<String, dynamic> data) {
    final messageSize = _calculateMessageSize(data);
    
    _currentMetrics = _currentMetrics.copyWith(
      messagesSent: _currentMetrics.messagesSent + 1,
      dataTransfer: _currentMetrics.dataTransfer.copyWith(
        bytesSent: _currentMetrics.dataTransfer.bytesSent + messageSize,
      ),
    );
    
    _updateMessageRate();
    _updateAverageMessageSize(messageSize);
  }

  /// Record a message being received
  void recordMessageReceived(String channel, Map<String, dynamic> data, {Duration? processingTime}) {
    final messageSize = _calculateMessageSize(data);
    final now = DateTime.now();
    
    _currentMetrics = _currentMetrics.copyWith(
      messagesReceived: _currentMetrics.messagesReceived + 1,
      dataTransfer: _currentMetrics.dataTransfer.copyWith(
        bytesReceived: _currentMetrics.dataTransfer.bytesReceived + messageSize,
      ),
    );
    
    if (processingTime != null) {
      _messageProcessingTimes.add(processingTime);
      
      // Keep only last 100 processing times for average calculation
      if (_messageProcessingTimes.length > 100) {
        _messageProcessingTimes.removeAt(0);
      }
      
      final averageProcessingTime = _messageProcessingTimes.isEmpty
          ? 0.0
          : _messageProcessingTimes
              .map((d) => d.inMicroseconds)
              .reduce((a, b) => a + b) / _messageProcessingTimes.length / 1000;
      
      _currentMetrics = _currentMetrics.copyWith(
        averageMessageProcessingTimeMs: averageProcessingTime,
      );
    }
    
    _lastMessageTime = now;
    _updateMessageRate();
    _updateAverageMessageSize(messageSize);
  }

  /// Record a subscription operation
  void recordSubscription(String channel) {
    _currentMetrics = _currentMetrics.copyWith(
      subscriptions: _currentMetrics.subscriptions + 1,
    );
  }

  /// Record an unsubscription operation
  void recordUnsubscription(String channel) {
    _currentMetrics = _currentMetrics.copyWith(
      unsubscriptions: _currentMetrics.unsubscriptions + 1,
    );
  }

  /// Record an error occurrence
  void recordError(WebSocketError error) {
    _currentMetrics = _currentMetrics.copyWith(
      errorCount: _currentMetrics.errorCount + 1,
      lastErrorTime: DateTime.now(),
    );
    
    // Track specific error types
    switch (error.type) {
      case WebSocketErrorType.heartbeatTimeout:
        _currentMetrics = _currentMetrics.copyWith(
          heartbeatTimeouts: _currentMetrics.heartbeatTimeouts + 1,
        );
        break;
      case WebSocketErrorType.authenticationFailed:
      case WebSocketErrorType.tokenExpired:
      case WebSocketErrorType.tokenRefreshFailed:
        _currentMetrics = _currentMetrics.copyWith(
          authenticationFailures: _currentMetrics.authenticationFailures + 1,
        );
        break;
      case WebSocketErrorType.networkError:
      case WebSocketErrorType.connectionTimeout:
        _currentMetrics = _currentMetrics.copyWith(
          networkErrors: _currentMetrics.networkErrors + 1,
        );
        break;
      default:
        break;
    }
  }

  void _updateMessageRate() {
    final now = DateTime.now();
    
    // Reset counter if more than a second has passed
    if (now.difference(_lastSecondStart).inSeconds >= 1) {
      final currentRate = _messagesInLastSecond.toDouble();
      
      _currentMetrics = _currentMetrics.copyWith(
        dataTransfer: _currentMetrics.dataTransfer.copyWith(
          currentMessageRate: currentRate,
          peakMessageRate: math.max(
            _currentMetrics.dataTransfer.peakMessageRate,
            currentRate,
          ),
        ),
      );
      
      _messagesInLastSecond = 0;
      _lastSecondStart = now;
    }
    
    _messagesInLastSecond++;
  }

  void _updateAverageMessageSize(int messageSize) {
    final totalMessages = _currentMetrics.messagesSent + _currentMetrics.messagesReceived;
    final totalBytes = _currentMetrics.dataTransfer.bytesSent + _currentMetrics.dataTransfer.bytesReceived;
    
    final averageSize = totalMessages > 0 ? totalBytes / totalMessages : 0.0;
    
    _currentMetrics = _currentMetrics.copyWith(
      dataTransfer: _currentMetrics.dataTransfer.copyWith(
        averageMessageSize: averageSize,
      ),
    );
  }

  void _updateMetrics() {
    // Update current connection duration
    if (_connectionStartTime != null) {
      final duration = DateTime.now().difference(_connectionStartTime!);
      _currentMetrics = _currentMetrics.copyWith(
        currentConnectionDurationMs: duration.inMilliseconds,
      );
    }
    
    // Calculate connection quality score
    final qualityScore = _calculateConnectionQualityScore();
    _currentMetrics = _currentMetrics.copyWith(
      connectionQualityScore: qualityScore,
    );
    
    // Emit updated metrics
    if (!_metricsController.isClosed) {
      _metricsController.add(_currentMetrics);
    }
  }

  int _calculateConnectionQualityScore() {
    int score = 100;
    
    // Deduct points for errors
    final errorRate = _currentMetrics.connectionAttempts > 0
        ? _currentMetrics.errorCount / _currentMetrics.connectionAttempts
        : 0.0;
    score -= (errorRate * 30).round();
    
    // Deduct points for failed connections
    final failureRate = _currentMetrics.connectionAttempts > 0
        ? _currentMetrics.failedConnections / _currentMetrics.connectionAttempts
        : 0.0;
    score -= (failureRate * 25).round();
    
    // Deduct points for frequent reconnections
    final reconnectionRate = _currentMetrics.successfulConnections > 0
        ? _currentMetrics.reconnectionAttempts / _currentMetrics.successfulConnections
        : 0.0;
    score -= (reconnectionRate * 20).round();
    
    // Deduct points for heartbeat timeouts
    if (_currentMetrics.heartbeatTimeouts > 0) {
      score -= _currentMetrics.heartbeatTimeouts * 5;
    }
    
    // Deduct points for authentication failures
    if (_currentMetrics.authenticationFailures > 0) {
      score -= _currentMetrics.authenticationFailures * 10;
    }
    
    return math.max(0, math.min(100, score));
  }

  void _performHealthCheck() {
    final now = DateTime.now();
    final issues = <String>[];
    final details = <String, dynamic>{};
    
    // Check connection stability
    final connectionStability = _currentMetrics.connectionAttempts > 0
        ? _currentMetrics.successfulConnections / _currentMetrics.connectionAttempts
        : 0.0;
    
    if (connectionStability < 0.8) {
      issues.add('Low connection stability: ${(connectionStability * 100).toStringAsFixed(1)}%');
    }
    
    // Check error rate
    final errorRate = _currentMetrics.connectionAttempts > 0
        ? _currentMetrics.errorCount / _currentMetrics.connectionAttempts
        : 0.0;
    
    if (errorRate > 0.1) {
      issues.add('High error rate: ${(errorRate * 100).toStringAsFixed(1)}%');
    }
    
    // Check recent activity
    if (_lastMessageTime != null) {
      final timeSinceLastMessage = now.difference(_lastMessageTime!);
      if (timeSinceLastMessage.inMinutes > 10) {
        issues.add('No recent message activity (${timeSinceLastMessage.inMinutes} minutes)');
      }
    }
    
    // Check heartbeat timeouts
    if (_currentMetrics.heartbeatTimeouts > 0) {
      issues.add('Heartbeat timeouts detected: ${_currentMetrics.heartbeatTimeouts}');
    }
    
    // Determine health status
    final score = _currentMetrics.connectionQualityScore;
    final status = _getHealthStatus(score);
    
    details.addAll({
      'connectionStability': connectionStability,
      'errorRate': errorRate,
      'qualityScore': score,
      'totalConnections': _currentMetrics.successfulConnections,
      'totalErrors': _currentMetrics.errorCount,
      'uptime': _currentMetrics.totalUptimeMs,
    });
    
    final healthCheck = WebSocketHealthCheck(
      status: status,
      score: score,
      timestamp: now,
      issues: issues,
      details: details,
    );
    
    if (!_healthController.isClosed) {
      _healthController.add(healthCheck);
    }
    
    developer.log(
      'Health check completed: ${status.name} (score: $score)',
      name: 'WebSocketMonitor',
    );
  }

  WebSocketHealthStatus _getHealthStatus(int score) {
    if (score >= 90) return WebSocketHealthStatus.excellent;
    if (score >= 75) return WebSocketHealthStatus.good;
    if (score >= 60) return WebSocketHealthStatus.fair;
    if (score >= 40) return WebSocketHealthStatus.poor;
    return WebSocketHealthStatus.critical;
  }

  int _calculateMessageSize(Map<String, dynamic> data) {
    // Rough estimation of JSON message size
    final jsonString = data.toString();
    return jsonString.length * 2; // Approximate UTF-8 byte size
  }

  /// Reset all metrics
  void resetMetrics() {
    _currentMetrics = const WebSocketMetrics();
    _connectionDurations.clear();
    _messageProcessingTimes.clear();
    _messageTimestamps.clear();
    _connectionStartTime = null;
    _lastMessageTime = null;
    
    developer.log('WebSocket metrics reset', name: 'WebSocketMonitor');
  }

  /// Get detailed performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'metrics': _currentMetrics.toJson(),
      'connectionDurations': _connectionDurations.map((d) => d.inMilliseconds).toList(),
      'messageProcessingTimes': _messageProcessingTimes.map((d) => d.inMicroseconds).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _metricsUpdateTimer?.cancel();
    _healthCheckTimer?.cancel();
    _metricsController.close();
    _healthController.close();
    
    developer.log('WebSocket monitor disposed', name: 'WebSocketMonitor');
  }
}