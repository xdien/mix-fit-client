import 'dart:async';
import 'package:mix_fit/core/stores/error/error_store.dart';
import 'package:mix_fit/core/stores/form/form_store.dart';
import 'package:mix_fit/domain/repository/setting/setting_repository.dart';
import 'package:mix_fit/presentation/home/store/language/language_store.dart';
import 'package:mix_fit/presentation/home/store/theme/theme_store.dart';
import 'package:mix_fit/presentation/login/store/login_store.dart';
import 'package:mix_fit/presentation/register/store/register_store.dart';

import '../../../di/service_locator.dart';
import '../../../domain/usecase/auth/is_logged_in_usecase.dart';
import '../../../domain/usecase/auth/login_usecase.dart';
import '../../../domain/usecase/auth/register_usecase.dart';
import '../../../domain/usecase/auth/remove_auth_token_usecase.dart';
import '../../../domain/usecase/auth/save_auth_token_usecase.dart';
import '../../../domain/usecase/auth/save_login_in_status_usecase.dart';
import '../../../domain/usecase/iot/get_liquorklin_online_steam_usecase.dart';
import '../../../domain/usecase/iot/get_temperature_stream_usecase.dart';
import '../../../domain/usecase/iot/set_liquor_kiln_heating_1_usecase.dart';
import '../../../domain/usecase/iot/set_liquor_kiln_oil_day_max_usecase.dart';
import '../../../domain/usecase/iot/set_liquor_kiln_oil_day_min_usecase.dart';
import '../../../domain/usecase/iot/set_liquor_kiln_overheat_usecase.dart';
import '../../../domain/usecase/iot/set_liquorklin_wifi_reset_usecase.dart';
import '../../../domain/usecase/iot/update_time_liquor_kiln_usecase.dart';
import '../../../domain/usecase/websocket/get_connection_status_usecase.dart';
import '../../liquorkiln-control/store/liquor_kiln_control_store.dart';
import '../../liquorkiln/store/liquor_kiln_store.dart';
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

    getIt.registerSingleton<LanguageStore>(
      LanguageStore(
        getIt<SettingRepository>(),
        getIt<ErrorStore>(),
      ),
    );

    getIt.registerLazySingleton<RegisterStore>(
      () => RegisterStore(getIt<ErrorStore>(), getIt<RegisterUsecase>()),
    );

    getIt.registerFactoryParam<LiquorKilnStore, String, void>(
      (deviceId, _) => LiquorKilnStore(
        getIt<GetConnectionStatusUseCase>(),
        getIt<GetLiquorKilnStreamUseCase>(),
        getIt<GetLiquorKilnOnlineStreamUseCase>(),
        getIt<SetLiquorKilnHeating1Usecase>(),
        getIt<SetLiquorKilnOverHeatUsecase>(),
        getIt<SetLiquorKilnOilDayMinUsecase>(),
        getIt<SetLiquorKilnOilDayMaxUsecase>(),
        getIt<UpdateTimeLiquorKilnUsecase>(),
        deviceId,
      ),
    );

    getIt.registerFactoryParam<LiquorKilnControlStore, String, void>(
      (deviceId, _) => LiquorKilnControlStore(
        getIt<SetLiquorklinWifiResetUsecase>(),
        deviceId,
      ),
    );
  }
}
