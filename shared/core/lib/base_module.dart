import 'package:flutter_modular/flutter_modular.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

abstract class BaseModule extends Module {
  String get moduleName;
  List<GoRoute> get moduleRoutes;
  Future<void> registerDependencies(GetIt getIt);
}