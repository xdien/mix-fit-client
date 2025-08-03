import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
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

    // WebSocket manager (singleton)
    getIt.registerSingleton<WebSocketManager>(
      WebSocketManager.instance,
    );
    
    // Initialize WebSocketManager with authentication callbacks
    WebSocketManager.instance.initialize(
      config: getIt<WebSocketConfig>(),
      getAuthToken: () async => await getIt<SharedPreferenceHelper>().authToken,
    );
  }
}