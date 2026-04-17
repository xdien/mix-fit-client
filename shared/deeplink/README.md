# Cross-Platform Deeplink System

A unified deeplink system for handling application navigation through external parameters. Supports desktop (command-line arguments), mobile (URL schemes), and web (URL routing) platforms.

## Features

- **Cross-Platform**: Platform-agnostic interfaces that work across desktop, mobile, and web
- **Configuration-Driven**: Routes and permissions defined in external configuration files
- **Type-Safe**: Full Dart type safety with comprehensive data models
- **Error Handling**: Robust error handling with specific error types
- **Permission System**: Role-based access control for routes
- **Navigation Context**: Maintains navigation history and application state

## Core Components

### Interfaces

- **`IDeeplinkParser`**: Parses deeplink URLs from various sources
- **`IRouteResolver`**: Resolves deeplink requests to application routes
- **`INavigationHandler`**: Handles navigation to specific screens
- **`IPermissionValidator`**: Validates user permissions for routes

### Data Models

- **`DeeplinkRequest`**: Represents a parsed deeplink with scheme, module, feature, and parameters
- **`RouteInfo`**: Contains resolved route information including target screen and permissions
- **`NavigationResult`**: Result of navigation operations with status and metadata
- **`NavigationContext`**: Provides navigation context including user state and history

### Error Handling

- **`DeeplinkError`**: Base class for all deeplink-related errors
- **`DeeplinkParsingError`**: URL parsing failures
- **`RouteResolutionError`**: Route resolution failures
- **`PermissionError`**: Permission validation failures
- **`NavigationError`**: Navigation operation failures
- **`ConfigurationError`**: Configuration loading failures

## Usage Example

```dart
import 'package:deeplink/deeplink.dart';

// Parse a deeplink URL
final parser = DesktopDeeplinkParser();
final request = await parser.parse(['iot://iot/device-list?type=sensor']);

// Resolve the route
final resolver = RouteResolver();
await resolver.loadRouteConfiguration('assets/routes.json');
final route = await resolver.resolveRoute(request);

// Validate permissions
final validator = PermissionValidator();
final hasPermission = await validator.hasPermission('user123', route);

// Navigate if permitted
if (hasPermission) {
  final handler = FlutterNavigationHandler();
  final result = await handler.navigate(route);
  
  if (result.isSuccess) {
    print('Navigation successful: ${result.targetScreen}');
  } else {
    print('Navigation failed: ${result.message}');
  }
}
```

## URL Format

The deeplink system uses a consistent URL format:

```
scheme://module/feature?param1=value1&param2=value2
```

Examples:
- `iot://iot/device-list`
- `iot://iot/device-detail?id=123`
- `iot://iot/monitoring?dashboard=main&timerange=24h`
- `iot://settings/preferences`

## Configuration

### Route Configuration (JSON)

```json
{
  "routes": {
    "iot": {
      "device-list": {
        "screen": "DeviceListScreen",
        "permissions": ["iot.view"],
        "parameters": {
          "type": "optional",
          "status": "optional"
        }
      }
    }
  },
  "fallbacks": {
    "default": "DashboardScreen",
    "permission_denied": "AccessDeniedScreen"
  }
}
```

### Permission Configuration (JSON)

```json
{
  "permissions": {
    "iot.view": {
      "description": "View IoT devices and data",
      "roles": ["iot_manager", "admin"]
    }
  },
  "roles": {
    "admin": {
      "permissions": ["*"]
    }
  }
}
```

## Testing

Run the test suite:

```bash
flutter test
```

The package includes comprehensive tests for:
- Data model serialization and equality
- Interface contracts
- Error handling scenarios
- Configuration parsing

## Platform Implementation

### Desktop (Qt/C++)
- Parse command-line arguments (argv, argc)
- Implement Qt-specific navigation handlers

### Mobile (Flutter)
- Handle URL schemes and intent filters
- Use Flutter navigation system

### Web
- Parse URL routes
- Integrate with web router

## Requirements Addressed

This implementation addresses the following requirements from the specification:

- **5.1**: Cross-platform deeplink handler interfaces with platform-agnostic design
- **5.2**: Reusable business logic across desktop, mobile, and web implementations

## Next Steps

1. Implement platform-specific parsers (Desktop, Mobile, Web)
2. Create route resolver with JSON configuration loading
3. Implement permission validator with role-based access control
4. Build navigation handlers for each platform
5. Add comprehensive integration tests