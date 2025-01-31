import 'package:mobx/mobx.dart';

import '../../constants/app_routes.dart';

part 'navigation_store.g.dart';

class NavigationStore = _NavigationStore with _$NavigationStore;

abstract class _NavigationStore with Store {
  @observable 
  String currentRoute = AppRoutes.post;

  @computed
  bool get isPostRoute => 
    currentRoute == AppRoutes.post || 
    currentRoute.startsWith('${AppRoutes.post}/');

  @action
  void setCurrentRoute(String route) {
    currentRoute = route;
  }
}
