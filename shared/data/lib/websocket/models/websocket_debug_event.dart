import 'package:freezed_annotation/freezed_annotation.dart';
import 'websocket_connection_state.dart';

part 'websocket_debug_event.freezed.dart';
part 'websocket_debug_event.g.dart';

/// Types of debug events that can occur in WebSocket operations
enum WebSocketDebugEventType {
  connectionAttempt,
  connectionSuccess,
  connectionFailure,
  disconnection,
  messageReceived,
  messageSent,
  subscriptionAdded,
  subscriptionRemoved,
  stateChange,
  error,
  heartbeat,
  authentication,
  tokenRefresh,
  networkChange,
  appLifecycleChange,
  configurationChange,
}

/// Debug event for WebSocket operations
@freezed
class WebSocketDebugEvent with _$WebSocketDebugEvent {
  const factory WebSocketDebugEvent({
    required WebSocketDebugEventType type,
    required DateTime timestamp,
    required String message,
    Map<String, dynamic>? data,
    WebSocketConnectionState? connectionState,
    String? channel,
    Duration? duration,
    @JsonKey(includeFromJson: false, includeToJson: false) WebSocketError? error,
    int? attemptNumber,
    String? instanceId,
  }) = _WebSocketDebugEvent;

  factory WebSocketDebugEvent.fromJson(Map<String, dynamic> json) =>
      _$WebSocketDebugEventFromJson(json);
}

/// Debug session information
@freezed
class WebSocketDebugSession with _$WebSocketDebugSession {
  const factory WebSocketDebugSession({
    required String sessionId,
    required DateTime startTime,
    DateTime? endTime,
    required List<WebSocketDebugEvent> events,
    @Default({}) Map<String, dynamic> metadata,
  }) = _WebSocketDebugSession;

  factory WebSocketDebugSession.fromJson(Map<String, dynamic> json) =>
      _$WebSocketDebugSessionFromJson(json);
}

/// Debug configuration settings
@freezed
class WebSocketDebugConfig with _$WebSocketDebugConfig {
  const factory WebSocketDebugConfig({
    /// Enable debug logging
    @Default(false) bool enableLogging,
    
    /// Enable event tracking
    @Default(false) bool enableEventTracking,
    
    /// Enable performance monitoring
    @Default(false) bool enablePerformanceMonitoring,
    
    /// Enable error analytics
    @Default(false) bool enableErrorAnalytics,
    
    /// Maximum number of events to keep in memory
    @Default(1000) int maxEventsInMemory,
    
    /// Log level for debug messages
    @Default(WebSocketDebugLogLevel.info) WebSocketDebugLogLevel logLevel,
    
    /// Event types to track
    @Default([]) List<WebSocketDebugEventType> trackedEventTypes,
    
    /// Enable console output
    @Default(true) bool enableConsoleOutput,
    
    /// Enable file logging
    @Default(false) bool enableFileLogging,
    
    /// File logging path
    String? fileLoggingPath,
  }) = _WebSocketDebugConfig;

  factory WebSocketDebugConfig.fromJson(Map<String, dynamic> json) =>
      _$WebSocketDebugConfigFromJson(json);
}

/// Debug log levels
enum WebSocketDebugLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}