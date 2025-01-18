import 'dart:async';

import '../../data/network/websocket/websocket_service.dart';
import '../../domain/repository/auth/auth_repository.dart';

class ConnectionManager {
  final WebSocketService _webSocketService;
  final AuthRepository _authRepository; // For checking login status

  StreamSubscription? _connectionSubscription;
  bool _isInitialized = false;

  ConnectionManager({
    required WebSocketService webSocketService,
    required AuthRepository authRepository,
  })  : _webSocketService = webSocketService,
        _authRepository = authRepository;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _checkAndHandleAuthStatus();
  }

  Future<void> _checkAndHandleAuthStatus() async {
    try {
      // final isAuthenticated = await _authRepository.isLoggedIn();
      if (true) {
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
    _connectionSubscription?.cancel();
    _connectionSubscription = _webSocketService.statusStream.listen(
      (status) {
        if (status == WebSocketStatus.disconnected)  {
          // WebSocketService sẽ tự động handle reconnection
          print('WebSocket disconnected');
        }
      },
    );

    // Initial connection attempt
    _webSocketService.connect();
  }

  void _cleanupConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _webSocketService.disconnect();
  }

  Future<void> dispose() async {
    _isInitialized = false;
    _cleanupConnection();
  }
}