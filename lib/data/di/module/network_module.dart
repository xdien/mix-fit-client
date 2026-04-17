import 'package:dio/dio.dart';
import 'package:core/network/dio/configs/dio_configs.dart';
import 'package:core/network/dio/dio_client.dart';
import 'package:core/network/dio/interceptors/auth_interceptor.dart';
import 'package:core/network/dio/interceptors/logging_interceptor.dart';
import 'package:core/network/dio/interceptors/retry_interceptor.dart';
import 'package:core/error/interceptors/error_service_interceptor.dart';
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
      DioConfigs(
        baseUrl: Endpoints.baseUrl,
        connectionTimeout: Endpoints.connectionTimeout,
        receiveTimeout: Endpoints.receiveTimeout,
      ),
    );
    // Create DioClient instance
    final dioClient = DioClient(dioConfigs: getIt());
    
    // Register the Dio instance for direct access
    getIt.registerSingleton<Dio>(dioClient.dio);
    
    // Register ErrorServiceInterceptor after Dio is available
    getIt.registerSingleton<ErrorServiceInterceptor>(ErrorServiceInterceptor());
    
    getIt.registerSingleton<DioClient>(
      dioClient
        ..addInterceptors(
          [
            getIt<AuthInterceptor>(),
            RetryInterceptor(
              dio: dioClient.dio,
              options: const RetryOptions(retries: 3),
            ),
            getIt<ErrorServiceInterceptor>(),
            getIt<ErrorInterceptor>(), // Keep existing for backward compatibility
            getIt<LoggingInterceptor>(),
          ],
        ),
    );
    
    // WebSocket is now managed by WebSocketManager in websocket_module.dart
  }
}
