import 'package:core/base_module.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:home_screen/presentation/home/home.dart';

class HomeScreenModule extends BaseModule {
  @override
  String get moduleName => 'home_screen';

  @override
  List<GoRoute> get moduleRoutes => [
    GoRoute(
        path: "/home",
        builder: (context, state) => HomeScreen(),
      ),
  ];

  @override
  Future<void> registerDependencies(GetIt getIt) async {
  }

  @override
  void binds(i) {
    // Modular bindings if needed
    // i.addSingleton(() => getIt<FeatureBloc>());
  }
}