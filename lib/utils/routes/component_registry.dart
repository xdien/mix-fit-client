import 'package:flutter/widgets.dart';

class ComponentRegistry {
  static final ComponentRegistry _instance = ComponentRegistry._internal();
  factory ComponentRegistry() => _instance;
  ComponentRegistry._internal();
  
  final Map<String, WidgetBuilder> _componentBuilders = {};
  
  void registerComponent(String componentKey, WidgetBuilder builder) {
    _componentBuilders[componentKey] = builder;
    print('Registered component: $componentKey');
  }
  
  WidgetBuilder? getComponentBuilder(String componentKey) {
    return _componentBuilders[componentKey];
  }
  
  bool hasComponent(String componentKey) {
    return _componentBuilders.containsKey(componentKey);
  }
  
  Widget buildComponent(String componentKey, BuildContext context) {
    final builder = _componentBuilders[componentKey];
    if (builder == null) {
      print('Component not found: $componentKey');
      return Text('Component not found: $componentKey');
    }
    return builder(context);
  }
}