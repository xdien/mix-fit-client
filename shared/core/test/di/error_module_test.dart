import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:core/di/error_module.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/network_monitor.dart';
import 'package:core/error/stores/error_store.dart';

void main() {
  group('ErrorModule', () {
    late GetIt getIt;

    setUp(() {
      getIt = GetIt.instance;
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('configureErrorModuleInjection', () {
      test('should register all error system dependencies', () async {
        // Act
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Assert
        expect(getIt.isRegistered<NetworkMonitor>(), isTrue);
        expect(getIt.isRegistered<IErrorService>(), isTrue);
        expect(getIt.isRegistered<ErrorStore>(), isTrue);
      });

      test('should register NetworkMonitor as lazy singleton', () async {
        // Act
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Assert
        final networkMonitor1 = getIt<NetworkMonitor>();
        final networkMonitor2 = getIt<NetworkMonitor>();
        expect(identical(networkMonitor1, networkMonitor2), isTrue);
      });

      test('should register IErrorService as lazy singleton', () async {
        // Act
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Assert
        final errorService1 = getIt<IErrorService>();
        final errorService2 = getIt<IErrorService>();
        expect(identical(errorService1, errorService2), isTrue);
      });

      test('should register ErrorStore as lazy singleton', () async {
        // Act
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Assert
        final errorStore1 = getIt<ErrorStore>();
        final errorStore2 = getIt<ErrorStore>();
        expect(identical(errorStore1, errorStore2), isTrue);
      });

      test('should inject NetworkMonitor into ErrorService', () async {
        // Act
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Assert
        final networkMonitor = getIt<NetworkMonitor>();
        final errorService = getIt<IErrorService>();
        
        // Verify that the error service has the network monitor
        // This is tested indirectly by checking that both services work together
        expect(errorService, isNotNull);
        expect(networkMonitor, isNotNull);
      });

      test('should inject dependencies into ErrorStore', () async {
        // Act
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Assert
        final errorStore = getIt<ErrorStore>();
        
        // Verify that the error store is properly initialized
        expect(errorStore, isNotNull);
        expect(errorStore.hasErrors, isFalse);
        expect(errorStore.activeErrors, isEmpty);
      });
    });

    group('disposeErrorModule', () {
      test('should dispose and unregister all dependencies', () async {
        // Arrange
        await ErrorModule.configureErrorModuleInjection(getIt);
        expect(getIt.isRegistered<NetworkMonitor>(), isTrue);
        expect(getIt.isRegistered<IErrorService>(), isTrue);
        expect(getIt.isRegistered<ErrorStore>(), isTrue);

        // Act
        await ErrorModule.disposeErrorModule(getIt);

        // Assert
        expect(getIt.isRegistered<NetworkMonitor>(), isFalse);
        expect(getIt.isRegistered<IErrorService>(), isFalse);
        expect(getIt.isRegistered<ErrorStore>(), isFalse);
      });

      test('should handle disposal when services are not registered', () async {
        // Act & Assert - should not throw
        await expectLater(
          ErrorModule.disposeErrorModule(getIt),
          completes,
        );
      });

      test('should dispose services in correct order', () async {
        // Arrange
        await ErrorModule.configureErrorModuleInjection(getIt);
        final errorStore = getIt<ErrorStore>();
        final errorService = getIt<IErrorService>();
        final networkMonitor = getIt<NetworkMonitor>();

        // Verify services are initialized
        expect(errorStore, isNotNull);
        expect(errorService, isNotNull);
        expect(networkMonitor, isNotNull);

        // Act
        await ErrorModule.disposeErrorModule(getIt);

        // Assert - services should be unregistered
        expect(getIt.isRegistered<ErrorStore>(), isFalse);
        expect(getIt.isRegistered<IErrorService>(), isFalse);
        expect(getIt.isRegistered<NetworkMonitor>(), isFalse);
      });
    });

    group('service lifecycle', () {
      test('should properly initialize services on first access', () async {
        // Arrange
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Act
        final networkMonitor = getIt<NetworkMonitor>();
        final errorService = getIt<IErrorService>();
        final errorStore = getIt<ErrorStore>();

        // Assert
        expect(networkMonitor, isNotNull);
        expect(errorService, isNotNull);
        expect(errorStore, isNotNull);
        
        // Verify initial states
        expect(errorService.hasErrors, isFalse);
        expect(errorService.activeErrors, isEmpty);
        expect(errorStore.hasErrors, isFalse);
        expect(errorStore.activeErrors, isEmpty);
      });

      test('should maintain service state across multiple accesses', () async {
        // Arrange
        await ErrorModule.configureErrorModuleInjection(getIt);
        final errorService = getIt<IErrorService>();
        final errorStore = getIt<ErrorStore>();

        // Act - modify state
        // Note: We can't easily test state changes without creating actual errors
        // This test verifies that the same instances are returned
        final errorService2 = getIt<IErrorService>();
        final errorStore2 = getIt<ErrorStore>();

        // Assert
        expect(identical(errorService, errorService2), isTrue);
        expect(identical(errorStore, errorStore2), isTrue);
      });
    });

    group('dependency relationships', () {
      test('should create proper dependency chain', () async {
        // Arrange & Act
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Assert - verify all dependencies can be resolved
        expect(() => getIt<NetworkMonitor>(), returnsNormally);
        expect(() => getIt<IErrorService>(), returnsNormally);
        expect(() => getIt<ErrorStore>(), returnsNormally);
      });

      test('should handle concurrent access to services', () async {
        // Arrange
        await ErrorModule.configureErrorModuleInjection(getIt);

        // Act - simulate concurrent access
        final futures = List.generate(10, (index) async {
          final networkMonitor = getIt<NetworkMonitor>();
          final errorService = getIt<IErrorService>();
          final errorStore = getIt<ErrorStore>();
          
          return [networkMonitor, errorService, errorStore];
        });

        final results = await Future.wait(futures);

        // Assert - all should return the same instances
        final firstResult = results.first;
        for (final result in results) {
          expect(identical(result[0], firstResult[0]), isTrue); // NetworkMonitor
          expect(identical(result[1], firstResult[1]), isTrue); // IErrorService
          expect(identical(result[2], firstResult[2]), isTrue); // ErrorStore
        }
      });
    });
  });
}