import 'package:core/base_module.dart';
import 'export_module.dart';

class ModuleFactory {
  static final Map<String, BaseModule Function()> _factories = {};
  static final Map<String, String> _modulePaths = {};
  
  // Đăng ký module factory
  static void register(String moduleName, BaseModule Function() factory) {
    _factories[moduleName] = factory;
  }
  
  // Đăng ký đường dẫn module
  static void registerPath(String moduleName, String modulePath) {
    _modulePaths[moduleName] = modulePath;
  }
  
  // Lấy module từ factory
  static BaseModule? create(String moduleName) {
    // Thử dùng factory đã đăng ký
    final factory = _factories[moduleName];
    if (factory != null) {
      try {
        return factory();
      } catch (e) {
        print('Error creating module $moduleName: $e');
      }
    }
    
    // Thử tìm và load trực tiếp từ đường dẫn
    final modulePath = _modulePaths[moduleName];
    if (modulePath != null) {
      try {
        return loadModuleFromPath(moduleName, modulePath);
      } catch (e) {
        print('Error loading module $moduleName from path: $e');
      }
    }
    
    return null;
  }
  
  // Kiểm tra một module có được đăng ký không
  static bool hasModule(String moduleName) {
    return _factories.containsKey(moduleName) || _modulePaths.containsKey(moduleName);
  }
  
  // Load module từ path
  static BaseModule? loadModuleFromPath(String moduleName, String modulePath) {
    // Xử lý các loại module cụ thể
    switch (moduleName) {
      case 'cms_auth':
          return CmsAuthModule();
      // Thêm các trường hợp khác ở đây
        
      default:
        print('No specific handler for module type: $moduleName');
        return null;
    }
  }
}
