import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_metrics.freezed.dart';
part 'websocket_metrics.g.dart';

/// Performance metrics for WebSocket connections
@freezed
class WebSocketMetrics with _$WebSocketMetrics {
  const factory WebSocketMetrics({
    /// Total number of connection attempts
    @Default(0) int connectionAttempts,
    
    /// Number of successful connections
    @Default(0) int successfulConnections,
    
    /// Number of failed connections
    @Default(0) int failedConnections,
    
    /// Total number of reconnection attempts
    @Default(0) int reconnectionAttempts,
    
    /// Number of messages sent
    @Default(0) int messagesSent,
    
    /// Number of messages received
    @Default(0) int messagesReceived,
    
    /// Number of subscription operations
    @Default(0) int subscriptions,
    
    /// Number of unsubscription operations
    @Default(0) int unsubscriptions,
    
    /// Total connection uptime in milliseconds
    @Default(0) int totalUptimeMs,
    
    /// Current connection duration in milliseconds
    @Default(0) int currentConnectionDurationMs,
    
    /// Average connection duration in milliseconds
    @Default(0) double averageConnectionDurationMs,
    
    /// Average message processing time in milliseconds
    @Default(0) double averageMessageProcessingTimeMs,
    
    /// Number of errors encountered
    @Default(0) int errorCount,
    
    /// Number of heartbeat timeouts
    @Default(0) int heartbeatTimeouts,
    
    /// Number of authentication failures
    @Default(0) int authenticationFailures,
    
    /// Number of network errors
    @Default(0) int networkErrors,
    
    /// Last connection timestamp
    DateTime? lastConnectionTime,
    
    /// Last disconnection timestamp
    DateTime? lastDisconnectionTime,
    
    /// Last error timestamp
    DateTime? lastErrorTime,
    
    /// Connection quality score (0-100)
    @Default(0) int connectionQualityScore,
    
    /// Data transfer statistics
    @Default(WebSocketDataTransferStats()) WebSocketDataTransferStats dataTransfer,
  }) = _WebSocketMetrics;

  factory WebSocketMetrics.fromJson(Map<String, dynamic> json) =>
      _$WebSocketMetricsFromJson(json);
}

/// Data transfer statistics for WebSocket connections
@freezed
class WebSocketDataTransferStats with _$WebSocketDataTransferStats {
  const factory WebSocketDataTransferStats({
    /// Total bytes sent
    @Default(0) int bytesSent,
    
    /// Total bytes received
    @Default(0) int bytesReceived,
    
    /// Average message size in bytes
    @Default(0) double averageMessageSize,
    
    /// Peak message rate (messages per second)
    @Default(0) double peakMessageRate,
    
    /// Current message rate (messages per second)
    @Default(0) double currentMessageRate,
  }) = _WebSocketDataTransferStats;

  factory WebSocketDataTransferStats.fromJson(Map<String, dynamic> json) =>
      _$WebSocketDataTransferStatsFromJson(json);
}

/// Connection health status
enum WebSocketHealthStatus {
  excellent,
  good,
  fair,
  poor,
  critical
}

/// Health check result for WebSocket connection
@freezed
class WebSocketHealthCheck with _$WebSocketHealthCheck {
  const factory WebSocketHealthCheck({
    required WebSocketHealthStatus status,
    required int score,
    required DateTime timestamp,
    required List<String> issues,
    required Map<String, dynamic> details,
  }) = _WebSocketHealthCheck;

  factory WebSocketHealthCheck.fromJson(Map<String, dynamic> json) =>
      _$WebSocketHealthCheckFromJson(json);
}