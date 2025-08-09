import 'package:get_it/get_it.dart';
import '../error/services/error_service.dart';
import '../error/services/error_service_interface.dart';
import '../error/services/network_monitor.dart';
import '../error/services/retry_service.dart';
import '../error/stores/error_store.dart';

/// Module for registering error system dependencies
class ErrorModule {
  /// Configures error system dependencies in the GetIt container
  static Future<void> configureErrorModuleInjection(GetIt getIt) async {
    // Register NetworkMonitor as singleton
    getIt.registerLazySingleton<NetworkMonitor>(
      () => NetworkMonitor(),
    );

    // Register RetryService as singleton
    getIt.registerLazySingleton<RetryService>(
      () => RetryService(),
    );

    // Register ErrorService as singleton with NetworkMonitor dependency
    getIt.registerLazySingleton<IErrorService>(
      () => ErrorService(
        networkMonitor: getIt<NetworkMonitor>(),
      ),
    );

    // Register ErrorStore as singleton with ErrorService dependency
    getIt.registerLazySingleton<ErrorStore>(
      () => ErrorStore(
        getIt<IErrorService>(),
        getIt<NetworkMonitor>(),
      ),
    );
  }

  /// Disposes of error system dependencies
  static Future<void> disposeErrorModule(GetIt getIt) async {
    // Dispose services in reverse order of registration
    if (getIt.isRegistered<ErrorStore>()) {
      final errorStore = getIt<ErrorStore>();
      errorStore.dispose();
      await getIt.unregister<ErrorStore>();
    }

    if (getIt.isRegistered<IErrorService>()) {
      final errorService = getIt<IErrorService>();
      errorService.dispose();
      await getIt.unregister<IErrorService>();
    }

    if (getIt.isRegistered<RetryService>()) {
      await getIt.unregister<RetryService>();
    }

    if (getIt.isRegistered<NetworkMonitor>()) {
      final networkMonitor = getIt<NetworkMonitor>();
      networkMonitor.dispose();
      await getIt.unregister<NetworkMonitor>();
    }
  }
}