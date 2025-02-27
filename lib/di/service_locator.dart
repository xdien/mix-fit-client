import 'package:mix_fit/data/di/data_layer_injection.dart';
import 'package:mix_fit/domain/di/domain_layer_injection.dart';
import 'package:mix_fit/presentation/di/presentation_layer_injection.dart';
import 'package:get_it/get_it.dart';

import '../core/managers/connection_manager.dart';
import '../data/network/websocket/websocket_service.dart';
import '../domain/repository/auth/auth_repository.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> configureDependencies() async {
    await DataLayerInjection.configureDataLayerInjection();
    await DomainLayerInjection.configureDomainLayerInjection();
    await PresentationLayerInjection.configurePresentationLayerInjection();
    // Register ConnectionManager as singleton
    getIt.registerSingleton<ConnectionManager>(
      ConnectionManager(
        socketService: getIt<SocketService>(),
        authRepository: getIt<AuthRepository>(),
      ),
    );
  }
}
