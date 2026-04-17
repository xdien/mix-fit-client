import '../../domain/repository/websocket_repository.dart';
import 'package:data/websocket/websocket.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  final IWebSocketService _service;

  WebSocketRepositoryImpl(this._service);

  @override
  Future<void> connect() => this._service.connect();

  @override
  Future<void> sendMessage(dynamic message) {
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect() => _service.disconnect();

  @override
  Stream<bool> getConnectionStatus() {
    return _service.connectionState.map((state) => 
      state == WebSocketConnectionState.connected
    );
  }

  @override
  Future<bool> isConnected() async {
    return _service.currentState == WebSocketConnectionState.connected;
  }
}
