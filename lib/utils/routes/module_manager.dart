import 'dart:convert';
import 'dart:io';
import 'package:core/base_module.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:home_screen/home_screen_module.dart';
import 'package:iot/iot_module.dart';
import 'package:mix_fit/utils/routes/stub_modules/cms_auth_stub.dart';
import 'package:yaml/yaml.dart';
import 'module_factory.dart';
import 'package_config.dart';

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
        await _registerDynamicModules(privateModulesDir);
        await for (var entity in privateModulesDir.list()) {
          if (entity is Directory) {
            final module = await _loadPrivateModule(entity.path);
            if (module != null) {
              _registerModule(module);
            }
          }
        }
      }
    } catch (e) {
      print('Error loading private modules: $e');
    }
  }
  Future<void> _registerDynamicModules(Directory moduleRootDir) async {
  await for (var entity in moduleRootDir.list()) {
    if (entity is Directory) {
      final modulePath = entity.path;
      final moduleName = modulePath.split('/').last;
      
      try {
        // Đăng ký đường dẫn vào ModuleFactory
        ModuleFactory.registerPath(moduleName, modulePath);
        
        // Đọc pubspec để lấy thông tin module
        final pubspecFile = File('$modulePath/pubspec.yaml');
        if (await pubspecFile.exists()) {
          final pubspecContent = await pubspecFile.readAsString();
          final pubspec = loadYaml(pubspecContent);
          final fullModuleName = pubspec['name'] as String;
          
          // Đăng ký factory cho module này
          ModuleFactory.register(fullModuleName, () {
            // Đối với module CMS, sử dụng conditional imports
            switch (fullModuleName) {
              // Thêm các trường hợp khác
              default:
                // Thử tải từ đường dẫn nếu không có factory cụ thể
                final moduleFromPath = ModuleFactory.loadModuleFromPath(
                    fullModuleName, modulePath);
                if (moduleFromPath != null) {
                  return moduleFromPath;
                }
                throw Exception('Cannot create module: $fullModuleName');
            }
          });
          
          print('Registered dynamic module: $fullModuleName');
        }
      } catch (e) {
        print('Error registering dynamic module $moduleName: $e');
      }
    }
  }
}

  Future<BaseModule?> _loadPrivateModule(String modulePath) async {
    try {
      final moduleDir = Directory(modulePath);
      if (!await moduleDir.exists()) {
        print('Module directory does not exist: $modulePath');
        return null;
      }

      final pubspecFile = File('${modulePath}/pubspec.yaml');
      if (!await pubspecFile.exists()) {
        print('Module pubspec.yaml not found: $modulePath');
        return null;
      }

      final pubspecContent = await pubspecFile.readAsString();
      final pubspec = loadYaml(pubspecContent);
      final moduleName = pubspec['name'] as String;

      final moduleFile = File('${modulePath}/lib/${moduleName}.dart');
      if (!await moduleFile.exists()) {
        print('Module definition file not found: ${moduleFile.path}');
        return null;
      }

      try {
        final packageConfig = await loadPackageConfig();
        final moduleUri = packageConfig.resolve(
            Uri.parse('package:$moduleName/${moduleName}_module.dart'));

        if (moduleUri == null) {
          print('Could not resolve module URI for: $moduleName');
          return null;
        }
        return await _createModuleInstance(moduleName);
      } catch (e) {
        print('Error loading module $moduleName: $e');
        return null;
      }
    } catch (e) {
      print('Error in _loadPrivateModule: $e');
      return null;
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

  Future<PackageConfig> loadPackageConfig() async {
    try {
      final packageConfigFile = File('.dart_tool/package_config.json');
      if (!await packageConfigFile.exists()) {
        throw Exception('Package config not found');
      }

      final content = await packageConfigFile.readAsString();
      return PackageConfig.fromJson(json.decode(content));
    } catch (e) {
      print('Error loading package config: $e');
      rethrow;
    }
  }

  Future<BaseModule?> _createModuleInstance(String moduleName) async {
    try {
      // Kiểm tra xem đã có factory cho module này chưa
      if (ModuleFactory.hasModule(moduleName)) {
        // Sử dụng factory để tạo module
        return ModuleFactory.create(moduleName);
      }

      // Nếu chưa có, đăng ký đường dẫn module vào factory
      final moduleDir = Directory('modules/cms/$moduleName');
      if (await moduleDir.exists()) {
        ModuleFactory.registerPath(moduleName, moduleDir.path);

        // Sau khi đăng ký đường dẫn, thử tạo lại module
        final module = ModuleFactory.create(moduleName);
        if (module != null) {
          return module;
        }
      }

      // Xử lý trường hợp đặc biệt cho modules bắt đầu bằng 'cms_'
      if (moduleName.startsWith('cms_')) {
        // Thử tạo thông qua conditional imports trong ModuleFactory
        final module = ModuleFactory.create(moduleName);
        if (module != null) {
          return module;
        }

        // Fallback nếu không có conditional import phù hợp
        print('Using stub module for: $moduleName');
        switch (moduleName) {
          case 'cms_auth':
            return CmsAuthModule();
          // Thêm các trường hợp khác nếu cần
          default:
            print('No stub available for module: $moduleName');
            return null;
        }
      }

      print('Module not found and no factory available: $moduleName');
      return null;
    } catch (e) {
      print('Error creating module instance for $moduleName: $e');
      return null;
    }
  }
}
