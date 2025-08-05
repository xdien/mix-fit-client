import '../models/route_configuration.dart';
import '../models/permission_configuration.dart';
import 'configuration_parser.dart';

/// Manages deeplink configuration loading, caching, and environment handling
/// Provides centralized access to route and permission configurations
class ConfigurationManager {
  static ConfigurationManager? _instance;
  
  RouteConfiguration? _routeConfiguration;
  PermissionConfiguration? _permissionConfiguration;
  
  String? _currentEnvironment;
  String? _routeConfigPath;
  String? _permissionConfigPath;

  ConfigurationManager._();

  /// Get singleton instance
  static ConfigurationManager get instance {
    _instance ??= ConfigurationManager._();
    return _instance!;
  }

  /// Initialize configuration manager with paths and environment
  Future<void> initialize({
    required String routeConfigPath,
    required String permissionConfigPath,
    String? environment,
  }) async {
    _routeConfigPath = routeConfigPath;
    _permissionConfigPath = permissionConfigPath;
    _currentEnvironment = environment;

    // Load configurations
    await _loadConfigurations();
  }

  /// Get current route configuration
  /// Throws StateError if not initialized
  RouteConfiguration get routeConfiguration {
    if (_routeConfiguration == null) {
      throw StateError('Configuration manager not initialized. Call initialize() first.');
    }
    return _routeConfiguration!;
  }

  /// Get current permission configuration
  /// Throws StateError if not initialized
  PermissionConfiguration get permissionConfiguration {
    if (_permissionConfiguration == null) {
      throw StateError('Configuration manager not initialized. Call initialize() first.');
    }
    return _permissionConfiguration!;
  }

  /// Check if configuration manager is initialized
  bool get isInitialized {
    return _routeConfiguration != null && _permissionConfiguration != null;
  }

  /// Get current environment
  String? get currentEnvironment => _currentEnvironment;

  /// Reload configurations from disk
  /// Useful for development or when configurations change
  Future<void> reload() async {
    if (_routeConfigPath == null || _permissionConfigPath == null) {
      throw StateError('Configuration manager not initialized. Call initialize() first.');
    }

    await _loadConfigurations();
  }

  /// Update environment and reload configurations
  Future<void> setEnvironment(String? environment) async {
    if (_routeConfigPath == null || _permissionConfigPath == null) {
      throw StateError('Configuration manager not initialized. Call initialize() first.');
    }

    _currentEnvironment = environment;
    await _loadConfigurations();
  }

  /// Load route configuration only
  Future<void> reloadRouteConfiguration() async {
    if (_routeConfigPath == null) {
      throw StateError('Configuration manager not initialized. Call initialize() first.');
    }

    _routeConfiguration = await ConfigurationParser.loadRouteConfiguration(
      _routeConfigPath!,
      environment: _currentEnvironment,
    );
  }

  /// Load permission configuration only
  Future<void> reloadPermissionConfiguration() async {
    if (_permissionConfigPath == null) {
      throw StateError('Configuration manager not initialized. Call initialize() first.');
    }

    _permissionConfiguration = await ConfigurationParser.loadPermissionConfiguration(
      _permissionConfigPath!,
      environment: _currentEnvironment,
    );
  }

  /// Clear cached configurations
  void clear() {
    _routeConfiguration = null;
    _permissionConfiguration = null;
    _currentEnvironment = null;
    _routeConfigPath = null;
    _permissionConfigPath = null;
  }

  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigurationSummary() {
    return {
      'initialized': isInitialized,
      'environment': _currentEnvironment,
      'routeConfigPath': _routeConfigPath,
      'permissionConfigPath': _permissionConfigPath,
      'routeModules': _routeConfiguration?.getAvailableModules() ?? [],
      'permissionCount': _permissionConfiguration?.getAvailablePermissions().length ?? 0,
      'roleCount': _permissionConfiguration?.getAvailableRoles().length ?? 0,
    };
  }

  /// Validate that route permissions exist in permission configuration
  List<String> validateRoutePermissions() {
    if (!isInitialized) {
      return ['Configuration manager not initialized'];
    }

    final errors = <String>[];
    final routeConfig = _routeConfiguration!;
    final permissionConfig = _permissionConfiguration!;

    // Check each route's permissions
    for (final moduleEntry in routeConfig.routes.entries) {
      final moduleName = moduleEntry.key;
      final moduleConfig = moduleEntry.value;

      for (final featureEntry in moduleConfig.features.entries) {
        final featureName = featureEntry.key;
        final routeDefinition = featureEntry.value;

        for (final permission in routeDefinition.permissions) {
          // Skip wildcard permissions
          if (permission.endsWith('*') || permission == '*') {
            continue;
          }

          if (!permissionConfig.hasPermission(permission)) {
            errors.add(
              'Route $moduleName/$featureName references unknown permission: $permission',
            );
          }
        }
      }
    }

    return errors;
  }

  /// Load both configurations
  Future<void> _loadConfigurations() async {
    // Load configurations in parallel
    final futures = await Future.wait([
      ConfigurationParser.loadRouteConfiguration(
        _routeConfigPath!,
        environment: _currentEnvironment,
      ),
      ConfigurationParser.loadPermissionConfiguration(
        _permissionConfigPath!,
        environment: _currentEnvironment,
      ),
    ]);

    _routeConfiguration = futures[0] as RouteConfiguration;
    _permissionConfiguration = futures[1] as PermissionConfiguration;

    // Validate cross-references
    final validationErrors = validateRoutePermissions();
    if (validationErrors.isNotEmpty) {
      throw ConfigurationError(
        'Configuration validation failed:\n${validationErrors.join('\n')}',
        ConfigurationErrorType.validationError,
      );
    }
  }
}

/// Environment-specific configuration helper
class EnvironmentConfig {
  /// Common environment names
  static const String development = 'dev';
  static const String staging = 'staging';
  static const String production = 'prod';
  static const String testing = 'test';

  /// Get environment from environment variable or default
  static String? getEnvironment({String? defaultEnvironment}) {
    // In Flutter, you might get this from build configuration or runtime
    // For now, return the default or null
    return defaultEnvironment;
  }

  /// Check if current environment is development
  static bool isDevelopment(String? environment) {
    return environment == development;
  }

  /// Check if current environment is production
  static bool isProduction(String? environment) {
    return environment == production;
  }

  /// Check if current environment is testing
  static bool isTesting(String? environment) {
    return environment == testing;
  }
}