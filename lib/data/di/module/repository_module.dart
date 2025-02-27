import 'dart:async';

import 'package:mix_fit/data/repository/setting/setting_repository_impl.dart';
import 'package:mix_fit/data/repository/user/user_repository_impl.dart';
import 'package:mix_fit/data/sharedpref/shared_preference_helper.dart';
import 'package:mix_fit/domain/repository/setting/setting_repository.dart';
import 'package:mix_fit/data/network/constants/endpoints.dart';

import '../../../di/service_locator.dart';
import 'package:mix_fit/data/network/apis/lib/api.dart';

import '../../../domain/repository/auth/auth_repository.dart';
import '../../../domain/repository/iot/temperature_repository.dart';
import '../../../domain/repository/websocket/websocket_repository.dart';
import '../../network/websocket/websocket_repository_impl.dart';
import '../../network/websocket/websocket_service.dart';
import '../../repository/iot/temperature_repository_impl.dart';

class RepositoryModule {
  static Future<void> configureRepositoryModuleInjection() async {
    // repository:--------------------------------------------------------------
    getIt.registerSingleton<SettingRepository>(SettingRepositoryImpl(
      getIt<SharedPreferenceHelper>(),
    ));
    // Register ApiClient
    getIt.registerSingleton<ApiClient>(ApiClient(basePath: Endpoints.baseUrl,
      authentication: OAuth(accessToken: await getIt<SharedPreferenceHelper>().authToken ?? ''))
    );

    getIt.registerSingleton<AuthRepository>(UserRepositoryImpl(
      getIt<SharedPreferenceHelper>(),getIt<ApiClient>(),
    ));
    getIt.registerLazySingleton<ILiquorKilnRepository>(
      () => TemperatureRepositoryImpl(getIt<SocketService>(),getIt<ApiClient>())
    );
    // Register WebSocket repository
    getIt.registerSingleton<WebSocketRepository>(
      WebSocketRepositoryImpl(getIt<SocketService>()),
    );
  }
}
