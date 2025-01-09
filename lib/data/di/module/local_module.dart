import 'dart:async';

import 'package:mix_fit/core/data/local/database/database.dart';
import 'package:mix_fit/data/sharedpref/shared_preference_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../di/service_locator.dart';

class LocalModule {
  static Future<void> configureLocalModuleInjection() async {
    // preference manager:------------------------------------------------------
    getIt.registerSingletonAsync<SharedPreferences>(
        SharedPreferences.getInstance);
    getIt.registerSingleton<SharedPreferenceHelper>(
      SharedPreferenceHelper(await getIt.getAsync<SharedPreferences>()),
    );

    // database:----------------------------------------------------------------

    getIt.registerSingletonAsync<AppDb>(() async {
      final db = AppDb();
      // Optional: You can perform any initial setup here
      return db;
    });

    // data sources:------------------------------------------------------------
    // getIt.registerSingleton(
    //     PostDataSource(await getIt.getAsync<SembastClient>()));
  }
}
