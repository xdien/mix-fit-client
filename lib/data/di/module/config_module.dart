import 'package:app_config/app_config.dart';
import 'package:flutter/foundation.dart';
import '../../../di/service_locator.dart';

class ConfigModule {
  static Future<void> configureConfigModuleInjection() async {
    // Register Environment Configuration Service (already initialized in main.dart)
    if (!getIt.isRegistered<EnvironmentConfigService>()) {
      getIt.registerSingleton<EnvironmentConfigService>(
        EnvironmentConfigService(),
      );
    }

    // Environment Configuration Loader
    if (!getIt.isRegistered<EnvironmentConfigLoader>()) {
      getIt.registerSingleton<EnvironmentConfigLoader>(
        YamlEnvironmentConfigLoader(),
      );
    }

    // AppConfig for backward compatibility
    if (!getIt.isRegistered<AppConfig>()) {
      final appConfig = AppConfig();
      try {
        // Try to load app config with environment name
        final configService = getIt<EnvironmentConfigService>();
        if (configService.isInitialized) {
          await appConfig.load(configService.environmentName);
        } else {
          await appConfig.load('development');
        }
      } catch (e) {
        debugPrint('Failed to load app config: $e');
        // Load with default environment
        try {
          await appConfig.load('development');
        } catch (fallbackError) {
          debugPrint('Failed to load app config with fallback: $fallbackError');
        }
      }
      getIt.registerSingleton<AppConfig>(appConfig);
    }
  }
}