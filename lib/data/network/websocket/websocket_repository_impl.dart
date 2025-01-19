import 'package:mix_fit/data/network/websocket/websocket_service.dart';
import 'package:mix_fit/domain/repository/websocket/websocket_repository.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  final WebSocketService _service;

  WebSocketRepositoryImpl(this._service);

  @override
  Future<void> connect() => this._service.connect();

  @override
  Stream<dynamic> get messages => _service.messageStream;

  @override
  Future<void> sendMessage(dynamic message) {
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect() => _service.disconnect();

  @override
  Stream<bool> getConnectionStatus() {
    throw UnimplementedError();
  }
}
