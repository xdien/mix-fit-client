import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import '../../../di/service_locator.dart';

class WebSocketModule {
  static Future<void> configureWebSocketModuleInjection() async {
    // WebSocket configuration
    getIt.registerSingleton<WebSocketConfig>(
      const WebSocketConfig(
        url: 'http://localhost:3000/socket.io', // This will be environment-specific later
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      ),
    );

    // WebSocket manager (singleton)
    getIt.registerSingleton<WebSocketManager>(
      WebSocketManager.instance,
    );
    
    // Note: WebSocketManager will be initialized later in the app lifecycle
    // to avoid conflicts with different configurations
  }
}