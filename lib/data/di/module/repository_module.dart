import 'dart:async';

import 'package:mix_fit/data/repository/setting/setting_repository_impl.dart';
import 'package:mix_fit/data/repository/user/user_repository_impl.dart';
import 'package:mix_fit/data/sharedpref/shared_preference_helper.dart';
import 'package:mix_fit/domain/repository/setting/setting_repository.dart';
import 'package:mix_fit/domain/repository/user/user_repository.dart';
import 'package:mix_fit/data/network/constants/endpoints.dart';

import '../../../di/service_locator.dart';
import 'package:api_client/api.dart';

class RepositoryModule {
  static Future<void> configureRepositoryModuleInjection() async {
    // repository:--------------------------------------------------------------
    getIt.registerSingleton<SettingRepository>(SettingRepositoryImpl(
      getIt<SharedPreferenceHelper>(),
    ));
    // Register ApiClient
    getIt.registerSingleton<ApiClient>(ApiClient(basePath: Endpoints.baseUrl));

    getIt.registerSingleton<UserRepository>(UserRepositoryImpl(
      getIt<SharedPreferenceHelper>(),getIt<ApiClient>(),
    ));

  }
}
