/// Shared module management interface
/// This provides access to module availability checking for shared modules
class ModuleManagement {
  static final ModuleManagement _instance = ModuleManagement._internal();
  ModuleManagement._internal();
  
  static ModuleManagement get instance => _instance;
  
  // Cache for module availability
  final Map<String, bool> _moduleCache = {};
  
  /// Check if a module is available
  /// This method will be implemented by the main app to provide actual module checking
  bool hasModule(String moduleName) {
    // Default implementation - modules are not available in shared context
    // This will be overridden by the main app
    return _moduleCache[moduleName] ?? false;
  }
  
  /// Set module availability (called by main app)
  void setModuleAvailability(String moduleName, bool available) {
    _moduleCache[moduleName] = available;
  }
  
  /// Clear all cached module availability
  void clearCache() {
    _moduleCache.clear();
  }
}
