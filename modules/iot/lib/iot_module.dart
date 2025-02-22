import 'package:api_client/api.dart';
import 'package:core/base_module.dart';
import 'package:core/domain/usecase/get_connection_status_usecase.dart';
import 'package:core/network/websocket/websocket_service.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:iot/data/repository/temperature_repository_impl.dart';

import 'domain/repository/i_liquor_kiln_repostitory.dart';
import 'domain/usecase/get_liquorklin_online_steam_usecase.dart';
import 'domain/usecase/get_temperature_stream_usecase.dart';
import 'domain/usecase/set_liquor_kiln_heating_1_usecase.dart';
import 'domain/usecase/set_liquor_kiln_oil_day_max_usecase.dart';
import 'domain/usecase/set_liquor_kiln_oil_day_min_usecase.dart';
import 'domain/usecase/set_liquor_kiln_overheat_usecase.dart';
import 'domain/usecase/set_liquorklin_wifi_reset_usecase.dart';
import 'domain/usecase/toggle_liquor_kiln_water_bump_usecase.dart';
import 'domain/usecase/update_time_liquor_kiln_usecase.dart';
import 'iot_routes.dart';
import 'presentation/liquorkiln-control/liquor_kiln_control_screen.dart';
import 'presentation/liquorkiln-control/store/liquor_kiln_control_store.dart';
import 'presentation/liquorkiln/store/liquor_kiln_store.dart';
import 'presentation/liquorkiln/view/liquor_kiln_screen.dart';

class IotModule extends BaseModule {
  @override
  String get moduleName => 'iot';

  @override
  List<GoRoute> get moduleRoutes => [
        GoRoute(
          path: IotRoutes.liquorKiln,
          builder: (context, state) => LiquorKilnScreen(),
        ),
        // GoRoute(
        //     path: IotRoutes.liquorKilnControl,
        //     builder: (context, state) {
        //       final deviceId = state.pathParameters['deviceId']!;
        //       return LiquorKilnControlScreen(deviceId: deviceId);
        //     }),
      ];

  @override
  Future<void> registerDependencies(GetIt getIt) async {
    getIt.registerLazySingleton(
        () => GetLiquorKilnStreamUseCase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => GetLiquorKilnOnlineStreamUseCase(getIt<ILiquorKilnRepository>()));

    getIt.registerLazySingleton(
        () => SetLiquorKilnHeating1Usecase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => SetLiquorKilnOilDayMaxUsecase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => SetLiquorKilnOilDayMinUsecase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => SetLiquorKilnOverHeatUsecase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => UpdateTimeLiquorKilnUsecase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => SetLiquorklinWifiResetUsecase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton(
        () => ToggleLiquorKilnWaterBumpUsecase(getIt<ILiquorKilnRepository>()));
    getIt.registerLazySingleton<ILiquorKilnRepository>(() =>
        TemperatureRepositoryImpl(getIt<SocketService>(), getIt<ApiClient>()));

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
        getIt<UpdateTimeLiquorKilnUsecase>(),
        getIt<ToggleLiquorKilnWaterBumpUsecase>(),
        deviceId,
      ),
    );
  }

  @override
  void binds(i) {
    // Modular bindings if needed
    // i.addSingleton(() => getIt<FeatureBloc>());
  }
}
