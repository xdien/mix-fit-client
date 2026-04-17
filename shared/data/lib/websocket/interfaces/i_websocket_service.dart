import 'package:flutter/widgets.dart';
import '../models/websocket_connection_state.dart';

abstract class IWebSocketService {
  Future<void> connect();
  Future<void> disconnect();
  void subscribe(String channel, Function(dynamic) callback);
  void unsubscribe(String channel);
  Stream<WebSocketConnectionState> get connectionState;
  WebSocketConnectionState get currentState;
  Future<void> handleAppLifecycle(AppLifecycleState state);
  void dispose();
}