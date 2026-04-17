import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_config.dart';
import '../models/websocket_connection_state.dart';
import 'websocket_service.dart';

/// WebSocket manager that handles authentication integration and service lifecycle
class WebSocketManager {
  static WebSocketManager? _instance;
  static WebSocketManager get instance => _instance ??= WebSocketManager._internal();
  
  WebSocketManager._internal();

  IWebSocketService? _webSocketService;
  final StreamController<WebSocketConnectionState> _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();

  // Authentication callbacks
  Future<String?> Function()? _getAuthToken;
  Future<String?> Function()? _refreshToken;

  /// Initialize the WebSocket manager with authentication callbacks
  void initialize({
    required WebSocketConfig config,
    required Future<String?> Function() getAuthToken,
    Future<String?> Function()? refreshToken,
  }) {
    developer.log('Initializing WebSocket manager', name: 'WebSocketManager');
    
    // Dispose existing service if any
    if (_webSocketService != null) {
      developer.log('Disposing existing WebSocket service', name: 'WebSocketManager');
      _webSocketService!.dispose();
      _webSocketService = null;
    }
    
    _getAuthToken = getAuthToken;
    _refreshToken = refreshToken;
    
    _webSocketService = WebSocketService(
      config,
      getAuthToken,
      refreshToken: refreshToken,
    );
    
    // Forward connection state changes
    _webSocketService!.connectionState.listen((state) {
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(state);
      }
    });
  }

  /// Get the WebSocket service instance
  IWebSocketService? get webSocketService => _webSocketService;

  /// Get connection state stream
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Get current connection state
  WebSocketConnectionState get currentState =>
      _webSocketService?.currentState ?? WebSocketConnectionState.disconnected;

  /// Connect to WebSocket
  Future<void> connect() async {
    if (_webSocketService == null) {
      developer.log('WebSocket service not initialized', name: 'WebSocketManager');
      throw StateError('WebSocket service not initialized. Call initialize() first.');
    }
    
    await _webSocketService!.connect();
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    if (_webSocketService == null) {
      developer.log('WebSocket service not initialized', name: 'WebSocketManager');
      return;
    }
    
    await _webSocketService!.disconnect();
  }

  /// Subscribe to a channel
  void subscribe(String channel, Function(dynamic) callback) {
    if (_webSocketService == null) {
      developer.log('WebSocket service not initialized', name: 'WebSocketManager');
      throw StateError('WebSocket service not initialized. Call initialize() first.');
    }
    
    _webSocketService!.subscribe(channel, callback);
  }

  /// Unsubscribe from a channel
  void unsubscribe(String channel) {
    if (_webSocketService == null) {
      developer.log('WebSocket service not initialized', name: 'WebSocketManager');
      return;
    }
    
    _webSocketService!.unsubscribe(channel);
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycle(AppLifecycleState state) async {
    if (_webSocketService == null) {
      developer.log('WebSocket service not initialized', name: 'WebSocketManager');
      return;
    }
    
    await _webSocketService!.handleAppLifecycle(state);
  }

  /// Check if WebSocket is connected
  bool get isConnected => currentState == WebSocketConnectionState.connected;

  /// Check if WebSocket is connecting
  bool get isConnecting => currentState == WebSocketConnectionState.connecting;

  /// Check if WebSocket is reconnecting
  bool get isReconnecting => currentState == WebSocketConnectionState.reconnecting;

  /// Check if WebSocket has error
  bool get hasError => currentState == WebSocketConnectionState.error;

  /// Dispose the WebSocket manager
  void dispose() {
    developer.log('Disposing WebSocket manager', name: 'WebSocketManager');
    
    if (_webSocketService != null) {
      _webSocketService!.dispose();
      _webSocketService = null;
    }
    
    _connectionStateController.close();
    _instance = null;
  }

  /// Reset the singleton instance (for testing)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}