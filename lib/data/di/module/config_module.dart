import 'package:app_config/app_config.dart';
import '../../../di/service_locator.dart';

class ConfigModule {
  static Future<void> configureConfigModuleInjection() async {
    // Environment Configuration Service
    getIt.registerSingleton<EnvironmentConfigService>(
      EnvironmentConfigService(),
    );

    // Environment Configuration Loader
    getIt.registerSingleton<EnvironmentConfigLoader>(
      YamlEnvironmentConfigLoader(),
    );

    // Initialize the configuration service
    await getIt<EnvironmentConfigService>().initialize();
  }
}