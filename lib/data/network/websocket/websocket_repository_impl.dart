import 'package:mix_fit/data/network/websocket/websocket_service.dart';
import 'package:mix_fit/domain/repository/websocket/websocket_repository.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  final SocketService _service;

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
    return _service.statusStream.map((status) => 
      status == SocketStatus.connected
    );
  }

  @override
  Future<bool> isConnected() {
    throw _service.status == SocketStatus.connected;
  }
}
