import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import '../domain/repository/websocket_preferences_repository.dart';
import '../data/repository/websocket_preferences_repository_impl.dart';
import '../stores/websocket_preferences_store.dart';

/// Dependency injection setup for websocket service module
class WebSocketDI {
  static void registerDependencies(GetIt getIt) {
    // Repository
    getIt.registerLazySingleton<WebSocketPreferencesRepository>(
      () => WebSocketPreferencesRepositoryImpl(getIt<SharedPreferenceHelper>()),
    );

    // Store
    getIt.registerLazySingleton<WebSocketPreferencesStore>(
      () => WebSocketPreferencesStore(
        getIt<WebSocketPreferencesRepository>(),
        getIt<IErrorService>(),
      ),
    );
  }

  static void unregisterDependencies(GetIt getIt) {
    if (getIt.isRegistered<WebSocketPreferencesStore>()) {
      getIt.unregister<WebSocketPreferencesStore>();
    }
    if (getIt.isRegistered<WebSocketPreferencesRepository>()) {
      getIt.unregister<WebSocketPreferencesRepository>();
    }
  }
}