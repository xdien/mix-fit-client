import 'dart:async';

import 'package:app_config/configured_app.dart';
import 'package:mix_fit/di/service_locator.dart';
import 'package:mix_fit/presentation/my_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/routes/module_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const String environment =
      String.fromEnvironment('ENV', defaultValue: 'development');

  await setPreferredOrientations();
  await ServiceLocator.configureDependencies();
  await ModuleManager.instance.initialize();
  await ModuleManager.instance.registerDependencies(getIt);
  runApp(
    ConfiguredApp(
      environment: environment,
      builder: (context) => MyApp(),
    ),
  );
}

Future<void> setPreferredOrientations() {
  return SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
}
