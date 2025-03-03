import 'package:core/base_module.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_core/modular_core.dart';

class PaymentModule implements BaseModule {
  @override
  String get moduleName => 'payment';
  
  @override
  List<GoRoute> get moduleRoutes => [];
  
  @override
  Future<void> registerDependencies(GetIt getIt) async {
    print('Using stub implementation for PaymentModule');
  }

  @override
  void binds(Injector i) {

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