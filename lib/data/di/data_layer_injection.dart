import 'module/config_module.dart';
import 'module/local_module.dart';
import 'module/network_module.dart';
import 'module/repository_module.dart';
import 'module/websocket_module.dart';

class DataLayerInjection {
  static Future<void> configureDataLayerInjection() async {
    // Initialize configuration first as other modules may depend on it
    await ConfigModule.configureConfigModuleInjection();
    await LocalModule.configureLocalModuleInjection();
    await NetworkModule.configureNetworkModuleInjection();
    await WebSocketModule.configureWebSocketModuleInjection();
    await RepositoryModule.configureRepositoryModuleInjection();
  }
}
