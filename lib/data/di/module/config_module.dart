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

    // Legacy AppConfig for backward compatibility
    if (!getIt.isRegistered<AppConfig>()) {
      final legacyConfig = AppConfig();
      try {
        // Try to load legacy config if it exists
        final configService = getIt<EnvironmentConfigService>();
        if (configService.isInitialized) {
          // Use environment config values for legacy config
          await legacyConfig.load(configService.environmentName);
        }
      } catch (e) {
        // If environment config fails, try to load legacy config
        try {
          await legacyConfig.load('development');
        } catch (legacyError) {
          debugPrint('Failed to load legacy config: $legacyError');
        }
      }
      getIt.registerSingleton<AppConfig>(legacyConfig);
    }
  }
}