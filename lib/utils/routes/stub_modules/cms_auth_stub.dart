import 'package:core/base_module.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_core/modular_core.dart';

class CmsAuthModule implements BaseModule {
  @override
  String get moduleName => 'cms_auth';
  
  @override
  List<GoRoute> get moduleRoutes => [];
  
  @override
  Future<void> registerDependencies(GetIt getIt) async {
    // No-op implementation
    print('Using stub implementation for CmsAuthModule');
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