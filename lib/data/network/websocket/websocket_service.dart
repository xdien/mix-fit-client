import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:logging/logging.dart';

enum WebSocketStatus { connecting, connected, disconnected, error }

typedef WebSocketEventHandler = void Function(dynamic event);

class WebSocketService {
  // WebSocket frame opcodes theo RFC 6455
  static const int PING = 0x9; // Binary: 1001
  static const int PONG = 0xA; // Binary: 1010

  static const int FRAME_FIN = 0x80; // 1000 0000 - Final fragment
  static const int FRAME_MASK = 0x80; // 1000 0000 - Mask bit

  List<int> _createFrame(int opcode, [List<int>? payload]) {
    final List<int> frame = [];

    frame.add(FRAME_FIN | opcode);
    int length = payload?.length ?? 0;
    frame
        .add(length);

    if (payload != null && payload.isNotEmpty) {
      frame.addAll(payload);
    }

    return frame;
  }

  final String url;
  final AsyncValueGetter<String?> token;
  final Duration pingInterval;
  final Duration reconnectDelay;
  final Duration pongTimeout;

  WebSocket? _ws;
  IOWebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _pongTimer;
  final _logger = Logger('WebSocketService');

  final _messageController = StreamController<dynamic>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  final Map<String, List<WebSocketEventHandler>> _eventHandlers = {};

  WebSocketStatus _status = WebSocketStatus.disconnected;
  bool _awaitingPong = false;

  WebSocketService({
    required this.url,
    required this.token,
    this.pingInterval = const Duration(seconds: 30),
    this.reconnectDelay = const Duration(seconds: 5),
    this.pongTimeout = const Duration(seconds: 10),
  });

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  WebSocketStatus get status => _status;

  Future<void> connect() async {
    if (_status == WebSocketStatus.connected) return;

    try {
      _setStatus(WebSocketStatus.connecting);
      final String token1 = await token() ?? '';

      _ws = await WebSocket.connect(
        url,
        headers: {'Authorization': 'Bearer $token1'},
      );

      _ws!.pingInterval = pingInterval;

      _channel = IOWebSocketChannel(_ws!);

      _channel!.stream.listen(
        (message) {
          if (message is List<int>) {
            int opcode = message[0] & 0x0F;

            if (opcode == PING) {
              _ws?.add(_createFrame(PONG));
              return;
            }

            if (opcode == PONG) {
              _handlePong();
              return;
            }
          }
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

  void _handlePong() {
    _awaitingPong = false;
    _pongTimer?.cancel();
  }

  void send(dynamic message) {
    if (_status != WebSocketStatus.connected) {
      throw WebSocketException('WebSocket is not connected');
    }
    try {
      _ws?.add(message);
    } catch (e) {
      _logger.severe('Failed to send message: $e');
      _handleError(e);
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      if (_awaitingPong) {
        _logger.warning('No pong received from previous ping');
        _handleError('Pong timeout');
        return;
      }

      try {
        _ws?.add(_createFrame(PING));
        _awaitingPong = true;

        _pongTimer?.cancel();
        _pongTimer = Timer(pongTimeout, () {
          if (_awaitingPong) {
            _logger.severe('Pong timeout');
            _handleError('Pong timeout');
          }
        });
      } catch (e) {
        _logger.severe('Error sending ping frame: $e');
      }
    });
  }

  Future<void> disconnect() async {
    _stopPingTimer();
    _stopReconnectTimer();
    _pongTimer?.cancel();
    await _ws?.close(ws_status.normalClosure);
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
    _pongTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () async {
      await connect();
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimer?.cancel();
    _pongTimer = null;
    _awaitingPong = false;
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

  void on(String eventType, WebSocketEventHandler handler) {
    _eventHandlers.putIfAbsent(eventType, () => []).add(handler);
  }

  void off(String eventType, WebSocketEventHandler handler) {
    _eventHandlers[eventType]?.remove(handler);
    if (_eventHandlers[eventType]?.isEmpty ?? false) {
      _eventHandlers.remove(eventType);
    }
  }
}

class WebSocketException implements Exception {
  final String message;
  WebSocketException(this.message);

  @override
  String toString() => message;
}
