import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mix_fit/di/service_locator.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/network_monitor.dart';
import 'package:core/error/stores/error_store.dart';

void main() {
  group('ServiceLocator Integration Tests', () {
    setUp(() async {
      // Reset GetIt before each test
      await GetIt.instance.reset();
    });

    tearDown(() async {
      // Clean up after each test
      await ServiceLocator.disposeDependencies();
    });

    group('configureDependencies', () {
      test('should register all dependencies including error system', () async {
        // Act
        await ServiceLocator.configureDependencies();

        // Assert - verify error system dependencies are available
        expect(GetIt.instance.isRegistered<NetworkMonitor>(), isTrue);
        expect(GetIt.instance.isRegistered<IErrorService>(), isTrue);
        expect(GetIt.instance.isRegistered<ErrorStore>(), isTrue);
      });

      test('should complete configuration without errors', () async {
        // Act & Assert
        await expectLater(
          ServiceLocator.configureDependencies(),
          completes,
        );
      });

      test('should provide working error system services', () async {
        // Arrange
        await ServiceLocator.configureDependencies();

        // Act
        final networkMonitor = GetIt.instance<NetworkMonitor>();
        final errorService = GetIt.instance<IErrorService>();
        final errorStore = GetIt.instance<ErrorStore>();

        // Assert
        expect(networkMonitor, isNotNull);
        expect(errorService, isNotNull);
        expect(errorStore, isNotNull);
        
        // Verify services are in expected initial state
        expect(errorService.hasErrors, isFalse);
        expect(errorService.activeErrors, isEmpty);
        expect(errorStore.hasErrors, isFalse);
        expect(errorStore.activeErrors, isEmpty);
      });

      test('should maintain singleton behavior for error services', () async {
        // Arrange
        await ServiceLocator.configureDependencies();

        // Act
        final networkMonitor1 = GetIt.instance<NetworkMonitor>();
        final networkMonitor2 = GetIt.instance<NetworkMonitor>();
        final errorService1 = GetIt.instance<IErrorService>();
        final errorService2 = GetIt.instance<IErrorService>();
        final errorStore1 = GetIt.instance<ErrorStore>();
        final errorStore2 = GetIt.instance<ErrorStore>();

        // Assert
        expect(identical(networkMonitor1, networkMonitor2), isTrue);
        expect(identical(errorService1, errorService2), isTrue);
        expect(identical(errorStore1, errorStore2), isTrue);
      });
    });

    group('disposeDependencies', () {
      test('should dispose all dependencies', () async {
        // Arrange
        await ServiceLocator.configureDependencies();
        expect(GetIt.instance.isRegistered<NetworkMonitor>(), isTrue);
        expect(GetIt.instance.isRegistered<IErrorService>(), isTrue);
        expect(GetIt.instance.isRegistered<ErrorStore>(), isTrue);

        // Act
        await ServiceLocator.disposeDependencies();

        // Assert
        expect(GetIt.instance.isRegistered<NetworkMonitor>(), isFalse);
        expect(GetIt.instance.isRegistered<IErrorService>(), isFalse);
        expect(GetIt.instance.isRegistered<ErrorStore>(), isFalse);
      });

      test('should handle disposal when dependencies are not configured', () async {
        // Act & Assert - should not throw
        await expectLater(
          ServiceLocator.disposeDependencies(),
          completes,
        );
      });

      test('should reset GetIt instance', () async {
        // Arrange
        await ServiceLocator.configureDependencies();
        expect(GetIt.instance.isRegistered<IErrorService>(), isTrue);

        // Act
        await ServiceLocator.disposeDependencies();

        // Assert
        expect(GetIt.instance.isRegistered<IErrorService>(), isFalse);
      });
    });

    group('lifecycle management', () {
      test('should support full configure-dispose cycle', () async {
        // Act - configure
        await ServiceLocator.configureDependencies();
        
        // Verify services are available
        expect(GetIt.instance.isRegistered<IErrorService>(), isTrue);
        final errorService = GetIt.instance<IErrorService>();
        expect(errorService, isNotNull);

        // Act - dispose
        await ServiceLocator.disposeDependencies();

        // Assert - services are no longer available
        expect(GetIt.instance.isRegistered<IErrorService>(), isFalse);
      });

      test('should support reconfiguration after disposal', () async {
        // Arrange - configure and dispose
        await ServiceLocator.configureDependencies();
        await ServiceLocator.disposeDependencies();

        // Act - reconfigure
        await ServiceLocator.configureDependencies();

        // Assert - services should be available again
        expect(GetIt.instance.isRegistered<NetworkMonitor>(), isTrue);
        expect(GetIt.instance.isRegistered<IErrorService>(), isTrue);
        expect(GetIt.instance.isRegistered<ErrorStore>(), isTrue);

        // Verify services work
        final errorService = GetIt.instance<IErrorService>();
        expect(errorService.hasErrors, isFalse);
      });

      test('should handle multiple configure calls gracefully', () async {
        // Arrange
        await ServiceLocator.configureDependencies();

        // Act & Assert - second call should handle gracefully or throw expected error
        await expectLater(
          ServiceLocator.configureDependencies(),
          throwsA(isA<ArgumentError>()), // GetIt throws when registering same type twice
        );
      });
    });

    group('error system integration', () {
      test('should provide fully functional error system', () async {
        // Arrange
        await ServiceLocator.configureDependencies();
        final errorService = GetIt.instance<IErrorService>();
        final errorStore = GetIt.instance<ErrorStore>();

        // Act & Assert - verify error system is functional
        expect(errorService.hasErrors, isFalse);
        expect(errorStore.hasErrors, isFalse);
        
        // Verify streams are available
        expect(errorService.errorStream, isNotNull);
        expect(errorService.currentErrorStream, isNotNull);
      });

      test('should maintain error system state consistency', () async {
        // Arrange
        await ServiceLocator.configureDependencies();
        final errorService = GetIt.instance<IErrorService>();
        final errorStore = GetIt.instance<ErrorStore>();

        // Act & Assert - verify initial state consistency
        expect(errorService.hasErrors, equals(errorStore.hasErrors));
        expect(errorService.activeErrors.length, equals(errorStore.activeErrors.length));
        expect(errorService.currentError, equals(errorStore.currentError));
      });
    });

    group('dependency resolution', () {
      test('should resolve all error system dependencies', () async {
        // Arrange
        await ServiceLocator.configureDependencies();

        // Act & Assert - all dependencies should resolve without error
        expect(() => GetIt.instance<NetworkMonitor>(), returnsNormally);
        expect(() => GetIt.instance<IErrorService>(), returnsNormally);
        expect(() => GetIt.instance<ErrorStore>(), returnsNormally);
      });

      test('should handle concurrent dependency access', () async {
        // Arrange
        await ServiceLocator.configureDependencies();

        // Act - simulate concurrent access
        final futures = List.generate(10, (index) async {
          final networkMonitor = GetIt.instance<NetworkMonitor>();
          final errorService = GetIt.instance<IErrorService>();
          final errorStore = GetIt.instance<ErrorStore>();
          
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