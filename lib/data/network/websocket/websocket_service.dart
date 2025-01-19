import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';

enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  error
}

class WebSocketService {
  final String url;
  final Duration pingInterval;
  final Duration reconnectDelay;
  
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  final _logger = Logger('WebSocketService');
  
  final _messageController = StreamController<dynamic>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  
  WebSocketStatus _status = WebSocketStatus.disconnected;
  
  WebSocketService({
    required this.url,
    this.pingInterval = const Duration(seconds: 30),
    this.reconnectDelay = const Duration(seconds: 5)
  });

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  WebSocketStatus get status => _status;

  Future<void> connect() async {
    if (_status == WebSocketStatus.connected) return;
    
    try {
      _setStatus(WebSocketStatus.connecting);
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel?.ready;
      
      _channel!.stream.listen(
        (message) {
          _messageController.add(message);
        },
        onError: (error) {
          _logger.severe('WebSocket error: $error');
          _handleError(error);
        },
        onDone: () {
          _logger.info('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      _setStatus(WebSocketStatus.connected);
      _startPingTimer();
      
    } catch (e) {
      _logger.severe('Failed to connect: $e');
      _handleError(e);
    }
  }

  void send(dynamic message) {
    if (_status != WebSocketStatus.connected) {
      throw WebSocketException('WebSocket is not connected');
    }
    try {
      _channel?.sink.add(message);
    } catch (e) {
      _logger.severe('Failed to send message: $e');
      _handleError(e);
    }
  }

  Future<void> disconnect() async {
    _stopPingTimer();
    _stopReconnectTimer();
    await _channel?.sink.close();
    _setStatus(WebSocketStatus.disconnected);
  }

  void _setStatus(WebSocketStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void _handleError(dynamic error) {
    _setStatus(WebSocketStatus.error);
    _startReconnection();
  }

  void _handleDisconnection() {
    _setStatus(WebSocketStatus.disconnected);
    _startReconnection();
  }

  void _startReconnection() {
    _stopPingTimer();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () async {
      await connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      send({'type': 'ping'});
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _statusController.close();
  }
}

class WebSocketException implements Exception {
  final String message;
  WebSocketException(this.message);
  
  @override
  String toString() => message;
}