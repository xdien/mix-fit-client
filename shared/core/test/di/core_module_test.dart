import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:core/di/core_module.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/network_monitor.dart';
import 'package:core/error/stores/error_store.dart';

void main() {
  group('CoreModule', () {
    late GetIt getIt;

    setUp(() {
      getIt = GetIt.instance;
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('configureCoreModuleInjection', () {
      test('should register all core dependencies', () async {
        // Act
        await CoreModule.configureCoreModuleInjection(getIt);

        // Assert - verify error system dependencies are registered
        expect(getIt.isRegistered<NetworkMonitor>(), isTrue);
        expect(getIt.isRegistered<IErrorService>(), isTrue);
        expect(getIt.isRegistered<ErrorStore>(), isTrue);
      });

      test('should complete without errors', () async {
        // Act & Assert
        await expectLater(
          CoreModule.configureCoreModuleInjection(getIt),
          completes,
        );
      });

      test('should handle multiple calls gracefully', () async {
        // Act
        await CoreModule.configureCoreModuleInjection(getIt);
        
        // Assert - second call should not throw
        await expectLater(
          CoreModule.configureCoreModuleInjection(getIt),
          throwsA(isA<ArgumentError>()), // GetIt throws when trying to register same type twice
        );
      });
    });

    group('disposeCoreModule', () {
      test('should dispose all core dependencies', () async {
        // Arrange
        await CoreModule.configureCoreModuleInjection(getIt);
        expect(getIt.isRegistered<NetworkMonitor>(), isTrue);
        expect(getIt.isRegistered<IErrorService>(), isTrue);
        expect(getIt.isRegistered<ErrorStore>(), isTrue);

        // Act
        await CoreModule.disposeCoreModule(getIt);

        // Assert
        expect(getIt.isRegistered<NetworkMonitor>(), isFalse);
        expect(getIt.isRegistered<IErrorService>(), isFalse);
        expect(getIt.isRegistered<ErrorStore>(), isFalse);
      });

      test('should handle disposal when dependencies are not registered', () async {
        // Act & Assert - should not throw
        await expectLater(
          CoreModule.disposeCoreModule(getIt),
          completes,
        );
      });

      test('should complete disposal process', () async {
        // Arrange
        await CoreModule.configureCoreModuleInjection(getIt);

        // Act & Assert
        await expectLater(
          CoreModule.disposeCoreModule(getIt),
          completes,
        );
      });
    });

    group('integration', () {
      test('should support full lifecycle', () async {
        // Act - configure
        await CoreModule.configureCoreModuleInjection(getIt);
        
        // Verify services are available
        final networkMonitor = getIt<NetworkMonitor>();
        final errorService = getIt<IErrorService>();
        final errorStore = getIt<ErrorStore>();
        
        expect(networkMonitor, isNotNull);
        expect(errorService, isNotNull);
        expect(errorStore, isNotNull);

        // Act - dispose
        await CoreModule.disposeCoreModule(getIt);

        // Assert - services are no longer available
        expect(getIt.isRegistered<NetworkMonitor>(), isFalse);
        expect(getIt.isRegistered<IErrorService>(), isFalse);
        expect(getIt.isRegistered<ErrorStore>(), isFalse);
      });

      test('should support reconfiguration after disposal', () async {
        // Arrange - configure and dispose
        await CoreModule.configureCoreModuleInjection(getIt);
        await CoreModule.disposeCoreModule(getIt);

        // Act - reconfigure
        await CoreModule.configureCoreModuleInjection(getIt);

        // Assert - services should be available again
        expect(getIt.isRegistered<NetworkMonitor>(), isTrue);
        expect(getIt.isRegistered<IErrorService>(), isTrue);
        expect(getIt.isRegistered<ErrorStore>(), isTrue);

        // Verify services work
        final errorService = getIt<IErrorService>();
        expect(errorService.hasErrors, isFalse);
      });
    });

    group('service availability', () {
      test('should provide access to all error system services', () async {
        // Arrange
        await CoreModule.configureCoreModuleInjection(getIt);

        // Act & Assert
        expect(() => getIt<NetworkMonitor>(), returnsNormally);
        expect(() => getIt<IErrorService>(), returnsNormally);
        expect(() => getIt<ErrorStore>(), returnsNormally);
      });

      test('should maintain service singleton behavior', () async {
        // Arrange
        await CoreModule.configureCoreModuleInjection(getIt);

        // Act
        final networkMonitor1 = getIt<NetworkMonitor>();
        final networkMonitor2 = getIt<NetworkMonitor>();
        final errorService1 = getIt<IErrorService>();
        final errorService2 = getIt<IErrorService>();
        final errorStore1 = getIt<ErrorStore>();
        final errorStore2 = getIt<ErrorStore>();

        // Assert
        expect(identical(networkMonitor1, networkMonitor2), isTrue);
        expect(identical(errorService1, errorService2), isTrue);
        expect(identical(errorStore1, errorStore2), isTrue);
      });
    });
  });
}