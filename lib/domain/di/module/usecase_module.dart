import 'dart:async';

import 'package:mix_fit/domain/repository/user/user_repository.dart';
import 'package:mix_fit/domain/usecase/user/is_logged_in_usecase.dart';
import 'package:mix_fit/domain/usecase/user/login_usecase.dart';
import 'package:mix_fit/domain/usecase/user/save_login_in_status_usecase.dart';

import '../../../di/service_locator.dart';

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

  }
}
