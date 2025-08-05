# Deeplink Configuration System

The deeplink configuration system provides a flexible, JSON-based approach to define routes and permissions for cross-platform deeplink navigation. This system supports environment-specific configurations and comprehensive validation.

## Overview

The configuration system consists of two main components:

1. **Route Configuration**: Defines available deeplink routes, their target screens, required parameters, and permissions
2. **Permission Configuration**: Defines permissions and roles that control access to routes

## Configuration Files

### Route Configuration (`routes.json`)

Defines the available deeplink routes in your application:

```json
{
  "routes": {
    "module_name": {
      "feature_name": {
        "screen": "TargetScreenName",
        "permissions": ["required.permission"],
        "parameters": {
          "param_name": {
            "required": true,
            "type": "string",
            "defaultValue": "default",
            "pattern": "^\\w+$",
            "description": "Parameter description"
          }
        },
        "requiresAuth": true,
        "fallbackRoute": "FallbackScreen",
        "metadata": {
          "custom": "value"
        }
      }
    }
  },
  "fallbacks": {
    "default": "DashboardScreen",
    "permission_denied": "AccessDeniedScreen",
    "not_found": "NotFoundScreen",
    "error": "ErrorScreen"
  },
  "metadata": {
    "version": "1.0.0",
    "description": "Route configuration"
  }
}
```

### Permission Configuration (`permissions.json`)

Defines permissions and roles for access control:

```json
{
  "permissions": {
    "permission.name": {
      "description": "Permission description",
      "category": "category_name",
      "roles": ["role1", "role2"],
      "isSystem": false
    }
  },
  "roles": {
    "role_name": {
      "permissions": ["permission1", "permission2", "module.*"],
      "description": "Role description",
      "inherits": ["parent_role"],
      "isSystem": false
    }
  },
  "metadata": {
    "version": "1.0.0",
    "description": "Permission configuration"
  }
}
```

## Environment-Specific Configuration

The system supports environment-specific configuration overrides:

- Base configuration: `routes.json`, `permissions.json`
- Development: `routes.dev.json`, `permissions.dev.json`
- Staging: `routes.staging.json`, `permissions.staging.json`
- Production: `routes.prod.json`, `permissions.prod.json`

Environment-specific files override the base configuration completely.

## Usage

### Basic Setup

```dart
import 'package:deeplink/deeplink.dart';

// Initialize configuration manager
final configManager = ConfigurationManager.instance;

await configManager.initialize(
  routeConfigPath: 'assets/config/routes.json',
  permissionConfigPath: 'assets/config/permissions.json',
  environment: 'dev', // Optional
);

// Access configurations
final routeConfig = configManager.routeConfiguration;
final permissionConfig = configManager.permissionConfiguration;
```

### Loading Configurations Manually

```dart
import 'package:deeplink/deeplink.dart';

// Parse from JSON string
final routeConfig = ConfigurationParser.parseRouteConfiguration(jsonString);
final permissionConfig = ConfigurationParser.parsePermissionConfiguration(jsonString);

// Load from file
final routeConfig = await ConfigurationParser.loadRouteConfiguration(
  'config/routes.json',
  environment: 'dev',
);
```

### Environment Management

```dart
// Check current environment
final currentEnv = configManager.currentEnvironment;

// Switch environment
await configManager.setEnvironment('prod');

// Reload configurations
await configManager.reload();
```

## Route Configuration Details

### Module and Feature Names

- Must be lowercase alphanumeric with optional hyphens/underscores
- Examples: `iot`, `user-management`, `cms_module`

### Screen Names

- Target screen or component to navigate to
- Should match your application's screen/route names
- Examples: `DeviceListScreen`, `UserProfilePage`

### Parameters

Parameters define the expected URL parameters for a route:

```json
{
  "parameters": {
    "id": {
      "required": true,
      "type": "string",
      "description": "Entity ID"
    },
    "tab": {
      "required": false,
      "type": "string",
      "defaultValue": "overview",
      "pattern": "^(overview|details|settings)$",
      "description": "Tab to display"
    }
  }
}
```

**Parameter Types**: `string`, `int`, `bool`, `double`

### Permissions

Routes can require specific permissions:

```json
{
  "permissions": ["module.view", "module.edit"]
}
```

## Permission Configuration Details

### Permission Names

- Use dot notation: `module.action`
- Examples: `iot.view`, `user.profile.edit`, `cms.nhansu.manage`

### Wildcard Permissions

- `*`: All permissions
- `module.*`: All permissions in a module
- Examples: `iot.*`, `cms.*`

### Role Inheritance

Roles can inherit permissions from parent roles:

```json
{
  "roles": {
    "manager": {
      "permissions": ["module.manage"],
      "inherits": ["staff"]
    },
    "staff": {
      "permissions": ["module.view"]
    }
  }
}
```

## Validation

The configuration system performs comprehensive validation:

### Route Validation

- Module/feature names must follow naming conventions
- Screen names cannot be empty
- Permission names must use valid dot notation
- Parameter types must be valid
- Regex patterns must be valid

### Permission Validation

- Permission names must use dot notation
- Role names must follow naming conventions
- Referenced permissions must exist
- Inherited roles must exist
- Circular inheritance is detected and prevented

### Cross-Reference Validation

- Route permissions must exist in permission configuration
- All referenced roles and permissions are validated

## Error Handling

The system provides detailed error messages for configuration issues:

```dart
try {
  final config = ConfigurationParser.parseRouteConfiguration(jsonContent);
} on ConfigurationError catch (e) {
  print('Configuration error: ${e.message}');
  print('Error type: ${e.type}');
  print('Context: ${e.context}');
}
```

### Error Types

- `invalidFormat`: JSON parsing errors
- `parsingError`: General parsing failures
- `validationError`: Configuration validation failures
- `fileNotFound`: Configuration file not found
- `loadError`: File loading errors

## Best Practices

### Route Organization

- Group related features under logical modules
- Use consistent naming conventions
- Document parameters and their purposes
- Define appropriate fallback routes

### Permission Design

- Follow principle of least privilege
- Use hierarchical permission structure
- Group permissions by functional area
- Document role purposes and capabilities

### Environment Configuration

- Keep production configurations secure
- Use minimal permissions in development
- Test with realistic permission scenarios
- Document environment-specific differences

### Validation and Testing

- Validate configurations in CI/CD pipeline
- Test with various user roles
- Verify cross-references between configurations
- Monitor configuration loading performance

## Example Configurations

See the `example/config/` directory for complete configuration examples:

- `routes.json`: Production route configuration
- `routes.dev.json`: Development route configuration
- `permissions.json`: Production permission configuration
- `permissions.dev.json`: Development permission configuration

## Integration with Route Resolver

The configuration system integrates seamlessly with the route resolver:

```dart
class MyRouteResolver implements IRouteResolver {
  final ConfigurationManager _configManager;

  MyRouteResolver(this._configManager);

  @override
  Future<RouteInfo> resolveRoute(DeeplinkRequest request) async {
    final routeConfig = _configManager.routeConfiguration;
    final routeDef = routeConfig.getRoute(request.module, request.feature);
    
    if (routeDef == null) {
      throw RouteResolutionError.routeNotFound(
        module: request.module,
        feature: request.feature,
      );
    }

    return RouteInfo(
      routeId: '${request.module}/${request.feature}',
      module: request.module,
      feature: request.feature,
      targetScreen: routeDef.screen,
      parameters: request.parameters,
      requiredPermissions: routeDef.permissions,
      fallbackRoute: routeDef.fallbackRoute ?? 
                     routeConfig.fallbacks.defaultRoute,
      requiresAuth: routeDef.requiresAuth,
    );
  }

  @override
  bool isRouteSupported(String module, String feature) {
    return _configManager.routeConfiguration.hasRoute(module, feature);
  }

  @override
  Future<void> loadRouteConfiguration(String configPath) async {
    // Configuration loading is handled by ConfigurationManager
    await _configManager.reloadRouteConfiguration();
  }

  @override
  List<String> getAvailableRoutes(String module) {
    return _configManager.routeConfiguration.getAvailableFeatures(module);
  }
}
```