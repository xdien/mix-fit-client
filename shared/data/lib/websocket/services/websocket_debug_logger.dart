import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/websocket_debug_event.dart';
import '../models/websocket_connection_state.dart';

/// Debug logger for WebSocket operations
class WebSocketDebugLogger {
  final WebSocketDebugConfig _config;
  final StreamController<WebSocketDebugEvent> _eventController = 
      StreamController<WebSocketDebugEvent>.broadcast();
  
  final List<WebSocketDebugEvent> _events = [];
  WebSocketDebugSession? _currentSession;
  IOSink? _fileLogger;
  
  WebSocketDebugLogger(this._config) {
    _initializeLogging();
  }

  /// Stream of debug events
  Stream<WebSocketDebugEvent> get eventStream => _eventController.stream;
  
  /// Get current debug session
  WebSocketDebugSession? get currentSession => _currentSession;
  
  /// Get all recorded events
  List<WebSocketDebugEvent> get events => List.unmodifiable(_events);

  void _initializeLogging() {
    if (_config.enableEventTracking) {
      _startDebugSession();
    }
    
    if (_config.enableFileLogging && _config.fileLoggingPath != null) {
      _initializeFileLogging();
    }
    
    developer.log(
      'WebSocket debug logger initialized (logging: ${_config.enableLogging}, tracking: ${_config.enableEventTracking})',
      name: 'WebSocketDebugLogger',
    );
  }

  void _startDebugSession() {
    _currentSession = WebSocketDebugSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      events: [],
    );
    
    developer.log('Debug session started: ${_currentSession!.sessionId}', name: 'WebSocketDebugLogger');
  }

  void _initializeFileLogging() {
    try {
      final file = File(_config.fileLoggingPath!);
      _fileLogger = file.openWrite(mode: FileMode.append);
      
      _fileLogger!.writeln('=== WebSocket Debug Session Started: ${DateTime.now().toIso8601String()} ===');
      
      developer.log('File logging initialized: ${_config.fileLoggingPath}', name: 'WebSocketDebugLogger');
    } catch (e) {
      developer.log('Failed to initialize file logging: $e', name: 'WebSocketDebugLogger');
    }
  }

  /// Log a connection attempt
  void logConnectionAttempt(String url, {Map<String, dynamic>? metadata}) {
    _logEvent(
      WebSocketDebugEventType.connectionAttempt,
      'Attempting to connect to $url',
      data: {
        'url': url,
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log a successful connection
  void logConnectionSuccess(String url, {Duration? connectionTime}) {
    _logEvent(
      WebSocketDebugEventType.connectionSuccess,
      'Successfully connected to $url',
      data: {
        'url': url,
        if (connectionTime != null) 'connectionTimeMs': connectionTime.inMilliseconds,
      },
      duration: connectionTime,
    );
  }

  /// Log a connection failure
  void logConnectionFailure(String url, WebSocketError error, {int? attemptNumber}) {
    _logEvent(
      WebSocketDebugEventType.connectionFailure,
      'Failed to connect to $url: ${error.message}',
      data: {
        'url': url,
        'errorType': error.type.name,
        'errorMessage': error.message,
        'isRecoverable': error.isRecoverable,
      },
      error: error,
      attemptNumber: attemptNumber,
    );
  }

  /// Log a disconnection
  void logDisconnection(String? reason, {bool wasExpected = false}) {
    _logEvent(
      WebSocketDebugEventType.disconnection,
      'Disconnected${reason != null ? ': $reason' : ''}',
      data: {
        'reason': reason,
        'wasExpected': wasExpected,
      },
    );
  }

  /// Log a message being sent
  void logMessageSent(String channel, Map<String, dynamic> message, {String? messageId}) {
    if (!_shouldLogEventType(WebSocketDebugEventType.messageSent)) return;
    
    _logEvent(
      WebSocketDebugEventType.messageSent,
      'Message sent to channel: $channel',
      data: {
        'channel': channel,
        'messageSize': _calculateMessageSize(message),
        'messageId': messageId,
        if (_config.logLevel == WebSocketDebugLogLevel.verbose) 'message': message,
      },
      channel: channel,
    );
  }

  /// Log a message being received
  void logMessageReceived(String channel, Map<String, dynamic> message, {Duration? processingTime}) {
    if (!_shouldLogEventType(WebSocketDebugEventType.messageReceived)) return;
    
    _logEvent(
      WebSocketDebugEventType.messageReceived,
      'Message received from channel: $channel',
      data: {
        'channel': channel,
        'messageSize': _calculateMessageSize(message),
        if (processingTime != null) 'processingTimeMs': processingTime.inMilliseconds,
        if (_config.logLevel == WebSocketDebugLogLevel.verbose) 'message': message,
      },
      channel: channel,
      duration: processingTime,
    );
  }

  /// Log a subscription operation
  void logSubscription(String channel, {bool isResubscription = false}) {
    _logEvent(
      WebSocketDebugEventType.subscriptionAdded,
      '${isResubscription ? 'Resubscribed' : 'Subscribed'} to channel: $channel',
      data: {
        'channel': channel,
        'isResubscription': isResubscription,
      },
      channel: channel,
    );
  }

  /// Log an unsubscription operation
  void logUnsubscription(String channel) {
    _logEvent(
      WebSocketDebugEventType.subscriptionRemoved,
      'Unsubscribed from channel: $channel',
      data: {
        'channel': channel,
      },
      channel: channel,
    );
  }

  /// Log a state change
  void logStateChange(WebSocketConnectionState oldState, WebSocketConnectionState newState) {
    _logEvent(
      WebSocketDebugEventType.stateChange,
      'State changed from ${oldState.name} to ${newState.name}',
      data: {
        'oldState': oldState.name,
        'newState': newState.name,
      },
      connectionState: newState,
    );
  }

  /// Log an error
  void logError(WebSocketError error, {String? context}) {
    _logEvent(
      WebSocketDebugEventType.error,
      'Error occurred${context != null ? ' in $context' : ''}: ${error.message}',
      data: {
        'errorType': error.type.name,
        'errorMessage': error.message,
        'isRecoverable': error.isRecoverable,
        if (context != null) 'context': context,
        if (error.originalError != null) 'originalError': error.originalError.toString(),
      },
      error: error,
      attemptNumber: error.attemptNumber,
    );
  }

  /// Log a heartbeat event
  void logHeartbeat(String type, {Map<String, dynamic>? data}) {
    if (!_shouldLogEventType(WebSocketDebugEventType.heartbeat)) return;
    
    _logEvent(
      WebSocketDebugEventType.heartbeat,
      'Heartbeat $type',
      data: {
        'type': type,
        if (data != null) ...data,
      },
    );
  }

  /// Log an authentication event
  void logAuthentication(String event, {bool success = true, String? error}) {
    _logEvent(
      WebSocketDebugEventType.authentication,
      'Authentication $event${success ? ' successful' : ' failed'}',
      data: {
        'event': event,
        'success': success,
        if (error != null) 'error': error,
      },
    );
  }

  /// Log a token refresh event
  void logTokenRefresh(bool success, {String? error}) {
    _logEvent(
      WebSocketDebugEventType.tokenRefresh,
      'Token refresh ${success ? 'successful' : 'failed'}',
      data: {
        'success': success,
        if (error != null) 'error': error,
      },
    );
  }

  /// Log a network change event
  void logNetworkChange(bool isConnected, {String? networkType}) {
    _logEvent(
      WebSocketDebugEventType.networkChange,
      'Network ${isConnected ? 'connected' : 'disconnected'}',
      data: {
        'isConnected': isConnected,
        if (networkType != null) 'networkType': networkType,
      },
    );
  }

  /// Log an app lifecycle change
  void logAppLifecycleChange(String state, {String? action}) {
    _logEvent(
      WebSocketDebugEventType.appLifecycleChange,
      'App lifecycle changed to $state',
      data: {
        'state': state,
        if (action != null) 'action': action,
      },
    );
  }

  /// Log a configuration change
  void logConfigurationChange(String setting, dynamic oldValue, dynamic newValue) {
    _logEvent(
      WebSocketDebugEventType.configurationChange,
      'Configuration changed: $setting',
      data: {
        'setting': setting,
        'oldValue': oldValue,
        'newValue': newValue,
      },
    );
  }

  void _logEvent(
    WebSocketDebugEventType type,
    String message, {
    Map<String, dynamic>? data,
    WebSocketConnectionState? connectionState,
    String? channel,
    Duration? duration,
    WebSocketError? error,
    int? attemptNumber,
  }) {
    if (!_config.enableLogging && !_config.enableEventTracking) return;
    
    final event = WebSocketDebugEvent(
      type: type,
      timestamp: DateTime.now(),
      message: message,
      data: data,
      connectionState: connectionState,
      channel: channel,
      duration: duration,
      error: error,
      attemptNumber: attemptNumber,
      instanceId: _currentSession?.sessionId,
    );

    // Add to events list if tracking is enabled
    if (_config.enableEventTracking) {
      _events.add(event);
      
      // Maintain max events limit
      if (_events.length > _config.maxEventsInMemory) {
        _events.removeAt(0);
      }
      
      // Add to current session
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          events: [..._currentSession!.events, event],
        );
      }
    }

    // Emit event to stream
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }

    // Log to console if enabled and appropriate log level
    if (_config.enableConsoleOutput && _shouldLogToConsole(type)) {
      _logToConsole(event);
    }

    // Log to file if enabled
    if (_config.enableFileLogging && _fileLogger != null) {
      _logToFile(event);
    }
  }

  bool _shouldLogEventType(WebSocketDebugEventType type) {
    if (_config.trackedEventTypes.isEmpty) return true;
    return _config.trackedEventTypes.contains(type);
  }

  bool _shouldLogToConsole(WebSocketDebugEventType type) {
    switch (_config.logLevel) {
      case WebSocketDebugLogLevel.verbose:
        return true;
      case WebSocketDebugLogLevel.debug:
        return type != WebSocketDebugEventType.heartbeat;
      case WebSocketDebugLogLevel.info:
        return ![
          WebSocketDebugEventType.heartbeat,
          WebSocketDebugEventType.messageSent,
          WebSocketDebugEventType.messageReceived,
        ].contains(type);
      case WebSocketDebugLogLevel.warning:
        return [
          WebSocketDebugEventType.error,
          WebSocketDebugEventType.connectionFailure,
          WebSocketDebugEventType.disconnection,
        ].contains(type);
      case WebSocketDebugLogLevel.error:
        return type == WebSocketDebugEventType.error;
    }
  }

  void _logToConsole(WebSocketDebugEvent event) {
    final prefix = '[${event.timestamp.toIso8601String()}] [${event.type.name.toUpperCase()}]';
    final message = '$prefix ${event.message}';
    
    if (kDebugMode) {
      switch (event.type) {
        case WebSocketDebugEventType.error:
        case WebSocketDebugEventType.connectionFailure:
          developer.log(message, name: 'WebSocketDebug', error: event.error?.originalError);
          break;
        default:
          developer.log(message, name: 'WebSocketDebug');
          break;
      }
    }
  }

  void _logToFile(WebSocketDebugEvent event) {
    try {
      final logEntry = {
        'timestamp': event.timestamp.toIso8601String(),
        'type': event.type.name,
        'message': event.message,
        if (event.data != null) 'data': event.data,
        if (event.connectionState != null) 'connectionState': event.connectionState!.name,
        if (event.channel != null) 'channel': event.channel,
        if (event.duration != null) 'durationMs': event.duration!.inMilliseconds,
        if (event.error != null) 'error': {
          'type': event.error!.type.name,
          'message': event.error!.message,
          'isRecoverable': event.error!.isRecoverable,
        },
        if (event.attemptNumber != null) 'attemptNumber': event.attemptNumber,
      };
      
      _fileLogger!.writeln(jsonEncode(logEntry));
    } catch (e) {
      developer.log('Failed to write to log file: $e', name: 'WebSocketDebugLogger');
    }
  }

  int _calculateMessageSize(Map<String, dynamic> message) {
    final jsonString = jsonEncode(message);
    return jsonString.length;
  }

  /// Get events filtered by type
  List<WebSocketDebugEvent> getEventsByType(WebSocketDebugEventType type) {
    return _events.where((event) => event.type == type).toList();
  }

  /// Get events within a time range
  List<WebSocketDebugEvent> getEventsInTimeRange(DateTime start, DateTime end) {
    return _events.where((event) => 
      event.timestamp.isAfter(start) && event.timestamp.isBefore(end)
    ).toList();
  }

  /// Get error events only
  List<WebSocketDebugEvent> getErrorEvents() {
    return _events.where((event) => event.error != null).toList();
  }

  /// Export debug session to JSON
  Map<String, dynamic> exportSession() {
    return {
      'session': _currentSession?.toJson(),
      'events': _events.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all events
  void clearEvents() {
    _events.clear();
    developer.log('Debug events cleared', name: 'WebSocketDebugLogger');
  }

  /// End current debug session
  void endSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
      );
      
      developer.log('Debug session ended: ${_currentSession!.sessionId}', name: 'WebSocketDebugLogger');
    }
  }

  /// Update debug configuration
  void updateConfig(WebSocketDebugConfig newConfig) {
    final oldConfig = _config;
    
    // Log configuration change
    logConfigurationChange('debugConfig', oldConfig.toJson(), newConfig.toJson());
    
    // Reinitialize if file logging settings changed
    if (oldConfig.enableFileLogging != newConfig.enableFileLogging ||
        oldConfig.fileLoggingPath != newConfig.fileLoggingPath) {
      _fileLogger?.close();
      _fileLogger = null;
      
      if (newConfig.enableFileLogging && newConfig.fileLoggingPath != null) {
        _initializeFileLogging();
      }
    }
    
    developer.log('Debug configuration updated', name: 'WebSocketDebugLogger');
  }

  /// Dispose resources
  void dispose() {
    endSession();
    _fileLogger?.close();
    _eventController.close();
    
    developer.log('WebSocket debug logger disposed', name: 'WebSocketDebugLogger');
  }
}