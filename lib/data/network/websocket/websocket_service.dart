import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

enum SocketStatus { connecting, connected, disconnected }

class SocketService {
  final String url;
  final AsyncValueGetter<String?> tokenProvider;
  final _logger = Logger('SocketService');

  IO.Socket? _socket;
  final _statusController = StreamController<SocketStatus>.broadcast();
  
  SocketStatus _status = SocketStatus.disconnected;

  SocketService({
    required this.url,
    required this.tokenProvider,
  });

  Stream<SocketStatus> get statusStream => _statusController.stream;
  SocketStatus get status => _status;

  Future<void> connect() async {
    if (_status == SocketStatus.connected) return;

    try {
      _setStatus(SocketStatus.connecting);
      final token = await tokenProvider() ?? '';

      _socket = IO.io(url, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .setAuth({'token': token})
        .enableAutoConnect()
        .enableReconnection()
        .build()
      );

      _setupSocketListeners();
      
    } catch (e) {
      _logger.severe('Failed to connect: $e');
      _setStatus(SocketStatus.disconnected);
    }
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      _logger.info('Socket connected');
      _setStatus(SocketStatus.connected);
    });

    _socket?.onDisconnect((_) {
      _logger.info('Socket disconnected');
      _setStatus(SocketStatus.disconnected);
    });

    _socket?.onError((error) {
      _logger.severe('Socket error: $error');
      _setStatus(SocketStatus.disconnected);
    });

    _socket?.onConnectError((error) {
      _logger.severe('Socket connect error: $error');
      _setStatus(SocketStatus.disconnected);
    });
  }

  void emit(String event, dynamic data) {
    if (_status != SocketStatus.connected) {
      throw SocketException('Socket is not connected');
    }
    try {
      _socket?.emit(event, data);
    } catch (e) {
      _logger.severe('Failed to emit message: $e');
    }
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    _socket?.off(event, handler);
  }

  void joinChannel(String channelId) {
    emit('join', channelId);
  }

  void leaveChannel(String channelId) {
    emit('leave', channelId);
  }

  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setStatus(SocketStatus.disconnected);
  }

  void _setStatus(SocketStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
  }
}

class SocketException implements Exception {
  final String message;
  SocketException(this.message);

  @override
  String toString() => message;
}