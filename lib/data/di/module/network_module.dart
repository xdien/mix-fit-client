import 'package:mix_fit/core/data/network/dio/configs/dio_configs.dart';
import 'package:mix_fit/core/data/network/dio/dio_client.dart';
import 'package:mix_fit/core/data/network/dio/interceptors/auth_interceptor.dart';
import 'package:mix_fit/core/data/network/dio/interceptors/logging_interceptor.dart';
import 'package:mix_fit/data/network/constants/endpoints.dart';
import 'package:mix_fit/data/network/interceptors/error_interceptor.dart';
import 'package:mix_fit/data/network/rest_client.dart';
import 'package:mix_fit/data/sharedpref/shared_preference_helper.dart';
import 'package:event_bus/event_bus.dart';

import '../../../core/managers/connection_manager.dart';
import '../../../di/service_locator.dart';
import '../../network/websocket/websocket_service.dart';

class NetworkModule {
  static Future<void> configureNetworkModuleInjection() async {
    // event bus:---------------------------------------------------------------
    getIt.registerSingleton<EventBus>(EventBus());

    // interceptors:------------------------------------------------------------
    getIt.registerSingleton<LoggingInterceptor>(LoggingInterceptor());
    getIt.registerSingleton<ErrorInterceptor>(ErrorInterceptor(getIt()));
    getIt.registerSingleton<AuthInterceptor>(
      AuthInterceptor(
        accessToken: () async => await getIt<SharedPreferenceHelper>().authToken,
      ),
    );

    // rest client:-------------------------------------------------------------
    getIt.registerSingleton(RestClient());

    // dio:---------------------------------------------------------------------
    getIt.registerSingleton<DioConfigs>(
      const DioConfigs(
        baseUrl: Endpoints.baseUrl,
        connectionTimeout: Endpoints.connectionTimeout,
        receiveTimeout:Endpoints.receiveTimeout,
      ),
    );
    getIt.registerSingleton<DioClient>(
      DioClient(dioConfigs: getIt())
        ..addInterceptors(
          [
            getIt<AuthInterceptor>(),
            getIt<ErrorInterceptor>(),
            getIt<LoggingInterceptor>(),
          ],
        ),
    );
    getIt.registerSingleton<SocketService>(
      SocketService(
         url: Endpoints.baseUrl,
         tokenProvider: () async => await getIt<SharedPreferenceHelper>().authToken,
      ),
    );
    // Register ConnectionManager as singleton
    getIt.registerSingleton<ConnectionManager>(
      ConnectionManager(
        socketService: getIt<SocketService>(),
        sharedPreferenceHelper: getIt<SharedPreferenceHelper>(),
      ),
    );
  }
}
