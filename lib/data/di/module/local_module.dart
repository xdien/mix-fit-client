import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mix_fit/core/data/local/database/database.dart';
import 'package:mix_fit/data/local/datasources/post/post_datasource.dart';
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

    getIt.registerSingletonAsync<AppDatabase>(
      () async {
        final database = AppDatabase();
        return database;
      },
      dispose: (db) => db.close(),
    );

    // data sources:------------------------------------------------------------
    getIt.registerSingleton(
      PostDataSource(await getIt
          .getAsync<AppDatabase>()),
    );

    // keychain:----------------------------------------------------------------
    getIt.registerSingletonAsync<FlutterSecureStorage>(
      () async {
        final storage = FlutterSecureStorage();
        return storage;
      },
    );
  }
}
