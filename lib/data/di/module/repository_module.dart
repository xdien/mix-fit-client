import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:api_client/api.dart';
import 'package:auth/domain/repository/auth/auth_repository.dart';
import 'package:core/domain/repository/websocket_repository.dart';
import 'package:core/network/websocket/websocket_repository_impl.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/network/constants/endpoints.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'package:setting/data/repository/setting/setting_repository_impl.dart';
import 'package:setting/domain/repository/setting/setting_repository.dart';
import '../../../di/service_locator.dart';
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

    // Register specific API classes
    getIt.registerLazySingleton<VehicleRepairEntryApi>(
      () => VehicleRepairEntryApi(getIt<ApiClient>()),
    );
    
    getIt.registerLazySingleton<CustomerManagementApi>(
      () => CustomerManagementApi(getIt<ApiClient>()),
    );

    getIt.registerSingleton<AuthRepository>(UserRepositoryImpl(
      getIt<SharedPreferenceHelper>(),getIt<ApiClient>(),
    ));
    
    // Register WebSocket repository using WebSocketManager
    // Check if WebSocketManager is initialized before registering
    final webSocketService = WebSocketManager.instance.webSocketService;
    if (webSocketService != null) {
      getIt.registerSingleton<WebSocketRepository>(
        WebSocketRepositoryImpl(webSocketService),
      );
    } else {
      // Register a null WebSocket repository if WebSocket is not available
      debugPrint('WebSocket service not available, skipping WebSocket repository registration');
    }
  }
}
