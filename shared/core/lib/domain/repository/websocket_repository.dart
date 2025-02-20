abstract class WebSocketRepository {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> sendMessage(dynamic message);
  Stream<bool> getConnectionStatus();
  Future<bool> isConnected();
}
