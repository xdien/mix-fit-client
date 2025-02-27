import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:core/base_module.dart';
import 'package:go_router/go_router.dart';
import 'component_registry.dart';

abstract class DynamicModuleBase implements BaseModule {
  final String modulePath;
  final ComponentRegistry _registry = ComponentRegistry();
  
  DynamicModuleBase(this.modulePath);
  
  // Helper methods
  String get moduleLibPath => '$modulePath/lib';
  bool get hasPubspec => File('$modulePath/pubspec.yaml').existsSync();
  
  // Method to register a component
  void registerComponent(String componentKey, WidgetBuilder builder) {
    _registry.registerComponent('${moduleName}_$componentKey', builder);
  }
  
  // Method to get component key
  String getComponentKey(String componentName) {
    return '${moduleName}_$componentName';
  }
  
  // Create a GoRoute that uses the component registry
  GoRoute createDynamicRoute({
    required String path,
    required String name,
    required String componentKey,
    Map<String, String> Function(BuildContext, GoRouterState)? pathParameters,
  }) {
    return GoRoute(
      path: path,
      name: name,
      builder: (context, state) {
        final fullKey = getComponentKey(componentKey);
        // Return the component from registry
        return _registry.buildComponent(fullKey, context);
      },
    );
  }
}
