import 'dart:async';
import 'package:core/local/database/database.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../di/service_locator.dart';

class LocalModule {
  static Future<void> configureLocalModuleInjection() async {
    // keychain:----------------------------------------------------------------
    getIt.registerSingletonAsync<FlutterSecureStorage>(
      () async {
        final storage = FlutterSecureStorage();
        return storage;
      },
    );
    // preference manager:------------------------------------------------------
    getIt.registerSingletonAsync<SharedPreferences>(
        SharedPreferences.getInstance);
    getIt.registerSingleton<SharedPreferenceHelper>(
      SharedPreferenceHelper(await getIt.getAsync<SharedPreferences>(), await getIt.getAsync<FlutterSecureStorage>()),
    );

    // database:----------------------------------------------------------------

    getIt.registerLazySingletonAsync<AppDatabase>(
      () async {
        final database = AppDatabase();
        return database;
      },
      dispose: (db) => db.close(),
    );

  }
}
