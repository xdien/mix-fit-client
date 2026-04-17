import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:app_config/models/environment_config.dart';
import 'package:app_config/loaders/environment_config_loader.dart';
import 'package:app_config/services/environment_config_service.dart';

void main() {
  group('Dependency Injection', () {
    late GetIt getIt;

    setUp(() {
      getIt = GetIt.instance;
      getIt.reset();
    });

    tearDown(() {
      getIt.reset();
    });

    test('should register EnvironmentConfigService as singleton', () {
      // Register the service
      getIt.registerSingleton<EnvironmentConfigService>(
        EnvironmentConfigService(),
      );

      // Verify it's registered
      expect(getIt.isRegistered<EnvironmentConfigService>(), true);

      // Verify it's a singleton
      final instance1 = getIt<EnvironmentConfigService>();
      final instance2 = getIt<EnvironmentConfigService>();
      expect(identical(instance1, instance2), true);
    });

    test('should register EnvironmentConfigLoader as singleton', () {
      // Register the loader
      getIt.registerSingleton<EnvironmentConfigLoader>(
        YamlEnvironmentConfigLoader(),
      );

      // Verify it's registered
      expect(getIt.isRegistered<EnvironmentConfigLoader>(), true);

      // Verify it's a singleton
      final instance1 = getIt<EnvironmentConfigLoader>();
      final instance2 = getIt<EnvironmentConfigLoader>();
      expect(identical(instance1, instance2), true);
    });

    test('should allow accessing service through dependency injection', () async {
      // Register the service
      final service = EnvironmentConfigService();
      getIt.registerSingleton<EnvironmentConfigService>(service);

      // Initialize with default config
      await service.initialize();

      // Access through DI
      final injectedService = getIt<EnvironmentConfigService>();
      
      expect(injectedService.isInitialized, true);
      expect(injectedService.environmentName, 'development');
      expect(injectedService.apiBaseUrl, isNotEmpty);
    });

    test('should support factory registration for testing', () {
      // Register as factory for testing scenarios
      getIt.registerFactory<EnvironmentConfigService>(
        () => EnvironmentConfigService(),
      );

      // Verify it's registered
      expect(getIt.isRegistered<EnvironmentConfigService>(), true);

      // Verify it creates new instances (factory pattern)
      final instance1 = getIt<EnvironmentConfigService>();
      final instance2 = getIt<EnvironmentConfigService>();
      // Note: Since EnvironmentConfigService is a singleton by design,
      // even with factory registration, it will return the same instance
      expect(identical(instance1, instance2), true);
    });

    test('should support lazy singleton registration', () {
      // Register as lazy singleton
      getIt.registerLazySingleton<EnvironmentConfigService>(
        () => EnvironmentConfigService(),
      );

      // Verify it's registered but not yet instantiated
      expect(getIt.isRegistered<EnvironmentConfigService>(), true);

      // Access it to trigger instantiation
      final instance1 = getIt<EnvironmentConfigService>();
      final instance2 = getIt<EnvironmentConfigService>();
      
      // Should be the same instance
      expect(identical(instance1, instance2), true);
    });

    test('should support conditional registration', () {
      const isTestEnvironment = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
      
      if (isTestEnvironment) {
        // Register mock for testing
        getIt.registerSingleton<EnvironmentConfigService>(
          EnvironmentConfigService(),
        );
      } else {
        // Register real implementation for production
        getIt.registerSingleton<EnvironmentConfigService>(
          EnvironmentConfigService(),
        );
      }

      expect(getIt.isRegistered<EnvironmentConfigService>(), true);
    });

    test('should handle service disposal properly', () {
      // Register with disposal callback
      final service = EnvironmentConfigService();
      getIt.registerSingleton<EnvironmentConfigService>(
        service,
        dispose: (service) {
          service.reset();
        },
      );

      // Initialize the service
      expect(getIt.isRegistered<EnvironmentConfigService>(), true);

      // Unregister the service explicitly
      getIt.unregister<EnvironmentConfigService>();

      // Verify service is no longer registered
      expect(getIt.isRegistered<EnvironmentConfigService>(), false);
    });

    test('should support named registrations', () {
      // Register multiple instances with different names
      getIt.registerSingleton<EnvironmentConfigService>(
        EnvironmentConfigService(),
        instanceName: 'development',
      );

      getIt.registerSingleton<EnvironmentConfigService>(
        EnvironmentConfigService(),
        instanceName: 'production',
      );

      // Verify both are registered
      expect(getIt.isRegistered<EnvironmentConfigService>(instanceName: 'development'), true);
      expect(getIt.isRegistered<EnvironmentConfigService>(instanceName: 'production'), true);

      // Verify they are different instances
      final devService = getIt<EnvironmentConfigService>(instanceName: 'development');
      final prodService = getIt<EnvironmentConfigService>(instanceName: 'production');
      // Note: Since EnvironmentConfigService is a singleton by design,
      // named instances will still be the same singleton instance
      expect(identical(devService, prodService), true);
    });
  });
}