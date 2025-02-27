import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../dynamic_module_base.dart';
import '../dynamic_module_component_loader.dart';

class DynamicCmsAuthModule extends DynamicModuleBase {
  DynamicCmsAuthModule(String modulePath) : super(modulePath) {
    print('Initializing Dynamic CMS Auth Module from $modulePath');
    _initializeComponents();
  }
  
  @override
  String get moduleName => 'cms_auth';
  
  // Initialize components from the module dynamically
  void _initializeComponents() {
    // Load các lazy component builders 
    // Các builder này sẽ lazy load các component từ module khi cần
    
    // Đăng ký component: login screen
    registerComponent('login_screen', (context) {
      // GIẢI PHÁP:
      // 1. Trả về một widget container thực sự load UI từ module
      return DynamicModuleComponentLoader(
        moduleName: moduleName,
        componentKey: 'login_screen',
        modulePath: modulePath,
        // Fallback UI khi không load được
        fallbackBuilder: (context) => Text('CMS Login Screen (Fallback)'),
      );
    });
    
    // Đăng ký component: dashboard screen
    registerComponent('dashboard_screen', (context) {
      return DynamicModuleComponentLoader(
        moduleName: moduleName,
        componentKey: 'dashboard_screen',
        modulePath: modulePath,
        fallbackBuilder: (context) => Text('CMS Dashboard Screen (Fallback)'),
      );
    });
  }
  
  @override
  List<GoRoute> get moduleRoutes {
    print('Getting routes for dynamic CMS Auth Module');
    
    // Tạo routes sử dụng dynamic components
    return [
      createDynamicRoute(
        path: '/cms/login',
        name: 'cms_login',
        componentKey: 'login_screen',
      ),
      createDynamicRoute(
        path: '/cms/dashboard',
        name: 'cms_dashboard',
        componentKey: 'dashboard_screen',
      ),
    ];
  }
  
  @override
  Future<void> registerDependencies(GetIt getIt) async {
    print('Registering dependencies for dynamic CMS Auth Module');
    
    // Đăng ký các services từ module
    // Đọc từ module descriptor nếu có
    final servicesFile = File('$modulePath/lib/services.json');
    if (servicesFile.existsSync()) {
      try {
        final servicesJson = json.decode(servicesFile.readAsStringSync());
        // Xử lý services...
      } catch (e) {
        print('Error registering services: $e');
      }
    }
  }
  
  // Implement các methods khác của BaseModule
  @override
  void binds(Injector i) {
    // Implementation 
  }

  @override
  void exportedBinds(Injector i) {
    // Implementation
  }

  @override
  List<Module> get imports => [];

  @override
  void routes(RouteManager r) {
    throw UnimplementedError();
    // Implementation
  //   r.module('/cms', module: this, children: [
  //     r.route('/login', name: 'login_screen'),
  //     r.route('/dashboard', name: 'dashboard_screen'),
  //   ]);
  }
}