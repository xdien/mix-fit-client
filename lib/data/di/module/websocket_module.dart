import 'package:data/websocket/websocket.dart';
import '../../../di/service_locator.dart';

class WebSocketModule {
  static Future<void> configureWebSocketModuleInjection() async {
    // WebSocket configuration
    getIt.registerSingleton<WebSocketConfig>(
      const WebSocketConfig(
        url: 'ws://localhost:3000', // This will be environment-specific later
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      ),
    );

    // WebSocket service
    getIt.registerSingleton<IWebSocketService>(
      WebSocketService(getIt<WebSocketConfig>()),
    );
  }
}