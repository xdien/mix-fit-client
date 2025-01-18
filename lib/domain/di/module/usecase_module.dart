import 'dart:async';

import 'package:mix_fit/domain/repository/user/user_repository.dart';
import 'package:mix_fit/domain/usecase/user/is_logged_in_usecase.dart';
import 'package:mix_fit/domain/usecase/user/login_usecase.dart';
import 'package:mix_fit/domain/usecase/user/save_login_in_status_usecase.dart';

import '../../../di/service_locator.dart';
import '../../repository/iot/temperature_repository.dart';
import '../../repository/websocket/websocket_repository.dart';
import '../../usecase/iot/get_connection_status_usecase.dart';
import '../../usecase/iot/get_temperature_stream_usecase.dart';
import '../../usecase/websocket/connect_websocket_usecase.dart';

class UseCaseModule {
  static Future<void> configureUseCaseModuleInjection() async {
    // user:--------------------------------------------------------------------
    getIt.registerSingleton<IsLoggedInUseCase>(
      IsLoggedInUseCase(getIt<UserRepository>()),
    );
    getIt.registerSingleton<SaveLoginStatusUseCase>(
      SaveLoginStatusUseCase(getIt<UserRepository>()),
    );
    getIt.registerSingleton<LoginUseCase>(
      LoginUseCase(getIt<UserRepository>()),
    );
    getIt.registerLazySingleton(() => GetConnectionStatusUseCase(getIt<TemperatureRepository>()));
    getIt.registerLazySingleton(() => GetTemperatureStreamUseCase(getIt<TemperatureRepository>()));
  }
}
