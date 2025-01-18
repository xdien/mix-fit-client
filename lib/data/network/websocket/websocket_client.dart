import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
enum ConnectionStatus {
  connecting,
  connected, 
  disconnected,
  error
}
class WebSocketClient {
  WebSocketChannel? _channel;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Timer? _reconnectionTimer;
  Timer? _pingTimer;
  bool _isManuallyDisconnected = false;
  
  // Expose connection status stream
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;
  
  // Add connection retry configuration
  static const Duration reconnectInterval = Duration(seconds: 5);
  static const Duration pingInterval = Duration(seconds: 30);
  static const int maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;

  final _temperatureController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get temperatureStream => _temperatureController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  Future<void> connect(String url) async {
    if (_channel != null) return;

    try {
      _statusController.add(ConnectionStatus.connecting);
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _statusController.add(ConnectionStatus.connected);

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          
          switch(data['type']) {
            case 'temperature':
              _temperatureController.add(data['payload']);
              break;
            case 'chat':
              // _chatController.add(data['payload']);
              break;
            default:
              print('Unknown message type: ${data['type']}');
          }
        },
        onError: _handleConnectionError,
        onDone: () {
          if (!_isManuallyDisconnected) {
            _handleConnectionError();
          }
        },
      );
    } catch (e) {
      _handleConnectionError();
      rethrow;
    }
  }

  Stream<dynamic> get messages {
    if (_channel == null) {
      throw WebSocketException('WebSocket not connected');
    }
    return _channel!.stream;
  }

  Future<void> sendMessage(dynamic message) async {
    if (_channel == null) {
      throw WebSocketException('WebSocket not connected');
    }
    
    try {
      _channel?.sink.add(message);
    } catch (e) {
      _handleConnectionError();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _isManuallyDisconnected = true;
    _stopReconnectionTimer();
    _stopPingTimer();
    
    try {
      await _channel?.sink.close();
      _channel = null;
      _statusController.add(ConnectionStatus.disconnected);
    } catch (e) {
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    _statusController.add(ConnectionStatus.error);
    _channel = null;

    if (!_isManuallyDisconnected && _reconnectAttempts < maxReconnectAttempts) {
      _startReconnectionTimer();
    }
  }

  void _startReconnectionTimer() {
    _stopReconnectionTimer();
    _reconnectionTimer = Timer.periodic(reconnectInterval, (timer) async {
      _reconnectAttempts++;
      if (_reconnectAttempts <= maxReconnectAttempts) {
        // Try to reconnect
        await connect(_channel!.closeCode.toString());
      } else {
        _stopReconnectionTimer();
      }
    });
  }

  void _stopReconnectionTimer() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      try {
        sendMessage('ping');
      } catch (e) {
        _handleConnectionError();
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void dispose() {
    _statusController.close();
    disconnect();
  }
}
class WebSocketException implements Exception {
  final String message;
  WebSocketException(this.message);
  
  @override
  String toString() => 'WebSocketException: $message';
}