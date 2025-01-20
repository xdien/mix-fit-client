abstract class WebSocketRepository {
  Future<void> connect();
  Future<void> disconnect();
  Stream<dynamic> get messages;
  Future<void> sendMessage(dynamic message);
  Stream<bool> getConnectionStatus();
  Future<bool> isConnected();
}
