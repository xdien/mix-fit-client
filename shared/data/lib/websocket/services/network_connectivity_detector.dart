import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

/// Detects network connectivity changes and provides network status
class NetworkConnectivityDetector {
  final StreamController<bool> _connectivityController = 
      StreamController<bool>.broadcast();
  
  Timer? _connectivityTimer;
  bool _isConnected = true;
  final Duration _checkInterval;
  final String _testHost;
  final int _testPort;
  final Duration _testTimeout;

  NetworkConnectivityDetector({
    Duration? checkInterval,
    String? testHost,
    int? testPort,
    Duration? testTimeout,
  }) : _checkInterval = checkInterval ?? const Duration(seconds: 30),
       _testHost = testHost ?? 'google.com',
       _testPort = testPort ?? 80,
       _testTimeout = testTimeout ?? const Duration(seconds: 5);

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Start monitoring network connectivity
  void startMonitoring() {
    developer.log('Starting network connectivity monitoring', name: 'NetworkConnectivityDetector');
    
    // Initial connectivity check
    _checkConnectivity();
    
    // Schedule periodic checks
    _connectivityTimer = Timer.periodic(_checkInterval, (_) {
      _checkConnectivity();
    });
  }

  /// Stop monitoring network connectivity
  void stopMonitoring() {
    developer.log('Stopping network connectivity monitoring', name: 'NetworkConnectivityDetector');
    
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  /// Manually check connectivity status
  Future<bool> checkConnectivity() async {
    return await _performConnectivityTest();
  }

  /// Check if a specific host is reachable
  Future<bool> isHostReachable(String host, int port, {Duration? timeout}) async {
    try {
      final socket = await Socket.connect(
        host, 
        port, 
        timeout: timeout ?? _testTimeout,
      );
      socket.destroy();
      return true;
    } catch (e) {
      developer.log('Host $host:$port is not reachable: $e', name: 'NetworkConnectivityDetector');
      return false;
    }
  }

  /// Check if WebSocket server is reachable
  Future<bool> isWebSocketServerReachable(String wsUrl) async {
    try {
      // Extract host and port from WebSocket URL
      final uri = Uri.parse(wsUrl);
      final host = uri.host;
      final port = uri.port != 0 ? uri.port : (uri.scheme == 'wss' ? 443 : 80);
      
      return await isHostReachable(host, port);
    } catch (e) {
      developer.log('Failed to parse WebSocket URL $wsUrl: $e', name: 'NetworkConnectivityDetector');
      return false;
    }
  }

  void _checkConnectivity() async {
    final wasConnected = _isConnected;
    _isConnected = await _performConnectivityTest();
    
    if (wasConnected != _isConnected) {
      developer.log(
        'Network connectivity changed: ${_isConnected ? 'connected' : 'disconnected'}',
        name: 'NetworkConnectivityDetector',
      );
      
      if (!_connectivityController.isClosed) {
        _connectivityController.add(_isConnected);
      }
    }
  }

  Future<bool> _performConnectivityTest() async {
    try {
      final socket = await Socket.connect(_testHost, _testPort, timeout: _testTimeout);
      socket.destroy();
      return true;
    } catch (e) {
      // Try alternative connectivity test
      return await _alternativeConnectivityTest();
    }
  }

  Future<bool> _alternativeConnectivityTest() async {
    try {
      // Try connecting to a different host
      final socket = await Socket.connect('1.1.1.1', 53, timeout: _testTimeout);
      socket.destroy();
      return true;
    } catch (e) {
      developer.log('Network connectivity test failed: $e', name: 'NetworkConnectivityDetector');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}