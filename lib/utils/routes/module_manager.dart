import 'dart:convert';
import 'dart:io';
import 'package:core/base_module.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:yaml/yaml.dart';

import 'package_config.dart';
import 'package:home_screen/home_screen_module.dart';
import 'package:iot/iot_module.dart';

class ModuleManager {
  static final ModuleManager instance = ModuleManager._internal();
  ModuleManager._internal();

  final List<BaseModule> _modules = [];
  final Map<String, Map<String, String>> _moduleRouteNames = {};

  Future<void> initialize() async {
    // Register public modules
    _registerModule(HomeScreenModule());
    _registerModule(IotModule());

    // Load and register private modules
    await _loadPrivateModules();
  }

  Future<void> _loadPrivateModules() async {
    try {
      final privateModulesDir = Directory('modules/cms');
      if (await privateModulesDir.exists()) {
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

  void _registerModule(BaseModule module) {
    _modules.add(module);

    // Register route names for the module
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

  Future<void> registerDependencies(GetIt getIt) async {
    for (var module in _modules) {
      await module.registerDependencies(getIt);
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

      final moduleFile = File('${modulePath}/lib/${moduleName}_module.dart');
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

  Future<BaseModule?> _createModuleInstance(String moduleName) async {
    // Factory pattern để tạo module instance
    // Bạn cần maintain một map của module factories
    switch (moduleName) {
      // case 'auth_module':
      //   return AuthModule();
      // case 'payment_module':
      //   return PaymentModule();
      default:
        print('Unknown module type: $moduleName');
        return null;
    }
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
}
