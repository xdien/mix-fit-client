import 'dart:async';
import '../../data/network/websocket/websocket_service.dart';
import '../../data/sharedpref/shared_preference_helper.dart';

class ConnectionManager {
  final SocketService _socketService;
  final SharedPreferenceHelper _sharedPreferenceHelper;

  StreamSubscription? _connectionSubscription;
  Timer? _reconnectTimer;
  bool _isInitialized = false;
  
  bool _shouldAutoReconnect = true;

  ConnectionManager({
    required SocketService socketService,
    required SharedPreferenceHelper sharedPreferenceHelper,
  })  : _socketService = socketService,
        _sharedPreferenceHelper = sharedPreferenceHelper;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _sharedPreferenceHelper.authStateChanges.listen((isAuthenticated) {
      if (isAuthenticated) {
        _setupConnectionMonitoring();
      } else {
        _cleanupConnection();
      }
    });

    await _checkAndHandleAuthStatus();
  }

  Future<void> _checkAndHandleAuthStatus() async {
    try {
      final isAuthenticated = await _sharedPreferenceHelper.isLoggedIn;
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
    _connectionSubscription?.cancel();
    _socketService.connect();
    _connectionSubscription = _socketService.statusStream.listen(
      (status) {
        switch (status) {
          case SocketStatus.disconnected:
            print('Socket disconnected');
            if (_shouldAutoReconnect) {
              _scheduleReconnect();
            }
            break;
          case SocketStatus.connected:
            print('Socket connected');
            _cancelReconnectTimer();
            break;
          case SocketStatus.connecting:
            print('Socket connecting...');
            break;
        }
      },
    );

    _socketService.connect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldAutoReconnect && _socketService.status != SocketStatus.connected) {
        print('Attempting to reconnect...');
        _socketService.connect();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void pauseAutoReconnect() {
    _shouldAutoReconnect = false;
    _cancelReconnectTimer();
  }

  void resumeAutoReconnect() {
    _shouldAutoReconnect = true;
    if (_socketService.status == SocketStatus.disconnected) {
      _scheduleReconnect();
    }
  }

  void _cleanupConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _cancelReconnectTimer();
    _socketService.disconnect();
  }

  Future<void> dispose() async {
    _isInitialized = false;
    _shouldAutoReconnect = false;
    _cleanupConnection();
  }
}