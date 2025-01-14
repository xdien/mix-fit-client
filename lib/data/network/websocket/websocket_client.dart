import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  late WebSocketChannel _channel;
  
  Future<void> connect(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  Stream<dynamic> get messages => _channel.stream;
  
  Future<void> sendMessage(dynamic message) async {
    _channel.sink.add(message);
  }
  
  Future<void> disconnect() async {
    await _channel.sink.close();
  }
}