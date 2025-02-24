import 'dart:async';
import 'package:auth/domain/usecase/is_logged_in_usecase.dart';
import 'package:auth/domain/usecase/login_usecase.dart';
import 'package:auth/domain/usecase/register_usecase.dart';
import 'package:auth/domain/usecase/remove_auth_token_usecase.dart';
import 'package:auth/domain/usecase/save_auth_token_usecase.dart';
import 'package:auth/domain/usecase/save_login_in_status_usecase.dart';
import 'package:constants/stores/error/error_store.dart';
import 'package:core/stores/form/form_store.dart';
import 'package:home_screen/presentation/home/store/language/language_store.dart';
import 'package:mix_fit/presentation/login/store/login_store.dart';
import 'package:mix_fit/presentation/register/store/register_store.dart';
import 'package:setting/domain/repository/setting/setting_repository.dart';
import 'package:setting/theme_store.dart';

import '../../../di/service_locator.dart';
import '../../store/navigation_store.dart';

class StoreModule {
  static Future<void> configureStoreModuleInjection() async {
    // factories:---------------------------------------------------------------
    getIt.registerFactory(() => ErrorStore());
    getIt.registerFactory(() => FormErrorStore());
    getIt.registerFactory(() => NavigationStore());
    getIt.registerFactory(
      () => FormStore(getIt<FormErrorStore>(), getIt<ErrorStore>()),
    );

    getIt.registerSingleton<LanguageStore>(
      LanguageStore(
        getIt<SettingRepository>(),
        getIt<ErrorStore>(),
      ));

    // stores:------------------------------------------------------------------
    getIt.registerSingleton<UserStore>(
      UserStore(
        getIt<IsLoggedInUseCase>(),
        getIt<SaveLoginStatusUseCase>(),
        getIt<SaveAuthTokenUseCase>(),
        getIt<RemoveAuthTokenUsecase>(),
        getIt<LoginUseCase>(),
        getIt<FormErrorStore>(),
        getIt<ErrorStore>(),
      ),
    );

    getIt.registerSingleton<ThemeStore>(
      ThemeStore(
        getIt<SettingRepository>(),
        getIt<ErrorStore>(),
      ),
    );
    getIt.registerLazySingleton<RegisterStore>(
      () => RegisterStore(getIt<ErrorStore>(), getIt<RegisterUsecase>()),
    );
  }
}
