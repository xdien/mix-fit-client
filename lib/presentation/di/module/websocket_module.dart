
import 'package:mix_fit/data/network/websocket/websocket_repository_impl.dart';
import 'package:mix_fit/di/service_locator.dart';

import '../../../data/network/websocket/websocket_client.dart';
import '../../../domain/repository/websocket/websocket_repository.dart';
import '../../../domain/usecase/websocket/connect_websocket_usecase.dart';

class WebSocketModule {
  static Future<void> configureWebSocketModuleInjection() async {
    // Register WebSocket client
    getIt.registerSingleton<WebSocketClient>(WebSocketClient());
    
    // Register WebSocket repository
    getIt.registerSingleton<WebSocketRepository>(
      WebSocketRepositoryImpl(getIt<WebSocketClient>()),
    );

    // Register use cases
    getIt.registerSingleton<ConnectWebSocketUseCase>(
      ConnectWebSocketUseCase(getIt<WebSocketRepository>()),
    );
  }
}