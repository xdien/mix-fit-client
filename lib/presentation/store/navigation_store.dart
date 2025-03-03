import 'package:constants/app_routes.dart';
import 'package:mobx/mobx.dart';
part 'navigation_store.g.dart';

class NavigationStore = _NavigationStore with _$NavigationStore;

abstract class _NavigationStore with Store {
  @observable 
  String currentRoute = AppRoutes.home;

  @action
  void setCurrentRoute(String route) {
    currentRoute = route;
  }
}
