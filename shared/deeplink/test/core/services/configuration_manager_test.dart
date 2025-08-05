import 'dart:io';
import 'package:test/test.dart';
import 'package:deeplink/core/services/configuration_manager.dart';
import 'package:deeplink/core/services/configuration_parser.dart';

void main() {
  group('ConfigurationManager', () {
    late ConfigurationManager manager;
    late Directory tempDir;
    late File routeConfigFile;
    late File permissionConfigFile;

    setUp(() async {
      manager = ConfigurationManager.instance;
      manager.clear(); // Clear any previous state
      
      // Create temporary directory and config files for testing
      tempDir = await Directory.systemTemp.createTemp('deeplink_config_test');
      routeConfigFile = File('${tempDir.path}/routes.json');
      permissionConfigFile = File('${tempDir.path}/permissions.json');

      // Write valid configuration files
      await routeConfigFile.writeAsString('''
      {
        "routes": {
          "iot": {
            "device-list": {
              "screen": "DeviceListScreen",
              "permissions": ["iot.view"],
              "parameters": {
                "type": {
                  "required": false,
                  "type": "string"
                }
              }
            }
          }
        },
        "fallbacks": {
          "default": "DashboardScreen",
          "permission_denied": "AccessDeniedScreen",
          "not_found": "NotFoundScreen",
          "error": "ErrorScreen"
        }
      }
      ''');

      await permissionConfigFile.writeAsString('''
      {
        "permissions": {
          "iot.view": {
            "description": "View IoT devices",
            "roles": ["iot_manager", "admin"]
          }
        },
        "roles": {
          "admin": {
            "permissions": ["*"],
            "description": "Administrator"
          },
          "iot_manager": {
            "permissions": ["iot.*"],
            "description": "IoT Manager"
          }
        }
      }
      ''');
    });

    tearDown(() async {
      manager.clear();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should initialize with configuration files', () async {
      await manager.initialize(
        routeConfigPath: routeConfigFile.path,
        permissionConfigPath: permissionConfigFile.path,
      );

      expect(manager.isInitialized, isTrue);
      expect(manager.routeConfiguration.hasRoute('iot', 'device-list'), isTrue);
      expect(manager.permissionConfiguration.hasPermission('iot.view'), isTrue);
    });

    test('should initialize with environment', () async {
      // Create environment-specific config files
      final devRouteFile = File('${tempDir.path}/routes.dev.json');
      await devRouteFile.writeAsString('''
      {
        "routes": {
          "debug": {
            "test-screen": {
              "screen": "TestScreen",
              "permissions": [],
              "requiresAuth": false
            }
          }
        },
        "fallbacks": {
          "default": "DashboardScreen",
          "permission_denied": "DashboardScreen",
          "not_found": "NotFoundScreen",
          "error": "ErrorScreen"
        }
      }
      ''');

      final devPermissionFile = File('${tempDir.path}/permissions.dev.json');
      await devPermissionFile.writeAsString('''
      {
        "permissions": {
          "debug.access": {
            "description": "Debug access",
            "roles": ["dev_user"]
          }
        },
        "roles": {
          "dev_user": {
            "permissions": ["*"],
            "description": "Development user"
          }
        }
      }
      ''');

      await manager.initialize(
        routeConfigPath: routeConfigFile.path,
        permissionConfigPath: permissionConfigFile.path,
        environment: 'dev',
      );

      expect(manager.isInitialized, isTrue);
      expect(manager.currentEnvironment, equals('dev'));
      expect(manager.routeConfiguration.hasRoute('debug', 'test-screen'), isTrue);
      expect(manager.permissionConfiguration.hasPermission('debug.access'), isTrue);
    });

    test('should throw StateError when accessing config before initialization', () {
      expect(() => manager.routeConfiguration, throwsStateError);
      expect(() => manager.permissionConfiguration, throwsStateError);
    });

    test('should reload configurations', () async {
      await manager.initialize(
        routeConfigPath: routeConfigFile.path,
        permissionConfigPath: permissionConfigFile.path,
      );

      // Modify the route configuration file
      await routeConfigFile.writeAsString('''
      {
        "routes": {
          "iot": {
            "device-list": {
              "screen": "DeviceListScreen",
              "permissions": ["iot.view"]
            },
            "new-feature": {
              "screen": "NewFeatureScreen",
              "permissions": ["iot.view"]
            }
          }
        },
        "fallbacks": {
          "default": "DashboardScreen",
          "permission_denied": "AccessDeniedScreen",
          "not_found": "NotFoundScreen",
          "error": "ErrorScreen"
        }
      }
      ''');

      await manager.reload();

      expect(manager.routeConfiguration.hasRoute('iot', 'new-feature'), isTrue);
    });

    test('should set environment and reload', () async {
      await manager.initialize(
        routeConfigPath: routeConfigFile.path,
        permissionConfigPath: permissionConfigFile.path,
      );

      expect(manager.currentEnvironment, isNull);

      // Create dev environment files
      final devRouteFile = File('${tempDir.path}/routes.dev.json');
      await devRouteFile.writeAsString('''
      {
        "routes": {
          "debug": {
            "test": {
              "screen": "TestScreen",
              "permissions": []
            }
          }
        },
        "fallbacks": {
          "default": "DashboardScreen",
          "permission_denied": "AccessDeniedScreen",
          "not_found": "NotFoundScreen",
          "error": "ErrorScreen"
        }
      }
      ''');

      final devPermissionFile = File('${tempDir.path}/permissions.dev.json');
      await devPermissionFile.writeAsString('''
      {
        "permissions": {
          "debug.test": {
            "description": "Debug test",
            "roles": ["dev"]
          }
        },
        "roles": {
          "dev": {
            "permissions": ["*"],
            "description": "Developer"
          }
        }
      }
      ''');

      await manager.setEnvironment('dev');

      expect(manager.currentEnvironment, equals('dev'));
      expect(manager.routeConfiguration.hasRoute('debug', 'test'), isTrue);
    });

    test('should reload individual configurations', () async {
      await manager.initialize(
        routeConfigPath: routeConfigFile.path,
        permissionConfigPath: permissionConfigFile.path,
      );

      // Modify only the route configuration
      await routeConfigFile.writeAsString('''
      {
        "routes": {
          "iot": {
            "device-list": {
              "screen": "DeviceListScreen",
              "permissions": ["iot.view"]
            },
            "updated-feature": {
              "screen": "UpdatedFeatureScreen",
              "permissions": ["iot.view"]
            }
          }
        },
        "fallbacks": {
          "default": "DashboardScreen",
          "permission_denied": "AccessDeniedScreen",
          "not_found": "NotFoundScreen",
          "error": "ErrorScreen"
        }
      }
      ''');

      await manager.reloadRouteConfiguration();

      expect(manager.routeConfiguration.hasRoute('iot', 'updated-feature'), isTrue);
      // Permission configuration should remain unchanged
      expect(manager.permissionConfiguration.hasPermission('iot.view'), isTrue);
    });

    test('should get configuration summary', () async {
      await manager.initialize(
        routeConfigPath: routeConfigFile.path,
        permissionConfigPath: permissionConfigFile.path,
      );

      final summary = manager.getConfigurationSummary();

      expect(summary['initialized'], isTrue);
      expect(summary['environment'], isNull);
      expect(summary['routeConfigPath'], equals(routeConfigFile.path));
      expect(summary['permissionConfigPath'], equals(permissionConfigFile.path));
      expect(summary['routeModules'], contains('iot'));
      expect(summary['permissionCount'], equals(1));
      expect(summary['roleCount'], equals(2));
    });

    test('should validate route permissions', () async {
      // Create configuration with invalid permission reference
      await routeConfigFile.writeAsString('''
      {
        "routes": {
          "iot": {
            "device-list": {
              "screen": "DeviceListScreen",
              "permissions": ["iot.view", "unknown.permission"]
            }
          }
        },
        "fallbacks": {
          "default": "DashboardScreen",
          "permission_denied": "AccessDeniedScreen",
          "not_found": "NotFoundScreen",
          "error": "ErrorScreen"
        }
      }
      ''');

      expect(
        () => manager.initialize(
          routeConfigPath: routeConfigFile.path,
          permissionConfigPath: permissionConfigFile.path,
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('should handle file not found error', () async {
      expect(
        () => manager.initialize(
          routeConfigPath: '/non/existent/routes.json',
          permissionConfigPath: permissionConfigFile.path,
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('should clear configuration', () async {
      await manager.initialize(
        routeConfigPath: routeConfigFile.path,
        permissionConfigPath: permissionConfigFile.path,
      );

      expect(manager.isInitialized, isTrue);

      manager.clear();

      expect(manager.isInitialized, isFalse);
      expect(manager.currentEnvironment, isNull);
    });
  });

  group('EnvironmentConfig', () {
    test('should identify development environment', () {
      expect(EnvironmentConfig.isDevelopment('dev'), isTrue);
      expect(EnvironmentConfig.isDevelopment('development'), isFalse);
      expect(EnvironmentConfig.isDevelopment('prod'), isFalse);
    });

    test('should identify production environment', () {
      expect(EnvironmentConfig.isProduction('prod'), isTrue);
      expect(EnvironmentConfig.isProduction('production'), isFalse);
      expect(EnvironmentConfig.isProduction('dev'), isFalse);
    });

    test('should identify testing environment', () {
      expect(EnvironmentConfig.isTesting('test'), isTrue);
      expect(EnvironmentConfig.isTesting('testing'), isFalse);
      expect(EnvironmentConfig.isTesting('dev'), isFalse);
    });

    test('should get environment with default', () {
      final env = EnvironmentConfig.getEnvironment(defaultEnvironment: 'dev');
      expect(env, equals('dev'));
    });

    test('should get environment without default', () {
      final env = EnvironmentConfig.getEnvironment();
      expect(env, isNull);
    });
  });
}