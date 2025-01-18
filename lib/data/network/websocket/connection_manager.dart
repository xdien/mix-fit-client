import 'dart:async';
import 'package:mix_fit/core/domain/usecase/use_case.dart';

import '../../../domain/usecase/auth/is_logged_in_usecase.dart';
import '../../../domain/usecase/websocket/connect_websocket_usecase.dart';
import '../../../domain/usecase/websocket/disconnect_websocket_usecase.dart';
import '../../../domain/usecase/websocket/get_connection_status_usecase.dart';

class ConnectionManager {
  final ConnectWebSocketUseCase _connectWebSocketUseCase;
  final DisconnectWebSocketUseCase _disconnectWebSocketUseCase;
  final GetConnectionStatusUseCase _getConnectionStatusUseCase;
  final IsLoggedInUseCase _isLoggedInUseCase;
  
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _authSubscription;
  Timer? _reconnectTimer;
  bool _isInitialized = false;
  
  // Exponential backoff parameters
  static const int maxRetries = 5;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  Duration _currentRetryDelay = initialRetryDelay;
  int _retryCount = 0;

  ConnectionManager(
    this._connectWebSocketUseCase,
    this._disconnectWebSocketUseCase,
    this._getConnectionStatusUseCase,
    this._isLoggedInUseCase,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Listen to auth status changes
     await _checkAndHandleAuthStatus();
  }

  Future<void> _checkAndHandleAuthStatus() async {
    try {
      final isAuthenticated = await _isLoggedInUseCase(params: null);
      if (isAuthenticated) {
        _setupConnectionMonitoring();
      } else {
        _cleanupConnection();
      }
    } catch (e) {
      print('Error checking auth status: $e');
      _cleanupConnection();
    }
  }

  void _setupConnectionMonitoring() {
    // Cancel existing subscription if any
    _connectionSubscription?.cancel();
    
    _connectionSubscription = _getConnectionStatusUseCase.call(params: NoParams()).listen(
      (isConnected) {
        if (!isConnected) {
          _handleDisconnection();
        } else {
          // Reset retry parameters on successful connection
          _retryCount = 0;
          _currentRetryDelay = initialRetryDelay;
        }
      },
    );

    // Initial connection attempt
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _connectWebSocketUseCase.call(params: NoParams());
    } catch (e) {
      print('Connection failed: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    // Cancel any existing reconnection timer
    _reconnectTimer?.cancel();

    if (_retryCount < maxRetries) {
      _reconnectTimer = Timer(_currentRetryDelay, () {
        _connect();
        // Implement exponential backoff
        _currentRetryDelay *= 2;
        _retryCount++;
      });
    } else {
      // Max retries reached, reset counters but stop trying
      _retryCount = 0;
      _currentRetryDelay = initialRetryDelay;
      // Optionally notify user or system about connection failure
    }
  }

  void _cleanupConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retryCount = 0;
    _currentRetryDelay = initialRetryDelay;
    
    // Disconnect websocket
    _disconnectWebSocketUseCase.call(params:  NoParams() );
  }

  Future<void> dispose() async {
    _isInitialized = false;
    _authSubscription?.cancel();
    _cleanupConnection();
  }
}