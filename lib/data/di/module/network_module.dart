import 'package:core/managers/connection_manager.dart';
import 'package:core/network/dio/configs/dio_configs.dart';
import 'package:core/network/dio/dio_client.dart';
import 'package:core/network/dio/interceptors/auth_interceptor.dart';
import 'package:core/network/dio/interceptors/logging_interceptor.dart';
import 'package:core/network/websocket/websocket_service.dart';
import 'package:data/network/constants/endpoints.dart';
import 'package:data/network/interceptors/error_interceptor.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'package:event_bus/event_bus.dart';
import '../../../di/service_locator.dart';

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
