import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import '../models/websocket_config.dart';
import '../models/websocket_subscription.dart';
import 'websocket_error_handler.dart';
import 'reconnection_strategy.dart';
import 'network_connectivity_detector.dart';

/// WebSocket service implementation with JWT authentication support
class WebSocketService implements IWebSocketService {
  IO.Socket? _socket;
  final WebSocketConfig _config;
  final StreamController<WebSocketConnectionState> _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final Map<String, WebSocketSubscription> _subscriptions = {};
  
  WebSocketConnectionState _currentState = WebSocketConnectionState.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;
  
  // Enhanced error handling and reconnection
  late final WebSocketErrorHandler _errorHandler;
  late final ReconnectionStrategy _reconnectionStrategy;
  late final NetworkConnectivityDetector _networkDetector;
  WebSocketError? _lastError;
  
  // Authentication callback to get JWT token
  final Future<String?> Function() _getAuthToken;
  
  // Token refresh callback
  final Future<String?> Function()? _refreshToken;

  WebSocketService(
    this._config, 
    this._getAuthToken, {
    Future<String?> Function()? refreshToken,
    WebSocketErrorHandler? errorHandler,
    ReconnectionStrategy? reconnectionStrategy,
    NetworkConnectivityDetector? networkDetector,
  }) : _refreshToken = refreshToken,
       _errorHandler = errorHandler ?? WebSocketErrorHandler(),
       _reconnectionStrategy = reconnectionStrategy ?? ReconnectionStrategy(),
       _networkDetector = networkDetector ?? NetworkConnectivityDetector() {
    _setupNetworkMonitoring();
  }

  @override
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  WebSocketConnectionState get currentState => _currentState;

  /// Stream of WebSocket errors
  Stream<WebSocketError> get errorStream => _errorHandler.errorStream;

  /// Get the last error that occurred
  WebSocketError? get lastError => _lastError;

  @override
  Future<void> connect() async {
    if (_currentState == WebSocketConnectionState.connected ||
        _currentState == WebSocketConnectionState.connecting) {
      developer.log('WebSocket already connected or connecting', name: 'WebSocketService');
      return;
    }

    _updateConnectionState(WebSocketConnectionState.connecting);
    _cancelConnectionTimeout();
    
    try {
      // Check network connectivity first
      if (!await _networkDetector.checkConnectivity()) {
        final networkError = _errorHandler.analyzeError(
          'No network connectivity',
          attemptNumber: _reconnectAttempts + 1,
        );
        _handleConnectionError(networkError);
        return;
      }

      // Get authentication token
      final token = await _getAuthToken();
      if (token == null) {
        final authError = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'No authentication token available',
          timestamp: DateTime.now(),
          attemptNumber: _reconnectAttempts + 1,
          isRecoverable: false,
        );
        _handleConnectionError(authError);
        return;
      }

      // Check if WebSocket server is reachable
      if (!await _networkDetector.isWebSocketServerReachable(_config.url)) {
        final serverError = WebSocketError(
          type: WebSocketErrorType.serverError,
          message: 'WebSocket server is not reachable',
          timestamp: DateTime.now(),
          attemptNumber: _reconnectAttempts + 1,
          isRecoverable: true,
        );
        _handleConnectionError(serverError);
        return;
      }

      // Create socket with authentication
      _socket = IO.io(_config.url, IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build());

      _setupSocketListeners();
      
      // Wait for connection with timeout
      final completer = Completer<void>();
      
      void onConnect() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      
      void onError(dynamic error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }
      
      _socket!.once('connect', (_) => onConnect());
      _socket!.once('connect_error', onError);
      
      // Set up connection timeout
      _connectionTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Connection timeout after 15 seconds'));
        }
      });
      
      await completer.future;
      _cancelConnectionTimeout();
      
      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _lastError = null;
      _startHeartbeat();
      _resubscribeChannels();
      
      developer.log('WebSocket connected successfully', name: 'WebSocketService');
      
    } catch (error) {
      _cancelConnectionTimeout();
      final wsError = _errorHandler.analyzeError(
        error,
        attemptNumber: _reconnectAttempts + 1,
      );
      _handleConnectionError(wsError);
    }
  }

  @override
  Future<void> disconnect() async {
    developer.log('Disconnecting WebSocket', name: 'WebSocketService');
    
    _cancelReconnectTimer();
    _cancelConnectionTimeout();
    _stopHeartbeat();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  @override
  void subscribe(String channel, Function(dynamic) callback) {
    developer.log('Subscribing to channel: $channel', name: 'WebSocketService');
    
    final subscription = WebSocketSubscription(
      channel: channel,
      callback: callback,
      subscribedAt: DateTime.now(),
    );
    _subscriptions[channel] = subscription;
    
    // If connected, subscribe immediately
    if (_currentState == WebSocketConnectionState.connected && _socket != null) {
      _socket!.emit('subscribe', {'channel': channel});
      _socket!.on(channel, callback);
    }
  }

  @override
  void unsubscribe(String channel) {
    developer.log('Unsubscribing from channel: $channel', name: 'WebSocketService');
    
    _subscriptions.remove(channel);
    
    if (_currentState == WebSocketConnectionState.connected && _socket != null) {
      _socket!.emit('unsubscribe', {'channel': channel});
      _socket!.off(channel);
    }
  }

  @override
  Future<void> handleAppLifecycle(AppLifecycleState state) async {
    developer.log('App lifecycle changed: $state', name: 'WebSocketService');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        await disconnect();
        break;
      case AppLifecycleState.resumed:
        if (_subscriptions.isNotEmpty) {
          await connect();
        }
        break;
      default:
        break;
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;
    
    _socket!.onConnect((_) {
      developer.log('Socket connected', name: 'WebSocketService');
      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _lastError = null;
    });
    
    _socket!.onDisconnect((reason) {
      developer.log('Socket disconnected: $reason', name: 'WebSocketService');
      _stopHeartbeat();
      
      final disconnectionError = _errorHandler.createUnexpectedDisconnectionError(reason?.toString());
      _lastError = disconnectionError;
      _errorHandler.emitError(disconnectionError);
      
      _updateConnectionState(WebSocketConnectionState.disconnected);
      
      if (_config.autoReconnect && 
          _reconnectionStrategy.shouldReconnectForError(disconnectionError, _reconnectAttempts, _config.maxReconnectAttempts)) {
        _scheduleReconnectWithError(disconnectionError);
      }
    });
    
    _socket!.onConnectError((error) {
      developer.log('Socket connection error: $error', name: 'WebSocketService');
      
      final wsError = _errorHandler.analyzeError(error, attemptNumber: _reconnectAttempts + 1);
      _handleConnectionError(wsError);
    });
    
    _socket!.onError((error) {
      developer.log('Socket error: $error', name: 'WebSocketService');
      
      final wsError = _errorHandler.analyzeError(error, attemptNumber: _reconnectAttempts + 1);
      _lastError = wsError;
      _errorHandler.emitError(wsError);
      _updateConnectionState(WebSocketConnectionState.error);
    });
    
    // Handle authentication errors from server
    _socket!.on('auth_error', (data) {
      developer.log('Authentication error from server: $data', name: 'WebSocketService');
      final authError = WebSocketError(
        type: WebSocketErrorType.authenticationFailed,
        message: 'Authentication error from server: $data',
        timestamp: DateTime.now(),
        isRecoverable: true,
      );
      _handleAuthenticationError(authError);
    });
    
    // Handle token expiration
    _socket!.on('token_expired', (data) {
      developer.log('Token expired, attempting refresh', name: 'WebSocketService');
      final tokenError = WebSocketError(
        type: WebSocketErrorType.tokenExpired,
        message: 'Token expired: $data',
        timestamp: DateTime.now(),
        isRecoverable: true,
      );
      _handleTokenExpiration(tokenError);
    });

    // Handle pong responses for heartbeat
    _socket!.on('pong', (_) {
      developer.log('Received pong response', name: 'WebSocketService');
    });
  }

  void _handleAuthenticationError(WebSocketError authError) async {
    developer.log('Handling authentication error', name: 'WebSocketService');
    
    _lastError = authError;
    _errorHandler.emitError(authError);
    
    // Try to refresh token if refresh callback is available
    if (_refreshToken != null) {
      try {
        final newToken = await _refreshToken!();
        if (newToken != null) {
          developer.log('Token refreshed, reconnecting', name: 'WebSocketService');
          await disconnect();
          await connect();
          return;
        }
      } catch (error) {
        developer.log('Token refresh failed: $error', name: 'WebSocketService');
        final refreshError = _errorHandler.createTokenRefreshError(error);
        _lastError = refreshError;
        _errorHandler.emitError(refreshError);
      }
    }
    
    // If refresh failed or not available, update state to error
    _updateConnectionState(WebSocketConnectionState.error);
    
    // Schedule reconnect if appropriate
    if (_config.autoReconnect && 
        _reconnectionStrategy.shouldReconnectForError(authError, _reconnectAttempts, _config.maxReconnectAttempts)) {
      _scheduleReconnectWithError(authError);
    }
  }

  void _handleTokenExpiration(WebSocketError tokenError) async {
    developer.log('Handling token expiration', name: 'WebSocketService');
    
    _lastError = tokenError;
    _errorHandler.emitError(tokenError);
    
    if (_refreshToken != null) {
      try {
        final newToken = await _refreshToken!();
        if (newToken != null) {
          // Emit new token to server
          _socket?.emit('refresh_token', {'token': newToken});
          return;
        }
      } catch (error) {
        developer.log('Token refresh failed: $error', name: 'WebSocketService');
        final refreshError = _errorHandler.createTokenRefreshError(error);
        _lastError = refreshError;
        _errorHandler.emitError(refreshError);
      }
    }
    
    // If refresh failed, disconnect and try to reconnect
    await disconnect();
    if (_config.autoReconnect && 
        _reconnectionStrategy.shouldReconnectForError(tokenError, _reconnectAttempts, _config.maxReconnectAttempts)) {
      _scheduleReconnectWithError(tokenError);
    }
  }

  void _scheduleReconnect() {
    _scheduleReconnectWithError(null);
  }

  void _scheduleReconnectWithError(WebSocketError? error) {
    if (_reconnectAttempts >= _config.maxReconnectAttempts) {
      developer.log('Max reconnect attempts reached', name: 'WebSocketService');
      final maxAttemptsError = _errorHandler.createMaxAttemptsError(_config.maxReconnectAttempts);
      _lastError = maxAttemptsError;
      _errorHandler.emitError(maxAttemptsError);
      return;
    }
    
    _updateConnectionState(WebSocketConnectionState.reconnecting);
    _reconnectAttempts++;
    
    // Calculate delay using enhanced reconnection strategy
    final delay = error != null 
        ? _reconnectionStrategy.calculateDelayWithError(_reconnectAttempts, error)
        : _reconnectionStrategy.calculateDelay(_reconnectAttempts);
    
    developer.log(
      'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s (error: ${error?.type})', 
      name: 'WebSocketService',
    );
    
    _reconnectTimer = Timer(delay, () {
      if (_currentState == WebSocketConnectionState.reconnecting) {
        connect();
      }
    });
  }

  void _handleConnectionError(WebSocketError error) {
    developer.log('Handling connection error: ${error.type} - ${error.message}', name: 'WebSocketService');
    
    _lastError = error;
    _errorHandler.emitError(error);
    _updateConnectionState(WebSocketConnectionState.error);
    
    if (_config.autoReconnect && 
        _reconnectionStrategy.shouldReconnectForError(error, _reconnectAttempts, _config.maxReconnectAttempts)) {
      _scheduleReconnectWithError(error);
    }
  }

  void _setupNetworkMonitoring() {
    _networkDetector.connectivityStream.listen((isConnected) {
      developer.log('Network connectivity changed: $isConnected', name: 'WebSocketService');
      
      if (!isConnected && _currentState == WebSocketConnectionState.connected) {
        // Network lost while connected
        final networkError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network connectivity lost',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );
        _handleConnectionError(networkError);
      } else if (isConnected && _currentState == WebSocketConnectionState.error && _lastError?.type == WebSocketErrorType.networkError) {
        // Network restored after network error
        developer.log('Network restored, attempting reconnection', name: 'WebSocketService');
        if (_config.autoReconnect) {
          connect();
        }
      }
    });
    
    _networkDetector.startMonitoring();
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (timer) {
      if (_currentState == WebSocketConnectionState.connected && _socket != null) {
        developer.log('Sending heartbeat ping', name: 'WebSocketService');
        _socket!.emit('ping');
        
        // Set up heartbeat timeout
        Timer(const Duration(seconds: 10), () {
          if (_currentState == WebSocketConnectionState.connected) {
            // If we haven't received a pong, consider it a heartbeat timeout
            final heartbeatError = _errorHandler.createHeartbeatTimeoutError();
            _handleConnectionError(heartbeatError);
          }
        });
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _resubscribeChannels() {
    if (_socket == null) return;
    
    for (final subscription in _subscriptions.values) {
      if (subscription.isActive) {
        developer.log('Resubscribing to channel: ${subscription.channel}', name: 'WebSocketService');
        _socket!.emit('subscribe', {'channel': subscription.channel});
        _socket!.on(subscription.channel, subscription.callback);
      }
    }
  }

  void _updateConnectionState(WebSocketConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(newState);
      }
      developer.log('Connection state changed to: $newState', name: 'WebSocketService');
    }
  }

  @override
  void dispose() {
    developer.log('Disposing WebSocket service', name: 'WebSocketService');
    
    _cancelReconnectTimer();
    _cancelConnectionTimeout();
    _stopHeartbeat();
    _networkDetector.dispose();
    _errorHandler.dispose();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _connectionStateController.close();
  }
}