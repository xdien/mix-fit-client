import 'dart:async';
import 'package:api_client/api.dart';
import 'package:core/domain/repository/websocket_repository.dart';
import 'package:core/network/websocket/websocket_repository_impl.dart';
import 'package:core/network/websocket/websocket_service.dart';
import 'package:data/network/constants/endpoints.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'package:mix_fit/domain/repository/setting/setting_repository.dart';
import '../../../di/service_locator.dart';
import '../../../domain/repository/auth/auth_repository.dart';
import '../../../domain/repository/iot/temperature_repository.dart';
import '../../repository/iot/temperature_repository_impl.dart';
import '../../repository/setting/setting_repository_impl.dart';
import '../../repository/user/user_repository_impl.dart';

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
