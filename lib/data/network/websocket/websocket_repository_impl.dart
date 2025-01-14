import 'package:mix_fit/domain/repository/websocket/websocket_repository.dart';

import '../constants/endpoints.dart';
import 'websocket_client.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  final WebSocketClient _client;
  
  WebSocketRepositoryImpl(this._client);

  @override
  Future<void> connect() => _client.connect(Endpoints.wsUrl);

  @override 
  Stream<dynamic> get messages => _client.messages;

  @override
  Future<void> sendMessage(dynamic message) => _client.sendMessage(message);

  @override
  Future<void> disconnect() => _client.disconnect();
}