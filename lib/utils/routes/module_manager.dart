import 'dart:io';
import 'package:core/base_module.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:home_screen/home_screen_module.dart';
import 'package:iot/iot_module.dart';
import 'package:yaml/yaml.dart';
import 'dynamic_modules/dynamic_cms_auth_module.dart';
import 'module_factory.dart';

class ModuleManager {
  static final ModuleManager instance = ModuleManager._internal();
  ModuleManager._internal();

  final List<BaseModule> _modules = [];
  final Map<String, Map<String, String>> _moduleRouteNames = {};
  final Map<String, BaseModule> _moduleInstances =
      {}; // Cache các module đã tạo

  Future<void> initialize() async {
    _registerBuiltInModuleFactories();

    _registerModule(HomeScreenModule());
    _registerModule(IotModule());

    // Load và đăng ký các module động
    await _loadPrivateModules();
  }

  // Đăng ký các built-in modules vào factory
  void _registerBuiltInModuleFactories() {
    ModuleFactory.register('home_screen', () => HomeScreenModule());
    ModuleFactory.register('iot', () => IotModule());
  }

  Future<void> _loadPrivateModules() async {
    try {
      final privateModulesDir = Directory('modules/cms');
      if (await privateModulesDir.exists()) {
        await for (var entity in privateModulesDir.list()) {
          if (entity is Directory) {
            final modulePath = entity.path;
            final pubspecFile = File('$modulePath/pubspec.yaml');

            if (await pubspecFile.exists()) {
              final pubspecContent = await pubspecFile.readAsString();
              final pubspec = loadYaml(pubspecContent);
              final moduleName = pubspec['name'] as String;

              print('Found module: $moduleName in $modulePath');

              // Đăng ký đường dẫn module
              ModuleFactory.registerPath(moduleName, modulePath);

              // Thêm đăng ký factory cho module
              if (!ModuleFactory.hasModule(moduleName)) {
                print('Registering dynamic module factory for $moduleName');

                // Đăng ký factory tùy theo loại module
                if (moduleName == 'cms_auth') {
                  ModuleFactory.register(moduleName, () {
                    print('Creating dynamic CmsAuthModule');
                    return DynamicCmsAuthModule(modulePath);
                  });
                }
                // Thêm các loại module khác ở đây
              }

              // Load module
              final module = ModuleFactory.create(moduleName);
              if (module != null) {
                _registerModule(module);
                print('Successfully loaded dynamic module: $moduleName');
              } else {
                print('Failed to create module: $moduleName');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading private modules: $e');
    }
  }

  void _registerModule(BaseModule module) {
    // Nếu module đã được đăng ký, không thêm lại
    if (_moduleInstances.containsKey(module.moduleName)) {
      return;
    }

    _modules.add(module);
    _moduleInstances[module.moduleName] = module;

    // Đăng ký route names cho module
    final routeNames = <String, String>{};
    for (var route in module.moduleRoutes) {
      routeNames[route.name ?? ''] = route.path;
    }
    _moduleRouteNames[module.moduleName] = routeNames;
  }

  List<GoRoute> getModuleRoutes() {
    return _modules.expand((module) => module.moduleRoutes).toList();
  }

  String? getModuleRoute(String moduleName, String routeName) {
    return _moduleRouteNames[moduleName]?[routeName];
  }

  // Tìm route theo tên màn hình
  GoRoute? getRouteByScreenName(String screenName) {
    for (var module in _modules) {
      try {
        final route = module.moduleRoutes.firstWhere(
          (route) => route.name == screenName,
        );
        return route;
      } catch (e) {
        // Không tìm thấy route trong module này, tiếp tục tìm
        continue;
      }
    }
    return null;
  }

  Future<void> registerDependencies(GetIt getIt) async {
    for (var module in _modules) {
      await module.registerDependencies(getIt);
    }
  }

  // Phương thức để lấy class từ một module
  T? getClassInstance<T extends Object>(String moduleName, String className) {
    final module = _moduleInstances[moduleName];
    if (module == null) {
      print('Module $moduleName not found');
      return null;
    }

    // Sử dụng GetIt để lấy instance nếu đã được đăng ký
    final getIt = GetIt.instance;
    if (getIt.isRegistered<T>()) {
      return getIt<T>();
    }

    // Nếu không tìm thấy qua GetIt, trả về null
    print('Class $className not found in module $moduleName');
    return null;
  }

  // Kiểm tra xem module có tồn tại không
  bool hasModule(String moduleName) {
    return _moduleInstances.containsKey(moduleName);
  }

  // Lấy module theo tên
  BaseModule? getModule(String moduleName) {
    return _moduleInstances[moduleName];
  }

  // Lấy danh sách tất cả các module
  List<String> getAllModuleNames() {
    return _moduleInstances.keys.toList();
  }
}
