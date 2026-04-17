import 'dart:async';
import 'package:auth/domain/repository/auth/auth_repository.dart';
import 'package:auth/domain/usecase/is_logged_in_usecase.dart';
import 'package:auth/domain/usecase/login_usecase.dart';
import 'package:auth/domain/usecase/register_usecase.dart';
import 'package:auth/domain/usecase/remove_auth_token_usecase.dart';
import 'package:auth/domain/usecase/save_auth_token_usecase.dart';
import 'package:auth/domain/usecase/save_login_in_status_usecase.dart';
import 'package:core/domain/repository/websocket_repository.dart';
import 'package:core/domain/usecase/get_connection_status_usecase.dart';

import '../../../di/service_locator.dart';
import '../../usecase/websocket/disconnect_websocket_usecase.dart';

class UseCaseModule {
  static Future<void> configureUseCaseModuleInjection() async {
    // user:--------------------------------------------------------------------
    getIt.registerSingleton<IsLoggedInUseCase>(
      IsLoggedInUseCase(getIt<AuthRepository>()),
    );
    getIt.registerSingleton<SaveLoginStatusUseCase>(
      SaveLoginStatusUseCase(getIt<AuthRepository>()),
    );
    getIt.registerSingleton<LoginUseCase>(
      LoginUseCase(getIt<AuthRepository>()),
    );

    // Register use cases
    getIt.registerSingleton(
        () => DisconnectWebSocketUseCase(getIt<WebSocketRepository>()));
    getIt.registerLazySingleton(
        () => GetConnectionStatusUseCase(getIt<WebSocketRepository>()));
    
    getIt.registerLazySingleton(
        () => SaveAuthTokenUseCase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(
        () => RemoveAuthTokenUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(
        () => RegisterUsecase(getIt<AuthRepository>()));
  }
}
