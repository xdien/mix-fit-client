import 'package:core/base_module.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_core/modular_core.dart';

class CmsSalesDashboardModule implements BaseModule {
  @override
  String get moduleName => 'sales_dashboard';
  
  @override
  List<GoRoute> get moduleRoutes => [];
  
  @override
  Future<void> registerDependencies(GetIt getIt) async {
    // No-op implementation
    print('Using stub implementation for CmsSalesDashboardModule');
  }

  @override
  void binds(Injector i) {
    // TODO: implement binds
  }

  @override
  void exportedBinds(Injector i) {
    // TODO: implement exportedBinds
  }

  @override
  // TODO: implement imports
  List<Module> get imports => throw UnimplementedError();

  @override
  void routes(RouteManager r) {
    // TODO: implement routes
  }
}