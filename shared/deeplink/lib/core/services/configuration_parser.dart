import 'dart:convert';
import 'dart:io';

import '../models/route_configuration.dart';
import '../models/permission_configuration.dart';
import '../errors/deeplink_error.dart';

/// Service for parsing and validating deeplink configuration files
/// Supports JSON format with comprehensive validation
class ConfigurationParser {
  /// Parse route configuration from JSON string
  /// Throws ConfigurationParsingError if parsing or validation fails
  static RouteConfiguration parseRouteConfiguration(String jsonContent) {
    try {
      final json = jsonDecode(jsonContent) as Map<String, dynamic>;
      final config = RouteConfiguration.fromJson(json);
      
      // Validate the configuration
      _validateRouteConfiguration(config);
      
      return config;
    } on FormatException catch (e) {
      throw ConfigurationError(
        message: 'Invalid JSON format in route configuration: ${e.message}',
        configPath: 'route_configuration',
      );
    } catch (e) {
      if (e is ConfigurationError) rethrow;
      throw ConfigurationError(
        message: 'Failed to parse route configuration: $e',
        configPath: 'route_configuration',
      );
    }
  }

  /// Parse permission configuration from JSON string
  /// Throws ConfigurationError if parsing or validation fails
  static PermissionConfiguration parsePermissionConfiguration(String jsonContent) {
    try {
      final json = jsonDecode(jsonContent) as Map<String, dynamic>;
      final config = PermissionConfiguration.fromJson(json);
      
      // Validate the configuration
      _validatePermissionConfiguration(config);
      
      return config;
    } on FormatException catch (e) {
      throw ConfigurationError(
        message: 'Invalid JSON format in permission configuration: ${e.message}',
        configPath: 'permission_configuration',
      );
    } catch (e) {
      if (e is ConfigurationError) rethrow;
      throw ConfigurationError(
        message: 'Failed to parse permission configuration: $e',
        configPath: 'permission_configuration',
      );
    }
  }

  /// Load route configuration from file
  /// Supports environment-specific configuration loading
  static Future<RouteConfiguration> loadRouteConfiguration(
    String configPath, {
    String? environment,
  }) async {
    try {
      final effectivePath = resolveConfigPath(configPath, environment);
      final file = File(effectivePath);
      
      if (!await file.exists()) {
        throw ConfigurationError(
          message: 'Route configuration file not found: $effectivePath',
          configPath: configPath,
        );
      }
      
      final content = await file.readAsString();
      return parseRouteConfiguration(content);
    } on ConfigurationError {
      rethrow;
    } catch (e) {
      throw ConfigurationError(
        message: 'Failed to load route configuration from $configPath: $e',
        configPath: configPath,
      );
    }
  }

  /// Load permission configuration from file
  /// Supports environment-specific configuration loading
  static Future<PermissionConfiguration> loadPermissionConfiguration(
    String configPath, {
    String? environment,
  }) async {
    try {
      final effectivePath = resolveConfigPath(configPath, environment);
      final file = File(effectivePath);
      
      if (!await file.exists()) {
        throw ConfigurationError(
          message: 'Permission configuration file not found: $effectivePath',
          configPath: configPath,
        );
      }
      
      final content = await file.readAsString();
      return parsePermissionConfiguration(content);
    } on ConfigurationError {
      rethrow;
    } catch (e) {
      throw ConfigurationError(
        message: 'Failed to load permission configuration from $configPath: $e',
        configPath: configPath,
      );
    }
  }

  /// Resolve configuration path with environment-specific overrides
  /// Supports patterns like config.json -> config.dev.json for development
  static String resolveConfigPath(String basePath, String? environment) {
    if (environment == null || environment.isEmpty) {
      return basePath;
    }
    
    final file = File(basePath);
    final directory = file.parent.path;
    final fileName = file.uri.pathSegments.last;
    
    // Split filename and extension
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) {
      // No extension, append environment
      return '$directory/${fileName}.$environment';
    }
    
    final nameWithoutExt = fileName.substring(0, lastDotIndex);
    final extension = fileName.substring(lastDotIndex);
    
    return '$directory/$nameWithoutExt.$environment$extension';
  }

  /// Validate route configuration structure and content
  static void _validateRouteConfiguration(RouteConfiguration config) {
    // Validate that we have at least one route
    if (config.routes.isEmpty) {
      throw ConfigurationError(
        message: 'Route configuration must contain at least one module',
        configPath: 'route_configuration',
      );
    }

    // Validate each module
    for (final entry in config.routes.entries) {
      final moduleName = entry.key;
      final moduleConfig = entry.value;
      
      _validateModuleName(moduleName);
      _validateModuleConfiguration(moduleName, moduleConfig);
    }

    // Validate fallback configuration
    _validateFallbackConfiguration(config.fallbacks);
  }

  /// Validate module name format
  static void _validateModuleName(String moduleName) {
    if (moduleName.isEmpty) {
      throw ConfigurationError(
        message: 'Module name cannot be empty',
        configPath: 'route_configuration',
      );
    }
    
    // Module names should be lowercase with optional hyphens/underscores
    final validPattern = RegExp(r'^[a-z][a-z0-9_-]*$');
    if (!validPattern.hasMatch(moduleName)) {
      throw ConfigurationError(
        message: 'Invalid module name format: $moduleName. Must be lowercase alphanumeric with optional hyphens/underscores',
        configPath: 'route_configuration',
      );
    }
  }

  /// Validate module configuration
  static void _validateModuleConfiguration(String moduleName, ModuleConfiguration moduleConfig) {
    if (moduleConfig.features.isEmpty) {
      throw ConfigurationError(
        message: 'Module $moduleName must contain at least one feature',
        configPath: 'route_configuration',
      );
    }

    // Validate each feature
    for (final entry in moduleConfig.features.entries) {
      final featureName = entry.key;
      final routeDefinition = entry.value;
      
      _validateFeatureName(moduleName, featureName);
      _validateRouteDefinition(moduleName, featureName, routeDefinition);
    }
  }

  /// Validate feature name format
  static void _validateFeatureName(String moduleName, String featureName) {
    if (featureName.isEmpty) {
      throw ConfigurationError(
        message: 'Feature name cannot be empty in module $moduleName',
        configPath: 'route_configuration',
      );
    }
    
    // Feature names should be lowercase with optional hyphens/underscores
    final validPattern = RegExp(r'^[a-z][a-z0-9_-]*$');
    if (!validPattern.hasMatch(featureName)) {
      throw ConfigurationError(
        message: 'Invalid feature name format: $featureName in module $moduleName. Must be lowercase alphanumeric with optional hyphens/underscores',
        configPath: 'route_configuration',
      );
    }
  }

  /// Validate route definition
  static void _validateRouteDefinition(String moduleName, String featureName, RouteDefinition routeDefinition) {
    // Validate screen name
    if (routeDefinition.screen.isEmpty) {
      throw ConfigurationError(
        message: 'Screen name cannot be empty for route $moduleName/$featureName',
        configPath: 'route_configuration',
      );
    }

    // Validate permissions format
    for (final permission in routeDefinition.permissions) {
      _validatePermissionName(permission, '$moduleName/$featureName');
    }

    // Validate parameter definitions
    for (final entry in routeDefinition.parameters.entries) {
      final paramName = entry.key;
      final paramDef = entry.value;
      
      _validateParameterName(paramName, '$moduleName/$featureName');
      _validateParameterDefinition(paramName, paramDef, '$moduleName/$featureName');
    }
  }

  /// Validate permission name format
  static void _validatePermissionName(String permission, String context) {
    if (permission.isEmpty) {
      throw ConfigurationError(
        message: 'Permission name cannot be empty in route $context',
        configPath: 'route_configuration',
      );
    }
    
    // Permission names should follow dot notation: module.action
    final validPattern = RegExp(r'^(\*|[a-z][a-z0-9_-]*(\.[a-z][a-z0-9_-]*)*(\.\*)?|\*\.[a-z][a-z0-9_-]*(\.[a-z][a-z0-9_-]*)*)$');
    if (!validPattern.hasMatch(permission)) {
      throw ConfigurationError(
        message: 'Invalid permission name format: $permission in route $context. Must follow dot notation (e.g., module.action)',
        configPath: 'route_configuration',
      );
    }
  }

  /// Validate parameter name format
  static void _validateParameterName(String paramName, String context) {
    if (paramName.isEmpty) {
      throw ConfigurationError(
        message: 'Parameter name cannot be empty in route $context',
        configPath: 'route_configuration',
      );
    }
    
    // Parameter names should be camelCase or snake_case
    final validPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    if (!validPattern.hasMatch(paramName)) {
      throw ConfigurationError(
        message: 'Invalid parameter name format: $paramName in route $context. Must be alphanumeric with optional underscores',
        configPath: 'route_configuration',
      );
    }
  }

  /// Validate parameter definition
  static void _validateParameterDefinition(String paramName, ParameterDefinition paramDef, String context) {
    // Validate parameter type
    const validTypes = ['string', 'int', 'bool', 'double'];
    if (!validTypes.contains(paramDef.type)) {
      throw ConfigurationError(
        message: 'Invalid parameter type: ${paramDef.type} for parameter $paramName in route $context. Must be one of: ${validTypes.join(', ')}',
        configPath: 'route_configuration',
      );
    }

    // Validate pattern if provided
    if (paramDef.pattern != null) {
      try {
        RegExp(paramDef.pattern!);
      } catch (e) {
        throw ConfigurationError(
          message: 'Invalid regex pattern for parameter $paramName in route $context: ${paramDef.pattern}',
          configPath: 'route_configuration',
        );
      }
    }
  }

  /// Validate fallback configuration
  static void _validateFallbackConfiguration(FallbackConfiguration fallbacks) {
    final routes = [
      fallbacks.defaultRoute,
      fallbacks.permissionDeniedRoute,
      fallbacks.notFoundRoute,
      fallbacks.errorRoute,
    ];

    for (final route in routes) {
      if (route.isEmpty) {
        throw ConfigurationError(
          message: 'Fallback route cannot be empty',
          configPath: 'route_configuration',
        );
      }
    }
  }

  /// Validate permission configuration structure and content
  static void _validatePermissionConfiguration(PermissionConfiguration config) {
    // Validate that we have at least one permission or role
    if (config.permissions.isEmpty && config.roles.isEmpty) {
      throw ConfigurationError(
        message: 'Permission configuration must contain at least one permission or role',
        configPath: 'permission_configuration',
      );
    }

    // Validate each permission
    for (final entry in config.permissions.entries) {
      final permissionName = entry.key;
      final permissionDef = entry.value;
      
      _validatePermissionName(permissionName, 'permission definition');
      _validatePermissionDefinition(permissionName, permissionDef);
    }

    // Validate each role
    for (final entry in config.roles.entries) {
      final roleName = entry.key;
      final roleDef = entry.value;
      
      _validateRoleName(roleName);
      _validateRoleDefinition(roleName, roleDef, config);
    }
  }

  /// Validate permission definition
  static void _validatePermissionDefinition(String permissionName, PermissionDefinition permissionDef) {
    if (permissionDef.description.isEmpty) {
      throw ConfigurationError(
        message: 'Permission description cannot be empty for permission $permissionName',
        configPath: 'permission_configuration',
      );
    }

    // Validate referenced roles exist (this would need the full config context)
    for (final role in permissionDef.roles) {
      _validateRoleName(role);
    }
  }

  /// Validate role name format
  static void _validateRoleName(String roleName) {
    if (roleName.isEmpty) {
      throw ConfigurationError(
        message: 'Role name cannot be empty',
        configPath: 'permission_configuration',
      );
    }
    
    // Role names should be lowercase with optional underscores
    final validPattern = RegExp(r'^[a-z][a-z0-9_]*$');
    if (!validPattern.hasMatch(roleName)) {
      throw ConfigurationError(
        message: 'Invalid role name format: $roleName. Must be lowercase alphanumeric with optional underscores',
        configPath: 'permission_configuration',
      );
    }
  }

  /// Validate role definition
  static void _validateRoleDefinition(String roleName, RoleDefinition roleDef, PermissionConfiguration config) {
    // Validate permissions referenced by the role
    for (final permission in roleDef.permissions) {
      if (permission != '*' && !permission.endsWith('*')) {
        // Direct permission reference - should exist in config
        if (!config.hasPermission(permission)) {
          throw ConfigurationError(
            message: 'Role $roleName references unknown permission: $permission',
            configPath: 'permission_configuration',
          );
        }
      }
    }

    // Validate inherited roles exist
    for (final parentRole in roleDef.inherits) {
      if (!config.hasRole(parentRole)) {
        throw ConfigurationError(
          message: 'Role $roleName inherits from unknown role: $parentRole',
          configPath: 'permission_configuration',
        );
      }
    }

    // Check for circular inheritance (basic check)
    _checkCircularInheritance(roleName, roleDef, config, []);
  }

  /// Check for circular inheritance in role definitions
  static void _checkCircularInheritance(
    String roleName,
    RoleDefinition roleDef,
    PermissionConfiguration config,
    List<String> visited,
  ) {
    if (visited.contains(roleName)) {
      throw ConfigurationError(
        message: 'Circular inheritance detected in role hierarchy: ${visited.join(' -> ')} -> $roleName',
        configPath: 'permission_configuration',
      );
    }

    visited.add(roleName);

    for (final parentRole in roleDef.inherits) {
      final parentRoleDef = config.getRole(parentRole);
      if (parentRoleDef != null) {
        _checkCircularInheritance(parentRole, parentRoleDef, config, List.from(visited));
      }
    }
  }
}

/// Configuration error types
enum ConfigurationErrorType {
  invalidFormat,
  parsingError,
  validationError,
  fileNotFound,
  loadError,
}

/// Exception thrown when configuration parsing or validation fails
class ConfigurationParsingError extends DeeplinkError {
  final ConfigurationErrorType type;

  ConfigurationParsingError(String message, this.type, {String configPath = ''}) 
      : super(
          message: message,
          code: 'CONFIGURATION_ERROR',
          context: {'type': type.name, 'configPath': configPath},
          timestamp: DateTime.now(),
        );

  @override
  String toString() {
    return 'ConfigurationParsingError(${type.name}): $message';
  }
}