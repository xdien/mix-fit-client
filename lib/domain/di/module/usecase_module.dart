import 'dart:async';

import 'package:mix_fit/domain/repository/auth/auth_repository.dart';
import 'package:mix_fit/domain/usecase/auth/is_logged_in_usecase.dart';
import 'package:mix_fit/domain/usecase/auth/login_usecase.dart';
import 'package:mix_fit/domain/usecase/auth/register_usecase.dart';
import 'package:mix_fit/domain/usecase/auth/save_login_in_status_usecase.dart';

import '../../../di/service_locator.dart';
import '../../repository/iot/temperature_repository.dart';
import '../../repository/websocket/websocket_repository.dart';
import '../../usecase/auth/remove_auth_token_usecase.dart';
import '../../usecase/auth/save_auth_token_usecase.dart';
import '../../usecase/iot/get_liquorklin_online_steam_usecase.dart';
import '../../usecase/iot/get_temperature_stream_usecase.dart';
import '../../usecase/websocket/disconnect_websocket_usecase.dart';
import '../../usecase/websocket/get_connection_status_usecase.dart';

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
        () => GetLiquorKilnStreamUseCase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => SaveAuthTokenUseCase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(
        () => RemoveAuthTokenUsecase(getIt<AuthRepository>()));
    getIt.registerLazySingleton(
        () => GetLiquorKilnOnlineStreamUseCase(getIt<ILiquorKilnRepository>()));

    getIt.registerLazySingleton(
        () => RegisterUsecase(getIt<AuthRepository>()));
    //
  }
}
